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
