package db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionBD {

    private static final String URL =
            "jdbc:mysql://localhost:3306/contratos?useSSL=false&serverTimezone=UTC";
    private static final String USER = "root";
    private static final String PASS = "NOELIADIVC9814";

    public static Connection getConnection() {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(URL, USER, PASS);
            System.out.println("Conexión exitosa a la base de datos");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return conn;
    }
}