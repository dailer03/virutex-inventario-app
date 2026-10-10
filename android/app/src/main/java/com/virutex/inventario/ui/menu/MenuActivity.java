package com.virutex.inventario.ui.menu;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.virutex.inventario.R;
import com.virutex.inventario.data.repository.AuthRepository;
import com.virutex.inventario.ui.inventario.InventarioActivity;
import com.virutex.inventario.ui.login.LoginActivity;
import com.virutex.inventario.util.SessionManager;

/** P-02 Menú principal: muestra solo las funciones del rol (Tabla 34). */
public class MenuActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_menu);
        SessionManager sesion = SessionManager.get(this);
        String rol = sesion.getRol();

        ((TextView) findViewById(R.id.tvBienvenida)).setText(sesion.getNombre() + " · " + rol);

        findViewById(R.id.btnInventario).setOnClickListener(v ->
                startActivity(new Intent(this, InventarioActivity.class)));

        mostrarSi(R.id.btnSalida, rol.equals("tecnico") || rol.equals("almacen"), "Sprint 3");
        mostrarSi(R.id.btnEntrada, rol.equals("almacen"), "Sprint 3");
        mostrarSi(R.id.btnNuevoRepuesto, rol.equals("almacen"), "Sprint 2");
        mostrarSi(R.id.btnAlertas, rol.equals("almacen") || rol.equals("supervisor"), "Sprint 4");
        mostrarSi(R.id.btnUsuarios, rol.equals("supervisor"), "Sprint 2");

        findViewById(R.id.btnCerrarSesion).setOnClickListener(v -> {
            new AuthRepository(this).logout();
            startActivity(new Intent(this, LoginActivity.class));
            finish();
        });
    }

    /** Muestra el botón solo al rol permitido. Mientras la pantalla no exista, avisa el sprint. */
    private void mostrarSi(int idBoton, boolean permitido, String sprint) {
        Button b = findViewById(idBoton);
        b.setVisibility(permitido ? View.VISIBLE : View.GONE);
        b.setOnClickListener(v ->
                Toast.makeText(this, "Disponible en el " + sprint, Toast.LENGTH_SHORT).show());
    }
}
