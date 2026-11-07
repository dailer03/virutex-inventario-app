package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Respuesta de POST /v1/repuestos. */
public class RepuestoCreado {
    @SerializedName("id_repuesto") public int idRepuesto;
}