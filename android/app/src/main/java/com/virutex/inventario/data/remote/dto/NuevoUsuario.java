package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Datos que se envían a POST /v1/usuarios (HU-16). */
public class NuevoUsuario {
    @SerializedName("nombre_completo") public String nombreCompleto;
    @SerializedName("nombre_usuario") public String nombreUsuario;
    public String contrasena;
    public String rol;
}