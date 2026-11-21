package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Respuesta del registro de un movimiento. */
public class MovimientoRegistrado {
    @SerializedName("id_movimiento") public long idMovimiento;
    public String tipo;
    public double cantidad;
    @SerializedName("stock_resultante") public double stockResultante;
}