package com.virutex.inventario.ui.login;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;

import com.virutex.inventario.R;
import com.virutex.inventario.ui.menu.MenuActivity;
import com.virutex.inventario.util.SessionManager;

/** P-01 Inicio de sesión (HU-01). */
public class LoginActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (SessionManager.get(this).haySesion()) {
            abrirMenu();
            return;
        }
        setContentView(R.layout.activity_login);

        EditText usuario = findViewById(R.id.etUsuario);
        EditText contrasena = findViewById(R.id.etContrasena);
        Button ingresar = findViewById(R.id.btnIngresar);
        ProgressBar progreso = findViewById(R.id.progreso);
        TextView error = findViewById(R.id.tvError);

        LoginViewModel vm = new ViewModelProvider(this).get(LoginViewModel.class);
        vm.getCargando().observe(this, c -> {
            progreso.setVisibility(c ? View.VISIBLE : View.GONE);
            ingresar.setEnabled(!c);
        });
        vm.getError().observe(this, m -> {
            error.setText(m);
            error.setVisibility(m == null ? View.GONE : View.VISIBLE);
        });
        vm.getUsuario().observe(this, u -> { if (u != null) abrirMenu(); });

        ingresar.setOnClickListener(v ->
                vm.ingresar(usuario.getText().toString(), contrasena.getText().toString()));
    }

    private void abrirMenu() {
        startActivity(new Intent(this, MenuActivity.class));
        finish();
    }
}
