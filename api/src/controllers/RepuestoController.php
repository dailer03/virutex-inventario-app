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

        // POST /v1/repuestos  (HU-02, HU-08)
    public static function crear(): void
    {
        $u = Auth::require(['almacen']);
        $in = Response::input();
        $codigo      = strtoupper(trim((string)($in['codigo'] ?? '')));
        $nombre      = trim((string)($in['nombre'] ?? ''));
        $descripcion = trim((string)($in['descripcion'] ?? ''));
        $idMaquina   = (int)($in['id_maquina'] ?? 0);
        $idUnidad    = (int)($in['id_unidad'] ?? 0);
        $idUbicacion = empty($in['id_ubicacion']) ? null : (int)$in['id_ubicacion'];
        $stockMinimo = $in['stock_minimo'] ?? 0;

        if ($codigo === '' || $codigo === 'NA' || $nombre === '' || $idMaquina <= 0 || $idUnidad <= 0) {
            Response::error(400, 'DATOS_INVALIDOS', 'Código (distinto de NA), nombre, máquina y unidad son obligatorios.');
        }
        if (mb_strlen($codigo) > 20 || mb_strlen($nombre) > 100 || mb_strlen($descripcion) > 255) {
            Response::error(400, 'DATOS_INVALIDOS', 'El código admite 20 caracteres, el nombre 100 y la descripción 255.');
        }
        if (!is_numeric($stockMinimo) || $stockMinimo < 0) {
            Response::error(400, 'DATOS_INVALIDOS', 'El stock mínimo debe ser un número mayor o igual a cero.');
        }

        $db = Database::get();
        $st = $db->prepare('SELECT permite_decimales FROM unidad_medida WHERE id_unidad = ?');
        $st->execute([$idUnidad]);
        $unidad = $st->fetch();
        if (!$unidad) {
            Response::error(400, 'DATOS_INVALIDOS', 'La unidad de medida no existe.');
        }
        if (!$unidad['permite_decimales'] && floor((float)$stockMinimo) != (float)$stockMinimo) {
            Response::error(400, 'DATOS_INVALIDOS', 'La unidad seleccionada no admite decimales.');
        }

        try {
            $st = $db->prepare(
                'INSERT INTO repuesto (codigo, nombre, descripcion, id_maquina, id_unidad, id_ubicacion,
                                       stock_minimo, id_usuario_registro)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
            $st->execute([$codigo, $nombre, $descripcion === '' ? null : $descripcion, $idMaquina,
                          $idUnidad, $idUbicacion, (float)$stockMinimo, $u['id_usuario']]);
        } catch (PDOException $e) {
            $codigoError = $e->errorInfo[1] ?? 0;
            if ($codigoError == 1062) {
                Response::error(409, 'CODIGO_DUPLICADO', "Ya existe un repuesto con el código $codigo.");
            }
            if ($codigoError == 1452) {
                Response::error(400, 'DATOS_INVALIDOS', 'La máquina o la ubicación seleccionada no existe.');
            }
            throw $e;
        }
        Response::ok(['id_repuesto' => (int)$db->lastInsertId()], 201);
    }
}