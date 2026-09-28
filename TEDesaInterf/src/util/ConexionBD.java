package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionBD {   //en esta clase conectamos con la base de datos

    private static final String URL =
        "jdbc:mysql://localhost:3306/smartocupation?useSSL=false&allowPublicKeyRetrieval=true";  //url mysql
    private static final String USUARIO = "root";      //usuario de mysql
    private static final String PASSWORD = "NOELIADIVC9814"; //contrasena de mysql

    public static Connection getConexion() throws SQLException {
        return DriverManager.getConnection(URL, USUARIO, PASSWORD);
    }

    public static void main(String[] args) {
        try {
            Connection con = getConexion();
            System.out.println("Conectado correctamente a MySQL");
            con.close();
        } catch (SQLException e) {
            System.out.println("ERROR al conectar");
            e.printStackTrace();
        }
    }
}
