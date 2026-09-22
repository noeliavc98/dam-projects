import 'dart:math';

import 'package:cyber_ops/games/nivel_17/components/background.dart';
import 'package:cyber_ops/games/nivel_17/components/hacker_enemy.dart';
import 'package:cyber_ops/games/nivel_17/components/player.dart';
import 'package:cyber_ops/games/nivel_17/components/spyware_enemy.dart';
import 'package:cyber_ops/games/nivel_17/components/static_obstacle.dart';
import 'package:cyber_ops/games/nivel_17/components/vpn_tunnel.dart';
import 'package:cyber_ops/games/nivel_17/components/xp_orb.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Nivel17Game extends FlameGame with HasCollisionDetection, KeyboardEvents {
  final VoidCallback? onStateChanged;
  final VoidCallback? onCompleted;
  final VoidCallback? onGameOver;

  late Player player;
  JoystickComponent? joystick;

  Nivel17Game({
    this.onStateChanged,
    this.onCompleted,
    this.onGameOver,
  });

  //Enemigos
  double enemySpawnTimer = 0;
  double spawnInterval = 1.5;

  // Barreras
  double _barrierSpawnTimer = 0;
  static const int _maxBarriersOnScreen = 8;

  //XP
  double _orbSpawnTimer = 0;
  static const double _orbSpawnInterval = 1.5;
  static const int _maxOrbs = 15;

  double gameTime = 0;
  int lives = 4;
  int score = 0;

  final List<String> sensitiveData = [
    'DNI',
    'TARJETA',
    'EMAIL',
    'UBICACIÓN',
  ];

  final Set<String> stolenData = {};

  double privacy = 100;

  bool gameOver = false;
  bool completed = false;

  double missionDuration = 60;

  List<String> get protectedData =>
    sensitiveData.where((data) => !stolenData.contains(data)).toList();

  bool get hasRemainingData => protectedData.isNotEmpty;

  // Intervalo dinámico según momento de la partida
  double get _barrierSpawnInterval => gameTime >= 90.0 ? 4.0 : 7.0;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    add(
      Background(),
    );

    add(
      VPNTunnel(),
    );

    add(HackerEnemy());

    player = Player();
    add(player);

    _spawnJoystick();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameOver || completed) return;

    gameTime += dt;

    if (privacy <= 0) {
      stealData();

      if (!gameOver) {
        privacy = 100;
      }
    }

    if (gameTime >= missionDuration) {
      completed = true;
      onCompleted?.call();
    }

    Future.microtask(() => onStateChanged?.call());

    //Spawn enemigos
    enemySpawnTimer += dt;

    if (enemySpawnTimer >= spawnInterval) {
      enemySpawnTimer = 0;

      spawnEnemy();
    }

    //Dificultad progresiva enemigos
    spawnInterval = max(
      0.6,
      1.5 - gameTime * 0.02,
    );

     // Spawn barreras
    _barrierSpawnTimer += dt;

    if (_barrierSpawnTimer >= _barrierSpawnInterval) {
      _barrierSpawnTimer = 0;
      _spawnBarriers();
    }

    // Spawn XP orbs
    _orbSpawnTimer += dt;
    if (_orbSpawnTimer >= _orbSpawnInterval) {
      _orbSpawnTimer = 0;
      if (children.whereType<XpOrb>().length < _maxOrbs) {
        add(XpOrb.spawn(this));
      }
    }

    //Joystick
    if (joystick != null && !joystick!.delta.isZero()) {
      player.joystickDelta = joystick!.relativeDelta;
    } else {
      player.joystickDelta = Vector2.zero();
    }
  }

  //Teclado
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    player.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  //Perder vidas
  void loseLife() {
     stealData();
  }

  void stealData() {
    if (gameOver || completed) return;
    if (protectedData.isEmpty) return;

    final data = protectedData.first;
    stolenData.add(data);

    lives = protectedData.length;

    if (lives <= 0) {
      lives = 0;
      privacy = 0;
      gameOver = true;
      Future.microtask(() => onGameOver?.call());
      return;
    }

    Future.microtask(() => onStateChanged?.call());
  }

  void _spawnJoystick() {
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20,
        paint: Paint()..color = const Color(0xFF06B6D4).withValues(alpha: 0.8),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFF0D0D2B).withValues(alpha: 0.7),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    add(joystick!);
  }

  void spawnEnemy() {
    // Máximo 2 spywares simultáneos
    final currentSpywares = children.whereType<SpywareEnemy>().length;
    if (currentSpywares >= 2) return;

    final spawnY = Random().nextDouble() * size.y;
    add(SpywareEnemy(position: Vector2(size.x + 100, spawnY)));
  }

  void _spawnBarriers() {
    final current = children.whereType<StaticObstacle>().length;
    if (current >= _maxBarriersOnScreen) return;

    final random = Random();
    final count = gameTime >= 90.0 ? 5 : 3;

    final blockH = StaticObstacle.blockH;
    final blockW = StaticObstacle.blockW;
    const gap = 90.0; // hueco vertical entre bloques

    // Todos comparten la misma X de spawn
    final spawnX = size.x + 60;

    // Y inicial aleatoria para la columna
    double currentY = random.nextDouble() * (size.y * 0.3);

    for (int i = 0; i < count; i++) {
      if (children.whereType<StaticObstacle>().length >= _maxBarriersOnScreen) break;

      final barrier = StaticObstacle.spawn(
        game: this,
        insideTunnel: false,
        forceY: currentY,
      );

      if (barrier != null) {
        barrier.position.x = spawnX;
        add(barrier);
      }

      currentY += blockH + gap;
    }
  }

      @override
      Color backgroundColor() {
        return const Color(0xFF050816);
      }
}
