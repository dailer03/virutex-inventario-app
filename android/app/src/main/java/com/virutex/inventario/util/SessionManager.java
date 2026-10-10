package com.virutex.inventario.util;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKey;

/** Guarda el token y los datos del usuario cifrados en el teléfono (DT-08). */
public final class SessionManager {
    private static SessionManager instancia;
    private final SharedPreferences prefs;

    private SessionManager(Context context) {
        try {
            MasterKey clave = new MasterKey.Builder(context)
                    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                    .build();
            prefs = EncryptedSharedPreferences.create(
                    context, "sesion_inventario", clave,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM);
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo abrir el almacenamiento seguro", e);
        }
    }

    public static synchronized SessionManager get(Context context) {
        if (instancia == null) {
            instancia = new SessionManager(context.getApplicationContext());
        }
        return instancia;
    }

    public void guardar(String token, int idUsuario, String nombre, String rol) {
        prefs.edit()
                .putString("token", token)
                .putInt("id_usuario", idUsuario)
                .putString("nombre", nombre)
                .putString("rol", rol)
                .apply();
    }

    public String getToken() { return prefs.getString("token", null); }
    public String getNombre() { return prefs.getString("nombre", ""); }
    public String getRol() { return prefs.getString("rol", ""); }
    public boolean haySesion() { return getToken() != null; }

    public void cerrar() { prefs.edit().clear().apply(); }
}
