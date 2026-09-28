package model;

public class Contrato {

    private String nif;
    private String adjudicatario;
    private String objetoGenerico;
    private String objeto;
    private String fechaAdjudicacion;
    private double importe;
    private String tipoContrato;

    public Contrato(String nif,
                    String adjudicatario,
                    String objetoGenerico,
                    String objeto,
                    String fechaAdjudicacion,
                    double importe,
                    String tipoContrato) {
        this.nif = nif;
        this.adjudicatario = adjudicatario;
        this.objetoGenerico = objetoGenerico;
        this.objeto = objeto;
        this.fechaAdjudicacion = fechaAdjudicacion;
        this.importe = importe;
        this.tipoContrato = tipoContrato;
    }

    public String getNif() {
        return nif;
    }

    public String getAdjudicatario() {
        return adjudicatario;
    }

    public String getObjetoGenerico() {
        return objetoGenerico;
    }

    public String getObjeto() {
        return objeto;
    }

    public String getFechaAdjudicacion() {
        return fechaAdjudicacion;
    }

    public double getImporte() {
        return importe;
    }

    public String getTipoContrato() {
        return tipoContrato;
    }
}

