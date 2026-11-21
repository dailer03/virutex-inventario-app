package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Alerta activa de GET /v1/alertas (HU-09, HU-14). */
public class Alerta {
    @SerializedName("id_alerta") public int idAlerta;
    public String tipo;                                   // stock_minimo o preventiva
    @SerializedName("fecha_generacion") public String fechaGeneracion;
    @SerializedName("id_repuesto") public int idRepuesto;
    public String codigo;
    public String repuesto;
    public String unidad;
    @SerializedName("stock_actual") public double stockActual;
    @SerializedName("stock_minimo") public double stockMinimo;
    @SerializedName("cobertura_dias") public Double coberturaDias;
    @SerializedName("cantidad_sugerida") public Double cantidadSugerida;
}
