<?php
class UsuarioController
{
    private const ROLES = ['supervisor' => 1, 'almacen' => 2, 'tecnico' => 3];

    // GET /v1/usuarios  (HU-16)
    public static function listar(): void
    {
        Auth::require(['supervisor']);
        $st = Database::get()->prepare(
            'SELECT u.id_usuario, u.nombre_completo, u.nombre_usuario, r.nombre AS rol, u.activo,
                    (u.bloqueado_hasta IS NOT NULL AND u.bloqueado_hasta > NOW()) AS bloqueado
               FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
              ORDER BY u.activo DESC, u.nombre_completo');
        $st->execute();
        Response::ok($st->fetchAll());
    }

        // GET /v1/tecnicos  (HU-06: el almacén elige quién recibe el repuesto)
    public static function tecnicos(): void
    {
        Auth::require(['almacen']);
        $st = Database::get()->prepare(
            "SELECT u.id_usuario, u.nombre_completo
               FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
              WHERE r.nombre = 'tecnico' AND u.activo = 1
              ORDER BY u.nombre_completo");
        $st->execute();
        Response::ok($st->fetchAll());
    }

    // POST /v1/usuarios  (HU-16: solo el supervisor crea usuarios y asigna el rol)
    public static function crear(): void
    {
        $sup = Auth::require(['supervisor']);
        $in = Response::input();
        $nombre  = trim((string)($in['nombre_completo'] ?? ''));
        $usuario = strtolower(trim((string)($in['nombre_usuario'] ?? '')));
        $clave   = (string)($in['contrasena'] ?? '');
        $rol     = (string)($in['rol'] ?? '');

        if ($nombre === '' || $usuario === '' || $clave === '' || !isset(self::ROLES[$rol])) {
            Response::error(400, 'DATOS_INVALIDOS',
                'Nombre, usuario, contraseña y rol (supervisor, almacen o tecnico) son obligatorios.');
        }
        if (mb_strlen($nombre) > 100) {
            Response::error(400, 'DATOS_INVALIDOS', 'El nombre admite 100 caracteres.');
        }
        if (!preg_match('/^[a-z0-9._]{3,30}$/', $usuario)) {
            Response::error(400, 'DATOS_INVALIDOS',
                'El usuario debe tener de 3 a 30 caracteres: letras minúsculas, números, punto o guion bajo.');
        }
        if (strlen($clave) < 8 || !preg_match('/[A-Za-z]/', $clave) || !preg_match('/\d/', $clave)) {
            Response::error(400, 'CONTRASENA_DEBIL',
                'La contraseña debe tener al menos 8 caracteres, con letras y números.');
        }

        $db = Database::get();
        try {
            $db->prepare('INSERT INTO usuario (nombre_completo, nombre_usuario, contrasena_hash, id_rol, id_creado_por)
                          VALUES (?, ?, ?, ?, ?)')
               ->execute([$nombre, $usuario, password_hash($clave, PASSWORD_BCRYPT),
                          self::ROLES[$rol], $sup['id_usuario']]);
        } catch (PDOException $e) {
            if (($e->errorInfo[1] ?? 0) == 1062) {
                Response::error(409, 'USUARIO_DUPLICADO', "Ya existe el usuario $usuario.");
            }
            throw $e;
        }
        Response::ok(['id_usuario' => (int)$db->lastInsertId()], 201);
    }

    // PATCH /v1/usuarios/{id}/estado  (HU-16: se desactiva en lugar de eliminar)
    public static function cambiarEstado(int $id): void
    {
        $sup = Auth::require(['supervisor']);
        $in = Response::input();
        if (!array_key_exists('activo', $in)) {
            Response::error(400, 'DATOS_INVALIDOS', 'Indique si el usuario queda activo (true o false).');
        }
        $activo = $in['activo'] ? 1 : 0;
        if ($id === (int)$sup['id_usuario'] && $activo === 0) {
            Response::error(409, 'OPERACION_NO_PERMITIDA', 'No puede desactivar su propio usuario.');
        }

        $db = Database::get();
        $st = $db->prepare('SELECT id_usuario FROM usuario WHERE id_usuario = ?');
        $st->execute([$id]);
        if (!$st->fetch()) {
            Response::error(404, 'NO_EXISTE', 'El usuario no existe.');
        }
        $db->prepare('UPDATE usuario SET activo = ? WHERE id_usuario = ?')->execute([$activo, $id]);
        if ($activo === 0) {
            // Cierra las sesiones abiertas del usuario desactivado
            $db->prepare('UPDATE sesion SET revocada = 1 WHERE id_usuario = ? AND revocada = 0')->execute([$id]);
        }
        Response::ok(['id_usuario' => $id, 'activo' => (bool)$activo]);
    }
}