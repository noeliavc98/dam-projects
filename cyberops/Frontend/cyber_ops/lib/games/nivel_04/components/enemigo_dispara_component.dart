import 'dart:math' as math;
import 'package:cyber_ops/services/music_service.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'drone_component.dart';
import 'bala_component.dart';
import 'bala_enemiga_component.dart';
import 'explosion_component.dart';

class EnemigoDisparaComponent extends CircleComponent
    with HasGameReference, CollisionCallbacks {
  static const double radio = 18.0;
  static const double velocidad = 70.0;

  DroneComponent? objetivo;
  bool eliminado = false;
  final void Function() onTocaDron;
  final void Function(BalaEnemigaComponent bala) onDisparar;

  // Control de disparo
  double _tiempoDesdeDisparo = 0;
  static const double _intervaloDisparo = 1.2;
  final math.Random _random = math.Random();

  // Órbita
  bool esOrbital = false;
  late Vector2 centroOrbita;
  late double radioOrbita;
  double anguloOrbita = 0;
  static const double velocidadAngular = 1.6; // radianes por segundo

  // Saltos entre anillos
  bool saltaAnillos = false;
  int anilloActual = 0; // 0=exterior, 1=medio, 2=interior
  static const int numAnillos = 3;
  double tiempoEnAnillo = 0;
  static const double intervaloSalto = 3.5; // segundos entre saltos

  EnemigoDisparaComponent({
    required Vector2 posicion,
    required this.onTocaDron,
    required this.onDisparar,
  }) : super(
         radius: radio,
         position: posicion,
         anchor: Anchor.center,
         paint: Paint()..color = const Color(0xFFEC4899).withValues(alpha: 0.3),
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  void setObjetivo(DroneComponent dron) {
    objetivo = dron;
  }

  void iniciarOrbita(Vector2 centro, double radio) {
    esOrbital = true;
    centroOrbita = centro;
    radioOrbita = radio;
    anguloOrbita =
        _random.nextDouble() * math.pi * 2; // Ángulo inicial aleatorio
  }

  void iniciarSaltos(Vector2 centro, double radioMax) {
    saltaAnillos = true;
    centroOrbita = centro;
    radioOrbita = radioMax;
    anilloActual = 0;
    anguloOrbita = _random.nextDouble() * math.pi * 2;
    tiempoEnAnillo = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (eliminado || objetivo == null) return;

    // Si el dron está invisible, el enemigo no puede detectarlo
    if (objetivo!.invisible) return;

    if (saltaAnillos) {
      // Modo saltos: orbitar en anillo actual y saltar cada cierto tiempo
      tiempoEnAnillo += dt;

      // Calcular radio del anillo actual
      final radioAnillo = radioOrbita * ((anilloActual + 1) / numAnillos);

      // Orbitar en el anillo actual
      anguloOrbita += velocidadAngular * dt;
      position =
          centroOrbita +
          Vector2(
            math.cos(anguloOrbita) * radioAnillo,
            math.sin(anguloOrbita) * radioAnillo,
          );

      // Saltar al siguiente anillo
      if (tiempoEnAnillo >= intervaloSalto && anilloActual < numAnillos - 1) {
        anilloActual++;
        tiempoEnAnillo = 0;
      }
    } else if (esOrbital) {
      // Modo orbital: orbitar alrededor del centro
      anguloOrbita += velocidadAngular * dt;
      position =
          centroOrbita +
          Vector2(
            math.cos(anguloOrbita) * radioOrbita,
            math.sin(anguloOrbita) * radioOrbita,
          );
    } else {
      // Modo persecución: perseguir al dron
      final dir = (objetivo!.position - position);
      if (dir.length > 1) {
        dir.normalize();
        position += dir * velocidad * dt;
      }
    }

    // Disparo periódico (hacia el dron)
    _tiempoDesdeDisparo += dt;
    if (_tiempoDesdeDisparo >= _intervaloDisparo) {
      _tiempoDesdeDisparo = 0;
      _disparar();
    }
  }

  void _disparar() {
    if (objetivo == null || objetivo!.invisible) return;

    final dir = (objetivo!.position - position);
    if (dir.length > 1) {
      dir.normalize();
      final bala = BalaEnemigaComponent(posicion: position, direccion: dir);
      onDisparar(bala);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BalaComponent) {
      other.removeFromParent();
      _eliminar();
    } else if (other is DroneComponent) {
      if (other.invisible) return;
      onTocaDron();
      _eliminar();
    }
  }

  void _eliminar() {
    eliminado = true;
    MusicService().playExplosion();
    game.add(ExplosionComponent(posicion: position.clone()));
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(
      Offset(radio, radio),
      radio,
      Paint()
        ..color = const Color(0xFFEC4899)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: '⚠',
        style: TextStyle(fontSize: 16, color: Color(0xFFEC4899)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(radio - tp.width / 2, radio - tp.height / 2));
  }
}
