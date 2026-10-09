<?php
$local = __DIR__ . '/config.local.php';
if (!file_exists($local)) {
    http_response_code(500);
    exit('Falta config/config.local.php. Copie config.local.example.php y complete la contraseña.');
}
return require $local;
