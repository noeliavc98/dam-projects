import 'dart:math';
import 'package:cyber_ops/games/nivel_17/nivel17_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum OrbType { small, medium, large }

class XpOrb extends PositionComponent with HasGameRef<Nivel17Game>, CollisionCallbacks {

  final OrbType type;
  double _time = 0;
  static const double _moveSpeed = 180.0;
  final double _waveOffset;

  static const Map<OrbType, int> _xpValues = {
    OrbType.small:  20,
    OrbType.medium: 40,
    OrbType.large:  80,
  };

  static const Map<OrbType, double> _radii = {
    OrbType.small:  15.0,
    OrbType.medium: 25.0,
    OrbType.large:  30.0,
  };

  static const Map<OrbType, Color> _colors = {
    OrbType.small:  Color(0xFF00E5FF),  // cian
    OrbType.medium: Color(0xFFFFD740),  // ámbar
    OrbType.large:  Color(0xFFFF4081),  // rosa
  };

  int get xpValue => _xpValues[type]!;
  double get _radius => _radii[type]!;
  Color get _color => _colors[type]!;

  XpOrb({required Vector2 position, required this.type})
    : _waveOffset = Random().nextDouble() * pi * 2 {
    final r = _radii[type]!;
    this.position = position;
    size = Vector2(r * 2, r * 2);
    anchor = Anchor.center;
  }

  static XpOrb spawn(Nivel17Game game) {
    final random = Random();
    final roll = random.nextDouble();

    // 60% small, 30% medium, 10% large
    final type = roll < 0.6
        ? OrbType.small
        : roll < 0.9
            ? OrbType.medium
            : OrbType.large;

    final x = game.size.x + 20.0 + random.nextDouble() * 100;
    final y = 60.0 + random.nextDouble() * (game.size.y - 120);

    return XpOrb(position: Vector2(x, y), type: type);
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Efecto magnético
    final player = gameRef.player;
    final playerCenter = player.position + player.size / 2;
    final dist = (playerCenter - position).length;

    if (dist < 80) {
      final dir = (playerCenter - position).normalized();
      position += dir * 300 * dt;
    }

    position.y += sin(_time * 2.5 + _waveOffset) * 60 * dt;

    position.x -= _moveSpeed * dt;

    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  void collect() {
    gameRef.score += xpValue;
    gameRef.onStateChanged?.call();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(_radius, _radius);
    final pulse = 1.0 + sin(_time * 4) * 0.12;

    // Glow
    final glowPaint = Paint()
      ..color = _color.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _radius);
    canvas.drawCircle(center, _radius * pulse * 1.4, glowPaint);

    // Cuerpo
    final bodyPaint = Paint()
      ..color = _color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _radius * pulse, bodyPaint);

    // Brillo interior
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center + Offset(-_radius * 0.25, -_radius * 0.25),
      _radius * 0.3,
      highlightPaint,
    );

    // Texto XP para medium y large
    if (type != OrbType.small) {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: '+$xpValue',
          style: TextStyle(
            color: Colors.white,
            fontSize: type == OrbType.large ? 8.0 : 6.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      textPainter.layout(maxWidth: _radius * 2);
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }
}