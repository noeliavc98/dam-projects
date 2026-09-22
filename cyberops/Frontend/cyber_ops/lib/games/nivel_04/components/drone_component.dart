import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DroneComponent extends CircleComponent
    with HasGameRef, CollisionCallbacks, KeyboardHandler {
  static const double radio = 16.0;
  static const double velocidadMax = 200.0;

  // Dirección de movimiento por teclado
  Vector2 _direccion = Vector2.zero();

  // Dirección de movimiento por joystick
  Vector2 joystickDelta = Vector2.zero();

  // true cuando el dron está sobre un nodo y no debe moverse
  bool bloqueado = false;

  // true mientras la habilidad de invisibilidad está activa
  bool invisible = false;

  // Ángulo actual de la flecha en radianes
  // Por defecto apunta hacia arriba
  double _anguloFlecha = -math.pi / 2;

  // Callback para disparar desde el juego
  final void Function() onDisparar;

  // Distancia desde el centro del dron hasta la base de la flecha
  static const double _distanciaFlecha = 0.0;
  // Tamaño de la flecha
  static const double _largoFlecha = 16.0;
  static const double _anchoFlecha = 8.0;

  // Animación de líneas de datos hacker
  double _tiempoAnimacion = 0.0;

  DroneComponent({required Vector2 posicion, required this.onDisparar})
    : super(
        radius: radio,
        position: posicion,
        anchor: Anchor.center,
        paint: Paint()..color = Colors.transparent,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  // Apuntar hacia una posición del canvas
  /// Recibe coordenadas absolutas del canvas.
  /// Calcula el ángulo entre el centro del dron y el destino.
  void apuntarHacia(Vector2 destino) {
    final diff = destino - position;
    if (diff.length > 2) {
      _anguloFlecha = math.atan2(diff.y, diff.x);
    }
  }

  // Dirección normalizada de disparo
  /// La bala saldrá exactamente en esta dirección.
  Vector2 get direccionDisparo =>
      Vector2(math.cos(_anguloFlecha), math.sin(_anguloFlecha));

  // Posición de la punta de la flecha
  /// Punto exacto donde aparece la bala al disparar.
  Vector2 get puntaFlecha =>
      position +
      Vector2(
        math.cos(_anguloFlecha) * (radio + _distanciaFlecha + _largoFlecha),
        math.sin(_anguloFlecha) * (radio + _distanciaFlecha + _largoFlecha),
      );

  // Bloquear movimiento al tocar un nodo
  void bloquear() {
    bloqueado = true;
    _direccion = Vector2.zero();
    joystickDelta = Vector2.zero();
  }

  // Desbloquear movimiento al responder la pregunta
  void desbloquear() {
    bloqueado = false;
    _direccion = Vector2.zero();
    joystickDelta = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tiempoAnimacion += dt;

    // Si está bloqueado no se mueve
    if (bloqueado) return;

    // Combinar teclado + joystick
    final input = _direccion + joystickDelta;
    if (input.length > 1) input.normalize();

    position += input * velocidadMax * dt;

    // Limitar a los bordes de pantalla
    final size = gameRef.size;
    position.x = position.x.clamp(radio, size.x - radio);
    position.y = position.y.clamp(radio + 60, size.y - radio - 80);
  }

  // Manejo de entrada del teclado
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (bloqueado) {
      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        onDisparar();
      }
      return true;
    }

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
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      onDisparar();
    }
    return true;
  }

  // Renderizar líneas de datos hacker animadas
  void _renderLineasDatos(Canvas canvas, Offset center, Color colorPrincipal) {
    const numLineas = 6;
    const radioOrbita = 28.0;

    for (int i = 0; i < numLineas; i++) {
      final angulo = (i / numLineas) * math.pi * 2 + _tiempoAnimacion * 2.5;
      final x = center.dx + math.cos(angulo) * radioOrbita;
      final y = center.dy + math.sin(angulo) * radioOrbita;

      // Pulseo de transparencia
      final pulso = (math.sin(_tiempoAnimacion * 3.0) + 1) / 2;

      // Líneas verticales que orbitan
      canvas.drawLine(
        Offset(x, y - 5),
        Offset(x, y + 5),
        Paint()
          ..color = colorPrincipal.withValues(alpha: 0.4 + (pulso * 0.3))
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );

      // Pequeño cuadrado en la punta (símbolo digital)
      final tamanoCuadrado = 3.0 + (pulso * 1.5);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: tamanoCuadrado,
          height: tamanoCuadrado,
        ),
        Paint()
          ..color = colorPrincipal.withValues(alpha: 0.6 + (pulso * 0.4))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Punto central más brillante
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        Paint()..color = colorPrincipal.withValues(alpha: 0.8 + (pulso * 0.2)),
      );
    }
  }

  // Renderizado principal del dron
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Cuando invisible: dibuja el dron muy transparente con efecto fantasma
    if (invisible) {
      _renderInvisible(canvas);
      return;
    }

    final center = Offset(radio, radio);
    final colorPrincipal = bloqueado
        ? const Color(0xFFEC4899)
        : const Color(0xFF06B6D4);

    // Glow exterior
    canvas.drawCircle(
      center,
      radio + 6,
      Paint()
        ..color = colorPrincipal.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // Líneas de datos hacker animadas
    _renderLineasDatos(canvas, center, colorPrincipal);

    // Cuerpo principal
    canvas.drawCircle(
      center,
      radio,
      Paint()
        ..color = const Color(0xFF0D0D2B)
        ..style = PaintingStyle.fill,
    );

    // Anillo exterior
    canvas.drawCircle(
      center,
      radio,
      Paint()
        ..color = colorPrincipal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Anillo interior
    canvas.drawCircle(
      center,
      radio * 0.5,
      Paint()
        ..color = colorPrincipal.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );

    // Brújula de escaneo rotativa
    canvas.save();
    canvas.translate(radio, radio);
    canvas.rotate(_tiempoAnimacion * 1.5);

    // Líneas de la brújula
    final pBrujula = Paint()
      ..color = colorPrincipal.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Línea vertical
    canvas.drawLine(Offset(0, -7), Offset(0, 7), pBrujula);
    // Línea horizontal
    canvas.drawLine(Offset(-7, 0), Offset(7, 0), pBrujula);

    // Puntas direccionales (N, S, E, W)
    final puntaPaint = Paint()
      ..color = colorPrincipal.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Punta Norte (arriba) - más brillante
    canvas.drawCircle(Offset(0, -7), 1.5, puntaPaint);
    canvas.drawLine(
      Offset(0, -7),
      Offset(0, -9),
      Paint()
        ..color = colorPrincipal.withValues(alpha: 0.8)
        ..strokeWidth = 1.0,
    );

    // Puntas Sur, Este, Oeste
    canvas.drawCircle(
      Offset(0, 7),
      1.0,
      puntaPaint..color = puntaPaint.color.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      Offset(7, 0),
      1.0,
      puntaPaint..color = puntaPaint.color.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      Offset(-7, 0),
      1.0,
      puntaPaint..color = puntaPaint.color.withValues(alpha: 0.6),
    );

    canvas.restore();

    // Flecha de dirección
    // Guardamos el estado, trasladamos al centro y rotamos
    canvas.save();
    canvas.translate(radio, radio);
    canvas.rotate(_anguloFlecha);

    // línea desde el borde del dron hasta la base de la flecha
    canvas.drawLine(
      Offset(radio, 0),
      Offset(radio + _distanciaFlecha, 0),
      Paint()
        ..color = colorPrincipal.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Flecha — triángulo apuntando hacia la derecha (dirección de disparo)

    final path = Path()
      // Punta de la flecha
      ..moveTo(radio + _distanciaFlecha + _largoFlecha, 0)
      // Ala izquierda
      ..lineTo(radio + _distanciaFlecha, -_anchoFlecha / 2)
      // Ala derecha
      ..lineTo(radio + _distanciaFlecha, _anchoFlecha / 2)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = colorPrincipal.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Relleno de la flecha
    canvas.drawPath(
      path,
      Paint()
        ..color = colorPrincipal
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  void _renderInvisible(Canvas canvas) {
    const color = Color(0xFF06B6D4);
    final center = Offset(radio, radio);

    // Anillo exterior difuso — único indicador visual para el jugador
    canvas.drawCircle(
      center,
      radio + 8,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Silueta casi transparente
    canvas.drawCircle(
      center,
      radio,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Puntos en los vértices — efecto "distorsión"
    const puntos = 6;
    for (int i = 0; i < puntos; i++) {
      final angle = (i / puntos) * math.pi * 2;
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * radio,
          center.dy + math.sin(angle) * radio,
        ),
        1.5,
        Paint()..color = color.withValues(alpha: 0.35),
      );
    }

    // Flecha de dirección muy sutil (solo visible para el jugador)
    canvas.save();
    canvas.translate(radio, radio);
    canvas.rotate(_anguloFlecha);
    final path = Path()
      ..moveTo(radio + _distanciaFlecha + _largoFlecha, 0)
      ..lineTo(radio + _distanciaFlecha, -_anchoFlecha / 2)
      ..lineTo(radio + _distanciaFlecha, _anchoFlecha / 2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }
}
