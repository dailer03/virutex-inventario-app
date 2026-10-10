package com.virutex.inventario.ui.inventario;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.Repuesto;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class RepuestoAdapter extends RecyclerView.Adapter<RepuestoAdapter.Fila> {
    private final List<Repuesto> datos = new ArrayList<>();

    public void mostrar(List<Repuesto> nuevos) {
        datos.clear();
        if (nuevos != null) datos.addAll(nuevos);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public Fila onCreateViewHolder(@NonNull ViewGroup padre, int tipo) {
        View v = LayoutInflater.from(padre.getContext()).inflate(R.layout.item_repuesto, padre, false);
        return new Fila(v);
    }

    @Override
    public void onBindViewHolder(@NonNull Fila f, int pos) {
        Repuesto r = datos.get(pos);
        f.nombre.setText(r.nombre);
        f.detalle.setText(r.codigo + " · " + r.maquina + " · "
                + (r.ubicacion != null ? r.ubicacion : "sin ubicación"));
        f.stock.setText(String.format(Locale.US, "%.2f %s", r.stockActual, r.unidad));
        f.estado.setText(r.estadoStock);
        // El estado se indica con texto y color (no solo color)
        int color = "agotado".equals(r.estadoStock) ? Color.parseColor("#B3261E")
                : "bajo".equals(r.estadoStock) ? Color.parseColor("#B86E00")
                : Color.parseColor("#1E7A4C");
        f.estado.setTextColor(color);
    }

    @Override
    public int getItemCount() { return datos.size(); }

    static class Fila extends RecyclerView.ViewHolder {
        final TextView nombre, detalle, stock, estado;

        Fila(View v) {
            super(v);
            nombre = v.findViewById(R.id.tvNombre);
            detalle = v.findViewById(R.id.tvDetalle);
            stock = v.findViewById(R.id.tvStock);
            estado = v.findViewById(R.id.tvEstado);
        }
    }
}
