import 'dart:math' as math;
import 'package:cyber_ops/services/music_service.dart';
import 'package:cyber_ops/games/nivel_01/components/bala_component.dart';
import 'package:cyber_ops/games/nivel_01/components/drone_component.dart';
import 'package:cyber_ops/games/nivel_01/components/nodo_component.dart';
import 'package:cyber_ops/games/nivel_03/components/bala_enemiga_component.dart';
import 'package:cyber_ops/games/nivel_03/components/enemigo_dispara_component.dart';
import 'package:cyber_ops/games/nivel_05/components/enemigo_hacia_nodo_component.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Nivel05Game extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  // ── CALLBACKS HACIA FLUTTER ──────────────────────────────────────────────────
  final void Function(NodoComponent nodo) onNodoTocado;
  final void Function(int puntos, int vidas) onEstadoActualizado;
  final void Function() onJuegoTerminado;
  final void Function() onNivelCompletado;
  final void Function() onPrimerFalloPregunta;

  // ── ESTADO DEL JUEGO ─────────────────────────────────────────────────────────
  int puntos = 0;
  int vidas = 3;
  bool juegoActivo = true;
  bool preguntaAbierta = false;
  int _erroresEnPreguntas = 0;
  int _nodoActualIndex = 0;
  bool _nodoEnCooldown = false;
  double _tiempoTranscurrido = 0;

  // ── COMPONENTES ──────────────────────────────────────────────────────────────
  late DroneComponent _dron;
  final List<NodoComponent> _nodos = [];
  final List<EnemigoDisparaComponent> _enemigosDron = [];
  final List<EnemigoHaciaNodoComponent> _enemigosNodo =
      []; //Dos tipos de enemigo
  final math.Random _random = math.Random();
  JoystickComponent? _joystick;
  //Frecuencia de aparición de enemigos
  double _timerSpawnEnemigo = 0;
  double _intervaloSpawn = 8.0; // empieza spawneando cada 8 segundos
  static const double _intervaloMinimo = 3.0; // nunca menos de 3 segundos

  // ── DISPARO ──────────────────────��───────────────────────────────────────────
  double _cooldownDisparo = 0;
  static const double _cooldownMaxDisparo = 0.25;

  // ── POSICIÓN DEL PUNTERO EN TIEMPO REAL ──────────────────────────────────────
  Vector2 _posicionPuntero = Vector2.zero();

  // ── COLA DE PREGUNTAS SIN REPETIR ────────────────────────────────────────────
  final List<Map<String, dynamic>> _colaPreguntas = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  // ── CONTROL DE VISIBILIDAD POR NODO ────────────────────────────────────────────
  final Map<NodoComponent, Timer> _timersVisibilidad = {};
  final Map<NodoComponent, bool> _nodoVisible = {};

  static const double _duracionVisible = 4.0;
  static const double _duracionOculto = 3.0;
  static const double _velocidadMaxNodo =
      160.0; //tope de velocidad de los nodos

  Nivel05Game({
    required this.onNodoTocado,
    required this.onEstadoActualizado,
    required this.onJuegoTerminado,
    required this.onNivelCompletado,
    required this.onPrimerFalloPregunta,
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
    _spawnEnemigosIniciales();
  }

  //Método para actualizar el color del nodo activo
  void _actualizarNodoActivo() {
    for (final nodo in _nodos) {
      if (nodo.estado == NodoEstado.comprometido) {
        continue; // los completados no se tocan
      }
      if (nodo.estado == NodoEstado.alerta) continue;
      if (nodo.id == _nodoActualIndex + 1) {
        nodo.estado = NodoEstado.vulnerable; // el activo: naranja
        nodo.actualizarColor();
      } else {
        nodo.estado = NodoEstado.seguro; // los demás: apagado
        nodo.actualizarColor();
      }
    }

    final nodoActivo = _nodos.firstWhere(
      (n) => n.id == _nodoActualIndex + 1,
      orElse: () => _nodos.first,
    );
    _timersVisibilidad[nodoActivo] = Timer(
      _duracionVisible,
      onTick: () => _ocultarNodo(nodoActivo),
    );
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

    posiciones.shuffle();

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
    _actualizarNodoActivo();

    _iniciarVisibilidadNodos();
  }

  void _spawnJoystick() {
    _joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20,
        paint: Paint()..color = const Color(0xFF06B6D4).withOpacity(0.8),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFF0D0D2B).withOpacity(0.7),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(_joystick!);
  }

  void _spawnEnemigo() {
    final pos = _posicionAleatoriaBorde();
    final enemigo = EnemigoDisparaComponent(
      posicion: pos,
      onTocaDron: _enemigoTocaDron,
      onDisparar: _agregarBalaEnemiga,
    );
    enemigo.setObjetivo(_dron);
    _enemigosDron.add(enemigo);
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

  void _spawnEnemigosIniciales() {
    // 2 enemigos que persiguen el nodo
    for (int i = 0; i < 2; i++) {
      final pos = _posicionAleatoriaBorde();
      final enemigo = EnemigoHaciaNodoComponent(
        posicion: pos,
        onTocaDron: _enemigoTocaDron,
        onDisparar: _agregarBalaEnemiga,
      );
      final nodoActivo = _nodos.firstWhere((n) => n.id == _nodoActualIndex + 1);
      enemigo.setObjetivo(nodoActivo);
      _enemigosNodo.add(enemigo);
      add(enemigo);
    }
    // 2 enemigos que persiguen al dron
    for (int i = 0; i < 2; i++) {
      final pos = _posicionAleatoriaBorde();
      final enemigo = EnemigoDisparaComponent(
        posicion: pos,
        onTocaDron: _enemigoTocaDron,
        onDisparar: _agregarBalaEnemiga,
      );
      enemigo.setObjetivo(_dron);
      _enemigosDron.add(enemigo);
      add(enemigo);
    }
  }

  Vector2 _posicionAleatoriaBorde() {
    final lado = _random.nextInt(4);
    switch (lado) {
      case 0:
        return Vector2(_random.nextDouble() * size.x, 80);
      case 1:
        return Vector2(_random.nextDouble() * size.x, size.y - 80);
      case 2:
        return Vector2(20, _random.nextDouble() * size.y);
      default:
        return Vector2(size.x - 20, _random.nextDouble() * size.y);
    }
  }

  // ── VISIBILIDAD DE LOS NODOS (APARECEN Y DESAPARECEN) ───────────────────────────────────────────────────────────────────
  void _iniciarVisibilidadNodos() {
    for (final nodo in _nodos) {
      _nodoVisible[nodo] = true;
    }
  }

  void _mostrarNodo(NodoComponent nodo) {
    if (nodo.estado == NodoEstado.comprometido ||
        nodo.estado == NodoEstado.alerta) {
      return;
    }

    nodo.bloqueado = false;
    nodo.actualizarColor();

    final random = math.Random();
    nodo.position = Vector2(
      random.nextDouble() * (size.x - NodoComponent.radio * 2) +
          NodoComponent.radio,
      random.nextDouble() * (size.y - NodoComponent.radio * 2 - 160) +
          NodoComponent.radio +
          100,
    );

    nodo.opacity = 0.4;
    _nodoVisible[nodo] = true;
    _timersVisibilidad[nodo] = Timer(
      _duracionVisible,
      onTick: () => _ocultarNodo(nodo),
    );
  }

  void _ocultarNodo(NodoComponent nodo) {
    if (nodo.estado == NodoEstado.comprometido ||
        nodo.estado == NodoEstado.alerta) {
      return;
    }

    nodo.bloqueado = true;
    nodo.opacity = 0.0;

    _nodoVisible[nodo] = false;
    _timersVisibilidad[nodo] = Timer(
      _duracionOculto,
      onTick: () => _mostrarNodo(nodo),
    );
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
    _verificarNivelCompletado();
    _nodoActualIndex++;
    _actualizarNodoActivo();
    onEstadoActualizado(puntos, vidas);
  }

  // ── RESPUESTA INCORRECTA ──────────────────────────────────────────────────
  void respuestaIncorrecta(NodoComponent nodo) {
    nodo.marcarAlerta();
    preguntaAbierta = false;
    _nodoEnCooldown = true;
    resumeEngine();
    _dron.desbloquear();
    _spawnEnemigo();
    //Solo se permite una respuesta incorrecta
    _erroresEnPreguntas++;
    if (_erroresEnPreguntas == 1) {
      onPrimerFalloPregunta();
    } else if (_erroresEnPreguntas >= 2) {
      juegoActivo = false;
      onJuegoTerminado();
      return;
    }
    nodo.marcarAlerta();
    _nodoActualIndex++;
    _actualizarNodoActivo();

    _nodoEnCooldown = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      nodo.resetPregunta();
      _nodoEnCooldown = false;
    });

    onEstadoActualizado(puntos, vidas);
    if (vidas <= 0) {
      juegoActivo = false;
      onJuegoTerminado();
    }
  }

  // ── LÓGICA INTERNA ────────────────────────────────────────────────────────────

  void _onNodoContacto(NodoComponent nodo) {
    if (!juegoActivo || preguntaAbierta) return;
    //Ignorar si no es el nodo activo
    if (nodo.id != _nodoActualIndex + 1) {
      nodo.marcarAlerta();
      Future.delayed(const Duration(milliseconds: 400), () {
        // Resetear al estado anterior si no estaba comprometido
        if (nodo.estado != NodoEstado.comprometido) {
          nodo.estado = NodoEstado.seguro;
        }
      });
      return;
    }
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
    final acertados = _nodos
        .where((n) => n.estado == NodoEstado.comprometido)
        .length;
    if (acertados >= 5) {
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

    //Actualizar timers de visibilidad
    for (final timer in _timersVisibilidad.values) {
      timer.update(dt);
    }

    //Aumento progresivo de la velocidad de los nodos
    _tiempoTranscurrido += dt;
    if (_tiempoTranscurrido % 3 < dt) {
      // cada 3 segundos
      for (final nodo in _nodos) {
        if (nodo.estado != NodoEstado.comprometido &&
            nodo.estado != NodoEstado.alerta) {
          nodo.velocidad *= 1.2; // aumenta un 20% cada 3 segundos
          if (nodo.velocidad.length > _velocidadMaxNodo) {
            nodo.velocidad = nodo.velocidad.normalized() * _velocidadMaxNodo;
          }
        }
      }
    }
    // ── Spawn progresivo de enemigos ──
    _timerSpawnEnemigo += dt;
    if (_timerSpawnEnemigo >= _intervaloSpawn) {
      _timerSpawnEnemigo = 0;
      _spawnEnemigo();
      // cada vez que spawnea, el intervalo se reduce un poco
      _intervaloSpawn = (_intervaloSpawn - 0.5).clamp(_intervaloMinimo, 8.0);
    }

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
      if (nodo.estado == NodoEstado.vulnerable ||
          nodo.estado == NodoEstado.alerta) {
        if (_nodoEnCooldown) continue;
        final dist = _dron.position.distanceTo(nodo.position);
        if (dist < DroneComponent.radio + NodoComponent.radio) {
          nodo.activarPregunta();
        }
      }
    }

    // Limpiar enemigos eliminados
    _enemigosDron.removeWhere((e) => e.eliminado);
    _enemigosNodo.removeWhere((e) => e.eliminado);
  }
}

// ── LÍNEAS DE RED ─────────────────────────────────────────────────────────────

class _RedLines extends Component {
  final List<NodoComponent> nodos;
  _RedLines({required this.nodos});

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.12)
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
