-- =====================================================================
-- Archivo : 05_consultas_comprobacion.sql
-- Objeto  : consultas que comprueban que la base de datos cumple los
--           criterios de aceptación del diseño. Cada consulta indica el
--           resultado esperado con los datos de 04_datos_prueba.sql.
-- =====================================================================
USE virutex_inventario;

-- C-01. Registros cargados por tabla.
-- Esperado: rol 3, usuario 4, repuesto 10, movimiento 51, alerta 5.
SELECT 'rol' AS tabla, COUNT(*) AS registros FROM rol
UNION ALL SELECT 'usuario', COUNT(*) FROM usuario
UNION ALL SELECT 'unidad_medida', COUNT(*) FROM unidad_medida
UNION ALL SELECT 'maquina', COUNT(*) FROM maquina
UNION ALL SELECT 'ubicacion', COUNT(*) FROM ubicacion
UNION ALL SELECT 'repuesto', COUNT(*) FROM repuesto
UNION ALL SELECT 'proveedor', COUNT(*) FROM proveedor
UNION ALL SELECT 'repuesto_proveedor', COUNT(*) FROM repuesto_proveedor
UNION ALL SELECT 'movimiento', COUNT(*) FROM movimiento
UNION ALL SELECT 'alerta', COUNT(*) FROM alerta
UNION ALL SELECT 'solicitud', COUNT(*) FROM solicitud
UNION ALL SELECT 'conflicto_sincronizacion', COUNT(*) FROM conflicto_sincronizacion
UNION ALL SELECT 'parametro', COUNT(*) FROM parametro;

-- C-02. El stock de cada repuesto coincide con la suma de sus movimientos (RNF-04).
-- Esperado: 0 filas.
SELECT r.codigo, r.stock_actual,
       SUM(CASE WHEN mv.tipo = 'salida' THEN -mv.cantidad ELSE mv.cantidad END) AS stock_calculado
  FROM repuesto r
  JOIN movimiento mv ON mv.id_repuesto = r.id_repuesto
 GROUP BY r.id_repuesto, r.codigo, r.stock_actual
HAVING r.stock_actual <> SUM(CASE WHEN mv.tipo = 'salida' THEN -mv.cantidad ELSE mv.cantidad END);

-- C-03. Ningún movimiento dejó el stock negativo.
-- Esperado: 0 filas.
SELECT id_movimiento, stock_resultante FROM movimiento WHERE stock_resultante < 0;

-- C-04. Consulta de inventario por código, nombre o máquina (HU-03).
-- Esperado: SIM-0001 y SIM-0004 (máquina INS-01) con su ubicación y estado.
SELECT codigo, nombre, maquina_codigo, ubicacion, stock_actual, unidad, estado_stock
  FROM v_inventario
 WHERE codigo = 'SIM-0001' OR nombre LIKE '%fusible%' OR maquina_codigo = 'INS-01';

-- C-05. Historial de un repuesto por rango de fechas (HU-07).
-- Esperado: salidas de SIM-0001 de los últimos 30 días con usuario y máquina.
SELECT fecha_movimiento, tipo, cantidad, stock_resultante, maquina_destino, registrado_por, recibido_por
  FROM v_historial_movimientos
 WHERE codigo = 'SIM-0001' AND fecha_movimiento >= DATE_SUB(NOW(), INTERVAL 30 DAY)
 ORDER BY fecha_movimiento;

-- C-06. Alertas activas (HU-09 y HU-14).
-- Esperado: stock mínimo para SIM-0001, SIM-0003 y SIM-0007; preventiva para SIM-0001 y SIM-0003.
SELECT tipo, codigo, repuesto, stock_actual, stock_minimo, cobertura_dias, cantidad_sugerida
  FROM v_alertas_activas ORDER BY tipo, codigo;

-- C-07. Estimación de reposición (HU-13 y HU-15).
-- Esperado: SIM-0005, SIM-0006 y SIM-0009 no estimables (menos de 3 salidas).
SELECT codigo, num_salidas, consumo_diario, tiempo_reposicion_dias,
       estimable, cobertura_dias, cantidad_sugerida, requiere_alerta_preventiva
  FROM v_estimacion_reposicion ORDER BY codigo;

-- C-08. Informe de movimientos de los últimos 30 días (HU-12).
CALL sp_informe_movimientos(DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE());

-- C-09. Repuestos bajo el mínimo para el informe (HU-12).
-- Esperado: SIM-0001, SIM-0003 y SIM-0007.
SELECT codigo, nombre, stock_actual, stock_minimo, estado_stock FROM v_repuestos_bajo_minimo;

-- C-10. Repuestos sin ubicación asignada (HU-04).
-- Esperado: SIM-0009.
SELECT codigo, nombre FROM repuesto WHERE id_ubicacion IS NULL;

-- C-11. Las contraseñas están cifradas con bcrypt (RNF-02).
-- Esperado: prefijo $2y$ y longitud 60 en todos los usuarios.
SELECT nombre_usuario, LEFT(contrasena_hash, 4) AS prefijo, CHAR_LENGTH(contrasena_hash) AS longitud
  FROM usuario;

-- C-12. Cada repuesto con proveedores tiene exactamente un proveedor principal (HU-10).
-- Esperado: 0 filas.
SELECT id_repuesto, SUM(es_principal) AS principales
  FROM repuesto_proveedor GROUP BY id_repuesto HAVING SUM(es_principal) <> 1;

-- C-13. Solicitudes abiertas (HU-11). Esperado: una pendiente para SIM-0003.
SELECT s.id_solicitud, r.codigo, s.cantidad, s.estado
  FROM solicitud s JOIN repuesto r ON r.id_repuesto = s.id_repuesto
 WHERE s.estado IN ('pendiente', 'enviada');

-- C-14. La búsqueda por código usa índice (RNF-05).
-- Esperado: la columna key muestra uq_repuesto_codigo.
EXPLAIN SELECT * FROM repuesto WHERE codigo = 'SIM-0001';

-- C-15. Privilegios del usuario de la API (RNF-02, RNF-04).
-- Esperado: sobre movimiento solo SELECT e INSERT.
SHOW GRANTS FOR 'app_inventario'@'localhost';
