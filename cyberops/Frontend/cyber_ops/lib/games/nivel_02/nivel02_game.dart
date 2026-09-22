import 'dart:math' as math;
import 'package:cyber_ops/services/music_service.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../nivel_01/components/drone_component.dart';
import '../nivel_01/components/nodo_component.dart';
import '../nivel_01/components/enemigo_component.dart';
import '../nivel_01/components/bala_component.dart';

class Nivel02Game extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {

  // ── CALLBACKS HACIA FLUTTER ───────────────────────────────────────────────
  final void Function(NodoComponent nodo) onNodoTocado;
  final void Function(int puntos, int vidas) onEstadoActualizado;
  final void Function() onJuegoTerminado;
  final void Function() onNivelCompletado;

  // ── ESTADO DEL JUEGO ──────────────────────────────────────────────────────
  int puntos = 0;
  int vidas = 3;
  int incidentesResueltos = 0;
  int combo = 0;
  static const int _comboMax = 5;
  int aciertosAcumulados = 0;
  bool escudoDisponible = false;

  int get incidentesActivos => _nodos
      .where((n) =>
          n.estado == NodoEstado.vulnerable ||
          n.estado == NodoEstado.alerta)
      .length;

  int get incidentesObjetivo => _incidentesParaGanar;

  bool juegoActivo = true;
  bool preguntaAbierta = false;

  // ── COMPONENTES ───────────────────────────────────────────────────────────
  late DroneComponent _dron;
  final List<NodoComponent> _nodos = [];
  final List<EnemigoComponent> _enemigos = [];
  final math.Random _random = math.Random();
  JoystickComponent? _joystick;

  // ── DISPARO ───────────────────────────────────────────────────────────────
  double _cooldownDisparo = 0;
  static const double _cooldownMaxDisparo = 0.3;

  // ── POSICIÓN DEL PUNTERO EN TIEMPO REAL ──────────────────────────────────
  Vector2 _posicionPuntero = Vector2.zero();

  // ── TEMPORIZADOR DE INCIDENTES ────────────────────────────────────────────
  double _timerIncidente = 0;
  static const double _intervaloIncidente = 8.0;
  static const double _tiempoLimiteIncidente = 10.0;

  // ── TEMPORIZADORES POR NODO ───────────────────────────────────────────────
  final Map<int, double> _temporizadoresNodos = {};

  // ── PULSO VISUAL DEL ESCUDO ───────────────────────────────────────────────
  bool _pulsoEscudoActivo = false;
  double _pulsoEscudoRadio = 0;
  double _pulsoEscudoOpacidad = 0;

  // ── CONDICIONES DE VICTORIA/DERROTA ──────────────────────────────────────
  static const int _incidentesParaGanar = 5;
  static const int _maxNodosComprometidos = 3;

  Nivel02Game({
    required this.onNodoTocado,
    required this.onEstadoActualizado,
    required this.onJuegoTerminado,
    required this.onNivelCompletado,
  });

  // ── COLOR DE FONDO ────────────────────────────────────────────────────────
  @override
  Color backgroundColor() => const Color(0xFF050510);

