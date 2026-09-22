import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'drone_component.dart';
import 'bala_component.dart';
import '../../nivel_03/components/explosion_component.dart';
import 'package:cyber_ops/services/music_service.dart';

class EnemigoComponent extends CircleComponent
    with HasGameRef, CollisionCallbacks {
  static const double radio = 18.0;
  static const double velocidad = 70.0;

  DroneComponent? objetivo;
  bool eliminado = false;
  final void Function() onTocaDron;

  EnemigoComponent({
    required Vector2 posicion,
    required this.onTocaDron,
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

  void setObjetivo(DroneComponent dron) {
    objetivo = dron;
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
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BalaComponent) {
      other.removeFromParent();
      _eliminar();
    } else if (other is DroneComponent) {
      onTocaDron();
      _eliminar();
    }
  }

  void _eliminar() {
    eliminado = true;
    game.add(ExplosionComponent(posicion: position.clone()));
    MusicService().playExplosion();

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