package xml;

import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.w3c.dom.*;

import model.Contrato;

import java.io.File;
import java.util.List;

public class EscritorXML {

    public static void generarXML(List<Contrato> contratos, String nombreArchivo) {

        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.newDocument();

            Element root = doc.createElement("contratos");
            doc.appendChild(root);

            for (Contrato c : contratos) {

                Element contrato = doc.createElement("contrato");

                crearElemento(doc, contrato, "nif", c.getNif());
                crearElemento(doc, contrato, "adjudicatario", c.getAdjudicatario());
                crearElemento(doc, contrato, "objetoGenerico", c.getObjetoGenerico());
                crearElemento(doc, contrato, "objeto", c.getObjeto());
                crearElemento(doc, contrato, "fechaAdjudicacion", c.getFechaAdjudicacion());
                crearElemento(doc, contrato, "importe", String.valueOf(c.getImporte()));

                // ❌ NO se añade tipoContrato

                root.appendChild(contrato);
            }

            Transformer transformer = TransformerFactory.newInstance().newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.setOutputProperty(
                    "{http://xml.apache.org/xslt}indent-amount", "4");

            transformer.transform(
                    new DOMSource(doc),
                    new StreamResult(new File("contratos_sin_tipo.xml"))
            );

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void crearElemento(Document doc, Element padre,
                                      String nombre, String valor) {
        Element e = doc.createElement(nombre);
        e.setTextContent(valor != null ? valor : "");
        padre.appendChild(e);
    }
}

