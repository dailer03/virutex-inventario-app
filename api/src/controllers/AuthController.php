<?php
class AuthController
{
    // POST /v1/auth/login  (HU-01)
    public static function login(): void
    {
        $in = Response::input();
        $usuario = trim($in['usuario'] ?? '');
        $clave = $in['contrasena'] ?? '';
        if ($usuario === '' || $clave === '') {
            Response::error(400, 'DATOS_INCOMPLETOS', 'Ingrese usuario y contraseña.');
        }
        $db = Database::get();
        $p = $db->query("SELECT clave, valor FROM parametro
                          WHERE clave IN ('intentos_maximos','minutos_bloqueo','horas_sesion')")
                ->fetchAll(PDO::FETCH_KEY_PAIR);

        // El bloqueo se compara con la hora de la base de datos para evitar diferencias de zona horaria
        $st = $db->prepare('SELECT u.*, r.nombre AS rol,
                                   (u.bloqueado_hasta IS NOT NULL AND u.bloqueado_hasta > NOW()) AS bloqueado,
                                   DATE_FORMAT(u.bloqueado_hasta, \'%H:%i\') AS hora_desbloqueo
                              FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
                             WHERE u.nombre_usuario = ?');
        $st->execute([$usuario]);
        $u = $st->fetch();
        if (!$u || !$u['activo']) {
            Response::error(401, 'CREDENCIALES', 'Usuario o contraseña incorrectos.');
        }
        if ($u['bloqueado']) {
            Response::error(423, 'CUENTA_BLOQUEADA', "Cuenta bloqueada hasta las {$u['hora_desbloqueo']}.");
        }
        if (!password_verify($clave, $u['contrasena_hash'])) {
            $intentos = $u['intentos_fallidos'] + 1;
            if ($intentos >= (int)$p['intentos_maximos']) {
                $db->prepare('UPDATE usuario SET intentos_fallidos = 0,
                                     bloqueado_hasta = DATE_ADD(NOW(), INTERVAL ? MINUTE)
                               WHERE id_usuario = ?')
                   ->execute([(int)$p['minutos_bloqueo'], $u['id_usuario']]);
                Response::error(423, 'CUENTA_BLOQUEADA', 'Demasiados intentos. La cuenta quedó bloqueada.');
            }
            $db->prepare('UPDATE usuario SET intentos_fallidos = ? WHERE id_usuario = ?')
               ->execute([$intentos, $u['id_usuario']]);
            $restan = (int)$p['intentos_maximos'] - $intentos;
            Response::error(401, 'CREDENCIALES', "Usuario o contraseña incorrectos. Le quedan $restan intentos.");
        }
        $db->prepare('UPDATE usuario SET intentos_fallidos = 0, bloqueado_hasta = NULL WHERE id_usuario = ?')
           ->execute([$u['id_usuario']]);

        $token = bin2hex(random_bytes(32));               // se entrega una sola vez al teléfono
        $db->prepare('INSERT INTO sesion (id_usuario, token_hash, fecha_expiracion)
                      VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? HOUR))')
           ->execute([$u['id_usuario'], hash('sha256', $token), (int)$p['horas_sesion']]);

        Response::ok([
            'token'   => $token,
            'usuario' => ['id' => (int)$u['id_usuario'], 'nombre' => $u['nombre_completo'], 'rol' => $u['rol']],
        ]);
    }

    // POST /v1/auth/logout
    public static function logout(): void
    {
        $u = Auth::require();
        Database::get()->prepare('UPDATE sesion SET revocada = 1 WHERE id_sesion = ?')->execute([$u['id_sesion']]);
        Response::ok(['mensaje' => 'Sesión cerrada.']);
    }
}
