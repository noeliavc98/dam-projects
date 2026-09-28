package test;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;
import java.util.Date;
import dao.AlquilerDAO;
import modelo.Alquiler;
import java.util.*;

public class AlquilerDAOTest {

    @Test
    void buscarAlquileresConResultados() {
        AlquilerDAO dao = new AlquilerDAO();

        Calendar cal = Calendar.getInstance();
        cal.set(2024, Calendar.JANUARY, 1);
        Date inicio = cal.getTime();

        cal.set(2025, Calendar.DECEMBER, 31);
        Date fin = cal.getTime();

        List<Alquiler> resultados = dao.buscarPorFechas(inicio, fin);

        assertNotNull(resultados);
        assertTrue(resultados.size() > 0);
    }

    @Test
    void buscarAlquileresSinResultados() {
        AlquilerDAO dao = new AlquilerDAO();

        Calendar cal = Calendar.getInstance();
        cal.set(2035, Calendar.JANUARY, 1);
        Date inicio = cal.getTime();

        cal.set(2035, Calendar.DECEMBER, 31);
        Date fin = cal.getTime();

        List<Alquiler> resultados = dao.buscarPorFechas(inicio, fin);

        assertNotNull(resultados);
        assertEquals(0, resultados.size());
    }

    @Test
    void buscarAlquileresFechasInvertidas() {
        AlquilerDAO dao = new AlquilerDAO();

        Calendar cal = Calendar.getInstance();
        cal.set(2025, Calendar.JUNE, 1);
        Date inicio = cal.getTime();

        cal.set(2025, Calendar.JANUARY, 1);
        Date fin = cal.getTime();

        List<Alquiler> alquileres = dao.buscarPorFechas(inicio, fin);

        assertNotNull(alquileres);
    }
}