  // ── RENDER DEL PULSO DEL ESCUDO ───────────────────────────────────────────
  @override
 void render(Canvas canvas) {
  super.render(canvas);

  if (_pulsoEscudoActivo) {
    final center = Offset(size.x / 2, size.y / 2);

    
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..color = const Color(0xFF06B6D4)
            .withValues(alpha: _pulsoEscudoOpacidad * 0.18)
        ..style = PaintingStyle.fill,
    );

   
    canvas.drawCircle(
      center,
      _pulsoEscudoRadio * 0.28,
      Paint()
        ..color = const Color(0xFF06B6D4)
            .withValues(alpha: _pulsoEscudoOpacidad * 0.10)
        ..style = PaintingStyle.fill,
    );

    
    canvas.drawCircle(
      center,
      _pulsoEscudoRadio,
      Paint()
        ..color = const Color(0xFF06B6D4)
            .withValues(alpha: _pulsoEscudoOpacidad)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

  
    canvas.drawCircle(
      center,
      _pulsoEscudoRadio + 18,
      Paint()
        ..color = const Color(0xFF06B6D4)
            .withValues(alpha: _pulsoEscudoOpacidad * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );


    canvas.drawCircle(
      center,
      _pulsoEscudoRadio + 38,
      Paint()
        ..color = const Color(0xFF6C63FF)
            .withValues(alpha: _pulsoEscudoOpacidad * 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

  
    canvas.drawCircle(
      center,
      _pulsoEscudoRadio + 12,
      Paint()
        ..color = const Color(0xFF06B6D4)
            .withValues(alpha: _pulsoEscudoOpacidad * 0.06)
        ..style = PaintingStyle.fill,
    );


    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = Colors.white.withValues(alpha: _pulsoEscudoOpacidad * 0.55)
        ..style = PaintingStyle.fill,
    );
  }
}

  // ── CARGA INICIAL ─────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Inicializamos el puntero en el centro de la pantalla
    _posicionPuntero = Vector2(size.x / 2, size.y / 2);
    _spawnDron();
    _spawnNodos();
    _spawnJoystick();
    add(_IncidentTimersOverlay());
    // Primer incidente al empezar para que el jugador tenga objetivo
    _crearIncidenteAleatorio();
  }

  // ── SPAWN DRON ────────────────────────────────────────────────────────────
  void _spawnDron() {
    _dron = DroneComponent(
      posicion: Vector2(size.x / 2, size.y / 2),
      onDisparar: _dispararEnDireccion,
    );
    add(_dron);
  }

  // ── SPAWN NODOS ───────────────────────────────────────────────────────────
  void _spawnNodos() {
    final posiciones = [
      Vector2(size.x * 0.2, size.y * 0.22),
      Vector2(size.x * 0.5, size.y * 0.18),
      Vector2(size.x * 0.8, size.y * 0.22),
      Vector2(size.x * 0.25, size.y * 0.50),
      Vector2(size.x * 0.75, size.y * 0.50),
      Vector2(size.x * 0.5, size.y * 0.72),
    ];

    for (int i = 0; i < posiciones.length; i++) {
      final nodo = NodoComponent(
        id: i + 1,
        posicion: posiciones[i],
        onContactoDron: _onNodoContacto,
        modoDefensa: true,
      );
      _nodos.add(nodo);
      add(nodo);
    }

    add(_RedLines(nodos: _nodos));
  }

  // ── SPAWN JOYSTICK ────────────────────────────────────────────────────────
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

  // ── SPAWN ENEMIGO ─────────────────────────────────────────────────────────
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

  // ── DISPARO EN DIRECCIÓN DE LA FLECHA ────────────────────────────────────
  /// Usado con ESPACIO o botón HUD táctil.
  void _dispararEnDireccion() {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;
    _cooldownDisparo = _cooldownMaxDisparo;
    MusicService().playDisparo();

    add(BalaComponent(
      posicion: _dron.puntaFlecha,
      direccion: _dron.direccionDisparo.clone(),
    ));
  }

  /// Dispara hacia una posición concreta — tap o click.
  void _dispararHacia(Vector2 destino) {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;
    _cooldownDisparo = _cooldownMaxDisparo;
    MusicService().playDisparo();

    // Apuntamos la flecha hacia el destino y disparamos
    _dron.apuntarHacia(destino);

    add(BalaComponent(
      posicion: _dron.puntaFlecha,
      direccion: _dron.direccionDisparo.clone(),
    ));
  }

  // ── MÉTODOS PÚBLICOS LLAMADOS DESDE LA PANTALLA ───────────────────────────

  /// Actualiza la posición del puntero en tiempo real — hover del ratón.
  void actualizarPuntero(Offset offset) {
    _posicionPuntero = Vector2(offset.dx, offset.dy);
  }

  /// Dispara hacia un Offset de Flutter — click o tap.
  void dispararHaciaOffset(Offset offset) {
    _dispararHacia(Vector2(offset.dx, offset.dy));
  }

  /// Dispara en la dirección actual de la flecha — botón HUD.
  void dispararManual() => _dispararEnDireccion();

  // ── RESPUESTA CORRECTA ────────────────────────────────────────────────────
  /// El nodo queda asegurado, se suma combo y puntos.
  /// El dron se desbloquea y el juego se reanuda.
  void respuestaCorrecta(NodoComponent nodo, int puntosGanados) {
    _asegurarNodo(nodo);
    combo++;
    if (combo > _comboMax) combo = _comboMax;

    // Los puntos se multiplican por el combo actual
    final int puntosFinales = puntosGanados * combo;
    puntos += puntosFinales;

    incidentesResueltos++;
    aciertosAcumulados++;
    preguntaAbierta = false;

    // Desbloqueamos el dron y reanudamos el juego
    _dron.desbloquear();
    resumeEngine();

    // Cada 2 aciertos consecutivos cargamos el escudo
    if (aciertosAcumulados >= 2) {
      escudoDisponible = true;
      aciertosAcumulados = 0;
    }

    onEstadoActualizado(puntos, vidas);
    _verificarVictoria();
  }

  // ── RESPUESTA INCORRECTA ──────────────────────────────────────────────────
  /// El nodo queda comprometido, se pierde combo y una vida.
  /// El dron se desbloquea y el juego se reanuda.
  void respuestaIncorrecta(NodoComponent nodo) {
    nodo.marcarComprometido();
    _temporizadoresNodos.remove(nodo.id);
    preguntaAbierta = false;

    // Al fallar se reinicia la racha
    combo = 0;

    // Desbloqueamos el dron y reanudamos el juego
    _dron.desbloquear();
    resumeEngine();

    vidas--;
    _spawnEnemigo();

    onEstadoActualizado(puntos, vidas);

    if (vidas <= 0) {
      juegoActivo = false;
      onJuegoTerminado();
      return;
    }

    _verificarDerrotaPorNodos();
  }

  // ── ESCUDO DE RED ─────────────────────────────────────────────────────────
  /// Asegura todos los nodos con incidente activo de golpe.
  void usarEscudoRed() {
    if (!escudoDisponible || !juegoActivo) return;
     MusicService().playEscudo();

    for (final nodo in _nodos) {
      nodo.estado = NodoEstado.seguro;
      nodo.resetPregunta();
      nodo.actualizarColor();

    }

    _temporizadoresNodos.clear();

    // Activamos el pulso visual del escudo
    _pulsoEscudoActivo = true;
    _pulsoEscudoRadio = 8;
    _pulsoEscudoOpacidad = 0.85;

    escudoDisponible = false;
    onEstadoActualizado(puntos, vidas);
  }

  // ── LÓGICA INTERNA ────────────────────────────────────────────────────────

  void _asegurarNodo(NodoComponent nodo) {
    nodo.estado = NodoEstado.seguro;
    nodo.resetPregunta();
    nodo.actualizarColor();
    _temporizadoresNodos.remove(nodo.id);
    onEstadoActualizado(puntos, vidas);
  }

  void _marcarNodoVulnerable(NodoComponent nodo) {
    nodo.estado = NodoEstado.vulnerable;
    nodo.resetPregunta();
    nodo.actualizarColor();
    _temporizadoresNodos[nodo.id] = _tiempoLimiteIncidente;
    onEstadoActualizado(puntos, vidas);
  }

  void _marcarNodoAlerta(NodoComponent nodo) {
    nodo.marcarAlerta();
    _temporizadoresNodos[nodo.id] = _tiempoLimiteIncidente;
    onEstadoActualizado(puntos, vidas);
  }

  void _crearIncidenteAleatorio() {
    if (!juegoActivo) return;

    // Solo elegimos nodos seguros para crear incidentes nuevos
    final seguros =
        _nodos.where((n) => n.estado == NodoEstado.seguro).toList();
    if (seguros.isEmpty) return;

    final nodo = seguros[_random.nextInt(seguros.length)];

    // Aleatoriamente el incidente empieza como vulnerable o alerta
    if (_random.nextBool()) {
      _marcarNodoVulnerable(nodo);
    } else {
      _marcarNodoAlerta(nodo);
    }
  }

  void _actualizarTemporizadoresIncidentes(double dt) {
    final ids = _temporizadoresNodos.keys.toList();

    for (final id in ids) {
      _temporizadoresNodos[id] = (_temporizadoresNodos[id] ?? 0) - dt;

      if ((_temporizadoresNodos[id] ?? 0) <= 0) {
        final nodo = _nodos.firstWhere(
          (n) => n.id == id,
          orElse: () => _nodos.first,
        );

        // Solo comprometemos si seguía en incidente activo
        if (nodo.estado == NodoEstado.vulnerable ||
            nodo.estado == NodoEstado.alerta) {
          nodo.marcarComprometido();
          _spawnEnemigo();
        }

        _temporizadoresNodos.remove(id);
        onEstadoActualizado(puntos, vidas);
        _verificarDerrotaPorNodos();
      }
    }
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

  void _verificarVictoria() {
    if (incidentesResueltos >= _incidentesParaGanar) {
      juegoActivo = false;
      onNivelCompletado();
    }
  }

  void _verificarDerrotaPorNodos() {
    final comprometidos =
        _nodos.where((n) => n.estado == NodoEstado.comprometido).length;
    if (comprometidos >= _maxNodosComprometidos) {
      juegoActivo = false;
      onJuegoTerminado();
    }
  }

  // ── CUANDO EL DRON TOCA UN NODO ───────────────────────────────────────────
  void _onNodoContacto(NodoComponent nodo) {
    if (!juegoActivo || preguntaAbierta) return;

    // En nivel 2 solo se interactúa con nodos con incidente activo
    if (nodo.estado == NodoEstado.vulnerable ||
        nodo.estado == NodoEstado.alerta) {
      preguntaAbierta = true;
       MusicService().playToqueNodo();
      // Bloqueamos el dron y pausamos el juego igual que en nivel 1
      _dron.bloquear();
      pauseEngine();
      onNodoTocado(nodo);
    }
  }

  // ── TAP EN PANTALLA → APUNTAR Y DISPARAR ─────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    if (!juegoActivo || preguntaAbierta) return;
    _dispararHacia(event.canvasPosition);
  }

  // ── TECLADO ───────────────────────────────────────────────────────────────
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _dron.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!juegoActivo || preguntaAbierta) return;

