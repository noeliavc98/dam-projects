import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class BalaComponent extends CircleComponent with HasGameRef, CollisionCallbacks {
  static const double radio = 5.0;
  static const double velocidad = 350.0;
  final Vector2 direccion;

  BalaComponent({
    required Vector2 posicion,
    required this.direccion,
  }) : super(
          radius: radio,
          position: posicion,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF06B6D4),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direccion * velocidad * dt;

    // Eliminar si sale de pantalla
    final size = gameRef.size;
    if (position.x < 0 || position.x > size.x ||
        position.y < 0 || position.y > size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset(radio, radio),
      radio + 3,
      Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }
}