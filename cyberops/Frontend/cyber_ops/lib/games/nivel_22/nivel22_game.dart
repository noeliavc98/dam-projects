import 'components/spoofing_packet.dart';
import 'data/spoofing_data.dart';

enum Nivel22Phase {
  intro,
  tutorial,
  pruebasSms,
  entreCreacion,
  pruebasEmail,
  entrePartes,
  deteccion,
  completado,
  fallado,
}

class Nivel22Game {
  static const int xpPorAcierto      = 120;
  static const int xpPorError        = -60;
  static const int segundosDeteccion = 12;
  static const int vidasIniciales    = 3;

  Nivel22Phase fase = Nivel22Phase.intro;
  int vidas    = vidasIniciales;
  int xp       = 0;
  int aciertos = 0;
  int errores  = 0;

  // ── Estado prueba SMS ──────────────────────────────────────────────────────
  int smsScenarioIdx        = 0;
  int smsPaso               = 0; // 0=emisor, 1=mensaje, 2=nombre
  String? smsEmisorElegido;
  String? smsMensajeElegido;

  // ── Estado prueba Email ────────────────────────────────────────────────────
  int emailScenarioIdx      = 0;
  int emailPaso             = 0; // 0=from, 1=mensaje, 2=nombre
  String? emailFromElegido;
  String? emailMensajeElegido;

  // ── Estado detección ───────────────────────────────────────────────────────
  int deteccionIdx          = 0;

  // ── Feedback de última acción ──────────────────────────────────────────────
  bool?  ultimaAccionCorrecta;
  String ultimaExplicacion    = '';
  String ultimaPistaRelevante = '';

  // ── Accesores ──────────────────────────────────────────────────────────────

  SmsPrueba? get smsActual {
    if (smsScenarioIdx < SpoofingData.pruebasSms.length) {
      return SpoofingData.pruebasSms[smsScenarioIdx];
    }
    return null;
  }

  EmailPrueba? get emailActual {
    if (emailScenarioIdx < SpoofingData.pruebasEmail.length) {
      return SpoofingData.pruebasEmail[emailScenarioIdx];
    }
    return null;
  }

  DeteccionItem? get deteccionActual {
    if (deteccionIdx < SpoofingData.itemsDeteccion.length) {
      return SpoofingData.itemsDeteccion[deteccionIdx];
    }
    return null;
  }

  // ── Control de fases ───────────────────────────────────────────────────────

  void iniciarSms() {
    fase              = Nivel22Phase.pruebasSms;
    smsScenarioIdx    = 0;
    smsPaso           = 0;
    smsEmisorElegido  = null;
    smsMensajeElegido = null;
    ultimaAccionCorrecta = null;
  }

  void iniciarEmail() {
    fase                  = Nivel22Phase.pruebasEmail;
    emailScenarioIdx      = 0;
    emailPaso             = 0;
    emailFromElegido      = null;
    emailMensajeElegido   = null;
    ultimaAccionCorrecta  = null;
  }

  void iniciarDeteccion() {
    fase                 = Nivel22Phase.deteccion;
    deteccionIdx         = 0;
    ultimaAccionCorrecta = null;
  }

  // ── Respuestas SMS ─────────────────────────────────────────────────────────

  bool responderSmsEmisor(int idx) {
    final prueba = smsActual;
    if (prueba == null) return false;
    ultimaPistaRelevante = prueba.pistas.isNotEmpty ? prueba.pistas[0] : '';
    final correcto = idx == prueba.idxEmisorCorrecto;
    smsEmisorElegido = prueba.opcionesEmisor[idx];
    _registrar(correcto, prueba.explicacion);
    smsPaso = 1;
    return correcto;
  }

  bool responderSmsMensaje(int idx) {
    final prueba = smsActual;
    if (prueba == null) return false;
    ultimaPistaRelevante = prueba.pistas.length > 1 ? prueba.pistas[1] : '';
    final correcto = idx == prueba.idxMensajeCorrecto;
    smsMensajeElegido = prueba.opcionesMensaje[idx];
    _registrar(correcto, prueba.explicacion);
    smsPaso = 2;
    return correcto;
  }

