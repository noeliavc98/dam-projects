import 'components/datos_nivel07.dart';
import 'components/resultado_nivel07.dart';

class Nivel07Game {
  int vidas = DatosNivel07.vidasIniciales;
  int xp = 0;
  final List<String> guesses = [];

  int get intentos => guesses.length;

  List<String> get pistasVisibles {
    final unlocked = intentos ~/ 2;
    final count = unlocked.clamp(0, DatosNivel07.pistasDesbloqueables.length);
    return DatosNivel07.pistasDesbloqueables.take(count).toList();
  }

  int get posicionesCorrectas {
    if (guesses.isEmpty) return 0;
    final last = guesses.last.padRight(DatosNivel07.password.length);
    int correct = 0;
    for (int i = 0; i < DatosNivel07.password.length; i++) {
      if (last[i] == DatosNivel07.password[i]) correct++;
    }
    return correct;
  }

  String get mejorPatron {
    if (guesses.isEmpty) return '?????????';
    final chars = List<String>.filled(DatosNivel07.password.length, '?');
    for (final guess in guesses) {
      final normalized = guess.padRight(DatosNivel07.password.length);
      for (int i = 0; i < DatosNivel07.password.length; i++) {
        if (normalized[i] == DatosNivel07.password[i]) {
          chars[i] = DatosNivel07.password[i];
        }
      }
    }
    return chars.join();
  }

  List<String> get dialogosIntro => DatosNivel07.dialogosIntro;
  List<String> get dialogosFinales => DatosNivel07.dialogosFinales;

  String _buildFeedback(String guess) {
    int green = 0;
    int present = 0;
    for (int i = 0; i < DatosNivel07.password.length; i++) {
      if (guess[i] == DatosNivel07.password[i]) {
        green++;
      } else if (DatosNivel07.password.contains(guess[i])) {
        present++;
      }
    }
    if (green == 0 && present == 0) {
      return 'Ningún carácter coincide. Descarta ese camino.';
    }
    if (green > 0) {
      return '$green caracteres están en la posición exacta. Conserva esas posiciones y sigue probando.';
    }
    return '$present caracteres existen, pero no están en la posición correcta.';
  }

  ResultadoNivel07 submitGuess(String texto) {
    final guess = texto.trim().toLowerCase();

    guesses.add(guess);

    if (guess == DatosNivel07.password) {
      xp += DatosNivel07.puntosNivel;
      return ResultadoNivel07(
        correcto: true,
        pierdeVida: false,
        gameOver: false,
        vidas: vidas,
        xp: xp,
        intentos: intentos,
        feedback: 'Clave encontrada. El terminal ha aceptado el candidato.',
        pistaDesbloqueada: false,
      );
    }

    bool pierdeVida = false;
    if (intentos % DatosNivel07.intentosPorVida == 0) {
      vidas = (vidas - 1).clamp(0, DatosNivel07.vidasIniciales);
      pierdeVida = true;
    }

    final pistaDesbloqueada = intentos % 2 == 0;
    final baseFeedback = _buildFeedback(guess);
    final feedback = pistaDesbloqueada
        ? '$baseFeedback Nueva pista desbloqueada.'
        : baseFeedback;

    return ResultadoNivel07(
      correcto: false,
      pierdeVida: pierdeVida,
      gameOver: vidas <= 0,
      vidas: vidas,
      xp: xp,
      intentos: intentos,
      feedback: feedback,
      pistaDesbloqueada: pistaDesbloqueada,
    );
  }

  void reiniciar() {
    guesses.clear();
    vidas = DatosNivel07.vidasIniciales;
    xp = 0;
  }
}
