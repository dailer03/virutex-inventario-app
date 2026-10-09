<?php
// Punto de entrada único de la API: /api/v1/...
declare(strict_types=1);
foreach (['Database', 'Response', 'Auth'] as $c) require __DIR__ . "/src/$c.php";
foreach (glob(__DIR__ . '/src/controllers/*.php') as $f) require $f;

// Rutas: método, patrón y función que la atiende
$rutas = [
    ['POST', '#^/v1/auth/login$#',             [AuthController::class, 'login']],
    ['POST', '#^/v1/auth/logout$#',            [AuthController::class, 'logout']],
    ['GET',  '#^/v1/repuestos$#',              [RepuestoController::class, 'listar']],
    ['GET',  '#^/v1/repuestos/(\d+)$#',        [RepuestoController::class, 'detalle']],
    ['POST', '#^/v1/repuestos$#',              [RepuestoController::class, 'crear']],
    ['POST', '#^/v1/movimientos/entradas$#',   [MovimientoController::class, 'entrada']],
    ['POST', '#^/v1/movimientos/salidas$#',    [MovimientoController::class, 'salida']],
];

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$ruta = preg_match('#/api(/v1/.*)$#', $uri, $m) ? rtrim($m[1], '/') : '';

try {
    foreach ($rutas as [$metodo, $patron, $accion]) {
        if ($_SERVER['REQUEST_METHOD'] === $metodo && preg_match($patron, $ruta, $p)) {
            array_shift($p);
            call_user_func_array($accion, array_map('intval', $p));
        }
    }
    Response::error(404, 'RUTA_INEXISTENTE', "No existe el servicio {$_SERVER['REQUEST_METHOD']} $ruta.");
} catch (PDOException $e) {
    error_log($e->getMessage());
    Response::error(500, 'ERROR_BD', 'Error en la base de datos. Revise el registro de errores de Apache.');
}
