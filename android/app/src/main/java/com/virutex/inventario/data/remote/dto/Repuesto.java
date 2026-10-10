package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Un registro de la vista v_inventario (HU-03). */
public class Repuesto {
    @SerializedName("id_repuesto") public int idRepuesto;
    public String codigo;
    public String nombre;
    @SerializedName("maquina_codigo") public String maquina;
    public String unidad;
    public String ubicacion;
    @SerializedName("stock_actual") public double stockActual;
    @SerializedName("stock_minimo") public double stockMinimo;
    @SerializedName("estado_stock") public String estadoStock;   // normal, bajo o agotado
}
