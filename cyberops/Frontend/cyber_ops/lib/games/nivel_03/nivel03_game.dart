import 'dart:math' as math;
import 'package:cyber_ops/services/music_service.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../nivel_01/components/drone_component.dart';
import '../nivel_01/components/nodo_component.dart';
import '../nivel_01/components/bala_component.dart';
import 'components/enemigo_dispara_component.dart';
import 'components/bala_enemiga_component.dart';

class Nivel03Game extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  // ── CALLBACKS HACIA FLUTTER ──────────────────────────────────────────────────
  final void Function(NodoComponent nodo) onNodoTocado;
  final void Function(int puntos, int vidas) onEstadoActualizado;
  final void Function() onJuegoTerminado;
  final void Function() onNivelCompletado;

  /// Notifica cambios en la habilidad: (activa, cooldownRestante, duracionRestante)
  final void Function(bool activa, double cooldown, double duracion)?
  onHabilidadActualizada;

  // ── ESTADO DEL JUEGO ─────────────────────────────────────────────────────────
  int puntos = 0;
  int vidas = 3;
  bool juegoActivo = true;
  bool preguntaAbierta = false;

  // ── COMPONENTES ──────────────────────────────────────────────────────────────
  late DroneComponent _dron;
  final List<NodoComponent> _nodos = [];
  final List<EnemigoDisparaComponent> _enemigos = [];
  final math.Random _random = math.Random();
  JoystickComponent? _joystick;
  final List<_BarreraCable> _barreras = [];

  // ── NODOS PAREADOS: índice A desbloquea índice B ──────────────────────────────
  // Par 0→2: nodo N1 desbloquea N3
  // Par 3→4: nodo N4 desbloquea N5
  // Par 1→7: nodo N2 desbloquea N7
  static const List<List<int>> _parejas = [
    [0, 2],
    [3, 4],
    [1, 7],
  ];

  static double _distPuntoSegmento(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final ap = p - a;
    final len2 = ab.dot(ab);
    if (len2 == 0) return ap.length;
    final t = (ap.dot(ab) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).length;
  }

  static Vector2 _puntoMasCercanoEnSegmento(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final len2 = ab.dot(ab);
    if (len2 == 0) return a.clone();
    final t = ((p - a).dot(ab) / len2).clamp(0.0, 1.0);
    return a + ab * t;
  }

  void _resolverBarreras() {
    const umbral = DroneComponent.radio + 2.0;
    for (final barrera in _barreras) {
      if (!barrera.activa) continue;
      final posA = _nodos[barrera.idxA].position;
      final posB = _nodos[barrera.idxB].position;
      final dron = _dron.position;
      if (_distPuntoSegmento(dron, posA, posB) < umbral) {
        final closest = _puntoMasCercanoEnSegmento(dron, posA, posB);
        final pushDir = dron - closest;
        if (pushDir.length < 0.001) {
          final cable = posB - posA;
          final perp = Vector2(-cable.y, cable.x)..normalize();
          _dron.position += perp * umbral;
        } else {
          pushDir.normalize();
          _dron.position = closest + pushDir * umbral;
        }
      }
    }
  }

  // ── INVISIBILIDAD ────────────────────────────────────────────────────────────
  static const double _duracionInvisibilidad = 4.0;
  static const int _nodosParaRecargar = 2;
  bool _dronInvisible = false;
  double _tiempoInvisibilidadRestante = 0;
  // Cooldown basado en nodos acertados: 0 = lista, >0 = nodos pendientes
  int _nodosParaCooldown = 0;

  // Getters públicos para que la pantalla pueda leer el estado
  bool get dronInvisible => _dronInvisible;
  // Normalizado 0..1 para el arco de progreso (1 = lista)
  double get cooldownInvisibilidad =>
      _nodosParaCooldown == 0 ? 0 : (_nodosParaCooldown / _nodosParaRecargar);
  double get tiempoInvisibilidadRestante => _tiempoInvisibilidadRestante;

  // ── DISPARO ──────────────────────────────────────────────────────────────────
  double _cooldownDisparo = 0;
  static const double _cooldownMaxDisparo = 0.25;

  // ── AUTOSPAWN DE ENEMIGOS ────────────────────────────────────────────────────
  double _tiempoDesdeSpawn = 0;
  static const double _intervaloAutoSpawn = 6.0;

  // ── POSICIÓN DEL PUNTERO EN TIEMPO REAL ──────────────────────────────────────
  Vector2 _posicionPuntero = Vector2.zero();

  // ── COLA DE PREGUNTAS SIN REPETIR ────────────────────────────────────────────
  final List<Map<String, dynamic>> _colaPreguntas = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  Nivel03Game({
    required this.onNodoTocado,
    required this.onEstadoActualizado,
    required this.onJuegoTerminado,
    required this.onNivelCompletado,
    this.onHabilidadActualizada,
  });

  // ── PREGUNTAS ─────────────────────────────────────────────────────────────────

  void cargarPreguntas(List<Map<String, dynamic>> preguntas) {
    _todasPreguntas = List.from(preguntas);
    _rellenarCola();
  }

  void _rellenarCola() {
    final mezcladas = List<Map<String, dynamic>>.from(_todasPreguntas)
      ..shuffle();
    _colaPreguntas.addAll(mezcladas);
  }

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
      Vector2(size.x * 0.2, size.y * 0.2), // 0
      Vector2(size.x * 0.5, size.y * 0.15), // 1
      Vector2(size.x * 0.8, size.y * 0.2), // 2
      Vector2(size.x * 0.15, size.y * 0.45), // 3
      Vector2(size.x * 0.85, size.y * 0.45), // 4
      Vector2(size.x * 0.3, size.y * 0.65), // 5
      Vector2(size.x * 0.7, size.y * 0.65), // 6
      Vector2(size.x * 0.5, size.y * 0.4), // 7
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

    // Bloquear el segundo nodo de cada pareja
    for (final pareja in _parejas) {
      _nodos[pareja[1]].bloqueado = true;
    }

    for (final pareja in _parejas) {
      _barreras.add(_BarreraCable(idxA: pareja[0], idxB: pareja[1]));
    }

    // Líneas de red generales (fondo)
    add(_RedLines(nodos: _nodos));
    // Cables transmisores de parejas (encima)
    add(_CableTransmisor(nodos: _nodos, parejas: _parejas));
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

    final enemigo = EnemigoDisparaComponent(
      posicion: pos,
      onTocaDron: _enemigoTocaDron,
      onDisparar: _agregarBalaEnemiga,
    );
    enemigo.setObjetivo(_dron);
    _enemigos.add(enemigo);
    add(enemigo);
  }

  void _agregarBalaEnemiga(BalaEnemigaComponent bala) {
    bala.onGolpearDron = _balaEnemigaGolpeaDron;
    add(bala);
  }

  void _balaEnemigaGolpeaDron() {
    if (!juegoActivo) return;
    vidas--;
    onEstadoActualizado(puntos, vidas);
    if (vidas <= 0) {
      juegoActivo = false;
      onJuegoTerminado();
    }
  }

  // ── INVISIBILIDAD ─────────────────────────────────────────────────────────────

  void activarInvisibilidad() {
    if (!juegoActivo || preguntaAbierta) return;
    if (_dronInvisible || _nodosParaCooldown > 0) return;

    _dronInvisible = true;
    _dron.invisible = true;
    _tiempoInvisibilidadRestante = _duracionInvisibilidad;
    _nodosParaCooldown = _nodosParaRecargar;
    onHabilidadActualizada?.call(true, 0, _duracionInvisibilidad);
  }

  void _tickInvisibilidad(double dt) {
    if (_dronInvisible) {
      _tiempoInvisibilidadRestante -= dt;
      if (_tiempoInvisibilidadRestante <= 0) {
        _dronInvisible = false;
        _dron.invisible = false;
        // Notificar: en cooldown, con ratio de nodos pendientes
        onHabilidadActualizada?.call(false, cooldownInvisibilidad, 0);
      } else {
        onHabilidadActualizada?.call(true, 0, _tiempoInvisibilidadRestante);
      }
    }
  }

  void _reducirCooldownPorNodo() {
    if (_nodosParaCooldown > 0) {
      _nodosParaCooldown--;
      onHabilidadActualizada?.call(false, cooldownInvisibilidad, 0);
    }
  }

  // ── DISPARO ───────────────────────────────────────────────────────────────────

  void _dispararHacia(Vector2 destino) {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;
    _cooldownDisparo = _cooldownMaxDisparo;

    _dron.apuntarHacia(destino);
    final direccion = _dron.direccionDisparo;

    MusicService().playDisparo();
    add(BalaComponent(posicion: _dron.puntaFlecha, direccion: direccion));
  }

  void _dispararEnDireccion() {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;

    final direccion = _dron.direccionDisparo;
    _cooldownDisparo = _cooldownMaxDisparo;
    MusicService().playDisparo();
    add(BalaComponent(posicion: _dron.puntaFlecha, direccion: direccion));
  }

  // ── MÉTODOS PÚBLICOS LLAMADOS DESDE LA PANTALLA ───────────────────────────────

  void actualizarPuntero(Offset offset) {
    _posicionPuntero = Vector2(offset.dx, offset.dy);
  }

  void dispararHaciaOffset(Offset offset) {
    _dispararHacia(Vector2(offset.dx, offset.dy));
  }

  void dispararManual() => _dispararEnDireccion();
  void limpiarInputs() {
    _dron.detenerMovimiento();
  }

  // ── RESPUESTA CORRECTA ────────────────────────────────────────────────────
  void respuestaCorrecta(NodoComponent nodo, int puntosGanados) {
    nodo.marcarComprometido();
    puntos += puntosGanados;
    preguntaAbierta = false;
    resumeEngine();
    _dron.desbloquear();
    onEstadoActualizado(puntos, vidas);

    // Desbloquear el nodo asociado si este era el nodo padre de una pareja
    final idx = _nodos.indexOf(nodo);
    for (final pareja in _parejas) {
      if (pareja[0] == idx) {
        _nodos[pareja[1]].desbloquear();
        break;
      }
      if (pareja[1] == idx) {
        final padreComprometido =
            _nodos[pareja[0]].estado == NodoEstado.comprometido;
        final hijoComprometido =
            _nodos[pareja[1]].estado == NodoEstado.comprometido;
        if (padreComprometido && hijoComprometido) {
          for (final b in _barreras) {
            if (b.idxA == pareja[0]) b.activa = false;
          }
        }
        break;
      }
    }

    _reducirCooldownPorNodo();
    _verificarNivelCompletado();
  }

  // ── RESPUESTA INCORRECTA ──────────────────────────────────────────────────
  void respuestaIncorrecta(NodoComponent nodo) {
    nodo.marcarAlerta();
    preguntaAbierta = false;
    resumeEngine();
    _dron.desbloquear();
    _spawnEnemigo();
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

    // Tecla E → activar invisibilidad
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      activarInvisibilidad();
    }

    return KeyEventResult.handled;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (!juegoActivo || preguntaAbierta) return;

    if (_cooldownDisparo > 0) _cooldownDisparo -= dt;

    _tickInvisibilidad(dt);

    // Autospawn continuo de enemigos
    _tiempoDesdeSpawn += dt;
    if (_tiempoDesdeSpawn >= _intervaloAutoSpawn) {
      _tiempoDesdeSpawn = 0;
      _spawnEnemigo();
    }

    if (!_dron.bloqueado) {
      _dron.apuntarHacia(_posicionPuntero);
    }

    if (_joystick != null && !_joystick!.delta.isZero()) {
      _dron.joystickDelta = _joystick!.relativeDelta;
    } else {
      _dron.joystickDelta = Vector2.zero();
    }

    for (final nodo in _nodos) {
      if (nodo.estado == NodoEstado.seguro && !nodo.bloqueado) {
        final dist = _dron.position.distanceTo(nodo.position);
        if (dist < DroneComponent.radio + NodoComponent.radio) {
          nodo.activarPregunta();
        }
      }
    }

    _resolverBarreras();
    _enemigos.removeWhere((e) => e.eliminado);
  }
}

