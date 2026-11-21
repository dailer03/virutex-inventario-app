package com.virutex.inventario.data.repository;

import android.content.Context;

import com.virutex.inventario.data.remote.ApiClient;
import com.virutex.inventario.data.remote.ApiService;
import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.data.remote.dto.Catalogos;
import com.virutex.inventario.data.remote.dto.NuevoRepuesto;
import com.virutex.inventario.data.remote.dto.Repuesto;
import com.virutex.inventario.data.remote.dto.RepuestoCreado;

import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class RepuestoRepository {
    private final ApiService api;

    public RepuestoRepository(Context context) {
        api = ApiClient.get(context);
    }

    public void buscar(String texto, String maquina, Resultado<List<Repuesto>> resultado) {
        enviar(api.buscarRepuestos(vacioANull(texto), vacioANull(maquina)), resultado);
    }

    public void catalogos(Resultado<Catalogos> resultado) {
        enviar(api.catalogos(), resultado);
    }

    public void crear(NuevoRepuesto repuesto, Resultado<RepuestoCreado> resultado) {
        enviar(api.crearRepuesto(repuesto), resultado);
    }

    /** Ejecuta la llamada y entrega los datos o el mensaje de error de la API. */
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

    private static String vacioANull(String s) {
        return (s == null || s.trim().isEmpty()) ? null : s.trim();
    }
}