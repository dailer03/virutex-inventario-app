package com.virutex.inventario.ui.repuesto;

import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.RepuestoDetalle;
import com.virutex.inventario.data.repository.RepuestoRepository;
import com.virutex.inventario.data.repository.Resultado;
import com.virutex.inventario.ui.login.LoginActivity;
import com.virutex.inventario.util.SessionManager;

import java.util.Locale;

/** P-04 Detalle del repuesto (HU-03, HU-04, HU-08, HU-10). */
public class DetalleRepuestoActivity extends AppCompatActivity {
    public static final String EXTRA_ID = "id_repuesto";
    private TextView tvMensaje;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_detalle_repuesto);
        tvMensaje = findViewById(R.id.tvMensaje);

        int id = getIntent().getIntExtra(EXTRA_ID, 0);
        if (id <= 0) {
            finish();
            return;
        }
        new RepuestoRepository(this).detalle(id, new Resultado<RepuestoDetalle>() {
            @Override public void exito(RepuestoDetalle r) {
                mostrar(r);
            }
            @Override public void error(int codigo, String mensaje) {
                if (codigo == 401) {               // sesión vencida: volver al inicio de sesión
                    SessionManager.get(DetalleRepuestoActivity.this).cerrar();
                    startActivity(new Intent(DetalleRepuestoActivity.this, LoginActivity.class));
                    finishAffinity();
                    return;
                }
                tvMensaje.setText(mensaje);
            }
        });
    }

    private void mostrar(RepuestoDetalle r) {
        texto(R.id.tvNombre, r.nombre);
        texto(R.id.tvCodigo, r.codigo);
        texto(R.id.tvStockActual, String.format(Locale.US, "%.2f %s", r.stockActual, r.unidad));
        texto(R.id.tvStockMinimo, String.format(Locale.US, "%.2f %s", r.stockMinimo, r.unidad));
        texto(R.id.tvMaquina, r.maquinaCodigo + " · " + r.maquinaNombre);
        texto(R.id.tvUbicacion, r.ubicacion != null ? r.ubicacion : "Sin ubicación asignada");
        texto(R.id.tvDescripcion, (r.descripcion != null && !r.descripcion.isEmpty())
                ? r.descripcion : "Sin descripción");

        // El estado se muestra con texto y color (no solo color)
        TextView estado = findViewById(R.id.tvEstado);
        if ("agotado".equals(r.estadoStock)) {
            estado.setText("Agotado");
            estado.setTextColor(Color.parseColor("#B3261E"));
        } else if ("bajo".equals(r.estadoStock)) {
            estado.setText("Stock bajo: igual o menor al mínimo");
            estado.setTextColor(Color.parseColor("#B86E00"));
        } else {
            estado.setText("Stock normal");
            estado.setTextColor(Color.parseColor("#1E7A4C"));
        }

        StringBuilder sb = new StringBuilder();
        if (r.proveedores == null || r.proveedores.isEmpty()) {
            sb.append("Sin proveedores registrados");
        } else {
            for (RepuestoDetalle.Proveedor p : r.proveedores) {
                if (sb.length() > 0) sb.append("\n");
                sb.append("- ").append(p.nombre)
                        .append(" · reposición en ").append(p.tiempoReposicionDias).append(" días");
                if (p.esPrincipal == 1) sb.append(" (principal)");
            }
        }
        texto(R.id.tvProveedores, sb.toString());

        tvMensaje.setVisibility(View.GONE);
        findViewById(R.id.contenido).setVisibility(View.VISIBLE);
    }

    private void texto(int idVista, String valor) {
        ((TextView) findViewById(idVista)).setText(valor);
    }
}