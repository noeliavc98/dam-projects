package src;


import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.util.Scanner;

public class WordleFileManager {
	
	public static String[] loadWordsFromFile(String filename) {
	    try {
	    	InputStream inputStream = WordleFileManager.class.getClassLoader().getResourceAsStream(filename);

	        if (inputStream == null) {
	            throw new FileNotFoundException("File not found: " + filename);
	        }

	        Scanner sc = new Scanner(inputStream);
	        
	        // Contamos el número de líneas para inicializar el array filewords
	        int wordCount = 0;
	        while (sc.hasNextLine()) {
	            sc.nextLine();
	            wordCount++;
	        }

	        // Reiniciamos el Scanner para leer las palabras porque Scanner no tiene un metodo para volver a inicio de flujo de entrada e InputStream tampoco
	        inputStream = WordleGame.class.getClassLoader().getResourceAsStream(filename);
	        sc = new Scanner(inputStream);

	        String[] fileWords = new String[wordCount];
	        int i = 0;
	        while (sc.hasNextLine()) {
	            fileWords[i] = sc.nextLine();
	            i++;
	        }

	        sc.close();
	        return fileWords;
	    } catch (IOException e) {
	        System.out.println("An error occurred.");
	        e.printStackTrace();
	    }
	    return null;
	}
	 // Método para almacenar una partida en un fichero de historial
    public static void saveGameHistory(String[] triesHistory, String secretWord, String result) {
        String fileName = "resources/game_history.txt"; // Ruta del archivo donde se guardarán las partidas
        
        try (FileWriter fileWriter = new FileWriter(fileName, true); // Modo 'append' para no sobrescribir
             PrintWriter printWriter = new PrintWriter(fileWriter)) {
            
            printWriter.println("===== Nueva Partida =====");
            printWriter.println("Palabra secreta: " + secretWord);
            printWriter.println("Resultado de la Partida: " + result);
            printWriter.println("Intentos realizados:");
            
            for (String attempt : triesHistory) {
                if (attempt != null) {
                    printWriter.println(attempt);
                }
            }
            
            printWriter.println("=========================\n");
            System.out.println("Partida guardada en " + fileName);
            
        } catch (IOException e) {
            System.out.println("Error al guardar la partida.");
            e.printStackTrace();
        }
    }
}
