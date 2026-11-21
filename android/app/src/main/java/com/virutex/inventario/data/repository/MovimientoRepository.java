package com.virutex.inventario.data.repository;

import android.content.Context;

import com.virutex.inventario.data.remote.ApiClient;
import com.virutex.inventario.data.remote.ApiService;
import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.data.remote.dto.MovimientoRegistrado;
import com.virutex.inventario.data.remote.dto.NuevoMovimiento;
import com.virutex.inventario.data.remote.dto.Tecnico;

import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/** Acceso a los servicios de movimientos (HU-05, HU-06). */
public class MovimientoRepository {
    private final ApiService api;

    public MovimientoRepository(Context context) {
        api = ApiClient.get(context);
    }

    public void salida(NuevoMovimiento m, Resultado<MovimientoRegistrado> resultado) {
        enviar(api.registrarSalida(m), resultado);
    }

    public void entrada(NuevoMovimiento m, Resultado<MovimientoRegistrado> resultado) {
        enviar(api.registrarEntrada(m), resultado);
    }

    public void tecnicos(Resultado<List<Tecnico>> resultado) {
        enviar(api.tecnicos(), resultado);
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