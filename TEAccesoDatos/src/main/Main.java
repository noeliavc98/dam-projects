package main;

import java.util.List;
import dao.ContratoDAO;
import xml.EscritorXML;
import model.Contrato;

public class Main {
    public static void main(String[] args) {

        ContratoDAO dao = new ContratoDAO();

        // Obtener todos los contratos de la base de datos
        List<Contrato> contratos = dao.obtenerTodos();
        System.out.println("Contratos obtenidos: " + contratos.size());

        // Generar XML de salida sin tipoContrato
        EscritorXML.generarXML(contratos, "contratos_sin_tipo.xml");

        System.out.println("Proceso completado");
    }
}

