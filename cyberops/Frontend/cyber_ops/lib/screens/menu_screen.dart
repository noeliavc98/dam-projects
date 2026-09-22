import 'dart:math' as math;
import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/config/app_styles.dart';
import 'package:cyber_ops/screens/home_screen.dart';
import 'package:cyber_ops/screens/profile_screen.dart';
import 'package:cyber_ops/screens/settings_screen.dart';
import 'package:cyber_ops/widgets/music_controls.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'level_map_screen.dart';
import 'dart:convert';
import 'clasificacion_screen.dart';
import 'package:cyber_ops/config/app_routes.dart';


class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
Future<void> _nuevaPartida() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Comprobamos si tiene progreso
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final datos = doc.data();
  final int nivel = datos?['nivel'] ?? 1;
  final int puntos = datos?['puntuacion_total'] ?? 0;
  final bool tieneProgreso = nivel > 1 || puntos > 0;

  if (!mounted) return;

  if (tieneProgreso) {
    // Mostramos advertencia
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgMain,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'REINICIAR PARTIDA',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Se perderá todo tu progreso:\nnivel, puntos y misiones completadas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Estás seguro?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.purple.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: AppColors.purple.withValues(alpha: 0.7),
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'REINICIAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true) return;

    // Reseteamos Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'nivel': 1,
      'puntuacion_total': 0,
      'partidas_jugadas': 0,
      'ultimo_nivel_completado': 0,
      'ultima_partida': null,
    });

    // Borramos subcolección de misiones
    final misiones = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('misiones')
        .get();
    for (final doc in misiones.docs) {
      await doc.reference.delete();
    }
  }

  if (!mounted) return;

  // Navegamos al mapa — con o sin reset
  Navigator.push(
    context,
    AppRoutes.fade(const LevelMapScreen()),
  ).then((_) {
    if (mounted) _refrescarUsuario();
  });
}
  late Future<Map<String, dynamic>?> _futureUsuario;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  final Map<String, bool> _isHovering = {};

  @override
  void initState() {
    super.initState();
    _futureUsuario = _obtenerDatosUsuario();

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
  }

  Future<Map<String, dynamic>?> _obtenerDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }
  void _refrescarUsuario() {
  setState(() {
    _futureUsuario = _obtenerDatosUsuario();
  });
}
Future<void> _continuar() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final int nivel = doc.data()?['nivel'] ?? 1;

  if (!mounted) return;

  Navigator.push(
    context,
    AppRoutes.fade(
     LevelMapScreen(nivelInicial: nivel),
    ),
  ).then((_) {
    if (mounted) _refrescarUsuario();
  });
}

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      AppRoutes.fade(HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
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
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 90,
                            height: 90,
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
                              width: 100,
                              height: 100,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppColors.purple, AppColors.blue, AppColors.cyan],
                      ).createShader(bounds),
                      child: const Text(
                        'BIENVENIDO/A',
                        style: AppStyles.screenTitle,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _futureUsuario,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(
                            color: AppColors.purple,
                          );
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Text(
                            'No se encontraron datos del usuario',
                            style: TextStyle(
                              color: AppColors.purple.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          );
                        }
                        final datos = snapshot.data!;
                        return Container(
                          width: 300,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.purple, AppColors.cyan ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.white,
                                backgroundImage: (datos['fotoPerfil'] != null && datos['fotoPerfil'].toString().startsWith('/'))
                                    ? MemoryImage(base64Decode(datos['fotoPerfil']))
                                    : null,
                                child: (datos['fotoPerfil'] == null || datos['fotoPerfil'].toString().isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.blue,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      datos['name'] ?? 'Usuario',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildButton(
                      label: 'NUEVA PARTIDA',
                      isPrimary: false,
                      icon: Icons.play_arrow_rounded,
                      onTap: () => _nuevaPartida(),
                    ),
                    const SizedBox(height: 14),
                    _buildButton(
                      label: 'CONTINUAR',
                      isPrimary: false,
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => _continuar(),
                    ),
                    const SizedBox(height: 14),
                    _buildButton(
                      label: 'MISIONES',
                      isPrimary: false,
                      icon: Icons.star_rounded,
                      onTap: () {
                        // ✅ Sin nombre — el nombre 'menu' ya está en esta ruta
                        Navigator.push(
                          context,
                          AppRoutes.fade(
                           const LevelMapScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildButton(
                      label: 'CLASIFICACIÓN',
                      isPrimary: false,
                      icon: Icons.emoji_events_rounded,
                      onTap: () {
                      Navigator.push(
                       context,
                      AppRoutes.fade(const ClasificacionScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildButton(
                      label: 'MI PERFIL',
                      isPrimary: false,
                      icon: Icons.person_rounded,
                      onTap: () {
                       Navigator.push(
                        context,
                      AppRoutes.fade(ProfileScreen()),
                      ).then((_) {
                      if (mounted) _refrescarUsuario();

                       });
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildButton(
                      label: 'AJUSTES',
                      isPrimary: false,
                      icon: Icons.settings_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppRoutes.fade(
                           SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildLogoutButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          const MusicControls(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    const label = 'CERRAR SESIÓN';
    _isHovering.putIfAbsent(label, () => false);
    final isHovering = _isHovering[label]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering[label] = true),
      onExit: (_) => setState(() => _isHovering[label] = false),
      child: GestureDetector(
        onTap: _cerrarSesion,
        child: Transform.scale(
          scale: isHovering ? 1.05 : 1.0,
          child: Container(
            width: 280,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              border: Border.all(
                color: isHovering
                    ? Colors.redAccent.withValues(alpha: 0.9)
                    : Colors.red.withValues(alpha: 0.6),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded,
                    color: Colors.red.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.withValues(alpha: 0.8),
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
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
                      )
                    ]
                  : (isPrimary
                      ? [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
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
      (angle: progress * 2 * math.pi,                   radius: 280.0, color: AppColors.purple, size: 3.0),
      (angle: progress * 2 * math.pi + math.pi,         radius: 280.0, color: AppColors.blue,   size: 3.0),
      (angle: -progress * 2 * math.pi + math.pi / 3,    radius: 200.0, color: AppColors.cyan,   size: 2.5),
      (angle: -progress * 2 * math.pi + math.pi * 1.33, radius: 200.0, color: AppColors.purple, size: 2.5),
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