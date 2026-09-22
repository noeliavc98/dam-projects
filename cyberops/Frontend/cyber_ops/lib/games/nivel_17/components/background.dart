import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Background extends Component {
  final random = Random();

  final List<Offset> stars = [];

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 100; i++) {
      stars.add(
        Offset(
          random.nextDouble() * 3000,
          random.nextDouble() * 1000,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (int i = 0; i < stars.length; i++) {
      stars[i] = Offset(
        stars[i].dx - 200 * dt,
        stars[i].dy,
      );

      // Reiniciar estrella cuando sale de pantalla
      if (stars[i].dx < 0) {
        stars[i] = Offset(
          3000,
          random.nextDouble() * 1000,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fondo oscuro
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 3000, 2000),
      Paint()..color = const Color(0xFF050816),
    );

    // PartÃ­culas digitales
    final starPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.7);

    for (final star in stars) {
      canvas.drawCircle(
        star,
        2,
        starPaint,
      );
    }
  }
}
