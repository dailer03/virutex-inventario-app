package com.virutex.inventario.data.remote;

import android.content.Context;

import com.google.gson.Gson;
import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.util.Constantes;
import com.virutex.inventario.util.SessionManager;

import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/** Crea el cliente HTTP y agrega el token a cada solicitud. */
public final class ApiClient {
    private static ApiService servicio;

    private ApiClient() { }

    public static synchronized ApiService get(Context context) {
        if (servicio == null) {
            SessionManager sesion = SessionManager.get(context);
            OkHttpClient http = new OkHttpClient.Builder()
                    .connectTimeout(10, TimeUnit.SECONDS)
                    .readTimeout(15, TimeUnit.SECONDS)
                    .addInterceptor(chain -> {
                        Request.Builder solicitud = chain.request().newBuilder();
                        String token = sesion.getToken();
                        if (token != null) {
                            solicitud.header("Authorization", "Bearer " + token);
                        }
                        return chain.proceed(solicitud.build());
                    })
                    .build();
            servicio = new Retrofit.Builder()
                    .baseUrl(Constantes.BASE_URL)
                    .client(http)
                    .addConverterFactory(GsonConverterFactory.create())
                    .build()
                    .create(ApiService.class);
        }
        return servicio;
    }

    /** Extrae el mensaje de error que envía la API cuando la respuesta no es 2xx. */
    public static String mensajeDeError(Response<?> respuesta) {
        try {
            ApiResponse<?> cuerpo = new Gson().fromJson(respuesta.errorBody().charStream(), ApiResponse.class);
            if (cuerpo != null && cuerpo.error != null) {
                return cuerpo.error.mensaje;
            }
        } catch (Exception ignorada) {
            // la respuesta no era JSON
        }
        return "Error del servidor (" + respuesta.code() + ")";
    }
}
