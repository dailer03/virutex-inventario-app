package com.virutex.inventario.ui.repuesto;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.Catalogos;
import com.virutex.inventario.data.remote.dto.NuevoRepuesto;
import com.virutex.inventario.data.remote.dto.RepuestoCreado;
import com.virutex.inventario.data.repository.RepuestoRepository;
import com.virutex.inventario.data.repository.Resultado;
import com.virutex.inventario.ui.login.LoginActivity;
import com.virutex.inventario.util.SessionManager;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** P-05 Registrar repuesto (HU-02, HU-08). Solo rol almacén. */
public class RegistroRepuestoActivity extends AppCompatActivity {
    private RepuestoRepository repo;
    private EditText etCodigo, etNombre, etDescripcion, etStockMinimo;
    private Spinner spMaquina, spUnidad, spUbicacion;
    private TextView tvError;
    private Button btnGuardar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_registro_repuesto);
        repo = new RepuestoRepository(this);

        etCodigo = findViewById(R.id.etCodigo);
        etNombre = findViewById(R.id.etNombre);
        etDescripcion = findViewById(R.id.etDescripcion);
        etStockMinimo = findViewById(R.id.etStockMinimo);
        spMaquina = findViewById(R.id.spMaquina);
        spUnidad = findViewById(R.id.spUnidad);
        spUbicacion = findViewById(R.id.spUbicacion);
        tvError = findViewById(R.id.tvError);
        btnGuardar = findViewById(R.id.btnGuardar);

        btnGuardar.setEnabled(false);              // se habilita cuando lleguen las listas
        btnGuardar.setOnClickListener(v -> guardar());
        cargarCatalogos();
    }

    private void cargarCatalogos() {
        repo.catalogos(new Resultado<Catalogos>() {
            @Override public void exito(Catalogos c) {
                spMaquina.setAdapter(adaptador(c.maquinas));
                spUnidad.setAdapter(adaptador(c.unidades));
                List<Catalogos.Ubicacion> ubicaciones = new ArrayList<>();
                ubicaciones.add(new Catalogos.Ubicacion(0, "Sin ubicación"));
                ubicaciones.addAll(c.ubicaciones);
                spUbicacion.setAdapter(adaptador(ubicaciones));
                btnGuardar.setEnabled(true);
            }
            @Override public void error(int codigo, String mensaje) {
                manejarError(codigo, mensaje);
            }
        });
    }

    private <T> ArrayAdapter<T> adaptador(List<T> datos) {
        ArrayAdapter<T> a = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, datos);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        return a;
    }

    private void guardar() {
        tvError.setVisibility(View.GONE);
        String codigo = etCodigo.getText().toString().trim().toUpperCase(Locale.ROOT);
        String nombre = etNombre.getText().toString().trim();
        String descripcion = etDescripcion.getText().toString().trim();
        String textoMinimo = etStockMinimo.getText().toString().trim().replace(',', '.');
        Catalogos.Maquina maquina = (Catalogos.Maquina) spMaquina.getSelectedItem();
        Catalogos.Unidad unidad = (Catalogos.Unidad) spUnidad.getSelectedItem();
        Catalogos.Ubicacion ubicacion = (Catalogos.Ubicacion) spUbicacion.getSelectedItem();

        // Validaciones en el teléfono; la API las repite (RNF-03)
        if (codigo.isEmpty() || codigo.equals("NA")) {
            etCodigo.setError("Ingrese un código distinto de NA.");
            return;
        }
        if (nombre.isEmpty()) {
            etNombre.setError("Ingrese el nombre del repuesto.");
            return;
        }
        double minimo;
        try {
            minimo = textoMinimo.isEmpty() ? 0 : Double.parseDouble(textoMinimo);
        } catch (NumberFormatException e) {
            etStockMinimo.setError("Ingrese un número válido.");
            return;
        }
        if (minimo < 0) {
            etStockMinimo.setError("El stock mínimo no puede ser negativo.");
            return;
        }
        if (unidad.permiteDecimales == 0 && minimo != Math.floor(minimo)) {
            etStockMinimo.setError("La unidad " + unidad.nombre + " no admite decimales.");
            return;
        }

        NuevoRepuesto nuevo = new NuevoRepuesto();
        nuevo.codigo = codigo;
        nuevo.nombre = nombre;
        nuevo.descripcion = descripcion.isEmpty() ? null : descripcion;
        nuevo.idMaquina = maquina.id;
        nuevo.idUnidad = unidad.id;
        nuevo.idUbicacion = ubicacion.id == 0 ? null : ubicacion.id;
        nuevo.stockMinimo = minimo;

        btnGuardar.setEnabled(false);
        repo.crear(nuevo, new Resultado<RepuestoCreado>() {
            @Override public void exito(RepuestoCreado datos) {
                Toast.makeText(RegistroRepuestoActivity.this,
                        "Repuesto " + codigo + " registrado.", Toast.LENGTH_LONG).show();
                finish();
            }
            @Override public void error(int codigoHttp, String mensaje) {
                btnGuardar.setEnabled(true);
                manejarError(codigoHttp, mensaje);
            }
        });
    }

    private void manejarError(int codigo, String mensaje) {
        if (codigo == 401) {                       // sesión vencida: volver al inicio de sesión
            SessionManager.get(this).cerrar();
            startActivity(new Intent(this, LoginActivity.class));
            finishAffinity();
            return;
        }
        tvError.setText(mensaje);
        tvError.setVisibility(View.VISIBLE);
    }
}