  bool responderSmsNombre(int idx) {
    final prueba = smsActual;
    if (prueba == null) return false;
    ultimaPistaRelevante = prueba.pistas.isNotEmpty ? prueba.pistas.last : '';
    final correcto = idx == prueba.idxNombreCorrecto;
    _registrar(correcto, prueba.explicacion);
    smsPaso           = 0;
    smsEmisorElegido  = null;
    smsMensajeElegido = null;
    smsScenarioIdx++;
    _finSms();
    return correcto;
  }

  void _finSms() {
    if (vidas <= 0) {
      fase = Nivel22Phase.fallado;
    } else if (smsScenarioIdx >= SpoofingData.pruebasSms.length) {
      fase = Nivel22Phase.entreCreacion;
    }
  }

  // ── Respuestas Email ───────────────────────────────────────────────────────

  bool responderEmailFrom(int idx) {
    final prueba = emailActual;
    if (prueba == null) return false;
    ultimaPistaRelevante = prueba.pistas.isNotEmpty ? prueba.pistas[0] : '';
    final correcto = idx == prueba.idxFromCorrecto;
    emailFromElegido = prueba.opcionesFrom[idx];
    _registrar(correcto, prueba.explicacion);
    emailPaso = 1;
    return correcto;
  }

  bool responderEmailMensaje(int idx) {
    final prueba = emailActual;
    if (prueba == null) return false;
    ultimaPistaRelevante = prueba.pistas.length > 1 ? prueba.pistas[1] : '';
    final correcto = idx == prueba.idxMensajeCorrecto;
    emailMensajeElegido = prueba.opcionesMensaje[idx];
    _registrar(correcto, prueba.explicacion);
    emailPaso = 2;
    return correcto;
  }

  bool responderEmailNombre(int idx) {
    final prueba = emailActual;
    if (prueba == null) return false;
    ultimaPistaRelevante = prueba.pistas.isNotEmpty ? prueba.pistas.last : '';
    final correcto = idx == prueba.idxNombreCorrecto;
    _registrar(correcto, prueba.explicacion);
    emailPaso           = 0;
    emailFromElegido    = null;
    emailMensajeElegido = null;
    emailScenarioIdx++;
    _finEmail();
    return correcto;
  }

  void _finEmail() {
    if (vidas <= 0) {
      fase = Nivel22Phase.fallado;
    } else if (emailScenarioIdx >= SpoofingData.pruebasEmail.length) {
      fase = Nivel22Phase.entrePartes;
    }
  }

  // ── Respuesta Detección ────────────────────────────────────────────────────

  bool responderDeteccion(bool esReal) {
    final item = deteccionActual;
    if (item == null) return false;
    final correcto = esReal == item.esReal;
    _registrar(correcto, item.explicacion);
    deteccionIdx++;
    _finDeteccion();
    return correcto;
  }

  void deteccionExpirada() {
    final item = deteccionActual;
    if (item == null) return;
    ultimaAccionCorrecta = false;
    ultimaExplicacion    = 'Tiempo agotado. ${item.explicacion}';
    errores++;
    vidas--;
    deteccionIdx++;
    _finDeteccion();
  }

  void _finDeteccion() {
    if (vidas <= 0) {
      fase = Nivel22Phase.fallado;
    } else if (deteccionIdx >= SpoofingData.itemsDeteccion.length) {
      fase = Nivel22Phase.completado;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _registrar(bool correcto, String explicacion) {
    ultimaAccionCorrecta = correcto;
    ultimaExplicacion    = explicacion;
    if (correcto) {
      xp += xpPorAcierto;
      aciertos++;
    } else {
      xp = (xp + xpPorError).clamp(0, 99999);
      errores++;
      vidas--;
      if (vidas <= 0) fase = Nivel22Phase.fallado;
    }
  }

  // ── Estadísticas ───────────────────────────────────────────────────────────

  int get totalAcciones =>
      SpoofingData.pruebasSms.length * 3 +
      SpoofingData.pruebasEmail.length * 3 +
      SpoofingData.itemsDeteccion.length;

  double get precision => totalAcciones > 0 ? aciertos / totalAcciones : 0;

  String get nivelRendimiento {
    if (precision >= 0.9) return 'EXPERTO EN SPOOFING';
    if (precision >= 0.75) return 'ANALISTA AVANZADO';
    if (precision >= 0.5) return 'AGENTE EN FORMACIÓN';
    return 'NECESITA REFUERZO';
  }
}
