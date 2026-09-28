package src;

import java.util.Date;
import java.text.SimpleDateFormat;
import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import com.toedter.calendar.JDateChooser;
import dao.AlquilerDAO;
import modelo.Alquiler;
import java.awt.*;
import java.util.List;


public class Principal extends JFrame {

	private static final long serialVersionUID = 1L;
	private JTable tabla;
    private DefaultTableModel modelo;
    private JDateChooser fechaInicio;
    private JDateChooser fechaFin;
    private JButton btnBuscar;
    
    public Principal(String usuario) {
    	
        setTitle("SmartOcupation - " + usuario);
        setSize(900, 400);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        inicializarTabla();    //metodo para crear la tabla de alquileres
        inicializarFiltro();  //metodo para crear el filtro por fechas 
        cargarAlquileres();	  //metodo donde se cargan los datos de los alquileres
        estilizarTabla();	  //metodo para estilizar la tabla 
        
        setVisible(true);
    }
   
    private void inicializarTabla() {
    	
    	String[] columnas = {			//nombres de las columnas
                "Numero de Expediente",
                "Cliente",
                "Cod. Ref. Vivienda",
                "Fecha de entrada",
                "Tiempo estimado (meses)",
                "Precio mensual",
                "Estado"
            };
    	
    	modelo = new DefaultTableModel(columnas, 0) {		
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;		//los datos de la tabla no se pueden editar
            }
        };
        
        tabla = new JTable(modelo);    //creamos la tabla 
        add(new JScrollPane(tabla), BorderLayout.CENTER);
       }
    
    private void inicializarFiltro() {
        JPanel panelFiltro = new JPanel(new FlowLayout(FlowLayout.LEFT));

        fechaInicio = new JDateChooser();
        fechaInicio.setDateFormatString("dd/MM/yyyy");  //filtro fecha de inicio

        fechaFin = new JDateChooser();
        fechaFin.setDateFormatString("dd/MM/yyyy");   //filtro fecha de fin

        btnBuscar = new JButton("Buscar");    //boton buscar

        panelFiltro.add(new JLabel("Fecha inicio:"));
        panelFiltro.add(fechaInicio);
        panelFiltro.add(new JLabel("Fecha fin:"));  //anadimos nombre del filtro y la eleccion de fecha
        panelFiltro.add(fechaFin);
        panelFiltro.add(btnBuscar);

        btnBuscar.addActionListener(e -> filtrarPorFecha());   //si pulsamos el boton buscar se filtran las fechas
        
        add(panelFiltro, BorderLayout.NORTH);    //el filtro se coloca al norte de la ventana 
    }
    
    private void estilizarTabla() {

    	DefaultTableCellRenderer combinadoRenderer = new DefaultTableCellRenderer() {
            private final SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");  //formato para fecha

            @Override
            public Component getTableCellRendererComponent(
                    JTable table, Object value, boolean isSelected,
                    boolean hasFocus, int row, int column) {

                Component c = super.getTableCellRendererComponent(
                        table, value, isSelected, hasFocus, row, column);
                
                // Colorear fila según estado (columna 6)
                if (!isSelected) {
                    Object estadoObj = table.getValueAt(row, 6);
                    if (estadoObj != null) {
                        String estado = estadoObj.toString().toLowerCase();
                        switch (estado) {
                            case "pagado":
                                c.setBackground(new Color(198, 239, 206));
                                c.setForeground(new Color(0, 97, 0));
                                break;
                            case "pendiente":
                                c.setBackground(new Color(255, 199, 206));
                                c.setForeground(new Color(156, 0, 6));
                                break;
                            default:
                                c.setBackground(row % 2 == 0 ? Color.WHITE : new Color(245, 245, 245));
                                c.setForeground(Color.BLACK);
                        }
                    }
             }
                // Formatear columnas
                if (column == 3 && value instanceof Date) { // fecha
                    setText(sdf.format(value));
                    setHorizontalAlignment(SwingConstants.CENTER);
                } else if (column == 5 && value instanceof Number) { // precio
                    setText(value.toString() + " €");
                    setHorizontalAlignment(SwingConstants.CENTER);
                } else if (column == 4 || column == 6) { // meses y estado
                    setHorizontalAlignment(SwingConstants.CENTER);
                } else { // resto
                    setHorizontalAlignment(SwingConstants.CENTER);
                }

                return c;
            }
        };
        
	        for (int i = 0; i < tabla.getColumnCount(); i++) {
	            tabla.getColumnModel().getColumn(i).setCellRenderer(combinadoRenderer);
	        }
	
	        tabla.getTableHeader().setFont(new Font("Tahoma", Font.BOLD, 13));
	        tabla.setRowHeight(24);
	        tabla.setShowGrid(false);
	        tabla.setIntercellSpacing(new Dimension(0, 0));
	    	}

    private void cargarAlquileres() {
        cargarAlquileres(null, null); // carga todos los alquileres si fechas null
    }
    
    private void filtrarPorFecha() {
        Date inicio = fechaInicio.getDate();   //obtiene las fechas que ha seleccionado el usuario
        Date fin = fechaFin.getDate();

        if (inicio == null || fin == null) {
            JOptionPane.showMessageDialog(this,
                    "Selecciona ambas fechas",
                    "Aviso", JOptionPane.WARNING_MESSAGE);  //si no se selecciona nada, aparece mensaje 
            return;
        }
        
        if (fin.before(inicio)) {
            JOptionPane.showMessageDialog(this,
                    "La fecha de fin no puede ser anterior a la fecha de inicio.",
                    "Error de fechas",
                    JOptionPane.ERROR_MESSAGE);    //si las fechas no concuerdan, aparece mensaje de error
            return;
        }

        cargarAlquileres(inicio, fin);   //se cargan los alquileres segun la seleccion de usuario
    }
    
    private void cargarAlquileres(Date inicio, Date fin) {
    	
    	modelo.setRowCount(0); // limpiar tabla
    	
    	AlquilerDAO dao = new AlquilerDAO();      
        List<Alquiler> alquileres = dao.buscarPorFechas(inicio, fin);

        for (Alquiler a : alquileres) {         //se obtienen los datos de la clase AlquilerDAO
            modelo.addRow(new Object[]{			//segun el filtro
                    a.getExpediente(),
                    a.getCliente(),
                    a.getVivienda(),
                    a.getFechaEntrada(),
                    a.getTiempoEstimado(),
                    a.getPrecio(),
                    a.getEstado()
            });
        }
    }
  
    	}
    
    	
    	
    

