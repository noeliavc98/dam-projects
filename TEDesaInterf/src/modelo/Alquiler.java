package modelo;

import java.util.Date;

public class Alquiler {

    private String expediente;
    private String cliente;
    private String vivienda;
    private Date fechaEntrada;
    private int tiempoEstimado;
    private int precio;
    private String estado;

    public Alquiler(String expediente, String cliente, String vivienda,
                    Date fechaEntrada, int tiempoEstimado, int precio, String estado) {
        this.expediente = expediente;
        this.cliente = cliente;
        this.vivienda = vivienda;
        this.fechaEntrada = fechaEntrada;
        this.tiempoEstimado = tiempoEstimado;
        this.precio = precio;
        this.estado = estado;
    }

    // getters
    public String getExpediente() { return expediente; }
    public String getCliente() { return cliente; }
    public String getVivienda() { return vivienda; }
    public Date getFechaEntrada() { return fechaEntrada; }
    public int getTiempoEstimado() { return tiempoEstimado; }
    public int getPrecio() { return precio; }
    public String getEstado() { return estado; }
}
