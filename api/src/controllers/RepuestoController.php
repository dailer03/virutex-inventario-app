<?php
class RepuestoController
{
    // GET /v1/repuestos?q=&maquina=  (HU-03)
    public static function listar(): void
    {
        Auth::require();
        $q = trim($_GET['q'] ?? '');
        $maquina = trim($_GET['maquina'] ?? '');
        $sql = 'SELECT * FROM v_inventario WHERE 1 = 1';
        $p = [];
        if ($q !== '') {
            $sql .= ' AND (codigo LIKE ? OR nombre LIKE ? OR maquina_codigo = ?)';
            array_push($p, "%$q%", "%$q%", $q);
        }
        if ($maquina !== '') {
            $sql .= ' AND maquina_codigo = ?';
            $p[] = $maquina;
        }
        $st = Database::get()->prepare($sql . ' ORDER BY nombre LIMIT 200');
        $st->execute($p);
        Response::ok($st->fetchAll());
    }

    // GET /v1/repuestos/{id}  (HU-03)
    public static function detalle(int $id): void
    {
        Auth::require();
        $db = Database::get();
        $st = $db->prepare('SELECT * FROM v_inventario WHERE id_repuesto = ?');
        $st->execute([$id]);
        $r = $st->fetch();
        if (!$r) {
            Response::error(404, 'NO_EXISTE', 'El repuesto no existe.');
        }
        $st = $db->prepare('SELECT p.id_proveedor, p.nombre, rp.tiempo_reposicion_dias, rp.es_principal
                              FROM repuesto_proveedor rp JOIN proveedor p ON p.id_proveedor = rp.id_proveedor
                             WHERE rp.id_repuesto = ?');
        $st->execute([$id]);
        $r['proveedores'] = $st->fetchAll();
        Response::ok($r);
    }

    // POST /v1/repuestos  (HU-02)
    public static function crear(): void
    {
        $u = Auth::require(['almacen']);
        $in = Response::input();
        $codigo = strtoupper(trim($in['codigo'] ?? ''));
        $nombre = trim($in['nombre'] ?? '');
        if ($codigo === '' || $codigo === 'NA' || $nombre === ''
            || empty($in['id_maquina']) || empty($in['id_unidad'])) {
            Response::error(400, 'DATOS_INVALIDOS', 'Código (distinto de NA), nombre, máquina y unidad son obligatorios.');
        }
        try {
            $st = Database::get()->prepare(
                'INSERT INTO repuesto (codigo, nombre, descripcion, id_maquina, id_unidad, id_ubicacion,
                                       stock_minimo, id_usuario_registro)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
            $st->execute([$codigo, $nombre, $in['descripcion'] ?? null, (int)$in['id_maquina'],
                          (int)$in['id_unidad'], $in['id_ubicacion'] ?? null,
                          (float)($in['stock_minimo'] ?? 0), $u['id_usuario']]);
        } catch (PDOException $e) {
            if (($e->errorInfo[1] ?? 0) == 1062) {
                Response::error(409, 'CODIGO_DUPLICADO', "Ya existe un repuesto con el código $codigo.");
            }
            throw $e;
        }
        Response::ok(['id_repuesto' => (int)Database::get()->lastInsertId()], 201);
    }
}