    if (_cooldownDisparo > 0) _cooldownDisparo -= dt;

    // Actualizar flecha en tiempo real según posición del puntero
    if (!_dron.bloqueado) {
      _dron.apuntarHacia(_posicionPuntero);
    }

    // Animación del pulso del escudo
   if (_pulsoEscudoActivo) {
  _pulsoEscudoRadio += 360 * dt;
  _pulsoEscudoOpacidad -= 0.45 * dt;

  if (_pulsoEscudoOpacidad <= 0) {
    _pulsoEscudoActivo = false;
    _pulsoEscudoRadio = 0;
    _pulsoEscudoOpacidad = 0;
  }
}

    // Mover dron con joystick
    if (_joystick != null && !_joystick!.delta.isZero()) {
      _dron.joystickDelta = _joystick!.relativeDelta;
    } else {
      _dron.joystickDelta = Vector2.zero();
    }

    // Actualizar temporizadores de incidentes
    _actualizarTemporizadoresIncidentes(dt);

    // Crear incidentes periódicamente
    _timerIncidente += dt;
    if (_timerIncidente >= _intervaloIncidente) {
      _timerIncidente = 0;

      // Evitamos saturar la pantalla con demasiados incidentes activos
      final activos = _nodos
          .where((n) =>
              n.estado == NodoEstado.vulnerable ||
              n.estado == NodoEstado.alerta)
          .length;

      if (activos < 2) {
        _crearIncidenteAleatorio();
      }
    }

