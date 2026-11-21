package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

/** Datos que se envían a POST /v1/repuestos (HU-02). */
public class NuevoRepuesto {
    public String codigo;
    public String nombre;
    public String descripcion;
    @SerializedName("id_maquina") public int idMaquina;
    @SerializedName("id_unidad") public int idUnidad;
    @SerializedName("id_ubicacion") public Integer idUbicacion;   // null = sin ubicación
    @SerializedName("stock_minimo") public double stockMinimo;
}