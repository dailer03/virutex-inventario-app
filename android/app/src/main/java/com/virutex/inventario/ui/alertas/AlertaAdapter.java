package com.virutex.inventario.ui.alertas;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.virutex.inventario.R;
import com.virutex.inventario.data.remote.dto.Alerta;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class AlertaAdapter extends RecyclerView.Adapter<AlertaAdapter.Fila> {

    public interface AlTocar {
        void abrir(Alerta alerta);
    }

    private final List<Alerta> datos = new ArrayList<>();
    private final AlTocar alTocar;

    public AlertaAdapter(AlTocar alTocar) {
        this.alTocar = alTocar;
    }

    public void mostrar(List<Alerta> nuevas) {
        datos.clear();
        if (nuevas != null) datos.addAll(nuevas);
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public Fila onCreateViewHolder(@NonNull ViewGroup padre, int tipo) {
        View v = LayoutInflater.from(padre.getContext()).inflate(R.layout.item_alerta, padre, false);
        return new Fila(v);
    }

    @Override
    public void onBindViewHolder(@NonNull Fila f, int pos) {
        Alerta a = datos.get(pos);
        f.repuesto.setText(a.codigo + " · " + a.repuesto);
        f.detalle.setText(String.format(Locale.US, "Stock: %.2f %s · Mínimo: %.2f · Desde: %s",
                a.stockActual, a.unidad, a.stockMinimo, a.fechaGeneracion));
        if ("preventiva".equals(a.tipo)) {
            String texto = "Preventiva";
            if (a.coberturaDias != null) texto += String.format(Locale.US, ": cubre %.1f días", a.coberturaDias);
            if (a.cantidadSugerida != null) texto += String.format(Locale.US, "; sugerido %.2f %s", a.cantidadSugerida, a.unidad);
            f.tipo.setText(texto);
            f.tipo.setTextColor(Color.parseColor("#B86E00"));
        } else {
            f.tipo.setText(a.stockActual == 0 ? "Agotado" : "Stock igual o menor al mínimo");
            f.tipo.setTextColor(Color.parseColor("#B3261E"));
        }
        f.itemView.setOnClickListener(v -> alTocar.abrir(a));
    }

    @Override
    public int getItemCount() { return datos.size(); }

    static class Fila extends RecyclerView.ViewHolder {
        final TextView repuesto, detalle, tipo;

        Fila(View v) {
            super(v);
            repuesto = v.findViewById(R.id.tvRepuesto);
            detalle = v.findViewById(R.id.tvDetalle);
            tipo = v.findViewById(R.id.tvTipo);
        }
    }
}