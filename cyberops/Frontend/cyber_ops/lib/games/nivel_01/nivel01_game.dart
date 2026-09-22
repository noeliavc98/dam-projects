import 'dart:math' as math;
import 'package:cyber_ops/services/music_service.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/drone_component.dart';
import 'components/nodo_component.dart';
import 'components/enemigo_component.dart';
import 'components/bala_component.dart';

class Nivel01Game extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  // ── CALLBACKS HACIA FLUTTER ──────────────────────────────────────────────────
  final void Function(NodoComponent nodo) onNodoTocado;
  final void Function(int puntos, int vidas) onEstadoActualizado;
  final void Function() onJuegoTerminado;
  final void Function() onNivelCompletado;

  // ── ESTADO DEL JUEGO ─────────────────────────────────────────────────────────
  int puntos = 0;
  int vidas = 3;
  bool juegoActivo = true;
  bool preguntaAbierta = false;

  // ── COMPONENTES ──────────────────────────────────────────────────────────────
  late DroneComponent _dron;
  final List<NodoComponent> _nodos = [];
  final List<EnemigoComponent> _enemigos = [];
  final math.Random _random = math.Random();
  JoystickComponent? _joystick;

  // ── DISPARO ──────────────────────��───────────────────────────────────────────
  double _cooldownDisparo = 0;
  static const double _cooldownMaxDisparo = 0.25;

  // ── POSICIÓN DEL PUNTERO EN TIEMPO REAL ──────────────────────────────────────
  Vector2 _posicionPuntero = Vector2.zero();

  // ── COLA DE PREGUNTAS SIN REPETIR ────────────────────────────────────────────
  final List<Map<String, dynamic>> _colaPreguntas = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  Nivel01Game({
    required this.onNodoTocado,
    required this.onEstadoActualizado,
    required this.onJuegoTerminado,
    required this.onNivelCompletado,
  });

  // ── PREGUNTAS ─────────────────────────────────────────────────────────────────

  /// Carga las preguntas desde la pantalla y rellena la cola inicial.
  void cargarPreguntas(List<Map<String, dynamic>> preguntas) {
    _todasPreguntas = List.from(preguntas);
    _rellenarCola();
  }

  /// Mezcla todas las preguntas y las añade a la cola.
  void _rellenarCola() {
    final mezcladas = List<Map<String, dynamic>>.from(_todasPreguntas)
      ..shuffle();
    _colaPreguntas.addAll(mezcladas);
  }

  /// Devuelve la siguiente pregunta sin repetir.
  /// Si la cola se vacía la rellena de nuevo.
  Map<String, dynamic>? _siguientePregunta() {
    if (_colaPreguntas.isEmpty) _rellenarCola();
    if (_colaPreguntas.isEmpty) return null;
    return _colaPreguntas.removeAt(0);
  }

  // ── CONFIGURACIÓN ────────────────────────────────────────────────────────

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _posicionPuntero = Vector2(size.x / 2, size.y / 2);
    _spawnDron();
    _spawnNodos();
    _spawnJoystick();
  }

  // ── SPAWN ─────────────────────────────────────────────────────────────────────

  void _spawnDron() {
    _dron = DroneComponent(
      posicion: Vector2(size.x / 2, size.y / 2),
      onDisparar: _dispararEnDireccion,
    );
    add(_dron);
  }

  void _spawnNodos() {
    final posiciones = [
      Vector2(size.x * 0.2, size.y * 0.2),
      Vector2(size.x * 0.5, size.y * 0.15),
      Vector2(size.x * 0.8, size.y * 0.2),
      Vector2(size.x * 0.15, size.y * 0.45),
      Vector2(size.x * 0.85, size.y * 0.45),
      Vector2(size.x * 0.3, size.y * 0.65),
      Vector2(size.x * 0.7, size.y * 0.65),
      Vector2(size.x * 0.5, size.y * 0.4),
    ];

    for (int i = 0; i < posiciones.length; i++) {
      final nodo = NodoComponent(
        id: i + 1,
        posicion: posiciones[i],
        onContactoDron: _onNodoContacto,
      );
      _nodos.add(nodo);
      add(nodo);
    }

    add(_RedLines(nodos: _nodos));
  }

  void _spawnJoystick() {
    _joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20,
        paint: Paint()..color = const Color(0xFF06B6D4).withValues(alpha: 0.8),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFF0D0D2B).withValues(alpha: 0.7),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(_joystick!);
  }

  void _spawnEnemigo() {
    final lado = _random.nextInt(4);
    Vector2 pos;
    switch (lado) {
      case 0:
        pos = Vector2(_random.nextDouble() * size.x, 80);
        break;
      case 1:
        pos = Vector2(_random.nextDouble() * size.x, size.y - 80);
        break;
      case 2:
        pos = Vector2(20, _random.nextDouble() * size.y);
        break;
      default:
        pos = Vector2(size.x - 20, _random.nextDouble() * size.y);
    }

    final enemigo = EnemigoComponent(
      posicion: pos,
      onTocaDron: _enemigoTocaDron,
    );
    enemigo.setObjetivo(_dron);
    _enemigos.add(enemigo);
    add(enemigo);
  }

  // ── DISPARO ───────────────────────────────────────────────────────────────────

  /// Dispara hacia una posición concreta en coordenadas de pantalla.
  void _dispararHacia(Vector2 destino) {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;
    _cooldownDisparo = _cooldownMaxDisparo;

    // ✅ Actualizar rotación hacia el destino
    _dron.apuntarHacia(destino);

    // ✅ Usar la dirección correcta del dron
    final direccion = _dron.direccionDisparo;

    MusicService().playDisparo();
    add(BalaComponent(posicion: _dron.puntaFlecha, direccion: direccion));
  }

  /// Dispara en la dirección actual de la flecha (sin buscar enemigos).
  void _dispararEnDireccion() {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;

    // ✅ USAR LA DIRECCIÓN ACTUAL DE LA FLECHA (no buscar enemigos)
    final direccion = _dron.direccionDisparo;

    _cooldownDisparo = _cooldownMaxDisparo;
    MusicService().playDisparo();
    add(BalaComponent(posicion: _dron.puntaFlecha, direccion: direccion));
  }

  // ── MÉTODOS PÚBLICOS LLAMADOS DESDE LA PANTALLA ───────────────────────────────

  /// ACTUALIZA LA POSICIÓN DEL PUNTERO EN TIEMPO REAL
  void actualizarPuntero(Offset offset) {
    _posicionPuntero = Vector2(offset.dx, offset.dy);
  }

  /// Dispara hacia un Offset de Flutter.
  void dispararHaciaOffset(Offset offset) {
    _dispararHacia(Vector2(offset.dx, offset.dy));
  }

  /// Dispara manualmente en la dirección de la flecha.
  void dispararManual() => _dispararEnDireccion();

  // ── RESPUESTA CORRECTA ────────────────────────────────────────────────────
  void respuestaCorrecta(NodoComponent nodo, int puntosGanados) {
    nodo.marcarComprometido();
    puntos += puntosGanados;
    preguntaAbierta = false;
    resumeEngine();
    _dron.desbloquear();
    onEstadoActualizado(puntos, vidas);
    _verificarNivelCompletado();
  }

  // ── RESPUESTA INCORRECTA ──────────────────────────────────────────────────
  void respuestaIncorrecta(NodoComponent nodo) {
    nodo.marcarAlerta();
    preguntaAbierta = false;
    resumeEngine();
    _dron.desbloquear();
    _spawnEnemigo();
    vidas--;
    onEstadoActualizado(puntos, vidas);
    if (vidas <= 0) {
      juegoActivo = false;
      onJuegoTerminado();
    }
  }

  // ── LÓGICA INTERNA ────────────────────────────────────────────────────────────

  void _onNodoContacto(NodoComponent nodo) {
    if (!juegoActivo || preguntaAbierta) return;
    preguntaAbierta = true;
    MusicService().playToqueNodo();
    pauseEngine();
    _dron.bloquear();
    onNodoTocado(nodo);
  }

  void _enemigoTocaDron() {
    if (!juegoActivo) return;
    vidas--;
    onEstadoActualizado(puntos, vidas);
    if (vidas <= 0) {
      juegoActivo = false;
      onJuegoTerminado();
    }
  }

  void _verificarNivelCompletado() {
    final comprometidos = _nodos
        .where((n) => n.estado == NodoEstado.comprometido)
        .length;
    if (comprometidos >= 5) {
      juegoActivo = false;
      onNivelCompletado();
    }
  }

  // ── TAP EN PANTALLA → DISPARAR ────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    if (!juegoActivo || preguntaAbierta) return;
    _dispararHacia(event.canvasPosition);
  }

  // ── TECLADO ───────────────────────────────────────────────────────────────────

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _dron.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (!juegoActivo || preguntaAbierta) return;

    if (_cooldownDisparo > 0) _cooldownDisparo -= dt;

    // ✅ ACTUALIZAR FLECHA EN TIEMPO REAL SEGÚN POSICIÓN DEL PUNTERO
    if (!_dron.bloqueado) {
      _dron.apuntarHacia(_posicionPuntero);
    }

    // Mover dron con joystick
    if (_joystick != null && !_joystick!.delta.isZero()) {
      _dron.joystickDelta = _joystick!.relativeDelta;
    } else {
      _dron.joystickDelta = Vector2.zero();
    }

    // Detectar colisión dron con nodos seguros
    for (final nodo in _nodos) {
      if (nodo.estado == NodoEstado.seguro) {
        final dist = _dron.position.distanceTo(nodo.position);
        if (dist < DroneComponent.radio + NodoComponent.radio) {
          nodo.activarPregunta();
        }
      }
    }

    // Limpiar enemigos eliminados
    _enemigos.removeWhere((e) => e.eliminado);
  }
}

// ── LÍNEAS DE RED ─────────────────────────────────────────────────────────────

class _RedLines extends Component {
  final List<NodoComponent> nodos;
  _RedLines({required this.nodos});

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    for (int i = 0; i < nodos.length; i++) {
      for (int j = i + 1; j < nodos.length; j++) {
        final dist = nodos[i].position.distanceTo(nodos[j].position);
        if (dist < 200) {
          canvas.drawLine(
            Offset(nodos[i].position.x, nodos[i].position.y),
            Offset(nodos[j].position.x, nodos[j].position.y),
            paint,
          );
        }
      }
    }
  }
}
