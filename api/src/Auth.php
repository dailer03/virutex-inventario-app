<?php
class Auth
{
    /**
     * Verifica el token y el rol. Devuelve el usuario de la sesión.
     * $roles vacío = cualquier rol autenticado.
     */
    public static function require(array $roles = []): array
    {
        $cabecera = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        if (!preg_match('/^Bearer\s+([a-f0-9]{64})$/i', $cabecera, $m)) {
            Response::error(401, 'SIN_SESION', 'Inicie sesión para continuar.');
        }
        $st = Database::get()->prepare(
            'SELECT u.id_usuario, u.nombre_completo, u.nombre_usuario, r.nombre AS rol, s.id_sesion
               FROM sesion s
               JOIN usuario u ON u.id_usuario = s.id_usuario
               JOIN rol r     ON r.id_rol = u.id_rol
              WHERE s.token_hash = ? AND s.revocada = 0
                AND s.fecha_expiracion > NOW() AND u.activo = 1');
        $st->execute([hash('sha256', $m[1])]);
        $usuario = $st->fetch();
        if (!$usuario) {
            Response::error(401, 'SESION_VENCIDA', 'La sesión venció. Inicie sesión de nuevo.');
        }
        if ($roles && !in_array($usuario['rol'], $roles, true)) {
            Response::error(403, 'SIN_PERMISO', 'Su rol no tiene permiso para esta acción.');
        }
        return $usuario;
    }
}
