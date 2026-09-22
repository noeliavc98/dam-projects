import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ExplosionComponent extends PositionComponent {
  static const int _numParticulas = 14;
  static const double _duracion = 0.55;

  final Color color;
  final math.Random _random = math.Random();

  // Cada partícula: [posX, posY, velX, velY, radio, alpha_inicial]
  final List<_Particula> _particulas = [];
  double _tiempo = 0;

  ExplosionComponent({
    required Vector2 posicion,
    this.color = const Color(0xFFEC4899),
  }) : super(position: posicion, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < _numParticulas; i++) {
      final angulo = _random.nextDouble() * math.pi * 2;
      final velocidad = 60.0 + _random.nextDouble() * 120.0;
      final radio = 2.0 + _random.nextDouble() * 3.0;
      _particulas.add(_Particula(
        vel: Vector2(math.cos(angulo) * velocidad, math.sin(angulo) * velocidad),
        radio: radio,
        pos: Vector2.zero(),
      ));
    }
  }

  @override
  void update(double dt) {
    _tiempo += dt;
    if (_tiempo >= _duracion) {
      removeFromParent();
      return;
    }

    final progreso = _tiempo / _duracion; // 0..1

    for (final p in _particulas) {
      // Desaceleración: la velocidad baja al avanzar
      final factor = (1.0 - progreso) * dt;
      p.pos += p.vel * factor;
    }
  }

  @override
  void render(Canvas canvas) {
    final progreso = (_tiempo / _duracion).clamp(0.0, 1.0);
    // Alpha: baja de 1 a 0 en la segunda mitad de la animación
    final alpha = (1.0 - progreso).clamp(0.0, 1.0);

    for (final p in _particulas) {
      final radioActual = p.radio * (1.0 - progreso * 0.5);

      // Glow
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        radioActual + 3,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Núcleo
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        radioActual,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }

    // Flash central al inicio
    if (progreso < 0.2) {
      final flashAlpha = (1.0 - progreso / 0.2) * 0.6;
      canvas.drawCircle(
        Offset.zero,
        18.0 * (1.0 - progreso / 0.2),
        Paint()
          ..color = Colors.white.withValues(alpha: flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }
}

class _Particula {
  Vector2 pos;
  final Vector2 vel;
  final double radio;

  _Particula({required this.pos, required this.vel, required this.radio});
}
