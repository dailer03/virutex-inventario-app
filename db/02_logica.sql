-- =====================================================================
-- Archivo : 02_logica.sql
-- Objeto  : disparadores, vistas y procedimientos que garantizan las
--           reglas del negocio dentro de la base de datos.
-- Nota    : en phpMyAdmin, importar el archivo completo desde la
--           pestaña Importar (reconoce la instrucción DELIMITER).
-- =====================================================================
USE virutex_inventario;

DROP TRIGGER IF EXISTS tr_movimiento_bi;
DROP TRIGGER IF EXISTS tr_movimiento_bu;
DROP TRIGGER IF EXISTS tr_movimiento_bd;
DROP TRIGGER IF EXISTS tr_repuesto_au;

DELIMITER $$

-- HU-05, HU-06, HU-07: aplica cada movimiento al stock dentro de la
-- misma transacción y rechaza los que dejarían el stock negativo.
CREATE TRIGGER tr_movimiento_bi BEFORE INSERT ON movimiento
FOR EACH ROW
BEGIN
  DECLARE v_stock  DECIMAL(10,2);
  DECLARE v_activo TINYINT;
  DECLARE v_delta  DECIMAL(10,2);

  SELECT stock_actual, activo INTO v_stock, v_activo
    FROM repuesto WHERE id_repuesto = NEW.id_repuesto FOR UPDATE;

  IF v_activo = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El repuesto esta inactivo';
  END IF;

  SET v_delta = CASE WHEN NEW.tipo = 'salida' THEN -NEW.cantidad ELSE NEW.cantidad END;

  IF v_stock + v_delta < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para registrar el movimiento';
  END IF;

  SET NEW.stock_resultante = v_stock + v_delta;
  UPDATE repuesto SET stock_actual = v_stock + v_delta WHERE id_repuesto = NEW.id_repuesto;
END$$

-- RNF-04: los movimientos no se modifican ni se eliminan.
CREATE TRIGGER tr_movimiento_bu BEFORE UPDATE ON movimiento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos no se modifican; registre un ajuste';
END$$

CREATE TRIGGER tr_movimiento_bd BEFORE DELETE ON movimiento
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los movimientos no se eliminan; registre un ajuste';
END$$

-- HU-09: genera o atiende la alerta de stock mínimo cuando cambia el
-- stock o el stock mínimo de un repuesto.
CREATE TRIGGER tr_repuesto_au AFTER UPDATE ON repuesto
FOR EACH ROW
BEGIN
  DECLARE v_activas INT DEFAULT 0;

  IF NEW.stock_actual <> OLD.stock_actual OR NEW.stock_minimo <> OLD.stock_minimo THEN
    SELECT COUNT(*) INTO v_activas FROM alerta
     WHERE id_repuesto = NEW.id_repuesto AND tipo = 'stock_minimo' AND estado = 'activa';

    IF NEW.stock_actual <= NEW.stock_minimo AND NEW.activo = 1 THEN
      IF v_activas = 0 THEN
        INSERT INTO alerta (id_repuesto, tipo, stock_al_generar)
        VALUES (NEW.id_repuesto, 'stock_minimo', NEW.stock_actual);
      END IF;
    ELSEIF v_activas > 0 THEN
      UPDATE alerta SET estado = 'atendida', fecha_atencion = NOW()
       WHERE id_repuesto = NEW.id_repuesto AND tipo = 'stock_minimo' AND estado = 'activa';
    END IF;
  END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- Vistas
-- ---------------------------------------------------------------------

