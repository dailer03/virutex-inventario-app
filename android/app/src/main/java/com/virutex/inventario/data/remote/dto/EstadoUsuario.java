package com.virutex.inventario.data.remote.dto;

/** Cuerpo de PATCH /v1/usuarios/{id}/estado. */
public class EstadoUsuario {
    public boolean activo;

    public EstadoUsuario(boolean activo) {
        this.activo = activo;
    }
}