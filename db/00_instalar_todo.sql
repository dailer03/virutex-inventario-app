-- Instalación completa: ejecuta en orden 01_esquema, 02_logica, 03_seguridad y 04_datos_prueba.
-- Importar en phpMyAdmin (pestaña Importar) con el usuario root de XAMPP.

-- >>>>> 01_esquema.sql
-- =====================================================================
-- Proyecto: Aplicación móvil para la gestión del inventario de
--           repuestos críticos del área de insertado - Virutex Ilko
-- Archivo : 01_esquema.sql  (Sprint 1 - diseño y base de datos)
-- Motor   : MariaDB 10.4+ (XAMPP) / MySQL 8.0+
-- Objeto  : crea la base de datos, tablas, relaciones, restricciones
--           e índices.
-- Autores : Johan Velasco, Dailer Silva
-- =====================================================================

DROP DATABASE IF EXISTS virutex_inventario;
CREATE DATABASE virutex_inventario
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE virutex_inventario;

-- ---------------------------------------------------------------------
-- Seguridad y usuarios (HU-01, HU-16, RNF-02)
-- ---------------------------------------------------------------------
CREATE TABLE rol (
  id_rol      TINYINT UNSIGNED NOT NULL,
  nombre      VARCHAR(20)      NOT NULL,
  descripcion VARCHAR(150)     NOT NULL,
  CONSTRAINT pk_rol PRIMARY KEY (id_rol),
  CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuario (
  id_usuario        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nombre_completo   VARCHAR(100)     NOT NULL,
  nombre_usuario    VARCHAR(30)      NOT NULL,
  contrasena_hash   VARCHAR(255)     NOT NULL,
  id_rol            TINYINT UNSIGNED NOT NULL,
  activo            TINYINT(1)       NOT NULL DEFAULT 1,
  intentos_fallidos TINYINT UNSIGNED NOT NULL DEFAULT 0,
  bloqueado_hasta   DATETIME         NULL,
  fecha_creacion    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_creado_por     INT UNSIGNED     NULL,
  CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
  CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES rol (id_rol),
  CONSTRAINT fk_usuario_creador FOREIGN KEY (id_creado_por) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_usuario_activo CHECK (activo IN (0, 1)),
  CONSTRAINT ck_usuario_hash CHECK (CHAR_LENGTH(contrasena_hash) >= 60)
) ENGINE=InnoDB;

CREATE TABLE sesion (
  id_sesion        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario       INT UNSIGNED    NOT NULL,
  token_hash       CHAR(64)        NOT NULL,
  fecha_inicio     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion DATETIME        NOT NULL,
  revocada         TINYINT(1)      NOT NULL DEFAULT 0,
  CONSTRAINT pk_sesion PRIMARY KEY (id_sesion),
  CONSTRAINT uq_sesion_token UNIQUE (token_hash),
  CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_sesion_fechas CHECK (fecha_expiracion > fecha_inicio)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Catálogos (HU-02, HU-04, H-13, V-03)
-- ---------------------------------------------------------------------
CREATE TABLE unidad_medida (
  id_unidad         TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo            VARCHAR(5)       NOT NULL,
  nombre            VARCHAR(30)      NOT NULL,
  permite_decimales TINYINT(1)       NOT NULL DEFAULT 0,
  CONSTRAINT pk_unidad_medida PRIMARY KEY (id_unidad),
  CONSTRAINT uq_unidad_codigo UNIQUE (codigo),
  CONSTRAINT uq_unidad_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE maquina (
  id_maquina SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo     VARCHAR(10)       NOT NULL,
  nombre     VARCHAR(60)       NOT NULL,
  activa     TINYINT(1)        NOT NULL DEFAULT 1,
  CONSTRAINT pk_maquina PRIMARY KEY (id_maquina),
  CONSTRAINT uq_maquina_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE ubicacion (
  id_ubicacion SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  estanteria   VARCHAR(10)       NOT NULL,
  cajon        VARCHAR(10)       NOT NULL,
  CONSTRAINT pk_ubicacion PRIMARY KEY (id_ubicacion),
  CONSTRAINT uq_ubicacion UNIQUE (estanteria, cajon)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Repuestos (HU-02, HU-03, HU-04, HU-08)
-- ---------------------------------------------------------------------
CREATE TABLE repuesto (
  id_repuesto         INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  codigo              VARCHAR(20)       NOT NULL,
  nombre              VARCHAR(100)      NOT NULL,
  descripcion         VARCHAR(255)      NULL,
  id_maquina          SMALLINT UNSIGNED NOT NULL,
  id_unidad           TINYINT UNSIGNED  NOT NULL,
  id_ubicacion        SMALLINT UNSIGNED NULL,
  stock_actual        DECIMAL(10,2)     NOT NULL DEFAULT 0,
  stock_minimo        DECIMAL(10,2)     NOT NULL DEFAULT 0,
  activo              TINYINT(1)        NOT NULL DEFAULT 1,
  fecha_registro      DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario_registro INT UNSIGNED      NOT NULL,
  CONSTRAINT pk_repuesto PRIMARY KEY (id_repuesto),
  CONSTRAINT uq_repuesto_codigo UNIQUE (codigo),
  CONSTRAINT fk_repuesto_maquina FOREIGN KEY (id_maquina) REFERENCES maquina (id_maquina),
  CONSTRAINT fk_repuesto_unidad FOREIGN KEY (id_unidad) REFERENCES unidad_medida (id_unidad),
  CONSTRAINT fk_repuesto_ubicacion FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion),
  CONSTRAINT fk_repuesto_usuario FOREIGN KEY (id_usuario_registro) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_repuesto_codigo CHECK (TRIM(codigo) <> '' AND UPPER(TRIM(codigo)) <> 'NA'),
  CONSTRAINT ck_repuesto_stock CHECK (stock_actual >= 0),
  CONSTRAINT ck_repuesto_minimo CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

CREATE INDEX ix_repuesto_nombre  ON repuesto (nombre);
CREATE INDEX ix_repuesto_maquina ON repuesto (id_maquina);

-- ---------------------------------------------------------------------
-- Movimientos (HU-05, HU-06, HU-07, RNF-04, RNF-06)
-- Los movimientos no se modifican ni se eliminan (ver 02_logica.sql).
-- ---------------------------------------------------------------------
CREATE TABLE movimiento (
  id_movimiento         BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
  uuid_cliente          CHAR(36)          NOT NULL,
  tipo                  ENUM('entrada','salida','ajuste') NOT NULL,
  id_repuesto           INT UNSIGNED      NOT NULL,
  cantidad              DECIMAL(10,2)     NOT NULL,
  stock_resultante      DECIMAL(10,2)     NOT NULL DEFAULT 0,
  id_maquina_destino    SMALLINT UNSIGNED NULL,
  id_usuario_registra   INT UNSIGNED      NOT NULL,
  id_usuario_recibe     INT UNSIGNED      NULL,
  motivo                VARCHAR(255)      NULL,
  observacion           VARCHAR(255)      NULL,
  fecha_movimiento      DATETIME          NOT NULL,
  fecha_sincronizacion  DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_movimiento PRIMARY KEY (id_movimiento),
  CONSTRAINT uq_movimiento_uuid UNIQUE (uuid_cliente),
  CONSTRAINT fk_mov_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT fk_mov_maquina FOREIGN KEY (id_maquina_destino) REFERENCES maquina (id_maquina),
  CONSTRAINT fk_mov_registra FOREIGN KEY (id_usuario_registra) REFERENCES usuario (id_usuario),
  CONSTRAINT fk_mov_recibe FOREIGN KEY (id_usuario_recibe) REFERENCES usuario (id_usuario),
  CONSTRAINT ck_mov_cantidad CHECK (
    (tipo IN ('entrada','salida') AND cantidad > 0) OR (tipo = 'ajuste' AND cantidad <> 0)),
  CONSTRAINT ck_mov_salida_destino CHECK (tipo <> 'salida' OR id_maquina_destino IS NOT NULL),
  CONSTRAINT ck_mov_ajuste_motivo CHECK (tipo <> 'ajuste' OR (motivo IS NOT NULL AND TRIM(motivo) <> ''))
) ENGINE=InnoDB;

CREATE INDEX ix_mov_repuesto_fecha ON movimiento (id_repuesto, fecha_movimiento);
CREATE INDEX ix_mov_tipo_fecha     ON movimiento (tipo, fecha_movimiento);

-- Salidas registradas sin conexión que no pudieron aplicarse al sincronizar
CREATE TABLE conflicto_sincronizacion (
  id_conflicto        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid_cliente        CHAR(36)        NOT NULL,
  id_usuario          INT UNSIGNED    NOT NULL,
  id_repuesto         INT UNSIGNED    NOT NULL,
  tipo                ENUM('entrada','salida','ajuste') NOT NULL,
  cantidad            DECIMAL(10,2)   NOT NULL,
  fecha_movimiento    DATETIME        NOT NULL,
  causa               VARCHAR(255)    NOT NULL,
  estado              ENUM('pendiente','resuelto') NOT NULL DEFAULT 'pendiente',
  fecha_registro      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_conflicto PRIMARY KEY (id_conflicto),
  CONSTRAINT uq_conflicto_uuid UNIQUE (uuid_cliente),
  CONSTRAINT fk_conflicto_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
  CONSTRAINT fk_conflicto_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Proveedores (HU-10). Sin precios ni condiciones comerciales (Tabla 15).
-- ---------------------------------------------------------------------
CREATE TABLE proveedor (
  id_proveedor    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(100)      NOT NULL,
  nombre_contacto VARCHAR(100)      NULL,
  telefono        VARCHAR(20)       NULL,
  correo          VARCHAR(100)      NULL,
  activo          TINYINT(1)        NOT NULL DEFAULT 1,
  CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
  CONSTRAINT uq_proveedor_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE repuesto_proveedor (
  id_repuesto            INT UNSIGNED      NOT NULL,
  id_proveedor           SMALLINT UNSIGNED NOT NULL,
  tiempo_reposicion_dias SMALLINT UNSIGNED NOT NULL,
  es_principal           TINYINT(1)        NOT NULL DEFAULT 0,
  -- Solo tiene valor cuando el proveedor es el principal: garantiza uno por repuesto
  principal_de           INT UNSIGNED AS (CASE WHEN es_principal = 1 THEN id_repuesto END) STORED,
  CONSTRAINT pk_repuesto_proveedor PRIMARY KEY (id_repuesto, id_proveedor),
  CONSTRAINT fk_rp_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT fk_rp_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor),
  CONSTRAINT uq_rp_principal UNIQUE (principal_de),
  CONSTRAINT ck_rp_tiempo CHECK (tiempo_reposicion_dias > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Alertas (HU-09, HU-14)
-- ---------------------------------------------------------------------
CREATE TABLE alerta (
  id_alerta         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  id_repuesto       INT UNSIGNED  NOT NULL,
  tipo              ENUM('stock_minimo','preventiva') NOT NULL,
  estado            ENUM('activa','atendida')         NOT NULL DEFAULT 'activa',
  stock_al_generar  DECIMAL(10,2) NOT NULL,
  cobertura_dias    DECIMAL(8,1)  NULL,
  cantidad_sugerida DECIMAL(10,2) NULL,
  fecha_generacion  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_atencion    DATETIME      NULL,
  -- Solo tiene valor mientras la alerta está activa: una activa por repuesto y tipo
  activa_de         INT UNSIGNED AS (CASE WHEN estado = 'activa' THEN id_repuesto END) STORED,
  CONSTRAINT pk_alerta PRIMARY KEY (id_alerta),
  CONSTRAINT fk_alerta_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT uq_alerta_activa UNIQUE (activa_de, tipo),
  CONSTRAINT ck_alerta_atencion CHECK (estado = 'activa' OR fecha_atencion IS NOT NULL)
) ENGINE=InnoDB;

CREATE INDEX ix_alerta_estado ON alerta (estado, tipo);

-- ---------------------------------------------------------------------
-- Solicitudes de repuestos (HU-11)
-- ---------------------------------------------------------------------
CREATE TABLE solicitud (
  id_solicitud        INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  id_repuesto         INT UNSIGNED      NOT NULL,
  id_proveedor        SMALLINT UNSIGNED NULL,
  cantidad            DECIMAL(10,2)     NOT NULL,
  estado              ENUM('pendiente','enviada','recibida','anulada') NOT NULL DEFAULT 'pendiente',
  id_usuario_solicita INT UNSIGNED      NOT NULL,
  fecha_solicitud     DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_envio         DATETIME          NULL,
  fecha_recepcion     DATETIME          NULL,
  observacion         VARCHAR(255)      NULL,
  -- Solo tiene valor mientras la solicitud está abierta: una abierta por repuesto
  abierta_de          INT UNSIGNED AS (CASE WHEN estado IN ('pendiente','enviada') THEN id_repuesto END) STORED,
  CONSTRAINT pk_solicitud PRIMARY KEY (id_solicitud),
  CONSTRAINT fk_sol_repuesto FOREIGN KEY (id_repuesto) REFERENCES repuesto (id_repuesto),
  CONSTRAINT fk_sol_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor),
  CONSTRAINT fk_sol_usuario FOREIGN KEY (id_usuario_solicita) REFERENCES usuario (id_usuario),
  CONSTRAINT uq_sol_abierta UNIQUE (abierta_de),
  CONSTRAINT ck_sol_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Parámetros configurables (HU-13, HU-15, RNF-02)
-- ---------------------------------------------------------------------
CREATE TABLE parametro (
  clave       VARCHAR(40)   NOT NULL,
  valor       DECIMAL(10,2) NOT NULL,
  descripcion VARCHAR(200)  NOT NULL,
  CONSTRAINT pk_parametro PRIMARY KEY (clave),
  CONSTRAINT ck_parametro_valor CHECK (valor >= 0)
) ENGINE=InnoDB;

-- >>>>> 02_logica.sql
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

-- >>>>> 03_seguridad.sql
-- =====================================================================
-- Archivo : 03_seguridad.sql
-- Objeto  : usuarios de base de datos y privilegios mínimos (RNF-02,
--           RNF-04, RNF-07). Cambiar las contraseñas antes de usarlo
--           fuera del entorno de pruebas.
-- =====================================================================

-- 1. Usuario de la API REST (PHP): solo lo que la aplicación necesita
DROP USER IF EXISTS 'app_inventario'@'localhost';
CREATE USER 'app_inventario'@'localhost' IDENTIFIED BY 'CambiarClave_App_2026';

GRANT SELECT ON virutex_inventario.* TO 'app_inventario'@'localhost';
GRANT INSERT, UPDATE ON virutex_inventario.sesion TO 'app_inventario'@'localhost';
GRANT INSERT, UPDATE (nombre_completo, contrasena_hash, id_rol, activo, intentos_fallidos, bloqueado_hasta)
      ON virutex_inventario.usuario TO 'app_inventario'@'localhost';
-- stock_actual queda fuera: solo cambia mediante movimientos (disparador)
GRANT INSERT, UPDATE (nombre, descripcion, id_maquina, id_unidad, id_ubicacion, stock_minimo, activo)
      ON virutex_inventario.repuesto TO 'app_inventario'@'localhost';
-- movimientos: solo inserción (sin UPDATE ni DELETE)
GRANT INSERT ON virutex_inventario.movimiento TO 'app_inventario'@'localhost';
GRANT INSERT, UPDATE ON virutex_inventario.conflicto_sincronizacion TO 'app_inventario'@'localhost';
GRANT INSERT ON virutex_inventario.ubicacion TO 'app_inventario'@'localhost';
GRANT INSERT, UPDATE ON virutex_inventario.proveedor TO 'app_inventario'@'localhost';
GRANT INSERT, UPDATE, DELETE ON virutex_inventario.repuesto_proveedor TO 'app_inventario'@'localhost';
GRANT INSERT, UPDATE ON virutex_inventario.solicitud TO 'app_inventario'@'localhost';
GRANT UPDATE (valor) ON virutex_inventario.parametro TO 'app_inventario'@'localhost';
GRANT EXECUTE ON PROCEDURE virutex_inventario.sp_actualizar_alertas_preventivas TO 'app_inventario'@'localhost';
GRANT EXECUTE ON PROCEDURE virutex_inventario.sp_informe_movimientos TO 'app_inventario'@'localhost';

-- 2. Usuario de solo lectura para informes y revisión académica:
--    accede a las vistas, no a las tablas con datos personales.
DROP USER IF EXISTS 'reportes_inventario'@'localhost';
CREATE USER 'reportes_inventario'@'localhost' IDENTIFIED BY 'CambiarClave_Rep_2026';
GRANT SELECT ON virutex_inventario.v_inventario            TO 'reportes_inventario'@'localhost';
GRANT SELECT ON virutex_inventario.v_repuestos_bajo_minimo TO 'reportes_inventario'@'localhost';
GRANT SELECT ON virutex_inventario.v_estimacion_reposicion TO 'reportes_inventario'@'localhost';
GRANT SELECT ON virutex_inventario.v_alertas_activas       TO 'reportes_inventario'@'localhost';

-- 3. Usuario de administración (equipo de desarrollo): cambios de esquema
DROP USER IF EXISTS 'admin_inventario'@'localhost';
CREATE USER 'admin_inventario'@'localhost' IDENTIFIED BY 'CambiarClave_Adm_2026';
GRANT ALL PRIVILEGES ON virutex_inventario.* TO 'admin_inventario'@'localhost';

FLUSH PRIVILEGES;

-- >>>>> 04_datos_prueba.sql
-- =====================================================================
-- Archivo : 04_datos_prueba.sql
-- Objeto  : catálogos y datos de prueba SIMULADOS. No contiene datos
--           reales de Virutex Ilko ni de sus trabajadores (Tabla 15).
-- Usuarios de prueba: contraseña Prueba2026* (solo entorno de pruebas)
-- Las fechas se calculan desde NOW() para que la estimación (90 días)
-- funcione en cualquier fecha de instalación.
-- =====================================================================
USE virutex_inventario;

INSERT INTO rol (id_rol, nombre, descripcion) VALUES
 (1,'supervisor','Planifica la reposición, define mínimos, gestiona usuarios y consulta informes'),
 (2,'almacen','Registra repuestos, ubicaciones, proveedores y entradas; entrega repuestos'),
 (3,'tecnico','Consulta el inventario y registra las salidas que utiliza');

INSERT INTO unidad_medida (codigo, nombre, permite_decimales) VALUES
 ('UND','Unidad',0),('PAR','Par',0),('JGO','Juego',0),('KIT','Kit',0),
 ('M','Metro',1),('L','Litro',1),('GAL','Galón',1),('KG','Kilogramo',1);

INSERT INTO maquina (codigo, nombre) VALUES
 ('INS-01','Insertadora 1'),('INS-02','Insertadora 2'),('INS-03','Insertadora 3'),
 ('INS-04','Insertadora 4'),('INS-05','Insertadora 5'),('INS-06','Insertadora 6');

INSERT INTO ubicacion (estanteria, cajon) VALUES
 ('A','01'),('A','02'),('A','03'),('A','04'),('B','01'),('B','02'),('B','03'),('B','04');

INSERT INTO parametro (clave, valor, descripcion) VALUES
 ('periodo_analisis_dias',90,'Días de historial usados para calcular el consumo (HU-13)'),
 ('minimo_salidas_estimacion',3,'Salidas mínimas en el periodo para estimar (HU-13)'),
 ('periodo_revision_dias',30,'Días adicionales que cubre la cantidad sugerida (HU-15)'),
 ('intentos_maximos',5,'Intentos fallidos antes de bloquear la cuenta (RNF-02)'),
 ('minutos_bloqueo',15,'Duración del bloqueo de la cuenta (RNF-02)'),
 ('horas_sesion',8,'Duración de la sesión (RNF-02)');

INSERT INTO usuario (id_usuario, nombre_completo, nombre_usuario, contrasena_hash, id_rol, id_creado_por) VALUES
 (1,'Supervisor Prueba','sup.prueba','$2y$10$392da3rSZ9Uf5DBBCPQyQu6b1SfqcKZ6yHPJcyUDKljmUiGEgZQDy',1,NULL),
 (2,'Almacén Prueba','alm.prueba','$2y$10$392da3rSZ9Uf5DBBCPQyQu6b1SfqcKZ6yHPJcyUDKljmUiGEgZQDy',2,1),
 (3,'Técnico Prueba Uno','tec.prueba1','$2y$10$392da3rSZ9Uf5DBBCPQyQu6b1SfqcKZ6yHPJcyUDKljmUiGEgZQDy',3,1),
 (4,'Técnico Prueba Dos','tec.prueba2','$2y$10$392da3rSZ9Uf5DBBCPQyQu6b1SfqcKZ6yHPJcyUDKljmUiGEgZQDy',3,1);

INSERT INTO repuesto (codigo, nombre, id_maquina, id_unidad, id_ubicacion, stock_minimo, id_usuario_registro) VALUES
 ('SIM-0001','Fusible cerámico 32 A',1,1,1,4,2),
 ('SIM-0002','Unión neumática 6 mm',2,1,2,5,2),
 ('SIM-0003','Cuchilla de corte',3,1,3,2,2),
 ('SIM-0004','Malla mesh #30',1,5,5,2,2),
 ('SIM-0005','Tornillo bristol M6x20',4,1,6,10,2),
 ('SIM-0006','Resorte de retorno',5,1,7,2,2),
 ('SIM-0007','Kit de sellos neumáticos',2,4,4,3,2),
 ('SIM-0008','Rodamiento 6204',6,1,8,2,2),
 ('SIM-0009','Correa dentada',5,1,NULL,1,2),
 ('SIM-0010','Aceite hidráulico',3,6,1,5,2);

INSERT INTO proveedor (nombre, nombre_contacto, telefono, correo) VALUES
 ('Proveedor Simulado A','Contacto A','6020000001','contacto.a@ejemplo.com'),
 ('Proveedor Simulado B','Contacto B','6020000002','contacto.b@ejemplo.com'),
 ('Proveedor Simulado C','Contacto C','6020000003','contacto.c@ejemplo.com');

INSERT INTO repuesto_proveedor (id_repuesto, id_proveedor, tiempo_reposicion_dias, es_principal) VALUES
 (1,1,15,1),(1,2,25,0),(2,1,20,1),(3,2,30,1),(4,3,20,1),(5,3,10,1),(7,1,25,1),(8,2,12,1),(10,3,10,1);

-- Movimientos en orden cronológico: el disparador calcula el stock de cada repuesto
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',1,30,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',2,20,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',3,12,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',4,10,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',5,50,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',6,8,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',7,6,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',8,10,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',9,4,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'entrada',10,20,NULL,2,NULL,NULL,DATE_SUB(NOW(), INTERVAL 100 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'ajuste',8,-1,NULL,1,NULL,'Diferencia encontrada en conteo físico',DATE_SUB(NOW(), INTERVAL 90 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 88 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',10,2.50,3,2,4,NULL,DATE_SUB(NOW(), INTERVAL 85 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 81 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',2,1.00,2,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 80 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',3,3.00,3,2,3,NULL,DATE_SUB(NOW(), INTERVAL 75 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 74 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',4,1.30,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 70 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 67 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',8,1.00,6,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 66 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',2,1.00,2,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 65 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 60 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',7,1.00,2,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 60 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',10,2.50,3,2,4,NULL,DATE_SUB(NOW(), INTERVAL 60 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 53 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',2,1.00,2,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 50 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',3,3.00,3,2,3,NULL,DATE_SUB(NOW(), INTERVAL 50 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 46 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',4,1.30,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 45 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',5,2.00,4,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 40 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',10,2.50,3,2,4,NULL,DATE_SUB(NOW(), INTERVAL 40 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 39 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',2,1.00,2,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 35 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',8,1.00,6,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 33 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 32 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',4,2.50,1,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 30 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',7,1.00,2,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 30 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 25 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',3,3.00,3,2,3,NULL,DATE_SUB(NOW(), INTERVAL 25 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',10,2.50,3,2,4,NULL,DATE_SUB(NOW(), INTERVAL 22 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',2,1.00,2,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 20 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 18 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',5,2.00,4,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 15 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',4,1.20,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 12 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 11 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',7,1.00,2,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',3,3.00,3,2,3,NULL,DATE_SUB(NOW(), INTERVAL 8 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',10,2.50,3,2,4,NULL,DATE_SUB(NOW(), INTERVAL 6 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',2,1.00,2,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 5 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',1,2.00,1,3,NULL,NULL,DATE_SUB(NOW(), INTERVAL 4 DAY));
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, id_usuario_recibe, motivo, fecha_movimiento) VALUES (UUID(), 'salida',8,1.00,6,4,NULL,NULL,DATE_SUB(NOW(), INTERVAL 3 DAY));

INSERT INTO solicitud (id_repuesto, id_proveedor, cantidad, estado, id_usuario_solicita, fecha_solicitud, fecha_envio, fecha_recepcion) VALUES
 (2,1,10,'recibida',1,DATE_SUB(NOW(), INTERVAL 60 DAY),DATE_SUB(NOW(), INTERVAL 59 DAY),DATE_SUB(NOW(), INTERVAL 40 DAY)),
 (3,2,6,'pendiente',1,DATE_SUB(NOW(), INTERVAL 2 DAY),NULL,NULL);

-- Ejemplo de salida registrada sin conexión que no pudo aplicarse (HU-06, RNF-06)
INSERT INTO conflicto_sincronizacion (uuid_cliente, id_usuario, id_repuesto, tipo, cantidad, fecha_movimiento, causa) VALUES
 (UUID(),4,3,'salida',1,DATE_SUB(NOW(), INTERVAL 1 DAY),'Stock insuficiente al sincronizar');

-- Genera las alertas preventivas a partir de la estimación (HU-14)
CALL sp_actualizar_alertas_preventivas();
