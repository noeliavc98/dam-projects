package src;


import java.awt.*;
import java.io.BufferedReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HexFormat;
import java.security.MessageDigest;
import javax.swing.*;
import java.awt.event.ActionEvent;

public class Inicio extends JFrame {

	private static final long serialVersionUID = 1L;
	private JTextField txtUsuario;
	private JPasswordField txtPass;
	private static final boolean USAR_HASH = false;
	private static final Path RUTA_USUARIOS =              
            Paths.get(System.getProperty("user.dir"),      
                      "data",                              
                      "usuarios.txt");                     
	
	public Inicio() {
		setTitle("Identificar Empleado/a");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setSize(400, 250);
        setLocationRelativeTo(null);
        
        JPanel contentPane = new JPanel();
        contentPane.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));
        contentPane.setLayout(new BoxLayout(contentPane, BoxLayout.Y_AXIS));
        setContentPane(contentPane); 
		
        JLabel lblUsuario = new JLabel("Empleado/a:");
        lblUsuario.setAlignmentX(Component.CENTER_ALIGNMENT);
        lblUsuario.setFont(new Font("Tahoma", Font.PLAIN, 16));
        contentPane.add(lblUsuario);
		
        txtUsuario = new JTextField(20);
        txtUsuario.setMaximumSize(new Dimension(Integer.MAX_VALUE, txtUsuario.getPreferredSize().height));
        contentPane.add(txtUsuario);
        contentPane.add(Box.createRigidArea(new Dimension(0, 10)));
		
        JLabel lblPass = new JLabel("Contraseña:");
        lblPass.setAlignmentX(Component.CENTER_ALIGNMENT);
        lblPass.setFont(new Font("Tahoma", Font.PLAIN, 16));
        contentPane.add(lblPass);
		
        txtPass = new JPasswordField(20);
        txtPass.setMaximumSize(new Dimension(Integer.MAX_VALUE, txtPass.getPreferredSize().height));
        contentPane.add(txtPass);
        contentPane.add(Box.createRigidArea(new Dimension(0, 20)));
        
        JPanel panelBotones = new JPanel();
        panelBotones.setLayout(new FlowLayout(FlowLayout.CENTER, 15, 0));
		
		JButton btnEntrar = new JButton("Entrar");
		JButton btnCancelar = new JButton("Cancelar");
		
		panelBotones.add(btnEntrar);
        panelBotones.add(btnCancelar);
        contentPane.add(panelBotones);
		
        btnEntrar.addActionListener(e -> onEntrar(e));
        btnCancelar.addActionListener(e -> System.exit(0));

        getRootPane().setDefaultButton(btnEntrar);

	}
	
	 private void onEntrar(ActionEvent e) {
		 String user = txtUsuario.getText().trim();
		 char[] pass = txtPass.getPassword();
		 boolean ok = USAR_HASH                              // Escoge método de validación según configuración
	                ? validarConFicheroHash(user, pass)         // Validación con hashes
	                : validarConFicheroPlano(user, pass);       // Validación con contraseña en claro

	        Arrays.fill(pass, '\0');                            // Limpia la copia local de la contraseña

	        if (ok) {                                           // Si credenciales válidas...
	            SwingUtilities.invokeLater(                     // Asegura ejecutar en el hilo de eventos de Swing
	                    () -> new Principal(user).setVisible(true) // Crea y muestra la ventana principal
	            );
	            dispose();                                      // Cierra la ventana de login
	        } else {                                            // Si no coincide...
	            JOptionPane.showMessageDialog(                  // Muestra un diálogo de error
	                    this,
	                    "Usuario o contraseña incorrectos",
	                    "Acceso denegado",
	                    JOptionPane.ERROR_MESSAGE
	            );
	            txtPass.setText("");                            // Vacía el campo de contraseña
	            txtPass.requestFocusInWindow();                 // Devuelve el foco a la contraseña
	        }
	 }
	
	 private boolean validarConFicheroPlano(String usuario, char[] passIngresada) {
	        if (!Files.exists(RUTA_USUARIOS)) {                 // Comprueba que el fichero exista
	            error("No existe " + RUTA_USUARIOS.toAbsolutePath()); // Mensaje claro si no existe
	            return false;                                   // Sin fichero no se puede validar
	        }

	        try (BufferedReader br = Files.newBufferedReader(   // Abre el fichero en UTF-8
	                RUTA_USUARIOS, StandardCharsets.UTF_8)) {

	            String linea;                                   // Línea actual leída
	            while ((linea = br.readLine()) != null) {       // Lee hasta EOF
	                linea = linea.trim();                       // Quita espacios extremos
	                if (linea.isEmpty() || linea.startsWith("#")) continue; // Salta comentarios/vacías

	                String[] partes = linea.split(";", 2);      // Divide por el primer ';' (máx 2 partes)
	                if (partes.length != 2) continue;           // Si el formato no es correcto, ignora

	                String u  = partes[0].trim();               // Usuario del fichero
	                String pw = partes[1];                      // Contraseña en claro del fichero

	                if (u.equals(usuario)                       // Compara usuario exacto...
	                        && pw.contentEquals(new String(passIngresada))) { // ...y contraseña igual
	                    return true;                            // Coincidencia encontrada → válido
	                }
	            }
	        } catch (IOException ex) {                          // Cualquier error de E/S
	            error("No puedo leer " + RUTA_USUARIOS + "\n" + ex.getMessage());
	        }
	        return false;                                       // Si no se encontró coincidencia → inválido
	    }
	 
	 
	 private boolean validarConFicheroHash(String usuario, char[] passIngresada) {
	        if (!Files.exists(RUTA_USUARIOS)) {                 // Verifica existencia del fichero
	            error("No existe " + RUTA_USUARIOS.toAbsolutePath());
	            return false;
	        }

	        String hashIngresado = sha256(new String(passIngresada)); // Calcula hash de lo que tecleó el usuario

	        try (BufferedReader br = Files.newBufferedReader(   // Abre el fichero en UTF-8
	                RUTA_USUARIOS, StandardCharsets.UTF_8)) {

	            String linea;                                   // Línea actual
	            while ((linea = br.readLine()) != null) {       // Itera por todas las líneas
	                linea = linea.trim();                       // Quita espacios
	                if (linea.isEmpty() || linea.startsWith("#")) continue; // Ignora comentarios

	                String[] partes = linea.split(";", 2);      // usuario;hash
	                if (partes.length != 2) continue;           // Formato incorrecto → ignora

	                String u = partes[0].trim();                // Usuario del fichero
	                String hashGuardado = partes[1].trim();     // Hash guardado (hexadecimal)

	                if (u.equals(usuario)                       // Usuario coincide
	                        && hashIngresado.equalsIgnoreCase(hashGuardado)) { // Hash coincide
	                    return true;                            // Credenciales válidas
	                }
	            }
	        } catch (IOException ex) {                          // Error leyendo el fichero
	            error("No puedo leer " + RUTA_USUARIOS + "\n" + ex.getMessage());
	        }
	        return false;                                       // No se encontró usuario/hash válido
	    }
	 
	 private void error(String msg) {
	        JOptionPane.showMessageDialog(this, msg, "Error", JOptionPane.ERROR_MESSAGE);
	    }
	 
	 private static String sha256(String texto) {
	        try {
	            MessageDigest md = MessageDigest.getInstance("SHA-256"); // Instancia del algoritmo
	            byte[] out = md.digest(texto.getBytes(StandardCharsets.UTF_8)); // Hash de los bytes UTF-8
	            return HexFormat.of().formatHex(out);                     // Convierte bytes → cadena hex
	        } catch (Exception e) {
	            throw new RuntimeException("No se pudo calcular SHA-256", e); // Propaga como unchecked
	        }
	    }

	 public static void main(String[] args) {
	        SwingUtilities.invokeLater(() -> {                  // Ejecuta UI en el EDT
	            try { UIManager.setLookAndFeel(                 // (Opcional) Look&Feel nativo
	                    UIManager.getSystemLookAndFeelClassName()); }
	            catch (Exception ignored) {}
	            new Inicio().setVisible(true);               // Crea y muestra el login
	        });
	    }


}
