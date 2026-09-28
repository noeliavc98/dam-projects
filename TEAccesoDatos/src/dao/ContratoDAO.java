package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import db.ConexionBD;
import model.Contrato;

public class ContratoDAO {
	
	private Connection conn;
	
	public ContratoDAO() {
        conn = ConexionBD.getConnection(); // Asumiendo que tu clase ConexionBD devuelve Connection
    }
	
    public void insertar(Contrato c) {

        String sql = """
            INSERT INTO contrato
            (nif, adjudicatario, objeto_generico, objeto,
             fecha_adjudicacion, importe, tipo_contrato)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, c.getNif());
            ps.setString(2, c.getAdjudicatario());
            ps.setString(3, c.getObjetoGenerico());
            ps.setString(4, c.getObjeto());
            ps.setString(5, c.getFechaAdjudicacion());
            ps.setDouble(6, c.getImporte());
            ps.setString(7, c.getTipoContrato());

            ps.executeUpdate();
            System.out.println("Contrato insertado: " + c.getNif());

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    
    public boolean existeContrato(String nif) {
        boolean existe = false;
        String sql = "SELECT COUNT(*) FROM contrato WHERE nif = ?";
        
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, nif);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                existe = rs.getInt(1) > 0;
            }
            rs.close();
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return existe;
    }
    
    public java.util.List<Contrato> obtenerTodos() {
        java.util.List<Contrato> lista = new java.util.ArrayList<>();
        String sql = "SELECT * FROM contrato";

        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {

            while (rs.next()) {
                Contrato c = new Contrato(
                        rs.getString("nif"),
                        rs.getString("adjudicatario"),
                        rs.getString("objeto_generico"),
                        rs.getString("objeto"),
                        rs.getString("fecha_adjudicacion"),
                        rs.getDouble("importe"),
                        rs.getString("tipo_contrato")
                );
                lista.add(c);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return lista;
    }
}


