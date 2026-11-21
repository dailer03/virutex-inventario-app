package com.virutex.inventario.data.repository;

import android.content.Context;

import com.virutex.inventario.data.remote.ApiClient;
import com.virutex.inventario.data.remote.ApiService;
import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.data.remote.dto.EstadoUsuario;
import com.virutex.inventario.data.remote.dto.NuevoUsuario;
import com.virutex.inventario.data.remote.dto.Usuario;

import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/** Acceso a los servicios de usuarios (HU-16). */
public class UsuarioRepository {
    private final ApiService api;

    public UsuarioRepository(Context context) {
        api = ApiClient.get(context);
    }

    public void listar(Resultado<List<Usuario>> resultado) {
        enviar(api.usuarios(), resultado);
    }

    public void crear(NuevoUsuario nuevo, Resultado<Object> resultado) {
        enviar(api.crearUsuario(nuevo), resultado);
    }

    public void cambiarEstado(int idUsuario, boolean activo, Resultado<Object> resultado) {
        enviar(api.cambiarEstadoUsuario(idUsuario, new EstadoUsuario(activo)), resultado);
    }

    private static <T> void enviar(Call<ApiResponse<T>> llamada, Resultado<T> resultado) {
        llamada.enqueue(new Callback<ApiResponse<T>>() {
            @Override
            public void onResponse(Call<ApiResponse<T>> call, Response<ApiResponse<T>> r) {
                if (r.isSuccessful() && r.body() != null) {
                    resultado.exito(r.body().datos);
                } else {
                    resultado.error(r.code(), ApiClient.mensajeDeError(r));
                }
            }

            @Override
            public void onFailure(Call<ApiResponse<T>> call, Throwable t) {
                resultado.error(0, "No hay conexión con el servidor.");
            }
        });
    }
}