import 'dart:math' as math;
import 'package:cyber_ops/services/music_service.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import 'components/drone_component.dart';
import 'components/nodo_component.dart';
import 'components/bala_component.dart';
import 'components/enemigo_dispara_component.dart';
import 'components/bala_enemiga_component.dart';

class Nivel04Game extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  final void Function(NodoComponent nodo) onNodoTocado;
  final void Function(int puntos, int vidas) onEstadoActualizado;
  final void Function() onJuegoTerminado;
  final void Function() onNivelCompletado;
  final void Function(bool activa, double cooldown, double duracion)?
  onHabilidadActualizada;

  int puntos = 0;
  int vidas = 3;
  bool juegoActivo = true;
  bool preguntaAbierta = false;

  late DroneComponent _dron;
  final List<NodoComponent> _nodos = [];
  final List<NodoComponent> _nodosAsegurados = [];
  final List<EnemigoDisparaComponent> _enemigos = [];
  final math.Random _random = math.Random();
  JoystickComponent? _joystick;

  static const double _duracionInvisibilidad = 4.0;
  static const int _nodosParaRecargar = 2;
  bool _dronInvisible = false;
  double _tiempoInvisibilidadRestante = 0;
  int _nodosParaCooldown = 0;

  bool get dronInvisible => _dronInvisible;
  double get cooldownInvisibilidad =>
      _nodosParaCooldown == 0 ? 0 : (_nodosParaCooldown / _nodosParaRecargar);
  double get tiempoInvisibilidadRestante => _tiempoInvisibilidadRestante;

  double _cooldownDisparo = 0;
  static const double _cooldownMaxDisparo = 0.25;

  // Bomba Neuronal
  double _cooldownBomba = 0;
  static const double _cooldownMaxBomba = 8.0;
  static const double _radioBomba = 300.0;
  bool _bombaNeuronalUsada = false;
  int _nodosComprometidosDesdeBomba = 0;

  double _tiempoDesdeSpawn = 0;
  double _intervaloAutoSpawn = 10.0; // Disminuye con dificultad
  static const double _intervaloMinimo = 6.0; // Mínimo intervalo

  // Dificultad progresiva
  int _nodosComprometidos = 0;

  Vector2 _posicionPuntero = Vector2.zero();

  final List<Map<String, dynamic>> _colaPreguntas = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  Nivel04Game({
    required this.onNodoTocado,
    required this.onEstadoActualizado,
    required this.onJuegoTerminado,
    required this.onNivelCompletado,
    this.onHabilidadActualizada,
  });

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

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _posicionPuntero = Vector2(size.x / 2, size.y / 2);
    _spawnDron();
    _spawnNodos();
    _spawnJoystick();
    // Spawn inicial de 4 enemigos
    for (int i = 0; i < 4; i++) {
      _spawnEnemigo();
    }
  }

  void _spawnDron() {
    _dron = DroneComponent(
      posicion: Vector2(size.x / 2, size.y / 2),
      onDisparar: _dispararEnDireccion,
    );
    add(_dron);
  }

  void _spawnNodos() {
    final posiciones = [
      Vector2(size.x * 0.18, size.y * 0.18),
      Vector2(size.x * 0.50, size.y * 0.12),
      Vector2(size.x * 0.82, size.y * 0.18),
      Vector2(size.x * 0.12, size.y * 0.45),
      Vector2(size.x * 0.38, size.y * 0.38),
      Vector2(size.x * 0.88, size.y * 0.45),
      Vector2(size.x * 0.25, size.y * 0.68),
      Vector2(size.x * 0.62, size.y * 0.38),
      Vector2(size.x * 0.50, size.y * 0.62),
      Vector2(size.x * 0.75, size.y * 0.68),
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
    final conSaltos = false; // 70% con saltos entre anillos
    Vector2 pos;

    if (conSaltos) {
      // Crear enemigo que salta entre anillos
      final radioMax = 250.0;
      final anguloInicial = _random.nextDouble() * math.pi * 2;
      pos =
          _dron.position +
          Vector2(
            math.cos(anguloInicial) * radioMax,
            math.sin(anguloInicial) * radioMax,
          );
    } else {
      // Crear enemigo normal en los bordes
      final lado = _random.nextInt(4);
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
    }

    final enemigo = EnemigoDisparaComponent(
      posicion: pos,
      onTocaDron: _enemigoTocaDron,
      onDisparar: (_) {},
    );

    if (conSaltos) {
      final radioMax = 250.0;
      enemigo.iniciarSaltos(_dron.position, radioMax);
    }

    enemigo.setObjetivo(_dron);
    _enemigos.add(enemigo);
    add(enemigo);
  }

  void _agregarBalaEnemiga(dynamic bala) {}

  void _balaEnemigaGolpeaDron() {
    if (!juegoActivo) return;
    vidas--;
    onEstadoActualizado(puntos, vidas);
    if (vidas <= 0) {
      juegoActivo = false;
      onJuegoTerminado();
    }
  }

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

  void activarBombaNeuronal() {
    if (!juegoActivo || preguntaAbierta) return;

    // Primera vez: permitir sin restricciones
    if (!_bombaNeuronalUsada) {
      _bombaNeuronalUsada = true;
      _usarBomba();
      return;
    }

    // Después de primera vez: requiere 1+ nodo comprometido
    if (_nodosComprometidosDesdeBomba < 1) return;

    _usarBomba();
    _nodosComprometidosDesdeBomba = 0;
  }

  void _usarBomba() {
    _cooldownBomba = _cooldownMaxBomba;

    // Crear explosión con onda expansiva
    add(
      _ExplosionBombaNeuronal(
        posicion: _dron.position.clone(),
        onOndaExpande: _eliminarEnemigosEnOndaExplosiva,
      ),
    );
  }

  void _eliminarEnemigosEnOndaExplosiva(Vector2 centro, double radioOnda) {
    for (final enemigo in _enemigos) {
      if (enemigo.eliminado) continue;
      final dist = centro.distanceTo(enemigo.position);
      if (dist < radioOnda) {
        enemigo.eliminado = true;
      }
    }
  }

  void _dispararHacia(Vector2 destino) {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;
    _cooldownDisparo = _cooldownMaxDisparo;
    _dron.apuntarHacia(destino);
    add(
      BalaComponent(
        posicion: _dron.puntaFlecha,
        direccion: _dron.direccionDisparo,
      ),
    );
  }

  void _dispararEnDireccion() {
    if (!juegoActivo || preguntaAbierta) return;
    if (_cooldownDisparo > 0) return;
    _cooldownDisparo = _cooldownMaxDisparo;
    MusicService().playDisparo();

    // Disparar en todas las direcciones (círculo completo)
    const int numBalas = 12; // 12 direcciones (cada 30°)
    for (int i = 0; i < numBalas; i++) {
      final angulo = (i / numBalas) * math.pi * 2;
      final direccion = Vector2(math.cos(angulo), math.sin(angulo));
      add(BalaComponent(posicion: _dron.puntaFlecha, direccion: direccion));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderConexionesNodos(canvas);
  }

  void _renderConexionesNodos(Canvas canvas) {
    if (_nodosAsegurados.length < 2) return;

    final paintGlow = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.12)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final paintLinea = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < _nodosAsegurados.length - 1; i++) {
      final a = _nodosAsegurados[i].position.toOffset();
      final b = _nodosAsegurados[i + 1].position.toOffset();
      canvas.drawLine(a, b, paintGlow);
      canvas.drawLine(a, b, paintLinea);
    }
  }

  void actualizarPuntero(Offset offset) =>
      _posicionPuntero = Vector2(offset.dx, offset.dy);
  void dispararHaciaOffset(Offset offset) =>
      _dispararHacia(Vector2(offset.dx, offset.dy));
  void dispararManual() => _dispararEnDireccion();

  void respuestaCorrecta(NodoComponent nodo, int puntosGanados) {
    nodo.marcarComprometido();
    puntos += puntosGanados;
    preguntaAbierta = false;
    resumeEngine();
    _dron.desbloquear();
    onEstadoActualizado(puntos, vidas);
    add(_ExplosionNodo(posicion: nodo.position.clone()));

    // Aumentar dificultad
    if (!_nodosAsegurados.contains(nodo)) {
      _nodosAsegurados.add(nodo);
    }
    _nodosComprometidos++;
    _aumentarDificultad();

    // Recargar bomba neuronal: cada nodo comprometido suma 1 a la cuenta
    _nodosComprometidosDesdeBomba++;

    // Spawnear 1-2 enemigos extra cuando comprometes un nodo
    if (_nodosComprometidos % 2 == 0) {
      _spawnEnemigo();
      _spawnEnemigo();
    }

    _verificarNivelCompletado();
  }

  void _aumentarDificultad() {
    // Reducir intervalo de spawn: 6.0 → 5.0 → 4.0 → 3.0 → 2.0
    _intervaloAutoSpawn = (6.0 - (_nodosComprometidos * 0.5)).clamp(
      _intervaloMinimo,
      6.0,
    );
  }

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
    if (comprometidos >= 6) {
      juegoActivo = false;

      onNivelCompletado();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!juegoActivo || preguntaAbierta) return;
    _dispararHacia(event.canvasPosition);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _dron.onKeyEvent(event, keysPressed);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        activarInvisibilidad();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        activarBombaNeuronal();
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!juegoActivo || preguntaAbierta) return;

    if (_cooldownDisparo > 0) _cooldownDisparo -= dt;
    if (_cooldownBomba > 0) _cooldownBomba -= dt;
    _tickInvisibilidad(dt);

    _tiempoDesdeSpawn += dt;
    if (_tiempoDesdeSpawn >= _intervaloAutoSpawn) {
      _tiempoDesdeSpawn = 0;
      _spawnEnemigo();
    }

    if (!_dron.bloqueado) _dron.apuntarHacia(_posicionPuntero);

    if (_joystick != null && !_joystick!.delta.isZero()) {
      _dron.joystickDelta = _joystick!.relativeDelta;
    } else {
      _dron.joystickDelta = Vector2.zero();
    }

    for (final nodo in _nodos) {
      if (nodo.estado == NodoEstado.seguro) {
        final dist = _dron.position.distanceTo(nodo.position);
        if (dist < DroneComponent.radio + NodoComponent.radio) {
          nodo.activarPregunta();
        }
      }
    }

    _enemigos.removeWhere((e) => e.eliminado);
  }
}

