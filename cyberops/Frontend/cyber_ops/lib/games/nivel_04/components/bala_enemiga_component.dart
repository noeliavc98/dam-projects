import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'drone_component.dart';

class BalaEnemigaComponent extends CircleComponent
    with HasGameReference, CollisionCallbacks {
  static const double radio = 2.0;
  static const double velocidad = 250.0;
  final Vector2 direccion;

  void Function()? onGolpearDron;

  static const Color _colorDorado = Color(0xFFFFD700);

  BalaEnemigaComponent({required Vector2 posicion, required this.direccion})
    : super(
        radius: radio,
        position: posicion,
        anchor: Anchor.center,
        paint: Paint()..color = _colorDorado,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is DroneComponent) {
      removeFromParent();
      onGolpearDron?.call();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direccion * velocidad * dt;
    final size = game.size;
    if (position.x < 0 ||
        position.x > size.x ||
        position.y < 0 ||
        position.y > size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Glow pequeño alrededor
    canvas.drawCircle(
      Offset(radio, radio),
      radio + 3,
      Paint()
        ..color = _colorDorado.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Círculo sólido
    canvas.drawCircle(
      Offset(radio, radio),
      radio,
      Paint()..color = _colorDorado,
    );

    // Borde fino
    canvas.drawCircle(
      Offset(radio, radio),
      radio,
      Paint()
        ..color = const Color(0xFFFFED4E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}
