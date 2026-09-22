import 'dart:math';
import 'package:cyber_ops/games/nivel_17/components/static_obstacle.dart';
import 'package:cyber_ops/games/nivel_17/components/vpn_tunnel.dart';
import 'package:cyber_ops/games/nivel_17/components/xp_orb.dart';
import 'package:cyber_ops/games/nivel_17/nivel17_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Player extends PositionComponent
    with CollisionCallbacks, HasGameRef<Nivel17Game>, KeyboardHandler {

  Vector2 _direccion = Vector2.zero();
  Vector2 joystickDelta = Vector2.zero();

  Vector2 getKeyboardDelta() => _direccion;
  
  final Map<String, String> encryptedLabels = {
    'DNI': 'AES',
    'TARJETA': '••••',
    'EMAIL': '0x7F',
    'UBICACIÓN': 'HASH',
  };

  final Map<String, String> visibleLabels = {
    'DNI': 'DNI',
    'TARJETA': 'VISA',
    'EMAIL': 'EMAIL',
    'UBICACIÓN': 'GPS',
  };

  bool encrypted = false;

  double time = 0;
  double speed = 220;

  double verticalVelocity = 0;
  double lastY = 0;
  final List<double> trailY = [];

  Player() {
    position = Vector2(100, 300);
    size = Vector2(50, 50);
  }

  @override
  void update(double dt) {
    verticalVelocity = position.y - lastY;
    lastY = position.y;

    trailY.insert(0, position.y);

    if (trailY.length > 20) {
      trailY.removeLast();
    }

    super.update(dt);

    time += dt;

    final input = _direccion + joystickDelta;
    if (input.length > 1) input.normalize();

    position += input * speed * dt;

    for (final barrier in gameRef.children.whereType<StaticObstacle>()) {
      final barrierRect = barrier.rect;

      final playerLeft = position.x;
      final playerRight = position.x + size.x;
      final playerTop = position.y;
      final playerBottom = position.y + size.y;

      final overlapX = min(playerRight, barrierRect.right) - max(playerLeft, barrierRect.left);
      final overlapY = min(playerBottom, barrierRect.bottom) - max(playerTop, barrierRect.top);

      // Solo actuar si hay solapamiento real en ambos ejes
      if (overlapX <= 0 || overlapY <= 0) continue;

      barrier.onPlayerContact();

      if (overlapX < overlapY) {
        if (position.x < barrierRect.left) {
          position.x -= overlapX + 2;
        } else {
          position.x += overlapX + 2;
        }
      } else {
        if (position.y < barrierRect.top) {
          position.y -= overlapY + 2;
        } else {
          position.y += overlapY + 2;
        }
      }
    }

    position.x = position.x.clamp(0, gameRef.size.x - size.x);
    position.y = position.y.clamp(0, gameRef.size.y - size.y);


    // Estado VPN
    final tunnel = gameRef.children.whereType<VPNTunnel>().first;

    encrypted = tunnel.isInsideTunnel(
      position.x + size.x / 2,
      position.y + size.y / 2,
    );
  }

  @override
  Future<void> onLoad() async {
    lastY = position.y;

    add(
      CircleHitbox(),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();

    final center = Offset(size.x / 2, size.y / 2);
    canvas.translate(center.dx, center.dy);

    // Animación flotante
    final pulse = 1 + sin(time * 4) * 0.08;
    canvas.scale(pulse);

    //Estela del player
    final trailPath = Path();

    for (int i = 0; i < trailY.length; i++) {
      final x = -(i * 10.0);
      final y = (trailY[i] - position.y) * 0.2;

      if (i == 0) {
        trailPath.moveTo(x, y);
      } else {
        trailPath.lineTo(x, y);
      }
    }

    final baseColor = encrypted ? Colors.blueAccent : Colors.redAccent;

    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [
          baseColor.withOpacity(0.0),
          baseColor.withOpacity(0.1),
          baseColor.withOpacity(0.2),
          baseColor.withOpacity(0.6),
        ],
      ).createShader(
        const Rect.fromLTWH(-200, -50, 200, 100),
      );

    canvas.drawPath(trailPath, trailPaint);

    // Glow
    final glowPaint = Paint()
      ..color = encrypted
          ? Colors.blueAccent.withOpacity(0.25)
          : Colors.redAccent.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(Offset.zero, 22, glowPaint);

    final dataColor = encrypted ? Colors.cyanAccent : Colors.redAccent;
    final remainingData = gameRef.protectedData;

    final labels = remainingData
        .map((data) => encrypted
            ? encryptedLabels[data] ?? data
            : visibleLabels[data] ?? data)
        .toList();
    
    if (labels.isEmpty) {
      canvas.restore();
      return;
    }

    // Enlaces entre fragmentos
    final linkPaint = Paint()
      ..color = dataColor.withOpacity(0.45)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Núcleo central
    final coreGlowPaint = Paint()
      ..color = dataColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset.zero, 13, coreGlowPaint);

    final corePaint = Paint()
      ..color = const Color(0xFF050816)
      ..style = PaintingStyle.fill;

    final coreBorderPaint = Paint()
      ..color = dataColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawCircle(Offset.zero, 10, corePaint);
    canvas.drawCircle(Offset.zero, 10, coreBorderPaint);

    // Calcular posiciones orbitando
    final List<Offset> points = [];

    for (int i = 0; i < labels.length; i++) {
      final angle = time * 1.6 + i * (pi * 2 / labels.length);
      final radius = 25 + sin(time * 2 + i) * 3;

      points.add(
        Offset(
          cos(angle) * radius,
          sin(angle) * radius,
        ),
      );
    }

    // Líneas al núcleo
    for (final point in points) {
      canvas.drawLine(Offset.zero, point, linkPaint);
    }

    // Texto orbitando
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final labelBgPaint = Paint()
        ..color = const Color(0xFF050816).withOpacity(0.82)
        ..style = PaintingStyle.fill;

      final labelBorderPaint = Paint()
        ..color = dataColor.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: point,
          width: encrypted ? 30 : 34,
          height: 16,
        ),
        const Radius.circular(5),
      );

      canvas.drawRRect(rect, labelBgPaint);
      canvas.drawRRect(rect, labelBorderPaint);

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: dataColor,
          fontSize: encrypted ? 7.5 : 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      );

      textPainter.layout(maxWidth: 32);
      textPainter.paint(
        canvas,
        point - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Indicador del estado del núcleo
    final statePaint = Paint()
      ..color = encrypted ? Colors.white : dataColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 3.5, statePaint);

    canvas.restore();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _direccion = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      _direccion.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      _direccion.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      _direccion.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      _direccion.x += 1;
    }

    return true;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other,
  ) {
    if (other is XpOrb) {
      other.collect();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
