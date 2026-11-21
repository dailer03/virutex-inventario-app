package com.virutex.inventario.data.remote;

import com.virutex.inventario.data.remote.dto.ApiResponse;
import com.virutex.inventario.data.remote.dto.LoginData;
import com.virutex.inventario.data.remote.dto.LoginRequest;
import com.virutex.inventario.data.remote.dto.Repuesto;
import com.virutex.inventario.data.remote.dto.Catalogos;
import com.virutex.inventario.data.remote.dto.NuevoRepuesto;
import com.virutex.inventario.data.remote.dto.RepuestoCreado;
import com.virutex.inventario.data.remote.dto.RepuestoDetalle;
import retrofit2.http.Path;
import com.virutex.inventario.data.remote.dto.EstadoUsuario;
import com.virutex.inventario.data.remote.dto.NuevoUsuario;
import com.virutex.inventario.data.remote.dto.Usuario;
import retrofit2.http.PATCH;
import com.virutex.inventario.data.remote.dto.MovimientoRegistrado;
import com.virutex.inventario.data.remote.dto.NuevoMovimiento;
import com.virutex.inventario.data.remote.dto.Tecnico;
import com.virutex.inventario.data.remote.dto.Alerta;

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

    @GET("v1/catalogos")
    Call<ApiResponse<Catalogos>> catalogos();

    @POST("v1/repuestos")
    Call<ApiResponse<RepuestoCreado>> crearRepuesto(@Body NuevoRepuesto cuerpo);


    @GET("v1/repuestos/{id}")
    Call<ApiResponse<RepuestoDetalle>> detalleRepuesto(@Path("id") int id);

    @GET("v1/usuarios")
    Call<ApiResponse<List<Usuario>>> usuarios();

    @POST("v1/usuarios")
    Call<ApiResponse<Object>> crearUsuario(@Body NuevoUsuario cuerpo);

    @PATCH("v1/usuarios/{id}/estado")
    Call<ApiResponse<Object>> cambiarEstadoUsuario(@Path("id") int id, @Body EstadoUsuario cuerpo);

    @POST("v1/movimientos/salidas")
    Call<ApiResponse<MovimientoRegistrado>> registrarSalida(@Body NuevoMovimiento cuerpo);

    @POST("v1/movimientos/entradas")
    Call<ApiResponse<MovimientoRegistrado>> registrarEntrada(@Body NuevoMovimiento cuerpo);

    @GET("v1/tecnicos")
    Call<ApiResponse<List<Tecnico>>> tecnicos();

    @GET("v1/alertas")
    Call<ApiResponse<List<Alerta>>> alertas(@Query("tipo") String tipo);
}
