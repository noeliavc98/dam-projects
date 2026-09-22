import 'components/sospechoso_nivel15.dart';
import 'components/pregunta_nivel15.dart';
import 'components/datos_nivel15.dart';

class Nivel15Game {
  int vidas = 3;
  int xp = 0;
  int labActual = 0;
  List<bool> preguntasUsadas = [false, false, false, false];

  Sospechoso get sospechoso => sospechososNivel15[labActual];
  List<Pregunta> get preguntas => sospechoso.preguntas;

  double get sinconia {
    int usadas = preguntasUsadas.where((u) => u).length;
    return (labActual * 4 + usadas) / 12.0;
  }

  int get preguntasHechas => preguntasUsadas.where((u) => u).length;
  int get maxPreguntasLab => [3, 2, 1][labActual];
  bool get puedeHacerMasPreguntas => preguntasHechas < maxPreguntasLab;

  Pregunta hacerPregunta(int i) {
    preguntasUsadas[i] = true;
    xp += 25;
    return preguntas[i];
  }

  Map<String, dynamic> darVeredicto(bool acusaRootkit) {
    bool correcto = acusaRootkit == sospechoso.esRootkit;
    int xpGanado = 0;
    if (correcto) {
      int preguntasHechas = preguntasUsadas.where((u) => u).length;
      xpGanado = 50 + (preguntasHechas * 25);
      xp += xpGanado;
    } else {
      vidas--;
    }
    return {'correcto': correcto, 'xp': xpGanado};
  }

  void siguienteLab() {
    if (labActual < 2) {
      labActual++;
      preguntasUsadas = [false, false, false, false];
    }
  }

  void reset() {
    vidas = 3;
    xp = 0;
    labActual = 0;
    preguntasUsadas = [false, false, false, false];
  }
}
