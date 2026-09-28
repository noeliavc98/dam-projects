package dao;

import java.sql.*;
import java.util.Date;
import java.util.*;
import util.ConexionBD;
import modelo.Alquiler;

public class AlquilerDAO {

    public List<Alquiler> buscarPorFechas(Date inicio, Date fin) {
        List<Alquiler> lista = new ArrayList<>();

        String sql = """
            SELECT a.numero_expediente,
                   CONCAT(c.nombre,' ',c.apellido) AS cliente,
                   v.codigo_referencia,
                   a.fecha_entrada,
                   a.tiempo_estimado,
                   v.precio,
                   a.estado_cobro
            FROM alquiler a
            JOIN cliente c ON a.id_cliente = c.id_cliente
            JOIN vivienda v ON a.id_vivienda = v.id_vivienda
        """;
        if (inicio != null && fin != null) {
            sql += " WHERE a.fecha_entrada BETWEEN ? AND ?";
        }
        sql += " ORDER BY a.fecha_entrada DESC";

        try (Connection con = ConexionBD.getConexion();
             PreparedStatement ps = con.prepareStatement(sql)) {

        	if (inicio != null && fin != null) {
            ps.setDate(1, new java.sql.Date(inicio.getTime()));
            ps.setDate(2, new java.sql.Date(fin.getTime()));
        	}

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                lista.add(new Alquiler(
                        rs.getString("numero_expediente"),
                        rs.getString("cliente"),
                        rs.getString("codigo_referencia"),
                        rs.getDate("fecha_entrada"),
                        rs.getInt("tiempo_estimado"),
                        rs.getInt("precio"),
                        rs.getString("estado_cobro")
                ));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return lista;
    }
}
