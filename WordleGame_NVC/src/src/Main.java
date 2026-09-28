package src;

public class Main {
	
	
	public static void main(String[] args) {
		
		// 1 - Leemos las palabras del fichero
		String[] words = WordleFileManager.loadWordsFromFile("words.txt");
		
		// 2 -  Creamos el objeto WordleGame con las palabras del fichero
		WordleGame myGame = new WordleGame(words);
		
			
		// 3 - Se inicializa el juego
		myGame.start();
		

	}

}
