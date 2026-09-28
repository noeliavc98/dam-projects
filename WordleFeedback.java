package src;

public class WordleFeedback {
	public static final int WORD_LENGTH = 5;     // Longitud de la palabra 
	public static final String ANSI_RESET = "\u001B[0m";
	public static final String ANSI_BLACK = "\u001B[30m";
	public static final String ANSI_RED = "\u001B[31m";
	public static final String ANSI_GREEN = "\u001B[32m";
	public static final String ANSI_YELLOW = "\u001B[33m";
	public static final String ANSI_BLUE = "\u001B[34m";
	public static final String ANSI_PURPLE = "\u001B[35m";
	public static final String ANSI_CYAN = "\u001B[36m";
	public static final String ANSI_WHITE = "\u001B[37m";
	
	// Método auxiliar para aplicar color
	public static String applyColor(String letter, String color) {
		return color + letter + ANSI_RESET; // Aplica el color y lo restablece
	}
	public static String feedBackString(String guess, String secretWord) {
	    
		// Inicializamos el String Builder
		StringBuilder feedback = new StringBuilder();
	    
		// Convertimos las dos palabras a mayúsculas para que ignore si una está en mayusculas y la otra en minusculas.
		String guessUpperCase = guess.toUpperCase();
		String secretWordUpperCase = secretWord.toUpperCase();
		
	    for (int i = 0; i < WordleFeedback.WORD_LENGTH; i++) {
	        char guessedLetter = guessUpperCase.charAt(i);
	        
	        if (guessedLetter == secretWordUpperCase.charAt(i)) {
	            // (VERDE) Letra en la posición correcta 
	            feedback.append(applyColor(String.valueOf(guessedLetter), WordleFeedback.ANSI_GREEN));
	        } else if (secretWordUpperCase.contains(String.valueOf(guessedLetter))) {
	            //  (AMARILLO) Letra en la palabra, pero en la posición incorrecta (amarillo)
	            feedback.append(applyColor(String.valueOf(guessedLetter), WordleFeedback.ANSI_YELLOW));
	        } else {
	            // (GRIS) Letra no está en la palabra 
	            feedback.append(applyColor(String.valueOf(guessedLetter), WordleFeedback.ANSI_WHITE));
	        }
	    }
	    
	    return feedback.toString(); // Devuelve la palabra en color
	}

	

	
}
