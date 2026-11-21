package com.virutex.inventario.ui.login;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import com.virutex.inventario.data.remote.dto.LoginData;
import com.virutex.inventario.data.repository.AuthRepository;
import com.virutex.inventario.data.repository.Resultado;

public class LoginViewModel extends AndroidViewModel {
    private final AuthRepository repo;
    private final MutableLiveData<Boolean> cargando = new MutableLiveData<>(false);
    private final MutableLiveData<String> error = new MutableLiveData<>();
    private final MutableLiveData<LoginData.Usuario> usuario = new MutableLiveData<>();

    public LoginViewModel(@NonNull Application app) {
        super(app);
        repo = new AuthRepository(app);
    }

    public LiveData<Boolean> getCargando() { return cargando; }
    public LiveData<String> getError() { return error; }
    public LiveData<LoginData.Usuario> getUsuario() { return usuario; }

    public void ingresar(String nombreUsuario, String contrasena) {
        if (nombreUsuario.trim().isEmpty() || contrasena.isEmpty()) {
            error.setValue("Ingrese usuario y contraseña.");
            return;
        }
        cargando.setValue(true);
        repo.login(nombreUsuario.trim(), contrasena, new Resultado<LoginData.Usuario>() {
            @Override public void exito(LoginData.Usuario u) {
                cargando.setValue(false);
                usuario.setValue(u);
            }
            @Override public void error(int codigo, String mensaje) {
                cargando.setValue(false);
                error.setValue(mensaje);
            }
        });
    }
}
