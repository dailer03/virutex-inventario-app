package com.virutex.inventario.data.remote.dto;

public class LoginData {
    public String token;
    public Usuario usuario;

    public static class Usuario {
        public int id;
        public String nombre;
        public String rol;      // supervisor, almacen o tecnico
    }
}