// Explosión sutil al comprometer un nodo
class _ExplosionNodo extends PositionComponent {
  static const double _duracion = 0.7;
  static const int _numParticulas = 10;
  static const Color _colorCyan = Color(0xFF06B6D4);
  static const Color _colorPurple = Color(0xFF6C63FF);

  final math.Random _rng = math.Random();
  final List<_ParticulaExplosion> _particulas = [];
  double _tiempo = 0;

  _ExplosionNodo({required Vector2 posicion})
    : super(position: posicion, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < _numParticulas; i++) {
      final angulo =
          (i / _numParticulas) * math.pi * 2 + _rng.nextDouble() * 0.4;
      final vel = 40.0 + _rng.nextDouble() * 55.0;
      _particulas.add(
        _ParticulaExplosion(
          vel: Vector2(math.cos(angulo) * vel, math.sin(angulo) * vel),
          radio: 1.5 + _rng.nextDouble() * 2.0,
          esCyan: _rng.nextBool(),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _tiempo += dt;
    if (_tiempo >= _duracion) {
      removeFromParent();
      return;
    }
    final progreso = _tiempo / _duracion;
    for (final p in _particulas) {
      p.pos += p.vel * ((1.0 - progreso) * dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final progreso = (_tiempo / _duracion).clamp(0.0, 1.0);
    final alpha = (1.0 - progreso).clamp(0.0, 1.0);
    final radioAnillo = 24.0 * progreso;
    final alphaAnillo = (alpha * (1.0 - progreso * 0.5)).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      radioAnillo + 4,
      Paint()
        ..color = _colorCyan.withValues(alpha: alphaAnillo * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.drawCircle(
      Offset.zero,
      radioAnillo,
      Paint()
        ..color = _colorCyan.withValues(alpha: alphaAnillo * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (progreso < 0.25) {
      final flashA = (1.0 - progreso / 0.25) * 0.5;
      canvas.drawCircle(
        Offset.zero,
        10.0 * (1.0 - progreso / 0.25),
        Paint()
          ..color = Colors.white.withValues(alpha: flashA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    for (final p in _particulas) {
      final r = p.radio * (1.0 - progreso * 0.5);
      final color = p.esCyan ? _colorCyan : _colorPurple;
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        r + 2,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        r,
        Paint()..color = color.withValues(alpha: alpha * 0.85),
      );
    }
  }
}

// Explosión de bomba neuronal con onda expansiva
class _ExplosionBombaNeuronal extends PositionComponent {
  static const double _duracion = 1.2;
  static const double _radioMaximo = 320.0;
  static const int _numAnilos = 4;
  static const int _numParticulas = 30;
  static const Color _colorCyan = Color(0xFF06B6D4);
  static const Color _colorPurple = Color(0xFF6C63FF);
  static const Color _colorPink = Color(0xFFEC4899);

  final math.Random _rng = math.Random();
  final List<_ParticulaExplosion> _particulas = [];
  final void Function(Vector2 centro, double radioOnda)? onOndaExpande;
  double _tiempo = 0;

  _ExplosionBombaNeuronal({required Vector2 posicion, this.onOndaExpande})
    : super(position: posicion, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Generar muchas partículas en todas direcciones
    for (int i = 0; i < _numParticulas; i++) {
      final angulo =
          (i / _numParticulas) * math.pi * 2 + _rng.nextDouble() * 0.3;
      final vel = 120.0 + _rng.nextDouble() * 180.0;
      final colores = [_colorCyan, _colorPurple, _colorPink];
      final esCyan = _rng.nextInt(3) == 0;

      _particulas.add(
        _ParticulaExplosion(
          vel: Vector2(math.cos(angulo) * vel, math.sin(angulo) * vel),
          radio: 2.0 + _rng.nextDouble() * 3.5,
          esCyan: esCyan,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _tiempo += dt;
    if (_tiempo >= _duracion) {
      removeFromParent();
      return;
    }
    final progreso = _tiempo / _duracion;

    // Llamar a callback conforme la onda se expande
    final radioOnda = _radioMaximo * progreso;
    onOndaExpande?.call(position, radioOnda);

    for (final p in _particulas) {
      p.pos += p.vel * ((1.0 - progreso) * dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final progreso = (_tiempo / _duracion).clamp(0.0, 1.0);
    final alpha = (1.0 - progreso).clamp(0.0, 1.0);
    final radioOndaPrincipal = _radioMaximo * progreso;

    // Ondas expansivas (múltiples capas)
    for (int i = 0; i < 5; i++) {
      final delayOnda = (i / 5) * 0.4;
      final radioOnda =
          _radioMaximo * ((progreso - delayOnda) * 1.2).clamp(0, 1.0);
      final alphaOnda =
          (alpha * (1.0 - ((progreso - delayOnda) * 1.2).clamp(0, 1.0))).clamp(
            0.0,
            1.0,
          );

      // Glow de la onda
      canvas.drawCircle(
        Offset.zero,
        radioOnda + 8,
        Paint()
          ..color = _colorCyan.withValues(alpha: alphaOnda * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );

      // Onda principal
      canvas.drawCircle(
        Offset.zero,
        radioOnda,
        Paint()
          ..color = _colorPink.withValues(alpha: alphaOnda * 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );

      // Onda interna (alternada)
      if (i % 2 == 0) {
        canvas.drawCircle(
          Offset.zero,
          radioOnda,
          Paint()
            ..color = _colorPurple.withValues(alpha: alphaOnda * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Flash central fuerte
    if (progreso < 0.15) {
      final flash = (1.0 - progreso / 0.15) * 0.7;
      canvas.drawCircle(
        Offset.zero,
        40.0 * (1.0 - progreso / 0.15),
        Paint()
          ..color = Colors.white.withValues(alpha: flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Núcleo brillante central
    canvas.drawCircle(
      Offset.zero,
      15.0 * (1.0 - progreso * 0.5),
      Paint()
        ..color = _colorPurple.withValues(alpha: alpha * 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(
      Offset.zero,
      8.0 * (1.0 - progreso * 0.5),
      Paint()..color = _colorCyan.withValues(alpha: alpha * 0.9),
    );

    // Renderizar partículas
    for (final p in _particulas) {
      final r = p.radio * (1.0 - progreso * 0.7);

      // Glow de partícula
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        r + 3.0,
        Paint()
          ..color = _colorPink.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Partícula principal
      final colorParticula = p.esCyan ? _colorCyan : _colorPurple;
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        r,
        Paint()..color = colorParticula.withValues(alpha: alpha * 0.9),
      );
    }
  }
}

//  CLASES AUXILIARES

class _ParticulaExplosion {
  Vector2 pos = Vector2.zero();
  final Vector2 vel;
  final double radio;
  final bool esCyan;
  _ParticulaExplosion({
    required this.vel,
    required this.radio,
    required this.esCyan,
  });
}
