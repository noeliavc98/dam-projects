import 'components/soc_alert.dart';
import 'data/soc_alert_data.dart';

enum Nivel19Phase { intro, tutorial, ronda1, entreRondas, ronda2, completado, fallado }

class Nivel19Game {
  // ── Configuración de tiempos ───────────────────────────────────────────────
  static const int segundosRonda1 = 14;
  static const int segundosRonda2 = 7;
  static const int xpPorAcierto = 120;
  static const int xpPorError = -60;
  static const int vidasIniciales = 3;

  // ── Estado ─────────────────────────────────────────────────────────────────
  Nivel19Phase fase = Nivel19Phase.intro;
  int vidas = vidasIniciales;
  int xp = 0;
  int alertaActualIndex = 0;
  int aciertos = 0;
  int errores = 0;
  int alertasExpiradas = 0;

  // Resultado de la última acción (para feedback visual)
  bool? ultimaAccionCorrecta;
  String ultimaExplicacion = '';
  AlertAccion? ultimaAccionEjecutada;

  List<SocAlert> get alertasActuales =>
      fase == Nivel19Phase.ronda1 || fase == Nivel19Phase.entreRondas
          ? SocAlertData.ronda1
          : SocAlertData.ronda2;

  SocAlert? get alertaActual {
    final lista = fase == Nivel19Phase.ronda2 ? SocAlertData.ronda2 : SocAlertData.ronda1;
    if (alertaActualIndex < lista.length) return lista[alertaActualIndex];
    return null;
  }

  int get segundosActuales =>
      fase == Nivel19Phase.ronda2 ? segundosRonda2 : segundosRonda1;

  bool get haTerminadoRonda1 =>
      alertaActualIndex >= SocAlertData.ronda1.length;

  bool get haTerminadoRonda2 =>
      alertaActualIndex >= SocAlertData.ronda2.length;

  // ── Acciones del jugador ───────────────────────────────────────────────────

  void iniciarRonda1() {
    fase = Nivel19Phase.ronda1;
    alertaActualIndex = 0;
    ultimaAccionCorrecta = null;
  }

  void iniciarRonda2() {
    fase = Nivel19Phase.ronda2;
    alertaActualIndex = 0;
    ultimaAccionCorrecta = null;
  }

  /// Devuelve true si la acción fue correcta.
  bool responder(AlertAccion accion) {
    final alerta = alertaActual;
    if (alerta == null) return false;

    final correcto = accion == alerta.accionCorrecta;
    ultimaAccionCorrecta = correcto;
    ultimaAccionEjecutada = accion;
    ultimaExplicacion = alerta.explicacion;

    if (correcto) {
      xp += xpPorAcierto;
      aciertos++;
    } else {
      xp = (xp + xpPorError).clamp(0, 99999);
      errores++;
      vidas--;
    }

    alertaActualIndex++;
    _comprobarFinDeRonda();
    return correcto;
  }

  void alertaExpirada() {
    final alerta = alertaActual;
    if (alerta == null) return;

    ultimaAccionCorrecta = false;
    ultimaAccionEjecutada = null;
    ultimaExplicacion =
        'Tiempo agotado. La amenaza avanzó sin respuesta.\n${alerta.explicacion}';
    xp = (xp - 80).clamp(0, 99999);
    alertasExpiradas++;
    vidas--;
    alertaActualIndex++;
    _comprobarFinDeRonda();
  }

  void _comprobarFinDeRonda() {
    if (vidas <= 0) {
      fase = Nivel19Phase.fallado;
      return;
    }
    if (fase == Nivel19Phase.ronda1 && haTerminadoRonda1) {
      fase = Nivel19Phase.entreRondas;
    } else if (fase == Nivel19Phase.ronda2 && haTerminadoRonda2) {
      fase = Nivel19Phase.completado;
    }
  }

  // ── Estadísticas ───────────────────────────────────────────────────────────
  int get totalAlertas =>
      SocAlertData.ronda1.length + SocAlertData.ronda2.length;

  double get precision =>
      totalAlertas > 0 ? aciertos / totalAlertas : 0;

  String get nivelRendimiento {
    if (precision >= 0.9) return 'ANALISTA ÉLITE';
    if (precision >= 0.75) return 'ANALISTA SENIOR';
    if (precision >= 0.5) return 'ANALISTA JUNIOR';
    return 'EN FORMACIÓN';
  }
}
