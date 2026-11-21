package com.virutex.inventario.data.repository;

/** Respuesta de una operación del repositorio hacia el ViewModel. */
public interface Resultado<T> {
    void exito(T datos);
    void error(int codigoHttp, String mensaje);   // codigoHttp = 0 si no hubo conexión
}