-- HU-03: inventario con ubicación y estado de stock
CREATE OR REPLACE VIEW v_inventario AS
SELECT r.id_repuesto, r.codigo, r.nombre, r.descripcion,
       m.codigo AS maquina_codigo, m.nombre AS maquina,
       u.codigo AS unidad,
       CASE WHEN ub.id_ubicacion IS NULL THEN NULL
            ELSE CONCAT(ub.estanteria, '-', ub.cajon) END AS ubicacion,
       r.stock_actual, r.stock_minimo,
       CASE WHEN r.stock_actual = 0 THEN 'agotado'
            WHEN r.stock_actual <= r.stock_minimo THEN 'bajo'
            ELSE 'normal' END AS estado_stock
  FROM repuesto r
  JOIN maquina m        ON m.id_maquina = r.id_maquina
  JOIN unidad_medida u  ON u.id_unidad = r.id_unidad
  LEFT JOIN ubicacion ub ON ub.id_ubicacion = r.id_ubicacion
 WHERE r.activo = 1;

-- HU-07: historial de movimientos con responsables
CREATE OR REPLACE VIEW v_historial_movimientos AS
SELECT mv.id_movimiento, mv.fecha_movimiento, mv.tipo,
       r.id_repuesto, r.codigo, r.nombre AS repuesto,
       mv.cantidad, mv.stock_resultante,
       m.codigo AS maquina_destino,
       ur.nombre_usuario AS registrado_por,
       uc.nombre_usuario AS recibido_por,
       mv.motivo, mv.observacion
  FROM movimiento mv
  JOIN repuesto r      ON r.id_repuesto = mv.id_repuesto
  JOIN usuario ur      ON ur.id_usuario = mv.id_usuario_registra
  LEFT JOIN usuario uc ON uc.id_usuario = mv.id_usuario_recibe
  LEFT JOIN maquina m  ON m.id_maquina = mv.id_maquina_destino;

-- HU-12: repuestos por debajo del mínimo
CREATE OR REPLACE VIEW v_repuestos_bajo_minimo AS
SELECT * FROM v_inventario WHERE estado_stock IN ('bajo', 'agotado');

-- HU-13: consumo de los últimos N días (parámetro periodo_analisis_dias)
CREATE OR REPLACE VIEW v_consumo_repuesto AS
SELECT r.id_repuesto, r.codigo, r.nombre, r.stock_actual, r.stock_minimo,
       u.permite_decimales,
       COUNT(mv.id_movimiento)                    AS num_salidas,
       COALESCE(SUM(mv.cantidad), 0)              AS total_salidas,
       ROUND(COALESCE(SUM(mv.cantidad), 0) / pa.valor, 4) AS consumo_diario
  FROM repuesto r
  JOIN unidad_medida u ON u.id_unidad = r.id_unidad
  JOIN parametro pa    ON pa.clave = 'periodo_analisis_dias'
  LEFT JOIN movimiento mv
         ON mv.id_repuesto = r.id_repuesto
        AND mv.tipo = 'salida'
        AND mv.fecha_movimiento >= DATE_SUB(NOW(), INTERVAL pa.valor DAY)
 WHERE r.activo = 1
 GROUP BY r.id_repuesto, r.codigo, r.nombre, r.stock_actual, r.stock_minimo,
          u.permite_decimales, pa.valor;

-- HU-13, HU-15, HU-14: cobertura, cantidad sugerida y condición de alerta preventiva
CREATE OR REPLACE VIEW v_estimacion_reposicion AS
SELECT c.id_repuesto, c.codigo, c.nombre, c.stock_actual, c.stock_minimo,
       c.num_salidas, c.consumo_diario,
       pv.nombre AS proveedor_principal,
       rp.tiempo_reposicion_dias,
       CASE WHEN c.num_salidas >= ms.valor AND c.consumo_diario > 0 THEN 1 ELSE 0 END AS estimable,
       CASE WHEN c.num_salidas >= ms.valor AND c.consumo_diario > 0
            THEN ROUND(c.stock_actual / c.consumo_diario, 1) END AS cobertura_dias,
       CASE WHEN c.num_salidas >= ms.valor AND c.consumo_diario > 0 AND rp.tiempo_reposicion_dias IS NOT NULL
            THEN CASE WHEN c.permite_decimales = 1
                      THEN GREATEST(0, ROUND(c.consumo_diario * (rp.tiempo_reposicion_dias + pr.valor) + c.stock_minimo - c.stock_actual, 2))
                      ELSE GREATEST(0, CEILING(c.consumo_diario * (rp.tiempo_reposicion_dias + pr.valor) + c.stock_minimo - c.stock_actual))
                 END END AS cantidad_sugerida,
       CASE WHEN c.num_salidas >= ms.valor AND c.consumo_diario > 0
             AND rp.tiempo_reposicion_dias IS NOT NULL
             AND c.stock_actual / c.consumo_diario < rp.tiempo_reposicion_dias
            THEN 1 ELSE 0 END AS requiere_alerta_preventiva
  FROM v_consumo_repuesto c
  JOIN parametro ms ON ms.clave = 'minimo_salidas_estimacion'
  JOIN parametro pr ON pr.clave = 'periodo_revision_dias'
  LEFT JOIN repuesto_proveedor rp ON rp.id_repuesto = c.id_repuesto AND rp.es_principal = 1
  LEFT JOIN proveedor pv          ON pv.id_proveedor = rp.id_proveedor;

