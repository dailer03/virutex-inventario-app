<?php
class AlertaController
{
    // GET /v1/alertas?tipo=stock_minimo|preventiva  (HU-09, HU-14)
    public static function listar(): void
    {
        Auth::require(['almacen', 'supervisor']);
        $tipo = $_GET['tipo'] ?? '';
        $sql = 'SELECT a.id_alerta, a.tipo, a.fecha_generacion, r.id_repuesto, r.codigo,
                       r.nombre AS repuesto, u.codigo AS unidad, r.stock_actual, r.stock_minimo,
                       a.cobertura_dias, a.cantidad_sugerida
                  FROM alerta a
                  JOIN repuesto r      ON r.id_repuesto = a.id_repuesto
                  JOIN unidad_medida u ON u.id_unidad = r.id_unidad
                 WHERE a.estado = \'activa\'';
        $p = [];
        if (in_array($tipo, ['stock_minimo', 'preventiva'], true)) {
            $sql .= ' AND a.tipo = ?';
            $p[] = $tipo;
        }
        $st = Database::get()->prepare($sql . ' ORDER BY r.stock_actual, r.nombre');
        $st->execute($p);
        Response::ok($st->fetchAll());
    }
}