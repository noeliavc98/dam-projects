import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../nivel_01/components/drone_component.dart';

class BalaEnemigaComponent extends CircleComponent
    with HasGameReference, CollisionCallbacks {
  static const double radio = 5.0;
  static const double velocidad = 250.0;
  final Vector2 direccion;

  /// Callback invocado cuando la bala impacta al dron.
  void Function()? onGolpearDron;

  BalaEnemigaComponent({
    required Vector2 posicion,
    required this.direccion,
  }) : super(
    radius: radio,
    position: posicion,
    anchor: Anchor.center,
    paint: Paint()..color = const Color(0xFFEC4899),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
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

    // Eliminar si sale de pantalla
    final size = game.size;
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
        ..color = const Color(0xFFEC4899).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }
}
