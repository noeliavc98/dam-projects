package xml;

import java.io.File;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;

import dao.ContratoDAO;
import model.Contrato;

public class LectorXML {

    public static void main(String[] args) {

        // Ruta del XML (ajusta si hace falta)
        String ruta = "C:/TEAccesoDatos/src/contratos.xml";

        leerXML(ruta);
        System.out.println("Proceso terminado");
    }

    public static void leerXML(String ruta) {

        try {
            File f = new File(ruta);

            DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
            DocumentBuilder db = dbf.newDocumentBuilder();
            Document doc = db.parse(f);

            NodeList lista = doc.getElementsByTagName("contrato");
            ContratoDAO dao = new ContratoDAO();

            for (int i = 0; i < lista.getLength(); i++) {

                Element e = (Element) lista.item(i);

                String nif = e.getElementsByTagName("nif").item(0).getTextContent();
                String adjudicatario = e.getElementsByTagName("adjudicatario").item(0).getTextContent();
                String objetoGen = e.getElementsByTagName("objetoGenerico").item(0).getTextContent();
                String objeto = e.getElementsByTagName("objeto").item(0).getTextContent();
                String fecha = e.getElementsByTagName("fechaAdjudicacion").item(0).getTextContent();
                String importeTxt = e.getElementsByTagName("importe").item(0).getTextContent();
                String tipo = e.getElementsByTagName("tipoContrato").item(0).getTextContent();

                double importe = Double.parseDouble(
                    importeTxt.replace("€", "").replace(",", ".").trim()
                );

                Contrato c = new Contrato(
                    nif, adjudicatario, objetoGen,
                    objeto, fecha, importe, tipo
                );

                // Validar si ya existe antes de insertar
                if (!dao.existeContrato(nif)) {
                    dao.insertar(c);
                } else {
                    System.out.println("Contrato ya existe: " + nif);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
