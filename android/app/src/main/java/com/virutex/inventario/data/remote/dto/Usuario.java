package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Un usuario de la lista de GET /v1/usuarios (HU-16). */
public class Usuario {
    @SerializedName("id_usuario") public int idUsuario;
    @SerializedName("nombre_completo") public String nombreCompleto;
    @SerializedName("nombre_usuario") public String nombreUsuario;
    public String rol;
    public int activo;
    public int bloqueado;
}