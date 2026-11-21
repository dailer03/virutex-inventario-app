package com.virutex.inventario.ui.alertas;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.Alerta;
import com.virutex.inventario.data.repository.RepuestoRepository;
import com.virutex.inventario.data.repository.Resultado;
import com.virutex.inventario.ui.login.LoginActivity;
import com.virutex.inventario.ui.repuesto.DetalleRepuestoActivity;
import com.virutex.inventario.util.SessionManager;

import java.util.List;

/** P-10 Alertas (HU-09, HU-14): pestañas de stock mínimo y preventivas. Almacén y supervisor. */
public class AlertasActivity extends AppCompatActivity {
    private RepuestoRepository repo;
    private AlertaAdapter adaptador;
    private TextView tvMensaje;
    private String tipoActual = "stock_minimo";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_alertas);
        repo = new RepuestoRepository(this);
        tvMensaje = findViewById(R.id.tvMensaje);

        adaptador = new AlertaAdapter(a -> {
            Intent i = new Intent(this, DetalleRepuestoActivity.class);
            i.putExtra(DetalleRepuestoActivity.EXTRA_ID, a.idRepuesto);
            startActivity(i);
        });
        RecyclerView lista = findViewById(R.id.rvAlertas);
        lista.setLayoutManager(new LinearLayoutManager(this));
        lista.setAdapter(adaptador);

        findViewById(R.id.btnStockMinimo).setOnClickListener(v -> cargar("stock_minimo"));
        findViewById(R.id.btnPreventivas).setOnClickListener(v -> cargar("preventiva"));
    }

    @Override
    protected void onResume() {
        super.onResume();
        cargar(tipoActual);      // se actualiza al volver del detalle
    }

    private void cargar(String tipo) {
        tipoActual = tipo;
        setTitle("stock_minimo".equals(tipo) ? "Alertas de stock mínimo" : "Alertas preventivas");
        repo.alertas(tipo, new Resultado<List<Alerta>>() {
            @Override public void exito(List<Alerta> datos) {
                adaptador.mostrar(datos);
                tvMensaje.setVisibility(datos.isEmpty() ? View.VISIBLE : View.GONE);
                tvMensaje.setText("No hay alertas activas de este tipo.");
            }
            @Override public void error(int codigo, String mensaje) {
                if (codigo == 401) {                   // sesión vencida: volver al inicio de sesión
                    SessionManager.get(AlertasActivity.this).cerrar();
                    startActivity(new Intent(AlertasActivity.this, LoginActivity.class));
                    finishAffinity();
                    return;
                }
                tvMensaje.setText(mensaje);
                tvMensaje.setVisibility(View.VISIBLE);
            }
        });
    }
}