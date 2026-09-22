import 'package:cyber_ops/games/nivel_10/data/phishing_data.dart';
import 'package:cyber_ops/games/nivel_10/components/email_component.dart';
import 'package:cyber_ops/games/nivel_10/components/email_model.dart';
import 'package:cyber_ops/games/nivel_10/components/inspection_element.dart';
import 'package:cyber_ops/games/nivel_10/components/nivel10_state.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
 
class Nivel10Game extends FlameGame {
 
  // ── CALLBACKS HACIA FLUTTER ──────────────────────────────────────────────
  final void Function() onActoCambiado;
  final void Function(int puntos) onNivelCompletado;
  final void Function() onJuegoTerminado;
  final void Function(int puntos, int acto) onEstadoActualizado;
 
  // ── ESTADO GENERAL ───────────────────────────────────────────────────────
  LevelAct actoActual = LevelAct.act1;
  int puntos = 0;
  int vidas = 3;
  bool nivelActivo = true;
 
  // ── ACTO 1 — Constructor del email ───────────────────────────────────────
  Map<ComponentType, EmailComponent?> componentesSeleccionados = {};
  int credibilidadTotal = 0;
 
  // ── ACTO 2 — Bandeja de entrada ──────────────────────────────────────────
  late List<EmailModel> bandeja;
  Map<String, bool> respuestasJugador = {}; // emailId → true=phishing
  int emailActualIndex = 0;
  int segundosRestantes = 120;
  bool _timerActivo = false;
  double _timerAcumulado = 0;
 
  // ── ACTO 3 — Inspección del email ambiguo ────────────────────────────────
  int acto3EmailIndex = 0;
  List<ElementType> elementosRevelados = [];
  Map<String, bool> respuestasActo3 = {};
  bool? decisionFinal; // true = bloqueado, false = dejado pasar
  int pistasActo3Reveladas = 0;
  int totalPistasActo3 = 0;   
 
  Nivel10Game({
    required this.onActoCambiado,
    required this.onNivelCompletado,
    required this.onJuegoTerminado,
    required this.onEstadoActualizado,
  });
 
  // ── CONFIGURACIÓN ─────────────────────────────────────────────────────────
 
