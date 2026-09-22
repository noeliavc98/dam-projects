import 'dart:math';
import 'package:cyber_ops/games/nivel_17/nivel17_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum HackerState { idle, hooking, retracting }

class HackerEnemy extends PositionComponent with HasGameRef<Nivel17Game> {

  static const double _moveSpeed = 90.0;       // más lento que el player (220)
  static const double _hookSpeed = 600.0;       // velocidad de extensión del gancho
  static const double _cooldown = 3.0;          // espera entre lanzamientos
  double get _hookTriggerDistance => gameRef.size.y * 0.6;

  String? _stolenLabel;          // dato que está volando
  Vector2 _stolenPos = Vector2.zero(); // posición actual del dato en vuelo
  bool _showStolenLabel = false;

  late Sprite _sprite;

  HackerState _state = HackerState.idle;
  double _cooldownTimer = 1.5;                  // espera inicial antes del primer gancho
  double _time = 0;

  bool _initialized = false;

  // Gancho
  Vector2 _hookPos = Vector2.zero();            // posición actual de la punta
  Vector2 _hookTarget = Vector2.zero();         // posición del player al lanzar
  bool _hookDidSteal = false;

  final List<String> _capturedData = [];

  HackerEnemy() {
    size = Vector2(90, 90);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    _sprite = await Sprite.load('hacker.png');
  }

  Vector2 get _bodyCenter => Vector2(position.x, position.y);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    //Posición del hacker
    if (!_initialized) {
      _initialized = true;
      position = Vector2(
        gameRef.size.x * 0.5,
        gameRef.size.y - size.y / 2 - 10, // pegado al borde inferior visible
      );
      _hookPos = Vector2(position.x, position.y);
    }

    final player = gameRef.player;
    final playerCenter = player.position + player.size / 2;

    // — Movimiento lateral siguiendo al player, más lento —
    final dx = playerCenter.x - position.x;
    if (dx.abs() > 5.0) {
      final moveX = dx.sign * _moveSpeed * dt;
      position.x = (position.x + moveX).clamp(size.x / 2, gameRef.size.x - size.x / 2);
    }

    // — Máquina de estados —
    switch (_state) {
      case HackerState.idle:
        _hookPos = _bodyCenter;
        _cooldownTimer -= dt;

        final distToPlayer = (playerCenter - position).length;
        final playerExposed = !player.encrypted;

        if (_cooldownTimer <= 0 && playerExposed && distToPlayer <= _hookTriggerDistance) {
          // Lanzar gancho
          _state = HackerState.hooking;
          _hookTarget = playerCenter.clone();
          _hookDidSteal = false;
        }
        break;

      case HackerState.hooking:
        // Mover la punta del gancho hacia el target
        final dir = (_hookTarget - _hookPos);
        if (dir.length <= _hookSpeed * dt) {
          // Llegó al target
          _hookPos = _hookTarget.clone();
          _trySteal();
          _state = HackerState.retracting;
        } else {
          _hookPos += dir.normalized() * _hookSpeed * dt;
        }
        break;

      case HackerState.retracting:

        if (_showStolenLabel) {
          final dir = (_bodyCenter - _stolenPos);
          if (dir.length <= _hookSpeed * dt) {
            _stolenPos = _bodyCenter.clone();
            if (_stolenLabel != null) {
              _capturedData.add(_stolenLabel!);
            }
            _showStolenLabel = false;
            _stolenLabel = null;
          } else {
            _stolenPos += dir.normalized() * _hookSpeed * dt;
          }
        }
        // Retraer el gancho de vuelta al cuerpo
        final dir = (_bodyCenter - _hookPos);
        if (dir.length <= _hookSpeed * dt) {
          _hookPos = _bodyCenter.clone();
          _state = HackerState.idle;
          _cooldownTimer = _cooldown;
        } else {
          _hookPos += dir.normalized() * _hookSpeed * dt;
        }
        break;
    }
  }

  void _trySteal() {
    if (_hookDidSteal) return;
    if (!gameRef.player.encrypted) {
      // Guardar qué dato se va a robar y desde dónde empieza
      if (gameRef.protectedData.isNotEmpty) {
        _stolenLabel = gameRef.protectedData.first;
        _stolenPos = _hookPos.clone();
        _showStolenLabel = true;
      }
      gameRef.stealData();
      _hookDidSteal = true;
    }
  }

  @override