// ── LÍNEAS DE RED (fondo) ─────────────────────────────────────────────────────

class _RedLines extends Component {
  final List<NodoComponent> nodos;
  _RedLines({required this.nodos});

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.10)
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

// ── CABLE TRANSMISOR (parejas de nodos) ──────────────────────────────────────

class _CableTransmisor extends Component {
  final List<NodoComponent> nodos;
  final List<List<int>> parejas;
  double _tiempo = 0;

  _CableTransmisor({required this.nodos, required this.parejas});

  @override
  void update(double dt) {
    _tiempo += dt;
  }

  @override
  void render(Canvas canvas) {
    for (final pareja in parejas) {
      final nodoA = nodos[pareja[0]];
      final nodoB = nodos[pareja[1]];
      final desbloqueado =
          nodoA.estado == NodoEstado.comprometido &&
          nodoB.estado == NodoEstado.comprometido;
      _dibujarCable(canvas, nodoA, nodoB, desbloqueado);
    }
  }

  void _dibujarCable(
    Canvas canvas,
    NodoComponent a,
    NodoComponent b,
    bool activo,
  ) {
    final pA = Offset(a.position.x, a.position.y);
    final pB = Offset(b.position.x, b.position.y);

    // Color base según estado: cyan si activo, naranja si bloqueado
    final colorBase = activo
        ? const Color(0xFF06B6D4)
        : const Color(0xFFFF9800);

    // Línea discontinua sutil
    final dx = pB.dx - pA.dx;
    final dy = pB.dy - pA.dy;
    final longitud = math.sqrt(dx * dx + dy * dy);
    const dashLen = 8.0;
    const gapLen = 6.0;
    final ux = dx / longitud;
    final uy = dy / longitud;

    final linePaint = Paint()
      ..color = colorBase.withValues(alpha: 0.20)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    double recorrido = 0;
    while (recorrido < longitud) {
      final inicio = recorrido;
      final fin = math.min(recorrido + dashLen, longitud);
      canvas.drawLine(
        Offset(pA.dx + ux * inicio, pA.dy + uy * inicio),
        Offset(pA.dx + ux * fin, pA.dy + uy * fin),
        linePaint,
      );
      recorrido += dashLen + gapLen;
    }

    // Punto de energía animado (pequeño y sutil)
    final t = (_tiempo * 0.4) % 1.0;
    final px = pA.dx + dx * t;
    final py = pA.dy + dy * t;
    canvas.drawCircle(
      Offset(px, py),
      2.0,
      Paint()..color = colorBase.withValues(alpha: 0.45),
    );

    // Candado en B si bloqueado
    if (!activo) {
      _dibujarIconoCandado(canvas, pB, colorBase);
    }
  }

  void _dibujarIconoCandado(Canvas canvas, Offset centro, Color color) {
    // Pequeño candado encima del nodo
    final offsetY = -NodoComponent.radio - 14.0;
    final c = Offset(centro.dx, centro.dy + offsetY);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 10, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = color.withValues(alpha: 0.85),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx, c.dy - 1), width: 8, height: 8),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }
}

class _BarreraCable {
  final int idxA;
  final int idxB;
  bool activa = true;
  _BarreraCable({required this.idxA, required this.idxB});
}
