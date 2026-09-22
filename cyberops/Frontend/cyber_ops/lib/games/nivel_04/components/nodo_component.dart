import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

enum NodoEstado { seguro, vulnerable, comprometido, alerta }

class NodoComponent extends CircleComponent
    with HasGameRef, CollisionCallbacks {
  final int id;
  NodoEstado estado;
  final void Function(NodoComponent nodo) onContactoDron;

  static const double radio = 26.0;
  bool _preguntaActiva = false;
  final bool modoDefensa;

  /// true mientras este nodo esté esperando que su nodo padre sea comprometido.
  bool bloqueado = false;

  // Movimiento flotante
  late Vector2 _velocidad;
  final math.Random _random = math.Random();

  NodoComponent({
    required this.id,
    required Vector2 posicion,
    required this.onContactoDron,
    this.modoDefensa = false,
  }) : estado = NodoEstado.seguro,
       super(radius: radio, position: posicion, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Velocidad flotante aleatoria
    _velocidad = Vector2(
      (_random.nextDouble() - 0.5) * 40,
      (_random.nextDouble() - 0.5) * 40,
    );
    add(CircleHitbox());
    _actualizarColor();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Movimiento flotante
    position += _velocidad * dt;

    // Rebotar en los bordes
    final size = gameRef.size;
    if (position.x < radio || position.x > size.x - radio) {
      _velocidad.x *= -1;
      position.x = position.x.clamp(radio, size.x - radio);
    }
    if (position.y < radio + 80 || position.y > size.y - radio - 60) {
      _velocidad.y *= -1;
      position.y = position.y.clamp(radio + 80, size.y - radio - 60);
    }
  }

  void desbloquear() {
    bloqueado = false;
  }

  void activarPregunta() {
    if (_preguntaActiva || bloqueado) return;
    // en el nivel 2 se activa la pregunta si el nodo esta en vulnerable o alerta
    if (estado == NodoEstado.seguro ||
        estado == NodoEstado.vulnerable ||
        estado == NodoEstado.alerta) {
      _preguntaActiva = true;
      onContactoDron(this);
    }
  }

  void resetPregunta() {
    _preguntaActiva = false;
  }

  void marcarComprometido() {
    estado = NodoEstado.comprometido;
    _preguntaActiva = false;
    _actualizarColor();
  }

  void marcarAlerta() {
    estado = NodoEstado.alerta;
    _preguntaActiva = false;
    _actualizarColor();
  }

  void actualizarColor() => _actualizarColor();

  void _actualizarColor() {
    paint = Paint()
      ..color = _colorPorEstado()
      ..style = PaintingStyle.fill;
  }

  // colores de momento sin la pagina de colores
  Color _colorPorEstado() {
  switch (estado) {
    case NodoEstado.seguro:
      return const Color(0xFF0D0D2B);
    case NodoEstado.vulnerable:
      return const Color(0xFFFF9800).withValues(alpha: 0.35); // naranja
    case NodoEstado.comprometido:
      return  const Color.fromARGB(255, 0, 60, 255).withValues(alpha: 0.35);
    case NodoEstado.alerta:
      return const Color(0xFFFF3B30).withValues(alpha: 0.45); // rojo fuerte
  }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (modoDefensa) {
      _renderDefensa(canvas);
    } else {
      _renderNormal(canvas);
    }
  }

  void _renderNormal(Canvas canvas) {
    final bordeColor = bloqueado ? const Color(0xFF444466) : _colorBorde();

    canvas.drawCircle(
      Offset(radio, radio),
      radio,
      Paint()
        ..color = const Color(0xFF6C63FF).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Anillo exterior pulsante para nodos seguros no bloqueados
    if (estado == NodoEstado.seguro && !bloqueado) {
      canvas.drawCircle(
        Offset(radio, radio),
        radio + 6,
        Paint()
          ..color = const Color(0xFF6C63FF).withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    if (bloqueado) {
      _renderCandado(canvas);
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: _iconoPorEstado(),
          style: TextStyle(fontSize: 16, color: bordeColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(radio - tp.width / 2, radio - tp.height / 2));
    }

    final idPainter = TextPainter(
      text: TextSpan(
        text: 'N$id',
        style: TextStyle(
          fontSize: 8,
          color: bloqueado ? Colors.white24 : Colors.white54,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    idPainter.paint(
      canvas,
      Offset(radio - idPainter.width / 2, radio * 2 - 10),
    );
  }

  void _renderCandado(Canvas canvas) {
    final cx = radio;
    final cy = radio;
    const cuerpoW = 14.0;
    const cuerpoH = 10.0;
    const arcoR = 5.5;

    // Cuerpo del candado
    final cuerpo = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + 3),
        width: cuerpoW,
        height: cuerpoH,
      ),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(cuerpo, Paint()..color = const Color(0xFF444466));
    canvas.drawRRect(
      cuerpo,
      Paint()
        ..color = const Color(0xFF888899)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Arco superior del candado
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy - 1),
        width: arcoR * 2,
        height: arcoR * 2,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF888899)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _renderDefensa(Canvas canvas) {
    final center = Offset(radio, radio);
    final borde = _colorBorde();

    // Halo principal
    canvas.drawCircle(
      center,
      radio + 8,
      Paint()
        ..color = borde.withOpacity(
          estado == NodoEstado.alerta
              ? 0.30
              : estado == NodoEstado.vulnerable
              ? 0.22
              : 0.14,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = estado == NodoEstado.alerta ? 2.2 : 1.4,
    );

    // Segundo halo para alerta
    if (estado == NodoEstado.alerta) {
      canvas.drawCircle(
        center,
        radio + 14,
        Paint()
          ..color = const Color(0xFFEC4899).withOpacity(0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // Base de la torre
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(radio, radio + 12), width: 34, height: 14),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      baseRect,
      Paint()..color = _colorPorEstado().withOpacity(0.9),
    );

    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cuerpo de la torre
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(radio, radio + 1), width: 18, height: 28),
      const Radius.circular(4),
    );

    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF0D0D2B));

    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Núcleo superior
    canvas.drawCircle(
      Offset(radio, radio - 12),
      7,
      Paint()..color = borde.withOpacity(0.9),
    );

    // Glow del núcleo
    canvas.drawCircle(
      Offset(radio, radio - 12),
      estado == NodoEstado.alerta ? 15 : 12,
      Paint()
        ..color = borde.withOpacity(
          estado == NodoEstado.alerta
              ? 0.28
              : estado == NodoEstado.vulnerable
              ? 0.22
              : 0.18,
        )
        ..style = PaintingStyle.fill,
    );

    // Línea vertical de energía
    canvas.drawLine(
      Offset(radio, radio - 5),
      Offset(radio, radio + 10),
      Paint()
        ..color = borde.withOpacity(0.7)
        ..strokeWidth = 1.4,
    );

    // Símbolo central
    final tp = TextPainter(
      text: TextSpan(
        text: _iconoPorEstado(),
        style: TextStyle(
          fontSize: 12,
          color: borde,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(radio - tp.width / 2, radio - 4 - tp.height / 2));

    // Etiqueta inferior
    final idPainter = TextPainter(
      text: TextSpan(
        text: 'DEF-$id',
        style: const TextStyle(
          fontSize: 7,
          color: Colors.white54,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    idPainter.paint(canvas, Offset(radio - idPainter.width / 2, radio + 24));

    // Marca extra si está vulnerable
    if (estado == NodoEstado.vulnerable) {
      final pulsePaint = Paint()
        ..color = const Color(0xFF06B6D4).withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, radio + 4, pulsePaint);
    }

    // Marca visual extra si está comprometido
    if (estado == NodoEstado.comprometido) {
      final dangerPaint = Paint()
        ..color = const Color(0xFFEC4899).withOpacity(0.75)
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(radio - 10, radio - 10),
        Offset(radio + 10, radio + 10),
        dangerPaint,
      );
      canvas.drawLine(
        Offset(radio + 10, radio - 10),
        Offset(radio - 10, radio + 10),
        dangerPaint,
      );

      // Grieta visual en la base
      canvas.drawLine(
        Offset(radio - 8, radio + 14),
        Offset(radio + 6, radio + 18),
        Paint()
          ..color = const Color(0xFFEC4899).withOpacity(0.75)
          ..strokeWidth = 1.4,
      );
    }
  }

  Color _colorBorde() {
    switch (estado) {
      case NodoEstado.seguro:
        return const Color(0xFF6C63FF).withOpacity(0.7);
      case NodoEstado.vulnerable:
        return const Color(0xFFFF9800); // naranja
      case NodoEstado.comprometido:
        return const Color(0xFFB71C1C); // rojo oscuro intenso
      case NodoEstado.alerta:
        return const Color(0xFFFF3B30); // rojo claro y visible
    }
  }

  String _iconoPorEstado() {
    switch (estado) {
      case NodoEstado.seguro:
        return '◈';
      case NodoEstado.vulnerable:
        return '⚡';
      case NodoEstado.comprometido:
        return '✓';
      case NodoEstado.alerta:
        return '☠';
    }
  }
}