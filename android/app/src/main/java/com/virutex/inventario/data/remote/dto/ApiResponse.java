package com.virutex.inventario.data.remote.dto;

/** Forma común de todas las respuestas de la API: {ok, datos, error}. */
public class ApiResponse<T> {
    public boolean ok;
    public T datos;
    public ApiError error;

    public static class ApiError {
        public String codigo;
        public String mensaje;
    }
}
