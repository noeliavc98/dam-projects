package db;

import dao.ContratoDAO;
import model.Contrato;

public class PruebaBD {

    public static void main(String[] args) {

        Contrato c = new Contrato(
            "B00000001",
            "PROVEEDOR PRUEBA SL",
            "MATERIAL",
            "Contrato de prueba",
            "2024-01-01 10:00:00",
            150.75,
            "MENOR"
        );

        new ContratoDAO().insertar(c);
        System.out.println("Insertado correctamente");
    }
}