-- HU-09, HU-14: alertas activas para el supervisor y el almacén
CREATE OR REPLACE VIEW v_alertas_activas AS
SELECT a.id_alerta, a.tipo, a.fecha_generacion, r.codigo, r.nombre AS repuesto,
       a.stock_al_generar, r.stock_actual, r.stock_minimo,
       a.cobertura_dias, a.cantidad_sugerida
  FROM alerta a
  JOIN repuesto r ON r.id_repuesto = a.id_repuesto
 WHERE a.estado = 'activa';

-- ---------------------------------------------------------------------
-- Procedimientos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_actualizar_alertas_preventivas;
DROP PROCEDURE IF EXISTS sp_informe_movimientos;

DELIMITER $$

-- HU-14: la API lo ejecuta después de sincronizar salidas y al consultar alertas
CREATE PROCEDURE sp_actualizar_alertas_preventivas()
SQL SECURITY DEFINER
BEGIN
  UPDATE alerta SET estado = 'atendida', fecha_atencion = NOW()
   WHERE tipo = 'preventiva' AND estado = 'activa'
     AND id_repuesto IN (SELECT id_repuesto FROM v_estimacion_reposicion
                          WHERE requiere_alerta_preventiva = 0);

  INSERT INTO alerta (id_repuesto, tipo, stock_al_generar, cobertura_dias, cantidad_sugerida)
  SELECT e.id_repuesto, 'preventiva', e.stock_actual, e.cobertura_dias, e.cantidad_sugerida
    FROM v_estimacion_reposicion e
   WHERE e.requiere_alerta_preventiva = 1
     AND NOT EXISTS (SELECT 1 FROM alerta a
                      WHERE a.id_repuesto = e.id_repuesto
                        AND a.tipo = 'preventiva' AND a.estado = 'activa');
END$$

-- HU-12: movimientos del periodo agrupados por repuesto
CREATE PROCEDURE sp_informe_movimientos(IN p_desde DATE, IN p_hasta DATE)
SQL SECURITY DEFINER
BEGIN
  SELECT r.codigo, r.nombre,
         SUM(CASE WHEN mv.tipo = 'entrada' THEN mv.cantidad ELSE 0 END) AS entradas,
         SUM(CASE WHEN mv.tipo = 'salida'  THEN mv.cantidad ELSE 0 END) AS salidas,
         SUM(CASE WHEN mv.tipo = 'ajuste'  THEN mv.cantidad ELSE 0 END) AS ajustes,
         COUNT(*) AS num_movimientos
    FROM movimiento mv
    JOIN repuesto r ON r.id_repuesto = mv.id_repuesto
   WHERE mv.fecha_movimiento >= p_desde
     AND mv.fecha_movimiento <  DATE_ADD(p_hasta, INTERVAL 1 DAY)
   GROUP BY r.codigo, r.nombre
   ORDER BY r.codigo;
END$$

DELIMITER ;
