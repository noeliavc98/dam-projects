import 'dart:math';

import 'package:cyber_ops/games/nivel_17/components/player.dart';
import 'package:cyber_ops/games/nivel_17/nivel17_game.dart';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:flutter/material.dart';

class SpywareEnemy extends PositionComponent
    with CollisionCallbacks, HasGameRef<Nivel17Game> {

  double speed = 320;
  double time = 0;
  bool isAttached = false;   // pegado al player
  double shakeTimer = 0;     // temporizador para sacudida
  Vector2 _offset = Vector2.zero(); // offset relativo al player cuando está pegado
  
  

  SpywareEnemy({
    required Vector2 position,
  }) {
    this.position = position;

    size = Vector2(50, 50);
  }

  @override
  Future<void> onLoad() async {
    add(
      CircleHitbox(),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    final player = gameRef.children.whereType<Player>().first;
    final playerCenter = player.position + player.size / 2;

    if (!isAttached) {
      // Avanzar horizontalmente siempre hacia la izquierda
      position.x -= speed * 0.7 * dt;

      // Seguimiento vertical hacia el player siempre
      final dir = (playerCenter - position);
      position.y += dir.normalized().y * speed * 0.8 * dt;

      // Solo pegarse si el player está expuesto
      if (!player.encrypted) {
        final dist = (playerCenter - position).length;
        if (dist < 30) {
          isAttached = true;
          _offset = position - playerCenter;
        }
      }

      if (position.x < -100) removeFromParent();
    } else {
      // Seguir al player pegado
      position = playerCenter + _offset;

      // Drenar privacidad
      gameRef.privacy = (gameRef.privacy - 12 * dt).clamp(0, 100);
      Future.microtask(() => gameRef.onStateChanged?.call());

      // Sacudida: si el player se mueve rápido lo sacude
      final playerSpeed = player.joystickDelta.length + player.getKeyboardDelta().length;
      if (playerSpeed > 0.8) {
        shakeTimer += dt;
        if (shakeTimer > 1.2) {
          removeFromParent();
          return;
        }
      } else {
        shakeTimer = 0;
      }

      // Si el player entra al túnel, destruirse
      if (player.encrypted) {
        removeFromParent();
      }
}
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final mainColor = isAttached ? Colors.redAccent : Colors.purpleAccent;

    if (isAttached) {
      final shakeX = sin(time * 30) * 2;
      final shakeY = cos(time * 30) * 2;
      canvas.translate(shakeX, shakeY);
    }

    // Radio de vigilancia
    final scanRadius = 34 + sin(time * 4) * 4;

    final scanPaint = Paint()
      ..color = mainColor.withValues(alpha: isAttached ? 0.18 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAttached ? 2.5 : 1.5;

    canvas.drawCircle(center, scanRadius, scanPaint);
    canvas.drawCircle(center, scanRadius * 0.68, scanPaint);

    // Glow
    final glowPaint = Paint()
      ..color = mainColor.withValues(alpha: isAttached ? 0.45 : 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, 23, glowPaint);

    // Forma de ojo
    final eyePath = Path()
      ..moveTo(center.dx - 22, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - 18, center.dx + 22, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + 18, center.dx - 22, center.dy)
      ..close();

    final eyeFill = Paint()
      ..color = const Color(0xFF050816)
      ..style = PaintingStyle.fill;

    final eyeStroke = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(eyePath, eyeFill);
    canvas.drawPath(eyePath, eyeStroke);

    // Iris
    final irisPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, irisPaint);

    // Pupila
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, pupilPaint);

    // Brillo
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center + const Offset(-3, -3), 2, highlightPaint);

    // Barrido de escáner
    final sweepAngle = time * 3;
    final sweepPaint = Paint()
      ..color = mainColor.withValues(alpha: isAttached ? 0.75 : 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      center + Offset(cos(sweepAngle), sin(sweepAngle)) * 28,
      sweepPaint,
    );
  }
}
