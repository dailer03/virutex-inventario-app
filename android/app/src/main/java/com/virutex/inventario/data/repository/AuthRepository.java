package com.virutex.inventario.data.repository;

import android.content.Context;

import com.virutex.inventario.data.remote.ApiClient;
import com.virutex.inventario.data.remote.ApiService;
import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.data.remote.dto.LoginData;
import com.virutex.inventario.data.remote.dto.LoginRequest;
import com.virutex.inventario.util.SessionManager;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AuthRepository {
    private final ApiService api;
    private final SessionManager sesion;

    public AuthRepository(Context context) {
        api = ApiClient.get(context);
        sesion = SessionManager.get(context);
    }

    public void login(String usuario, String contrasena, Resultado<LoginData.Usuario> resultado) {
        api.login(new LoginRequest(usuario, contrasena)).enqueue(new Callback<ApiResponse<LoginData>>() {
            @Override
            public void onResponse(Call<ApiResponse<LoginData>> call, Response<ApiResponse<LoginData>> r) {
                if (r.isSuccessful() && r.body() != null && r.body().ok) {
                    LoginData d = r.body().datos;
                    sesion.guardar(d.token, d.usuario.id, d.usuario.nombre, d.usuario.rol);
                    resultado.exito(d.usuario);
                } else {
                    resultado.error(r.code(), ApiClient.mensajeDeError(r));
                }
            }

            @Override
            public void onFailure(Call<ApiResponse<LoginData>> call, Throwable t) {
                resultado.error(0, "No hay conexión con el servidor. Verifique la red Wi-Fi.");
            }
        });
    }

    public void logout() {
        api.logout().enqueue(new Callback<ApiResponse<Object>>() {
            @Override public void onResponse(Call<ApiResponse<Object>> c, Response<ApiResponse<Object>> r) { }
            @Override public void onFailure(Call<ApiResponse<Object>> c, Throwable t) { }
        });
        sesion.cerrar();
    }
}
