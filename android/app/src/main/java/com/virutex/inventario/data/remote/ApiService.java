package com.virutex.inventario.data.remote;

import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.data.remote.dto.LoginData;
import com.virutex.inventario.data.remote.dto.LoginRequest;
import com.virutex.inventario.data.remote.dto.Repuesto;

import java.util.List;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.Query;

/** Servicios de la API (Tabla 25). Se agregan aquí a medida que se implementan. */
public interface ApiService {

    @POST("v1/auth/login")
    Call<ApiResponse<LoginData>> login(@Body LoginRequest cuerpo);

    @POST("v1/auth/logout")
    Call<ApiResponse<Object>> logout();

    @GET("v1/repuestos")
    Call<ApiResponse<List<Repuesto>>> buscarRepuestos(@Query("q") String texto,
                                                     @Query("maquina") String maquina);
}
