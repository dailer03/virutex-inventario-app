package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Técnico activo que puede recibir un repuesto. */
public class Tecnico {
    @SerializedName("id_usuario") public int idUsuario;
    @SerializedName("nombre_completo") public String nombreCompleto;

    @Override public String toString() { return nombreCompleto; }
}