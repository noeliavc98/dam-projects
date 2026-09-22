import 'components/ddos_packet.dart';
import 'data/ddos_data.dart';

enum Nivel23Phase { intro, ronda1, ronda2, ronda3, completado, fallado }

class Nivel23Game {
  static const int xpPorAcierto = 140;
  static const int xpPorError = -70;
  static const int vidasIniciales = 3;
  static const int segundosRonda = 18;

  Nivel23Phase fase = Nivel23Phase.intro;
  int vidas = vidasIniciales;
  int xp = 0;
  int escenarioIndex = 0;
  int aciertos = 0;
  int aciertosLab = 0;
  int preguntasLab = 0;
  int errores = 0;

  String ultimaExplicacion = '';
  bool? ultimaCorrecta;

  DdosScenario? get escenarioActual {
    if (fase == Nivel23Phase.ronda1) {
      return escenarioIndex < DdosData.ronda1.length
          ? DdosData.ronda1[escenarioIndex]
          : null;
    }
    if (fase == Nivel23Phase.ronda2) {
      return escenarioIndex < DdosData.ronda2.length
          ? DdosData.ronda2[escenarioIndex]
          : null;
    }
    return null;
  }

  DdosMitigationScenario? get mitigacionActual {
    if (fase != Nivel23Phase.ronda3) return null;
    return escenarioIndex < DdosData.ronda3.length
        ? DdosData.ronda3[escenarioIndex]
        : null;
  }

  void iniciarRonda1() {
    fase = Nivel23Phase.ronda1;
    escenarioIndex = 0;
  }

  void iniciarRonda2() {
    fase = Nivel23Phase.ronda2;
    escenarioIndex = 0;
  }

  void iniciarRonda3() {
    fase = Nivel23Phase.ronda3;
    escenarioIndex = 0;

    // opciones ya cargadas
  }

  bool responderTipo(DdosType tipo) {
    final escenario = escenarioActual;
    if (escenario == null) return false;

    final correcto = tipo == escenario.tipoCorrecto;
    _registrar(correcto, escenario.explicacion);
    escenarioIndex++;
    _comprobarFin();
    return correcto;
  }

  bool responderMitigacion(String opcion) {
    final escenario = mitigacionActual;
    if (escenario == null) return false;

    final correcto = opcion == escenario.opcionCorrecta;
    _registrar(correcto, escenario.explicacion);
    escenarioIndex++;
    _comprobarFin();

    return correcto;
  }

  void tiempoAgotado() {
    ultimaCorrecta = false;
    ultimaExplicacion =
        'Tiempo agotado. En un ataque DDoS cada segundo cuenta.';
    errores++;
    vidas--;
    escenarioIndex++;
    _comprobarFin();
  }

  void _registrar(bool correcto, String explicacion) {
    ultimaCorrecta = correcto;
    ultimaExplicacion = explicacion;

    preguntasLab++;

    if (correcto) {
      xp += xpPorAcierto;
      aciertos++;
      aciertosLab++;
    } else {
      xp = (xp + xpPorError).clamp(0, 99999);
      errores++;
      vidas--;
    }
  }

  void _comprobarFin() {
    if (vidas <= 0) {
      fase = Nivel23Phase.fallado;
      return;
    }

    if (fase == Nivel23Phase.ronda3 && preguntasLab >= 3) {
      fase = Nivel23Phase.completado;
    }
  }

  bool get labActualTerminado =>
      (fase == Nivel23Phase.ronda1 || fase == Nivel23Phase.ronda2) &&
      preguntasLab >= 3;

  void siguienteLab() {
    preguntasLab = 0;
    aciertosLab = 0;
    ultimaCorrecta = null;
    ultimaExplicacion = '';

    if (fase == Nivel23Phase.ronda1) {
      iniciarRonda2();
    } else if (fase == Nivel23Phase.ronda2) {
      iniciarRonda3();
    }
  }

  void reiniciar() {
    fase = Nivel23Phase.ronda1;
    vidas = vidasIniciales;
    xp = 0;
    escenarioIndex = 0;
    aciertos = 0;
    errores = 0;
    aciertosLab = 0;
    preguntasLab = 0;
    ultimaExplicacion = '';
    ultimaCorrecta = null;
  }
}
