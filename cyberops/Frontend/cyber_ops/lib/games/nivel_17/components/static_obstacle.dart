import 'dart:math';
 
import 'package:cyber_ops/games/nivel_17/components/vpn_tunnel.dart';
import 'package:cyber_ops/games/nivel_17/nivel17_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
 
/// Barrera que se mueve de derecha a izquierda a la misma velocidad
/// que los enemigos (250 px/s). Puede estar dentro o fuera del túnel,
/// forzando al jugador a esquivarla.
class StaticObstacle extends PositionComponent
    with HasGameRef<Nivel17Game>, CollisionCallbacks {
 
  static const double _speed = 250.0;
  static const double _privacyDamage = 15.0;
  static const double _damageCooldown = 1.2;

  static const double blockW = 50.0;
  static const double blockH = 170.0;
 
  /// true  → bloquea dentro del túnel (color ámbar)
  /// false → bloquea fuera del túnel  (color rojo)
  final bool insideTunnel;
 
  double _damageCooldownTimer = 0;
  double _time = 0;

  Rect get rect => Rect.fromLTWH(
    position.x - 8,
    position.y - size.y / 2 - 6,
    size.x + 16,
    size.y + 12,
  );
 
  StaticObstacle({
    required Vector2 position,
    required this.insideTunnel,
    required Vector2 blockSize,
  }) {
    this.position = position;
    size = blockSize;
    anchor = Anchor.centerLeft;
  }
 
  // ── Factory ────────────────────────────────────────────────────────────────
 
  /// Genera una barrera con posición Y válida según [insideTunnel].
  /// Siempre aparece por la derecha, fuera del viewport.
  static StaticObstacle? spawn({
    required Nivel17Game game,
    required bool insideTunnel,
    double? forceY,
    int maxAttempts = 40,
  }) {
    final random = Random();
    final tunnel = game.children.whereType<VPNTunnel>().firstOrNull;
    if (tunnel == null) return null;
 
    final w = StaticObstacle.blockW;
    final h = StaticObstacle.blockH;
 
    final spawnX = game.size.x + 60;
    final y = forceY ?? (h / 2 + random.nextDouble() * (game.size.y - h));

    return StaticObstacle(
      position: Vector2(spawnX, y),
      insideTunnel: insideTunnel,
      blockSize: Vector2(w, h),
    );
  }
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
 
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
 
  @override
  void update(double dt) {
    super.update(dt);
 
    _time += dt;
 
    if (_damageCooldownTimer > 0) _damageCooldownTimer -= dt;
 
    position.x -= _speed * dt;
 
    if (position.x < -size.x - 20) {
      removeFromParent();
    }
  }
 
  /// Llamado desde Player.onCollisionStart
  void onPlayerContact() {
    if (_damageCooldownTimer > 0) return;
    _damageCooldownTimer = _damageCooldown;
    gameRef.privacy = (gameRef.privacy - _privacyDamage).clamp(0, 100);
    gameRef.onStateChanged?.call();
  }
 
  // ── Render ─────────────────────────────────────────────────────────────────
 
  @override
  void render(Canvas canvas) {
    super.render(canvas);
 
    final Color accent = const Color(0xFFFF3D71);
 
    final w = size.x;
    final h = size.y;
 
    // ── Glow exterior ──
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(Rect.fromLTWH(-4, -4, w + 8, h + 8), glowPaint);
 
    // ── Cuerpo del bloque ──
    final bgPaint = Paint()
      ..color = const Color(0xFF0A0E2A)
      ..style = PaintingStyle.fill;
 
    final borderPaint = Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
 
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);
 
    // ── Patrón de líneas diagonales internas (textura de barrera) ──
    final stripePaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt;
 
    canvas.save();
    canvas.clipRRect(rrect);
    const stripeGap = 14.0;
    final stripeCount = ((w + h) / stripeGap).ceil() + 2;
    for (int i = 0; i < stripeCount; i++) {
      final x = i * stripeGap - h;
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), stripePaint);
    }
    canvas.restore();
 
    // ── Icono central ──
    final iconPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
 
    final cx = w / 2;
    final cy = h / 2;
 
    if (insideTunnel) {
      // Triángulo de advertencia
      final triPath = Path()
        ..moveTo(cx, cy - 7)
        ..lineTo(cx + 7, cy + 5)
        ..lineTo(cx - 7, cy + 5)
        ..close();
      canvas.drawPath(triPath, iconPaint);
      canvas.drawCircle(
        Offset(cx, cy + 2),
        1.5,
        Paint()..color = accent,
      );
    } else {
      // X de bloqueo
      canvas.drawLine(Offset(cx - 6, cy - 6), Offset(cx + 6, cy + 6), iconPaint);
      canvas.drawLine(Offset(cx + 6, cy - 6), Offset(cx - 6, cy + 6), iconPaint);
    }
 
    // ── Pulso en borde izquierdo (dirección de avance) ──
    final pulseOpacity = (sin(_time * 5) * 0.5 + 0.5) * 0.6;
    final pulsePaint = Paint()
      ..color = accent.withValues(alpha: pulseOpacity)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
 
    canvas.drawLine(Offset(0, 4), Offset(0, h - 4), pulsePaint);
  }
}