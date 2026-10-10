package com.virutex.inventario.data.repository;

import android.content.Context;

import com.virutex.inventario.data.remote.ApiClient;
import com.virutex.inventario.data.remote.ApiService;
import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.data.remote.dto.Repuesto;

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
        api.buscarRepuestos(vacioANull(texto), vacioANull(maquina))
                .enqueue(new Callback<ApiResponse<List<Repuesto>>>() {
            @Override
            public void onResponse(Call<ApiResponse<List<Repuesto>>> call,
                                   Response<ApiResponse<List<Repuesto>>> r) {
                if (r.isSuccessful() && r.body() != null) {
                    resultado.exito(r.body().datos);
                } else {
                    resultado.error(r.code(), ApiClient.mensajeDeError(r));
                }
            }

            @Override
            public void onFailure(Call<ApiResponse<List<Repuesto>>> call, Throwable t) {
                resultado.error(0, "No hay conexión con el servidor.");
            }
        });
    }

    private static String vacioANull(String s) {
        return (s == null || s.trim().isEmpty()) ? null : s.trim();
    }
}
