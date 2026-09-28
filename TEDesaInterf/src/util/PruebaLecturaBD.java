package util;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class PruebaLecturaBD {   //prueba de lectura de los datos de la bd

    public static void main(String[] args) {

        String sql = "SELECT id_cliente, nombre, apellido FROM cliente";

        try (
            Connection con = ConexionBD.getConexion();
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(sql);
        ) {

            while (rs.next()) {
                int id = rs.getInt("id_cliente");
                String nombre = rs.getString("nombre");
                String apellido = rs.getString("apellido");

                System.out.println(id + " - " + nombre + " " + apellido);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
