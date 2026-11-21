package com.virutex.inventario.data.remote.dto;

public class LoginRequest {
    public final String usuario;
    public final String contrasena;

    public LoginRequest(String usuario, String contrasena) {
        this.usuario = usuario;
        this.contrasena = contrasena;
    }
}
