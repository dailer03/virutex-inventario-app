package com.virutex.inventario.ui.movimiento;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.Catalogos;
import com.virutex.inventario.data.remote.dto.MovimientoRegistrado;
import com.virutex.inventario.data.remote.dto.NuevoMovimiento;
import com.virutex.inventario.data.remote.dto.Repuesto;
import com.virutex.inventario.data.repository.MovimientoRepository;
import com.virutex.inventario.data.repository.RepuestoRepository;
import com.virutex.inventario.data.repository.Resultado;
import com.virutex.inventario.ui.inventario.RepuestoAdapter;
import com.virutex.inventario.ui.login.LoginActivity;
import com.virutex.inventario.util.SessionManager;

import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/** P-06 Registrar entrada (HU-05): repuesto → cantidad → confirmación. Solo rol almacén. */
public class RegistroEntradaActivity extends AppCompatActivity {
    private RepuestoRepository repoRepuestos;
    private MovimientoRepository repoMovimientos;
    private RepuestoAdapter resultados;
    private Repuesto seleccionado;
    private final Map<String, Integer> decimalesPorUnidad = new HashMap<>();
    private EditText etBuscar, etCantidad, etObservacion;
    private TextView tvSeleccionado, tvError;
    private Button btnRegistrar;
    private String uuidPendiente;   // se reutiliza al reintentar, para no duplicar la entrada

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_registro_entrada);
        repoRepuestos = new RepuestoRepository(this);
        repoMovimientos = new MovimientoRepository(this);

        etBuscar = findViewById(R.id.etBuscar);
        etCantidad = findViewById(R.id.etCantidad);
        etObservacion = findViewById(R.id.etObservacion);
        tvSeleccionado = findViewById(R.id.tvSeleccionado);
        tvError = findViewById(R.id.tvError);
        btnRegistrar = findViewById(R.id.btnRegistrar);

        resultados = new RepuestoAdapter(this::seleccionar);
        RecyclerView lista = findViewById(R.id.rvResultados);
        lista.setLayoutManager(new LinearLayoutManager(this));
        lista.setAdapter(resultados);

        findViewById(R.id.btnBuscar).setOnClickListener(v -> buscar());
        btnRegistrar.setOnClickListener(v -> confirmar());

        // Unidades: para saber cuáles admiten decimales (H-10)
        repoRepuestos.catalogos(new Resultado<Catalogos>() {
            @Override public void exito(Catalogos c) {
                for (Catalogos.Unidad u : c.unidades) decimalesPorUnidad.put(u.codigo, u.permiteDecimales);
            }
            @Override public void error(int codigo, String mensaje) { manejarError(codigo, mensaje); }
        });
    }

    private void buscar() {
        tvError.setVisibility(View.GONE);
        repoRepuestos.buscar(etBuscar.getText().toString(), null, new Resultado<List<Repuesto>>() {
            @Override public void exito(List<Repuesto> datos) {
                resultados.mostrar(datos);
                if (datos.isEmpty()) mostrarError("No hay repuestos que coincidan con la búsqueda.");
            }
            @Override public void error(int codigo, String mensaje) { manejarError(codigo, mensaje); }
        });
    }

    private void seleccionar(Repuesto r) {
        seleccionado = r;
        uuidPendiente = null;
        resultados.mostrar(null);
        tvSeleccionado.setText(r.codigo + " · " + r.nombre + "\nStock actual: "
                + formato(r.stockActual) + " " + r.unidad);
    }

    private void confirmar() {
        tvError.setVisibility(View.GONE);
        if (seleccionado == null) {
            mostrarError("Busque y seleccione el repuesto.");
            return;
        }
        double cantidad;
        try {
            cantidad = Double.parseDouble(etCantidad.getText().toString().trim().replace(',', '.'));
        } catch (NumberFormatException e) {
            etCantidad.setError("Ingrese la cantidad recibida.");
            return;
        }
        if (cantidad <= 0) {
            etCantidad.setError("La cantidad debe ser mayor que cero.");
            return;
        }
        Integer decimales = decimalesPorUnidad.get(seleccionado.unidad);
        if (decimales != null && decimales == 0 && cantidad != Math.floor(cantidad)) {
            etCantidad.setError("La unidad " + seleccionado.unidad + " no admite decimales.");
            return;
        }

        final double cant = cantidad;
        String resumen = "Repuesto: " + seleccionado.codigo + " · " + seleccionado.nombre
                + "\nCantidad recibida: " + formato(cant) + " " + seleccionado.unidad
                + "\nStock después de la entrada: " + formato(seleccionado.stockActual + cant);
        new AlertDialog.Builder(this)
                .setTitle("Confirmar entrada")
                .setMessage(resumen)
                .setPositiveButton("Registrar", (d, w) -> enviar(cant))
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private void enviar(double cantidad) {
        if (uuidPendiente == null) uuidPendiente = UUID.randomUUID().toString();
        String observacion = etObservacion.getText().toString().trim();

        NuevoMovimiento m = new NuevoMovimiento();
        m.uuidCliente = uuidPendiente;
        m.idRepuesto = seleccionado.idRepuesto;
        m.cantidad = cantidad;
        m.observacion = observacion.isEmpty() ? null : observacion;

        btnRegistrar.setEnabled(false);
        String unidad = seleccionado.unidad;
        repoMovimientos.entrada(m, new Resultado<MovimientoRegistrado>() {
            @Override public void exito(MovimientoRegistrado r) {
                uuidPendiente = null;
                Toast.makeText(RegistroEntradaActivity.this, "Entrada registrada. Stock resultante: "
                        + formato(r.stockResultante) + " " + unidad, Toast.LENGTH_LONG).show();
                finish();
            }
            @Override public void error(int codigo, String mensaje) {
                btnRegistrar.setEnabled(true);
                if (codigo != 0) uuidPendiente = null;   // sin conexión se conserva para reintentar
                manejarError(codigo, mensaje);
            }
        });
    }

    private static String formato(double v) {
        return String.format(Locale.US, "%.2f", v);
    }

    private void mostrarError(String mensaje) {
        tvError.setText(mensaje);
        tvError.setVisibility(View.VISIBLE);
    }

    private void manejarError(int codigo, String mensaje) {
        if (codigo == 401) {                       // sesión vencida: volver al inicio de sesión
            SessionManager.get(this).cerrar();
            startActivity(new Intent(this, LoginActivity.class));
            finishAffinity();
            return;
        }
        mostrarError(mensaje);
    }
}