    // Detectar contacto dron con nodos con incidente activo
    for (final nodo in _nodos) {
      if (nodo.estado == NodoEstado.vulnerable ||
          nodo.estado == NodoEstado.alerta) {
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
    for (int i = 0; i < nodos.length; i++) {
      for (int j = i + 1; j < nodos.length; j++) {
        final nodoA = nodos[i];
        final nodoB = nodos[j];
        final dist = nodoA.position.distanceTo(nodoB.position);

        if (dist < 240) {
          canvas.drawLine(
            Offset(nodoA.position.x, nodoA.position.y),
            Offset(nodoB.position.x, nodoB.position.y),
            Paint()
              ..color = _colorLinea(nodoA.estado, nodoB.estado)
              ..strokeWidth = _grosorLinea(nodoA.estado, nodoB.estado),
          );
        }
      }
    }
  }

  Color _colorLinea(NodoEstado a, NodoEstado b) {
    if (a == NodoEstado.comprometido || b == NodoEstado.comprometido) {
      return const Color(0xFFEC4899).withValues(alpha: 0.10);
    }
    if (a == NodoEstado.alerta || b == NodoEstado.alerta) {
      return const Color(0xFFEC4899).withValues(alpha: 0.35);
    }
    if (a == NodoEstado.vulnerable || b == NodoEstado.vulnerable) {
      return const Color(0xFF06B6D4).withValues(alpha: 0.28);
    }
    return const Color(0xFF6C63FF).withValues(alpha: 0.12);
  }

  double _grosorLinea(NodoEstado a, NodoEstado b) {
    if (a == NodoEstado.alerta || b == NodoEstado.alerta) return 2.0;
    if (a == NodoEstado.vulnerable || b == NodoEstado.vulnerable) return 1.5;
    return 1.0;
  }
}

// ── OVERLAY DE TEMPORIZADORES ─────────────────────────────────────────────────
/// Muestra el tiempo restante encima de cada nodo con incidente activo.
class _IncidentTimersOverlay extends PositionComponent
    with HasGameRef<Nivel02Game> {
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final nodo in gameRef._nodos) {
      final tiempo = gameRef._temporizadoresNodos[nodo.id];
      if (tiempo == null) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${tiempo.ceil()}s',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = nodo.position.x - textPainter.width / 2;
      final y = nodo.position.y - NodoComponent.radio - 22;

      // Fondo oscuro para que se lea bien
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - 6,
          y - 2,
          textPainter.width + 12,
          textPainter.height + 4,
        ),
        const Radius.circular(6),
      );

      canvas.drawRRect(
        rect,
        Paint()..color = const Color(0xFF0D0D2B).withValues(alpha: 0.85),
      );

      textPainter.paint(canvas, Offset(x, y));
    }
  }
}