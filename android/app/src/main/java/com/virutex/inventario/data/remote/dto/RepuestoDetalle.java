package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

import java.util.List;

/** Respuesta de GET /v1/repuestos/{id} (P-04). */
public class RepuestoDetalle {
    @SerializedName("id_repuesto") public int idRepuesto;
    public String codigo;
    public String nombre;
    public String descripcion;
    @SerializedName("maquina_codigo") public String maquinaCodigo;
    @SerializedName("maquina") public String maquinaNombre;
    public String unidad;
    public String ubicacion;
    @SerializedName("stock_actual") public double stockActual;
    @SerializedName("stock_minimo") public double stockMinimo;
    @SerializedName("estado_stock") public String estadoStock;
    public List<Proveedor> proveedores;

    public static class Proveedor {
        public String nombre;
        @SerializedName("tiempo_reposicion_dias") public int tiempoReposicionDias;
        @SerializedName("es_principal") public int esPrincipal;
    }
}
