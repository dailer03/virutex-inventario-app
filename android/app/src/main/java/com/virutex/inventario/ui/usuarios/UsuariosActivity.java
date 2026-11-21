package com.virutex.inventario.ui.usuarios;

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
import com.virutex.inventario.data.remote.dto.NuevoUsuario;
import com.virutex.inventario.data.remote.dto.Usuario;
import com.virutex.inventario.data.repository.Resultado;
import com.virutex.inventario.data.repository.UsuarioRepository;
import com.virutex.inventario.ui.login.LoginActivity;
import com.virutex.inventario.util.SessionManager;

import java.util.List;
import java.util.Locale;

/** P-15 Gestión de usuarios (HU-16). Solo rol supervisor. */
public class UsuariosActivity extends AppCompatActivity {
    private static final String[] ROLES = {"tecnico", "almacen", "supervisor"};
    private static final String[] ETIQUETAS = {"Técnico", "Almacén", "Supervisor"};

    private UsuarioRepository repo;
    private UsuarioAdapter adaptador;
    private EditText etNombreCompleto, etNombreUsuario, etContrasena;
    private Spinner spRol;
    private TextView tvError;
    private Button btnCrear;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_usuarios);
        repo = new UsuarioRepository(this);

        etNombreCompleto = findViewById(R.id.etNombreCompleto);
        etNombreUsuario = findViewById(R.id.etNombreUsuario);
        etContrasena = findViewById(R.id.etContrasena);
        spRol = findViewById(R.id.spRol);
        tvError = findViewById(R.id.tvError);
        btnCrear = findViewById(R.id.btnCrear);

        ArrayAdapter<String> roles = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, ETIQUETAS);
        roles.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spRol.setAdapter(roles);

        adaptador = new UsuarioAdapter(this::confirmarCambio);
        RecyclerView lista = findViewById(R.id.rvUsuarios);
        lista.setLayoutManager(new LinearLayoutManager(this));
        lista.setAdapter(adaptador);

        btnCrear.setOnClickListener(v -> crear());
        cargar();
    }

    private void cargar() {
        repo.listar(new Resultado<List<Usuario>>() {
            @Override public void exito(List<Usuario> datos) {
                adaptador.mostrar(datos);
            }
            @Override public void error(int codigo, String mensaje) {
                manejarError(codigo, mensaje);
            }
        });
    }

    private void crear() {
        tvError.setVisibility(View.GONE);
        String nombre = etNombreCompleto.getText().toString().trim();
        String usuario = etNombreUsuario.getText().toString().trim().toLowerCase(Locale.ROOT);
        String clave = etContrasena.getText().toString();

        // Mismas reglas que valida la API
        if (nombre.isEmpty()) {
            etNombreCompleto.setError("Ingrese el nombre completo.");
            return;
        }
        if (!usuario.matches("[a-z0-9._]{3,30}")) {
            etNombreUsuario.setError("De 3 a 30 caracteres: minúsculas, números, punto o guion bajo.");
            return;
        }
        if (clave.length() < 8 || !clave.matches(".*[A-Za-z].*") || !clave.matches(".*\\d.*")) {
            etContrasena.setError("Mínimo 8 caracteres, con letras y números.");
            return;
        }

        NuevoUsuario nuevo = new NuevoUsuario();
        nuevo.nombreCompleto = nombre;
        nuevo.nombreUsuario = usuario;
        nuevo.contrasena = clave;
        nuevo.rol = ROLES[spRol.getSelectedItemPosition()];

        btnCrear.setEnabled(false);
        repo.crear(nuevo, new Resultado<Object>() {
            @Override public void exito(Object datos) {
                btnCrear.setEnabled(true);
                Toast.makeText(UsuariosActivity.this, "Usuario " + usuario + " creado.", Toast.LENGTH_LONG).show();
                etNombreCompleto.setText("");
                etNombreUsuario.setText("");
                etContrasena.setText("");
                cargar();
            }
            @Override public void error(int codigo, String mensaje) {
                btnCrear.setEnabled(true);
                manejarError(codigo, mensaje);
            }
        });
    }

    private void confirmarCambio(Usuario u) {
        boolean activar = u.activo == 0;
        new AlertDialog.Builder(this)
                .setTitle(activar ? "Activar usuario" : "Desactivar usuario")
                .setMessage(activar
                        ? "¿Activar a " + u.nombreCompleto + "?"
                        : "¿Desactivar a " + u.nombreCompleto + "? No podrá iniciar sesión, pero su historial se conserva.")
                .setPositiveButton(activar ? "Activar" : "Desactivar", (d, w) -> cambiarEstado(u, activar))
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private void cambiarEstado(Usuario u, boolean activar) {
        tvError.setVisibility(View.GONE);
        repo.cambiarEstado(u.idUsuario, activar, new Resultado<Object>() {
            @Override public void exito(Object datos) {
                Toast.makeText(UsuariosActivity.this,
                        u.nombreUsuario + (activar ? " activado." : " desactivado."), Toast.LENGTH_SHORT).show();
                cargar();
            }
            @Override public void error(int codigo, String mensaje) {
                manejarError(codigo, mensaje);
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