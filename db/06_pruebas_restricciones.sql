-- =====================================================================
-- Archivo : 06_pruebas_restricciones.sql
-- Objeto  : pruebas negativas. Cada instrucción DEBE fallar con el
--           mensaje indicado; así se comprueba que la base de datos
--           protege las reglas del negocio. En phpMyAdmin, ejecutar
--           una por una (la ejecución se detiene en el primer error).
-- =====================================================================
USE virutex_inventario;

-- P-01 (HU-06, C-01): salida mayor que el stock. SIM-0003 tiene stock 0.
-- Esperado: 'Stock insuficiente para registrar el movimiento'.
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino, id_usuario_registra, fecha_movimiento)
VALUES (UUID(), 'salida', 3, 1, 3, 3, NOW());

-- P-02 (HU-02, H-11): repuesto con código «NA». Esperado: violación de ck_repuesto_codigo.
INSERT INTO repuesto (codigo, nombre, id_maquina, id_unidad, id_usuario_registro)
VALUES ('NA', 'Repuesto sin código', 1, 1, 2);

-- P-03 (HU-02): código duplicado. Esperado: entrada duplicada en uq_repuesto_codigo.
INSERT INTO repuesto (codigo, nombre, id_maquina, id_unidad, id_usuario_registro)
VALUES ('SIM-0001', 'Duplicado', 1, 1, 2);

-- P-04 (HU-07, RNF-04): modificar un movimiento. Esperado: 'Los movimientos no se modifican; registre un ajuste'.
UPDATE movimiento SET cantidad = 99 WHERE id_movimiento = 1;

-- P-05 (HU-07, RNF-04): eliminar un movimiento. Esperado: 'Los movimientos no se eliminan; registre un ajuste'.
DELETE FROM movimiento WHERE id_movimiento = 1;

-- P-06 (HU-06): salida sin máquina de destino. Esperado: violación de ck_mov_salida_destino.
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_usuario_registra, fecha_movimiento)
VALUES (UUID(), 'salida', 2, 1, 3, NOW());

-- P-07 (HU-05): entrada con cantidad cero. Esperado: violación de ck_mov_cantidad.
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_usuario_registra, fecha_movimiento)
VALUES (UUID(), 'entrada', 2, 0, 2, NOW());

-- P-08 (HU-07): ajuste sin motivo. Esperado: violación de ck_mov_ajuste_motivo.
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_usuario_registra, fecha_movimiento)
VALUES (UUID(), 'ajuste', 2, -1, 1, NOW());

-- P-09 (RNF-06): sincronizar dos veces el mismo movimiento. Esperado: entrada duplicada en uq_movimiento_uuid.
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_usuario_registra, fecha_movimiento)
SELECT uuid_cliente, 'entrada', 2, 1, 2, NOW() FROM movimiento WHERE id_movimiento = 1;

-- P-10 (HU-08): stock mínimo negativo. Esperado: violación de ck_repuesto_minimo.
UPDATE repuesto SET stock_minimo = -1 WHERE id_repuesto = 2;

-- P-11 (HU-11): segunda solicitud abierta para SIM-0003. Esperado: entrada duplicada en uq_sol_abierta.
INSERT INTO solicitud (id_repuesto, cantidad, id_usuario_solicita) VALUES (3, 4, 1);

-- P-12 (HU-10): segundo proveedor principal para SIM-0001. Esperado: entrada duplicada en uq_rp_principal.
UPDATE repuesto_proveedor SET es_principal = 1 WHERE id_repuesto = 1 AND id_proveedor = 2;

-- P-13 (HU-16): eliminar un usuario con movimientos. Esperado: violación de clave foránea.
DELETE FROM usuario WHERE id_usuario = 3;

-- ---------------------------------------------------------------------
-- Prueba de flujo (se deshace al final con ROLLBACK)
-- F-01 (HU-05, HU-09, HU-14): una entrada de 5 unidades de SIM-0003
-- debe atender sus alertas de stock mínimo y preventiva.
-- ---------------------------------------------------------------------
START TRANSACTION;
INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_usuario_registra, fecha_movimiento)
VALUES (UUID(), 'entrada', 3, 5, 2, NOW());
CALL sp_actualizar_alertas_preventivas();
SELECT r.codigo, r.stock_actual, a.tipo, a.estado
  FROM alerta a JOIN repuesto r ON r.id_repuesto = a.id_repuesto
 WHERE r.codigo = 'SIM-0003';
-- Esperado: stock 5.00 y las dos alertas de SIM-0003 en estado «atendida».
ROLLBACK;
