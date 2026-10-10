package com.virutex.inventario.ui.inventario;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.Repuesto;
import com.virutex.inventario.data.repository.RepuestoRepository;
import com.virutex.inventario.data.repository.Resultado;
import com.virutex.inventario.ui.login.LoginActivity;
import com.virutex.inventario.util.SessionManager;

import java.util.List;

/** P-03 Consulta de inventario (HU-03). */
public class InventarioActivity extends AppCompatActivity {
    private RepuestoRepository repo;
    private RepuestoAdapter adaptador;
    private TextView mensaje;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_inventario);
        repo = new RepuestoRepository(this);
        adaptador = new RepuestoAdapter();
        mensaje = findViewById(R.id.tvMensaje);

        RecyclerView lista = findViewById(R.id.rvRepuestos);
        lista.setLayoutManager(new LinearLayoutManager(this));
        lista.setAdapter(adaptador);

        EditText buscar = findViewById(R.id.etBuscar);
        findViewById(R.id.btnBuscar).setOnClickListener(v -> cargar(buscar.getText().toString()));
        cargar("");
    }

    private void cargar(String texto) {
        repo.buscar(texto, null, new Resultado<List<Repuesto>>() {
            @Override public void exito(List<Repuesto> datos) {
                adaptador.mostrar(datos);
                mensaje.setVisibility(datos.isEmpty() ? View.VISIBLE : View.GONE);
                mensaje.setText("No hay repuestos que coincidan con la búsqueda.");
            }
            @Override public void error(int codigo, String mensajeError) {
                if (codigo == 401) {          // sesión vencida: volver al inicio de sesión
                    SessionManager.get(InventarioActivity.this).cerrar();
                    startActivity(new Intent(InventarioActivity.this, LoginActivity.class));
                    finishAffinity();
                    return;
                }
                mensaje.setVisibility(View.VISIBLE);
                mensaje.setText(mensajeError);
            }
        });
    }
}
