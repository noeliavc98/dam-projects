import 'package:cyber_ops/services/music_service.dart';
import 'package:cyber_ops/widgets/music_controls.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';
import '../config/app_styles.dart';
import 'login_screen.dart';
import 'menu_screen.dart';
import 'register_screen.dart';
import 'dart:ui';
import 'package:cyber_ops/config/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Map<String, bool> _isHovering = {};
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late AnimationController _tapPulseController;
  late Animation<double> _tapPulseAnimation;
  bool _audioUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkAudioUnlocked();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tapPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _tapPulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _tapPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _tapPulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAudioUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getBool('audio_unlocked') ?? false;
    if (unlocked && mounted) {
      setState(() => _audioUnlocked = true);
      await MusicService().playMenuMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(_rotateController.value),
                );
              },
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.purple,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 200,
                            height: 200,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.purple,
                        AppColors.blue,
                        AppColors.cyan,
                      ],
                    ).createShader(bounds),
                    child: const Text('CYBER OPS', style: AppStyles.titleMain),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: AppColors.purple.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'OPERACIÓN CLASIFICADA',
                        style: AppStyles.subtitle,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 40,
                        height: 1,
                        color: AppColors.purple.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  _buildButton(
                    label: 'JUGAR',
                    isPrimary: true,
                    icon: Icons.play_arrow_rounded,
                    onTap: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // NOMBRE 'menu' para que pushAndRemoveUntil sepa dónde parar
                        Navigator.push(
                          context,
                          AppRoutes.fade(
                            const MenuScreen(),
                            settings: const RouteSettings(name: AppRoutes.menu),
                          ),
                        );
                      } else {
                        Navigator.push(context, AppRoutes.fade(LoginScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildButton(
                    label: 'INICIAR SESIÓN',
                    isPrimary: false,
                    icon: Icons.lock_open_rounded,
                    onTap: () {
                      Navigator.push(context, AppRoutes.fade(LoginScreen()));
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildButton(
                    label: 'REGISTRARSE',
                    isPrimary: false,
                    icon: Icons.person_add_rounded,
                    onTap: () {
                      Navigator.push(context, AppRoutes.fade(RegisterScreen()));
                    },
                  ),
                  const SizedBox(height: 50),
                  Text(
                    'v1.0.0  ·  DAM PRÁCTICAS 2026',
                    style: AppStyles.small.copyWith(
                      color: AppColors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const MusicControls(),
          if (!_audioUnlocked) 
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('audio_unlocked', true);
                  setState(() => _audioUnlocked = true);
                  await MusicService().playMenuMusic();
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(color: Colors.black.withValues(alpha: 0.35)),
                      ),
                    ),
                    Center(
                      child: AnimatedBuilder(
                        animation: _tapPulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _tapPulseAnimation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'CLICK PARA EMPEZAR',
                                  style: TextStyle(
                                    color: AppColors.cyan,
                                    fontSize: 22,
                                    fontFamily: 'monospace',
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '👆',
                                  style: TextStyle(
                                    fontSize: 42,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.cyan.withValues(alpha: 0.6),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required bool isPrimary,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    _isHovering.putIfAbsent(label, () => false);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering[label] = true),
      onExit: (_) => setState(() => _isHovering[label] = false),
      child: GestureDetector(
        onTap: onTap,
        child: Transform.scale(
          scale: _isHovering[label]! ? 1.05 : 1.0,
          child: Container(
            width: 280,
            height: 54,
            decoration: BoxDecoration(
              gradient: isPrimary || _isHovering[label]!
                  ? const LinearGradient(
                      colors: [AppColors.purple, AppColors.blue],
                    )
                  : null,
              color: isPrimary ? null : AppColors.bgCard,
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent
                    : (_isHovering[label]! ? AppColors.cyan : AppColors.purple),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: _isHovering[label]!
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : (isPrimary
                        ? [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary || _isHovering[label]!
                      ? Colors.white
                      : AppColors.purple,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: isPrimary || _isHovering[label]!
                      ? AppStyles.buttonPrimary
                      : AppStyles.buttonSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;
  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final rings = [
      (radius: 280.0, opacity: 0.04),
      (radius: 200.0, opacity: 0.06),
      (radius: 130.0, opacity: 0.05),
    ];

    for (final ring in rings) {
      final paint = Paint()
        ..color = AppColors.purple.withValues(alpha: ring.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(cx, cy), ring.radius, paint);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dots = [
      (
        angle: progress * 2 * math.pi,
        radius: 280.0,
        color: AppColors.purple,
        size: 3.0,
      ),
      (
        angle: progress * 2 * math.pi + math.pi,
        radius: 280.0,
        color: AppColors.blue,
        size: 3.0,
      ),
      (
        angle: -progress * 2 * math.pi + math.pi / 3,
        radius: 200.0,
        color: AppColors.cyan,
        size: 2.5,
      ),
      (
        angle: -progress * 2 * math.pi + math.pi * 1.33,
        radius: 200.0,
        color: AppColors.purple,
        size: 2.5,
      ),
    ];

    for (final dot in dots) {
      dotPaint.color = dot.color.withValues(alpha: 0.7);
      canvas.drawCircle(
        Offset(
          cx + dot.radius * math.cos(dot.angle),
          cy + dot.radius * math.sin(dot.angle),
        ),
        dot.size,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.progress != progress;
}
