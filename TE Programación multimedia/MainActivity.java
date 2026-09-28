package com.example.conversorunidades;

import androidx.appcompat.app.AppCompatActivity;
import android.content.SharedPreferences;
import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.TextView;


public class MainActivity extends AppCompatActivity {

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        EditText valor;
        TextView resultado;
        RadioButton rbLongitud, rbPeso, rbTemperatura;
        Button calcular, borrar, guardar, mostrar;

        SharedPreferences sharedPreferences;
        String PREFS_NAME="MisPrefs";
        String KEY_RESULTADO = "ultimoResultado";

        valor=(EditText)findViewById(R.id.valor);

        resultado=(TextView)findViewById(R.id.resultado);

        rbLongitud=(RadioButton)findViewById(R.id.rbLongitud);
        rbPeso=(RadioButton)findViewById(R.id.rbPeso);
        rbTemperatura=(RadioButton)findViewById(R.id.rbTemperatura);

        calcular=(Button)findViewById(R.id.calcular);
        borrar=(Button)findViewById(R.id.borrar);
        guardar=(Button)findViewById(R.id.guardar);
        mostrar=(Button)findViewById(R.id.mostrar);

        sharedPreferences = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);

        //Boton Calcular
        calcular.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String valornum=valor.getText().toString();
                if (valornum.isEmpty()) {
                    resultado.setText("Por favor, ingresa un valor");
                    return;                }
                try {
                    double num = Double.parseDouble(valornum);
                    if (rbLongitud.isChecked()) {
                        double makm = num / 1000.00;
                        resultado.setText(String.valueOf(makm) + " km");

                    } else if (rbPeso.isChecked()) {
                        double gakg = num / 1000.00;
                        resultado.setText(String.valueOf(gakg) + " kg");

                    } else if (rbTemperatura.isChecked()) {
                        double caf = (num * (9.0 / 5)) + 32;
                        resultado.setText(String.valueOf(caf) + " Fº");

                    }
                }catch (NumberFormatException e) {
                        resultado.setText("Error en la conversión del número");
                    }
                }
        });

        //Boton borrar
        borrar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                valor.setText("");
                resultado.setText("");
            }
        });

        //Boton guardar
        guardar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String texto=resultado.getText().toString();
                if (!texto.isEmpty()) {
                    SharedPreferences.Editor editor = sharedPreferences.edit();
                    editor.putString(KEY_RESULTADO, texto);
                    editor.apply();

                    resultado.setText("Guardado!");
                } else {
                    resultado.setText("Introduce algo primero");
                }
            }
        });

        //Boton mostrar
        mostrar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String ultimoResultado = sharedPreferences.getString(KEY_RESULTADO, "");
                if (!ultimoResultado.isEmpty()) {
                    resultado.setText("Último resultado: " + ultimoResultado);
                } else {
                    resultado.setText("No hay resultados guardados");
                }
            }
        });

    }
}