  @override
  Color backgroundColor() => const Color(0xFF050510);
 
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    bandeja = List.from(PhishingData.inbox)..shuffle();
    totalPistasActo3 = PhishingData.acto3Emails.fold(
    0,
    (total, caso) => total + caso.inspectionElements.length,
  );
  }
 
  // ── UPDATE — Gestiona el timer del Acto 2 ─────────────────────────────────
 
  @override
  void update(double dt) {
    super.update(dt);
    if (!nivelActivo) return;
    if (actoActual != LevelAct.act2 || !_timerActivo) return;
 
    _timerAcumulado += dt;
    if (_timerAcumulado >= 1.0) {
      _timerAcumulado = 0;
      segundosRestantes--;
      onEstadoActualizado(puntos, 2);
      if (segundosRestantes <= 0) {
        _timerActivo = false;
        _finalizarActo2();
      }
    }
  }
 
  // ── ACTO 1 — Lógica ───────────────────────────────────────────────────────
 
  /// Selecciona un componente del email. Ignorado si está bloqueado.
  void seleccionarComponente(EmailComponent componente) {
    if (componente.isBlocked) return;
    componentesSeleccionados[componente.type] = componente;
    credibilidadTotal = componentesSeleccionados.values
        .whereType<EmailComponent>()
        .fold(0, (sum, c) => sum + c.credibility);
    onEstadoActualizado(puntos, 1);
  }
 
  /// True cuando el jugador ha elegido una opción en cada paso.
  bool get acto1Completo =>
      ComponentType.values.every((t) => componentesSeleccionados[t] != null);
 
  /// Confirma el Acto 1 y avanza al Acto 2.
  void confirmarActo1() {
    if (!acto1Completo) return;
    actoActual = LevelAct.act2;
    _timerActivo = true;
    onActoCambiado();
    onEstadoActualizado(puntos, 2);
  }
 
  // ── ACTO 2 — Lógica ───────────────────────────────────────────────────────
 
  /// Registra la clasificación del jugador para el email actual.
  void clasificarEmail(String emailId, bool esPhishing) {
    respuestasJugador[emailId] = esPhishing;
    final email = bandeja.firstWhere((e) => e.id == emailId);
    if (email.isPhishing == esPhishing) {
      puntos += 100;
    } else {
      vidas--;
      if (vidas <= 0) {
        nivelActivo = false;
        onJuegoTerminado();
        return;
      }
    }
    emailActualIndex++;
    onEstadoActualizado(puntos, 2);
 
    if (emailActualIndex >= bandeja.length) {
      _timerActivo = false;
      _finalizarActo2();
    }
  }

  void pausarTemporizadorActo2() {
    if (actoActual == LevelAct.act2) {
      _timerActivo = false;
    }
  }

  void reanudarTemporizadorActo2() {
    if (actoActual == LevelAct.act2 && nivelActivo) {
      _timerActivo = true;
    }
  }
 
  void _finalizarActo2() {
    actoActual = LevelAct.act3;
    onActoCambiado();
    onEstadoActualizado(puntos, 3);
  }
 
  // ── ACTO 3 — Lógica ───────────────────────────────────────────────────────
 
  /// Revela un elemento inspeccionable. Da bonus de puntos la primera vez.
  void revelarElemento(ElementType tipo) {
    if (elementosRevelados.contains(tipo)) return;

    elementosRevelados.add(tipo);
    pistasActo3Reveladas++;
    puntos += 25;

    onEstadoActualizado(puntos, 3);
  }
 
  /// Decisión final del jugador: bloquear o dejar pasar el email ambiguo.
  void tomarDecisionFinal(bool bloquear) {
    final caso = acto3EmailActual;
    respuestasActo3[caso.email.id] = bloquear;

    if (bloquear == caso.email.isPhishing) {
      puntos += 200;
    } else {
      vidas--;
      if (vidas <= 0) {
        nivelActivo = false;
        onJuegoTerminado();
        return;
      }
    }

    acto3EmailIndex++;
    elementosRevelados.clear();

    if (acto3EmailIndex >= PhishingData.acto3Emails.length) {
      nivelActivo = false;
      actoActual = LevelAct.results;
      onNivelCompletado(puntos);
    } else {
      onEstadoActualizado(puntos, 3);
      onActoCambiado();
    }
  }
 
  // ── HELPERS PARA LA PANTALLA ──────────────────────────────────────────────
 
  /// Email que el jugador está viendo actualmente en el Acto 2.
  EmailModel? get emailActual =>
      emailActualIndex < bandeja.length ? bandeja[emailActualIndex] : null;

  /// Email que el jugador está viendo actualmente en el Acto 3.
  Acto3Email get acto3EmailActual =>
      PhishingData.acto3Emails[acto3EmailIndex];

  /// True cuando ya se han resuelto todos los emails del Acto 3.
  bool get acto3Completo =>
    acto3EmailIndex >= PhishingData.acto3Emails.length;
 
  /// Número de emails clasificados correctamente en el Acto 2.
  int get emailsAcertados {
    int aciertos = 0;
    for (final email in bandeja) {
      if (respuestasJugador[email.id] == email.isPhishing) aciertos++;
    }
    return aciertos;
  }
 
  /// Rango final según puntuación.
  String get rangFinal {
    if (puntos >= 800) return 'Analista Experto';
    if (puntos >= 500) return 'Buen Ojo';
    return 'Sigue Practicando';
  }
 
  /// Puntuación máxima posible del nivel.
  static int get puntuacionMaxima =>
      (PhishingData.inbox.length * 100) + (3 * 25) + 200;
}