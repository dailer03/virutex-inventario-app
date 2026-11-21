<?php
class CatalogoController
{
    // GET /v1/catalogos  (HU-02: listas cerradas para el formulario P-05)
    public static function listar(): void
    {
        Auth::require();
        $db = Database::get();

        $st = $db->prepare('SELECT id_maquina AS id, codigo, nombre
                              FROM maquina WHERE activa = 1 ORDER BY codigo');
        $st->execute();
        $maquinas = $st->fetchAll();

        $st = $db->prepare('SELECT id_unidad AS id, codigo, nombre, permite_decimales
                              FROM unidad_medida ORDER BY nombre');
        $st->execute();
        $unidades = $st->fetchAll();

        $st = $db->prepare("SELECT id_ubicacion AS id, CONCAT(estanteria, '-', cajon) AS nombre
                              FROM ubicacion ORDER BY estanteria, cajon");
        $st->execute();
        $ubicaciones = $st->fetchAll();

        Response::ok(['maquinas' => $maquinas, 'unidades' => $unidades, 'ubicaciones' => $ubicaciones]);
    }
}