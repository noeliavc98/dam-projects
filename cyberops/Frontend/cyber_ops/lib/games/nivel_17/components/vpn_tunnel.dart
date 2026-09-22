import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:cyber_ops/games/nivel_17/nivel17_game.dart';

class VPNTunnel extends PositionComponent with HasGameRef<Nivel17Game> {
  double time = 0;
  double difficulty = 0;
  double tunnelHeight = 220;
  double centerY = 250;

  VPNTunnel() {
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);

    time += dt;

    difficulty += dt * 0.12;

    final screenHeight = gameRef.size.y;
    final screenWidth = gameRef.size.x;

    size = Vector2(screenWidth + 1200, screenHeight);

    tunnelHeight = max(140.0, min(screenHeight * 0.42, 240.0 - difficulty * 4));

    final margin = max(28.0, screenHeight * 0.06);
    final minCenter = tunnelHeight / 2 + margin;
    final maxCenter = screenHeight - tunnelHeight / 2 - margin;

    final middle = (minCenter + maxCenter) / 2;
    final range = max(0.0, (maxCenter - minCenter) / 2);

    centerY = middle + sin(time * 0.45) * range;
  }

  bool isInsideTunnel(double x, double y) {
    final localX = x - position.x;
    final localY = y - position.y;

    final topBase = centerY - tunnelHeight / 2;

    final amplitude = 15 + difficulty * 3;
    final frequency = 0.008 + difficulty * 0.003;

    final wave =
        sin((localX * frequency) + time * 2) * amplitude +
        sin((localX * 0.02) + time * 3) * 10;

    final top = topBase + wave;
    final bottom = top + tunnelHeight;

    return localY > top && localY < bottom;
  }


  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final path = Path();

    final width = size.x;

    final double height = tunnelHeight;
    final double baseY = centerY - height / 2;

    final double amplitude = 15 + difficulty * 3;
    final double frequency = 0.008 + difficulty * 0.003;
    

    path.moveTo(0, baseY);

    for (double x = 0.0; x <= width; x += 20.0) {

      final double y =
          baseY +

          // Onda principal
          sin((x * frequency) + time * 2) * amplitude +

          // Microondas secundarias
          sin((x * 0.02) + time * 3) * 10;

      path.lineTo(x, y);
    }

    for (double x = width; x >= 0.0; x -= 20.0) {

      final double y =
          baseY +
          height +

          sin((x * frequency) + time * 2) * amplitude +

          sin((x * 0.02) + time * 3) * 10;

      path.lineTo(x, y);
    }

    path.close();

    final Paint fillPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        6,
      );

    canvas.drawPath(path, borderPaint);

  }
}
