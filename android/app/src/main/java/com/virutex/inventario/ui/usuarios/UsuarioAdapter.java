package com.virutex.inventario.ui.usuarios;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.Usuario;

import java.util.ArrayList;
import java.util.List;

public class UsuarioAdapter extends RecyclerView.Adapter<UsuarioAdapter.Fila> {

    public interface AlCambiarEstado {
        void cambiar(Usuario usuario);
    }

    private final List<Usuario> datos = new ArrayList<>();
    private final AlCambiarEstado accion;

    public UsuarioAdapter(AlCambiarEstado accion) {
        this.accion = accion;
    }

    public void mostrar(List<Usuario> nuevos) {
        datos.clear();
        if (nuevos != null) datos.addAll(nuevos);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public Fila onCreateViewHolder(@NonNull ViewGroup padre, int tipo) {
        View v = LayoutInflater.from(padre.getContext()).inflate(R.layout.item_usuario, padre, false);
        return new Fila(v);
    }

    @Override
    public void onBindViewHolder(@NonNull Fila f, int pos) {
        Usuario u = datos.get(pos);
        boolean activo = u.activo == 1;
        f.nombre.setText(u.nombreCompleto);
        f.detalle.setText(u.nombreUsuario + " · " + rolLegible(u.rol) + " · "
                + (activo ? "Activo" : "Inactivo") + (u.bloqueado == 1 ? " · bloqueado" : ""));
        f.estado.setText(activo ? "Desactivar" : "Activar");
        f.estado.setOnClickListener(v -> accion.cambiar(u));
    }

    @Override
    public int getItemCount() { return datos.size(); }

    static String rolLegible(String rol) {
        if ("supervisor".equals(rol)) return "Supervisor";
        if ("almacen".equals(rol)) return "Almacén";
        return "Técnico";
    }

    static class Fila extends RecyclerView.ViewHolder {
        final TextView nombre, detalle;
        final Button estado;

        Fila(View v) {
            super(v);
            nombre = v.findViewById(R.id.tvNombre);
            detalle = v.findViewById(R.id.tvDetalle);
            estado = v.findViewById(R.id.btnEstado);
        }
    }
}