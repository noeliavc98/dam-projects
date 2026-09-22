import 'dart:math' as math;

import 'package:cyber_ops/games/nivel_01/components/bala_component.dart';
import 'package:cyber_ops/games/nivel_01/components/drone_component.dart';
import 'package:cyber_ops/games/nivel_03/components/bala_enemiga_component.dart';
import 'package:cyber_ops/games/nivel_03/components/explosion_component.dart';
import 'package:cyber_ops/services/music_service.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class EnemigoHaciaNodoComponent extends CircleComponent
    with HasGameRef, CollisionCallbacks {
  static const double radio = 18.0;
  static const double velocidad = 70.0;

  PositionComponent? objetivo;
  bool eliminado = false;
  final void Function() onTocaDron;
  final void Function(BalaEnemigaComponent bala) onDisparar;

  // Control de disparo
  double _tiempoDesdeDisparo = 0;
  static const double _intervaloDisparo = 2.0;
  final math.Random _random = math.Random();

  EnemigoHaciaNodoComponent({
    required Vector2 posicion,
    required this.onTocaDron,
    required this.onDisparar,
  }) : super(
         radius: radio,
         position: posicion,
         anchor: Anchor.center,
         paint: Paint()..color = const Color(0xFFEC4899).withValues(alpha: 0.3),
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  void setObjetivo(PositionComponent objetivo) {
    this.objetivo = objetivo;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (eliminado || objetivo == null) return;

    // Perseguir al dron
    final dir = (objetivo!.position - position);
    if (dir.length > 1) {
      dir.normalize();
      position += dir * velocidad * dt;
    }

    // Disparo periódico
    _tiempoDesdeDisparo += dt;
    if (_tiempoDesdeDisparo >= _intervaloDisparo) {
      _tiempoDesdeDisparo = 0;
      _disparar();
    }
  }

  void _disparar() {
    // Dirección hacia el dron
    final dir = (objetivo!.position - position);
    if (dir.length > 1) {
      dir.normalize();

      final bala = BalaEnemigaComponent(posicion: position, direccion: dir);
      onDisparar(bala);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BalaComponent) {
      other.removeFromParent();
      _eliminar();
    } else if (other is DroneComponent) {
      // El dron invisible no puede ser tocado por enemigos
      if (other.invisible) return;
      onTocaDron();
      _eliminar();
    }
  }

  void _eliminar() {
    eliminado = true;
    MusicService().playExplosion();
    // Lanzar explosión de partículas en la posición del enemigo
    game.add(ExplosionComponent(posicion: position.clone()));
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(
      Offset(radio, radio),
      radio,
      Paint()
        ..color = const Color(0xFFEC4899)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Icono
    final tp = TextPainter(
      text: const TextSpan(
        text: '⚠',
        style: TextStyle(fontSize: 16, color: Color(0xFFEC4899)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(radio - tp.width / 2, radio - tp.height / 2));
  }
}
