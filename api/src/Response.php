<?php
class Response
{
    public static function ok($datos, int $codigo = 200): void
    {
        self::send($codigo, ['ok' => true, 'datos' => $datos]);
    }

    public static function error(int $codigo, string $error, string $mensaje): void
    {
        self::send($codigo, ['ok' => false, 'error' => ['codigo' => $error, 'mensaje' => $mensaje]]);
    }

    private static function send(int $codigo, array $cuerpo): void
    {
        http_response_code($codigo);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($cuerpo, JSON_UNESCAPED_UNICODE);
        exit;
    }

    /** Lee el cuerpo JSON de la solicitud. */
    public static function input(): array
    {
        $datos = json_decode(file_get_contents('php://input'), true);
        return is_array($datos) ? $datos : [];
    }
}