void render(Canvas canvas) {
  super.render(canvas);

  final center = Offset(size.x / 2, size.y / 2);

  // — Gancho —
  if (_state == HackerState.hooking || _state == HackerState.retracting) {
    final hookLocal = Offset(
      _hookPos.x - position.x + size.x / 2,
      _hookPos.y - position.y + size.y / 2,
    );

    final hookPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final hookGlowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.25)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;

    // Cable
    canvas.drawLine(center, hookLocal, hookGlowPaint);
    canvas.drawLine(center, hookLocal, hookPaint);

    // Dirección del cable para orientar la pinza
    final dir = (hookLocal - center);
    final angle = dir.direction;

    canvas.save();
    canvas.translate(hookLocal.dx, hookLocal.dy);
    canvas.rotate(angle);

    // Brazo izquierdo de la pinza
    final clawPath1 = Path()
      ..moveTo(0, 0)
      ..lineTo(10, -6)
      ..lineTo(14, -3);

    // Brazo derecho de la pinza
    final clawPath2 = Path()
      ..moveTo(0, 0)
      ..lineTo(10, 6)
      ..lineTo(14, 3);

    // Glow de la pinza
    final clawGlowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.25)
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(clawPath1, clawGlowPaint);
    canvas.drawPath(clawPath2, clawGlowPaint);
    canvas.drawPath(clawPath1, hookPaint);
    canvas.drawPath(clawPath2, hookPaint);

    canvas.restore();
  }

  if (_showStolenLabel && _stolenLabel != null) {
    final labelPos = Offset(
      _stolenPos.x - position.x + size.x / 2,
      _stolenPos.y - position.y + size.y / 2,
    );

    final labelBgPaint = Paint()
      ..color = const Color(0xFF050816).withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final labelBorderPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: labelPos, width: 36, height: 16),
      const Radius.circular(4),
    );

    canvas.drawRRect(rect, labelBgPaint);
    canvas.drawRRect(rect, labelBorderPaint);

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: _stolenLabel,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );

    textPainter.layout(maxWidth: 34);
    textPainter.paint(
      canvas,
      labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  // — Glow —
  final glowPaint = Paint()
    ..color = Colors.greenAccent.withOpacity(0.2 + sin(_time * 3) * 0.1)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  canvas.drawCircle(center, 22, glowPaint);

  // — Sprite —
  final paint = Paint()
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;

  _sprite.render(
    canvas,
    position: Vector2.zero(),
    size: size,
    overridePaint: paint,
  );

  //Datos robados del hacker
  if (_capturedData.isNotEmpty) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < _capturedData.length; i++) {
      final angle = _time * 1.6 + i * (pi * 2 / _capturedData.length);
      final radius = 35.0;

      final orbitPos = Offset(
        size.x / 2 + cos(angle) * radius,
        size.y / 2 + sin(angle) * radius,
      );

      // Línea al centro
      final linkPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.4)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(size.x / 2, size.y / 2), orbitPos, linkPaint);

      // Fondo etiqueta
      final labelBgPaint = Paint()
        ..color = const Color(0xFF050816).withOpacity(0.9)
        ..style = PaintingStyle.fill;

      final labelBorderPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: orbitPos, width: 64, height: 16),
        const Radius.circular(4),
      );

      canvas.drawRRect(rect, labelBgPaint);
      canvas.drawRRect(rect, labelBorderPaint);

      // Texto
      textPainter.text = TextSpan(
        text: _capturedData[i],
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      );

      textPainter.layout(maxWidth: 50);
      textPainter.paint(
        canvas,
        orbitPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }
}
}