import 'components/datos_nivel06.dart';
import 'components/elemento_nivel06.dart';
import 'components/resultado_password_nivel06.dart';

class Nivel06Game {
  int vidas = 3;
  int xp = 0;
  int intentosFallidos = 0;
  int fallosParaPerderVida = 0;

  final List<String> pistasDescubiertas = [];

  List<ElementoNivel06> get correos => DatosNivel06.correos;
  List<ElementoNivel06> get archivos => DatosNivel06.archivos;

  List<String> get dialogosIntro => DatosNivel06.dialogosIntro;
  List<String> get dialogosFinales => DatosNivel06.dialogosFinales;

  String? registrarPista(ElementoNivel06 elemento) {
    final pista = DatosNivel06.pistasPorTitulo[elemento.titulo];

    if (pista != null && !pistasDescubiertas.contains(pista)) {
      pistasDescubiertas.add(pista);
      return pista;
    }

    return null;
  }

  ResultadoPasswordNivel06 comprobarPassword(String texto) {
    final intento = texto.trim().toLowerCase();

    if (intento == DatosNivel06.passwordCorrecta) {
      xp += 250;

      return ResultadoPasswordNivel06(
        correcto: true,
        pierdeVida: false,
        gameOver: false,
        vidas: vidas,
        xp: xp,
        intentosFallidos: intentosFallidos,
      );
    }

    intentosFallidos++;
    fallosParaPerderVida++;

    bool pierdeVida = false;

    if (fallosParaPerderVida >= 3) {
      vidas--;
      fallosParaPerderVida = 0;
      pierdeVida = true;
    }

    return ResultadoPasswordNivel06(
      correcto: false,
      pierdeVida: pierdeVida,
      gameOver: vidas <= 0,
      vidas: vidas,
      xp: xp,
      intentosFallidos: intentosFallidos,
    );
  }
}