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
