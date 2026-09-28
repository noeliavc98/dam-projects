package src;
import java.util.Random;
import java.util.Scanner;

public class WordleGame {
	
	// Constantes
    public static final int MAX_TRIES = 6;       // Número máximo de intentos
    public static final int WORD_LENGTH = 5;     // Longitud de la palabra 
    
    private  String[] fileWords;				// Palabras del fichero
    public String secretWord;                  // La palabra secreta que debe adivinar el jugador
    private int remainingAttempts;              // Intentos restantes del jugador
    private String[] triesHistory;              // Array para almacenar los intentos del jugador
    
    // Constructor de la clase
    public WordleGame(String[] fileWords) {
        this.fileWords = fileWords;
        this.remainingAttempts = MAX_TRIES;
        this.triesHistory = new String[MAX_TRIES]; // Array de tamaño máximo de intentos
        this.secretWord = selectRandomWord(fileWords);
    }
    
    public void start() {
    	
    	Scanner sc = new Scanner(System.in);
    	
    	while(remainingAttempts > 0 ) {
    		
    		String userInput = getUserInput(sc);
    		triesHistory[MAX_TRIES - remainingAttempts] = userInput; // almacenamos el userInput en el array de intentos
    		remainingAttempts --;
    		
    		if (userInput.equalsIgnoreCase(secretWord)) { // Palabra correcta
    			
    			System.out.println("¡Felicidades! Has adivinado la palabra correcta: " + secretWord);
    			WordleFileManager.saveGameHistory(triesHistory, secretWord, "VICTORIA"); // Guardamos la partida
    			System.exit(0);; // Sale del bucle inmediatamente; Ha terminado la partida
    			
    		}else { // Palabra incorrecta
    	
    			showTriesHistory();
    			
    		}
    	}
    	WordleFileManager.saveGameHistory(triesHistory, secretWord, "DERROTA"); // Guardamos la partida
    	System.exit(0);; // Sale del bucle inmediatamente; Ha terminado la partida
    }
    
    public void showTriesHistory() {
    	System.out.println("\nTienes " + remainingAttempts +" intentos restantes");
    	
    	// Recorremos el array de intentos
       	for(int i=0; i< triesHistory.length; i++) {
    		// Imprimimos intento si no está vacio
       		if (triesHistory[i] != null) {
       			System.out.println(WordleFeedback.feedBackString(triesHistory[i], this.secretWord));
       		}
    		
    	}
    }
    
    public String selectRandomWord(String[] words) {
    	Random random = new Random();
    	// Seleccionamos numero aleatorio 
    	int randomNumber = random.nextInt(words.length);
    	
    	// Elegimos palabra aleatoria utilizando el numero aleatorio
    	return words[randomNumber];
    }
    
    public String getUserInput(Scanner scanner) {
    	
    	boolean correctInput = false;
    	String userInput = "";
        while (correctInput == false) {
        	System.out.print("Introduce una palabra de 5 letras: ");
        	userInput = scanner.nextLine();
        	
        	if (userInput.length()==5) {
        		correctInput = true;
        		
        	}else {
        		System.out.println("La palabra debe tener 5 letras.");
        	}
        }
        return userInput;
    }
    


}
