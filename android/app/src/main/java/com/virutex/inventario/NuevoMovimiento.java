package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Datos que se envían a POST /v1/movimientos/salidas y /entradas. */
public class NuevoMovimiento {
    @SerializedName("uuid_cliente") public String uuidCliente;
    @SerializedName("id_repuesto") public int idRepuesto;
    public double cantidad;
    @SerializedName("id_maquina_destino") public Integer idMaquinaDestino;
    @SerializedName("id_usuario_recibe") public Integer idUsuarioRecibe;
    public String observacion;
}