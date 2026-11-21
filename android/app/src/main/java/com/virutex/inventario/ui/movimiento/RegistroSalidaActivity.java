package com.virutex.inventario.ui.movimiento;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
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
import com.virutex.inventario.data.remote.dto.Tecnico;
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

/** P-07 Registrar salida (HU-06): repuesto → datos → confirmación. Roles técnico y almacén. */
public class RegistroSalidaActivity extends AppCompatActivity {
    private RepuestoRepository repoRepuestos;
    private MovimientoRepository repoMovimientos;
    private RepuestoAdapter resultados;
    private Repuesto seleccionado;
    private final Map<String, Integer> decimalesPorUnidad = new HashMap<>();
    private EditText etBuscar, etCantidad, etObservacion;
    private Spinner spMaquina, spTecnico;
    private TextView tvSeleccionado, tvError;
    private Button btnRegistrar;
    private boolean esAlmacen;
    private int listasPendientes;
    private String uuidPendiente;   // se reutiliza al reintentar, para no duplicar la salida

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_registro_salida);
        repoRepuestos = new RepuestoRepository(this);
        repoMovimientos = new MovimientoRepository(this);

        etBuscar = findViewById(R.id.etBuscar);
        etCantidad = findViewById(R.id.etCantidad);
        etObservacion = findViewById(R.id.etObservacion);
        spMaquina = findViewById(R.id.spMaquina);
        spTecnico = findViewById(R.id.spTecnico);
        tvSeleccionado = findViewById(R.id.tvSeleccionado);
        tvError = findViewById(R.id.tvError);
        btnRegistrar = findViewById(R.id.btnRegistrar);

        esAlmacen = "almacen".equals(SessionManager.get(this).getRol());
        int visibilidad = esAlmacen ? View.VISIBLE : View.GONE;
        findViewById(R.id.tvLabelTecnico).setVisibility(visibilidad);
        spTecnico.setVisibility(visibilidad);

        resultados = new RepuestoAdapter(this::seleccionar);
        RecyclerView lista = findViewById(R.id.rvResultados);
        lista.setLayoutManager(new LinearLayoutManager(this));
        lista.setAdapter(resultados);

        findViewById(R.id.btnBuscar).setOnClickListener(v -> buscar());
        btnRegistrar.setEnabled(false);             // se habilita cuando lleguen las listas
        btnRegistrar.setOnClickListener(v -> confirmar());
        cargarListas();
    }

    private void cargarListas() {
        listasPendientes = esAlmacen ? 2 : 1;
        repoRepuestos.catalogos(new Resultado<Catalogos>() {
            @Override public void exito(Catalogos c) {
                spMaquina.setAdapter(adaptador(c.maquinas));
                for (Catalogos.Unidad u : c.unidades) decimalesPorUnidad.put(u.codigo, u.permiteDecimales);
                listaCargada();
            }
            @Override public void error(int codigo, String mensaje) { manejarError(codigo, mensaje); }
        });
        if (esAlmacen) {
            repoMovimientos.tecnicos(new Resultado<List<Tecnico>>() {
                @Override public void exito(List<Tecnico> datos) {
                    spTecnico.setAdapter(adaptador(datos));
                    listaCargada();
                }
                @Override public void error(int codigo, String mensaje) { manejarError(codigo, mensaje); }
            });
        }
    }

    private void listaCargada() {
        listasPendientes--;
        if (listasPendientes == 0) btnRegistrar.setEnabled(true);
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

    /** Paso 1: el usuario toca un repuesto de la lista. */
    private void seleccionar(Repuesto r) {
        seleccionado = r;
        uuidPendiente = null;
        resultados.mostrar(null);
        tvSeleccionado.setText(r.codigo + " · " + r.nombre + "\nDisponible: "
                + formato(r.stockActual) + " " + r.unidad);
    }

    /** Pasos 2 y 3: valida los datos y muestra el resumen para confirmar. */
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
            etCantidad.setError("Ingrese la cantidad.");
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
        if (cantidad > seleccionado.stockActual) {
            etCantidad.setError("Supera el stock disponible (" + formato(seleccionado.stockActual) + ").");
            return;
        }
        Catalogos.Maquina maquina = (Catalogos.Maquina) spMaquina.getSelectedItem();
        Tecnico recibe = esAlmacen ? (Tecnico) spTecnico.getSelectedItem() : null;
        if (esAlmacen && recibe == null) {
            mostrarError("No hay técnicos activos para recibir el repuesto.");
            return;
        }

        final double cant = cantidad;
        String resumen = "Repuesto: " + seleccionado.codigo + " · " + seleccionado.nombre
                + "\nCantidad: " + formato(cant) + " " + seleccionado.unidad
                + "\nMáquina: " + maquina
                + (recibe != null ? "\nRecibe: " + recibe.nombreCompleto : "")
                + "\nStock después de la salida: " + formato(seleccionado.stockActual - cant);
        new AlertDialog.Builder(this)
                .setTitle("Confirmar salida")
                .setMessage(resumen)
                .setPositiveButton("Registrar", (d, w) -> enviar(cant, maquina, recibe))
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private void enviar(double cantidad, Catalogos.Maquina maquina, Tecnico recibe) {
        if (uuidPendiente == null) uuidPendiente = UUID.randomUUID().toString();
        String observacion = etObservacion.getText().toString().trim();

        NuevoMovimiento m = new NuevoMovimiento();
        m.uuidCliente = uuidPendiente;
        m.idRepuesto = seleccionado.idRepuesto;
        m.cantidad = cantidad;
        m.idMaquinaDestino = maquina.id;
        m.idUsuarioRecibe = recibe != null ? recibe.idUsuario : null;
        m.observacion = observacion.isEmpty() ? null : observacion;

        btnRegistrar.setEnabled(false);
        String unidad = seleccionado.unidad;
        repoMovimientos.salida(m, new Resultado<MovimientoRegistrado>() {
            @Override public void exito(MovimientoRegistrado r) {
                uuidPendiente = null;
                Toast.makeText(RegistroSalidaActivity.this, "Salida registrada. Stock resultante: "
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

    private <T> ArrayAdapter<T> adaptador(List<T> datos) {
        ArrayAdapter<T> a = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, datos);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        return a;
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
