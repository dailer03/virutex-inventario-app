package com.virutex.inventario.data.remote.dto;

import com.google.gson.annotations.SerializedName;

import java.util.List;

/** Listas cerradas para el formulario de registro (HU-02). */
public class Catalogos {
    public List<Maquina> maquinas;
    public List<Unidad> unidades;
    public List<Ubicacion> ubicaciones;

    public static class Maquina {
        public int id;
        public String codigo;
        public String nombre;
        @Override public String toString() { return codigo + " · " + nombre; }
    }

    public static class Unidad {
        public int id;
        public String codigo;
        public String nombre;
        @SerializedName("permite_decimales") public int permiteDecimales;
        @Override public String toString() { return nombre + " (" + codigo + ")"; }
    }

    public static class Ubicacion {
        public int id;
        public String nombre;
        public Ubicacion() { }
        public Ubicacion(int id, String nombre) { this.id = id; this.nombre = nombre; }
        @Override public String toString() { return nombre; }
    }
}