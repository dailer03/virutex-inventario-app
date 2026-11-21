 <?php
class MovimientoController
{
    // POST /v1/movimientos/entradas  (HU-05)
    public static function entrada(): void
    {
        $u = Auth::require(['almacen']);
        self::registrar('entrada', Response::input(), $u);
    }

    // POST /v1/movimientos/salidas  (HU-06)
    public static function salida(): void
    {
        $u = Auth::require(['tecnico', 'almacen']);
        $in = Response::input();
        if (empty($in['id_maquina_destino'])) {
            Response::error(400, 'DATOS_INVALIDOS', 'La máquina de destino es obligatoria.');
        }
        if ($u['rol'] === 'almacen' && empty($in['id_usuario_recibe'])) {
            Response::error(400, 'DATOS_INVALIDOS', 'Indique el técnico que recibe el repuesto.');
        }
        self::registrar('salida', $in, $u);
    }

    private static function registrar(string $tipo, array $in, array $u): void
    {
        $uuid = $in['uuid_cliente'] ?? '';
        $cantidad = (float)($in['cantidad'] ?? 0);
        if (!preg_match('/^[0-9a-f-]{36}$/i', $uuid) || $cantidad <= 0 || empty($in['id_repuesto'])) {
            Response::error(400, 'DATOS_INVALIDOS', 'Repuesto, cantidad mayor que cero e identificador son obligatorios.');
        }
        $db = Database::get();

        // El repuesto debe existir y la cantidad respetar su unidad de medida (H-10)
        $st = $db->prepare('SELECT u.permite_decimales, u.codigo AS unidad
                              FROM repuesto r JOIN unidad_medida u ON u.id_unidad = r.id_unidad
                             WHERE r.id_repuesto = ? AND r.activo = 1');
        $st->execute([(int)$in['id_repuesto']]);
        $rep = $st->fetch();
        if (!$rep) {
            Response::error(404, 'NO_EXISTE', 'El repuesto no existe o está inactivo.');
        }
        if (!$rep['permite_decimales'] && floor($cantidad) != $cantidad) {
            Response::error(400, 'DATOS_INVALIDOS', "La unidad {$rep['unidad']} no admite decimales.");
        }

        try {
            $db->prepare('INSERT INTO movimiento (uuid_cliente, tipo, id_repuesto, cantidad, id_maquina_destino,
                                                  id_usuario_registra, id_usuario_recibe, observacion, fecha_movimiento)
                          VALUES (?, ?, ?, ?, ?, ?, ?, ?, COALESCE(?, NOW()))')
               ->execute([$uuid, $tipo, (int)$in['id_repuesto'], $cantidad, $in['id_maquina_destino'] ?? null,
                          $u['id_usuario'], $in['id_usuario_recibe'] ?? null, $in['observacion'] ?? null,
                          $in['fecha_movimiento'] ?? null]);
        } catch (PDOException $e) {
            $msg = $e->errorInfo[2] ?? $e->getMessage();
            if (($e->errorInfo[1] ?? 0) == 1062) {
                // El mismo movimiento ya llegó antes (reenvío): no se duplica.
                $codigo = 200;
            } elseif (str_contains($msg, 'Stock insuficiente')) {
                Response::error(409, 'STOCK_INSUFICIENTE', 'Stock insuficiente para registrar la salida.');
            } elseif (($e->errorInfo[1] ?? 0) == 1452) {
                Response::error(400, 'DATOS_INVALIDOS', 'La máquina o el usuario que recibe no existe.');
            } else {
                throw $e;
            }
        }
        try {
            $db->query('CALL sp_actualizar_alertas_preventivas()')->closeCursor();   // HU-14
        } catch (PDOException $e) {
            error_log('Alertas preventivas: ' . $e->getMessage());   // el movimiento ya quedó registrado
        }
        $st = $db->prepare('SELECT id_movimiento, tipo, cantidad, stock_resultante FROM movimiento WHERE uuid_cliente = ?');
        $st->execute([$uuid]);
        Response::ok($st->fetch(), $codigo ?? 201);
    }
}