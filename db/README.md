# Base de datos `virutex_inventario`

Scripts de la base de datos de la aplicación de inventario de repuestos críticos (Sprint 1).
Motor: MariaDB 10.4 o superior (incluido en XAMPP) o MySQL 8.0 o superior.

## Instalación en XAMPP

1. Iniciar **Apache** y **MySQL** en el panel de control de XAMPP.
2. Abrir http://localhost/phpmyadmin con el usuario `root`.
3. Pestaña **Importar** → seleccionar `00_instalar_todo.sql` → **Importar**.
   (Equivale a ejecutar en orden 01, 02, 03 y 04.)
4. Verificar en el panel izquierdo la base `virutex_inventario` con 14 tablas y 6 vistas.

## Archivos

| Archivo | Contenido |
|---|---|
| 00_instalar_todo.sql | Instalación completa (01 + 02 + 03 + 04). |
| 01_esquema.sql | Base de datos, tablas, claves, restricciones e índices. |
| 02_logica.sql | Disparadores, vistas y procedimientos. |
| 03_seguridad.sql | Usuarios de base de datos y privilegios mínimos. |
| 04_datos_prueba.sql | Catálogos y datos simulados. |
| 05_consultas_comprobacion.sql | Consultas C-01 a C-15 con el resultado esperado. |
| 06_pruebas_restricciones.sql | Pruebas P-01 a P-13 (deben fallar) y prueba de flujo F-01. |
| evidencia_pruebas_bd.txt | Resultados de la ejecución de prueba. |

## Datos de prueba

Todos los datos son simulados (códigos SIM-xxxx, proveedores y usuarios de prueba).
Usuarios de la aplicación: `sup.prueba`, `alm.prueba`, `tec.prueba1`, `tec.prueba2`,
contraseña `Prueba2026*` (solo para pruebas).

Las contraseñas de `app_inventario`, `reportes_inventario` y `admin_inventario`
en `03_seguridad.sql` deben cambiarse antes de usar la base fuera del entorno de pruebas
y no deben subirse al repositorio con valores reales.
