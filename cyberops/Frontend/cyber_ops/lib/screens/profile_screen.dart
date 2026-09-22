import 'dart:convert';
import 'dart:math' as math;
import 'package:cyber_ops/config/app_routes.dart';
import 'package:cyber_ops/screens/change_password_screen.dart';
import 'package:cyber_ops/screens/change_profile_photo_screen.dart';
import 'package:cyber_ops/screens/home_screen.dart';
import 'package:cyber_ops/screens/totp_setup_screen.dart';
import 'package:cyber_ops/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/config/app_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  final Map<String, bool> _isHoveringProfile = {};

  late AnimationController _rotateController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _aliasController;
  late TextEditingController _bioController;

  final AuthService _authService = AuthService();

  Map<String, dynamic>? _datosUsuario;
  bool _cargando = true;
  bool _totpEnabled = false;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _aliasController = TextEditingController();
    _bioController = TextEditingController();

    // Cargamos los datos del usuario al iniciar la pantalla
    _cargarDatos();
  }

  // Carga los datos del usuario desde Firestore
  Future<void> _cargarDatos() async {
    await obtenerDatosUsuario();
  }

  // Obtiene datos reales del usuario
  Future<void> obtenerDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!mounted) return;

    if (doc.exists) {
      setState(() {
        _datosUsuario = doc.data();
        _nameController.text = _datosUsuario!['name'] ?? '';
        _emailController.text = _datosUsuario!['email'] ?? '';
        _aliasController.text = _datosUsuario!['alias'] ?? '';
        _bioController.text = _datosUsuario!['bio'] ?? '';
        _totpEnabled = _datosUsuario!['totp_enabled'] == true;
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
    }
  }

  // Guarda los cambios del formulario en Firestore
  Future<void> _guardarCambios() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'alias': _aliasController.text.trim(),
      'bio': _bioController.text.trim(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Perfil actualizado correctamente'),
        backgroundColor: AppColors.purple,
      ),
    );
  }

  // Cierra la sesión y vuelve a la home screen
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
    _orbitController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _aliasController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          // Fondo animado
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     _buildHeader(),
                    const SizedBox(height: 24),
                    // Si está cargando mostramos spinner
                    if (_cargando)
                      Center(
                        child: SizedBox(
                          height: 380,
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.purple),
                          ),
                        ),
                      )
                    else if (_datosUsuario == null)
                      Center(
                        child: Text(
                          'No se encontraron datos del usuario',
                          style: TextStyle(
                            color: AppColors.purple.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      )
                    else ...[
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildEditableInfo(),
                      const SizedBox(height: 24),
                      _buildProfileActionButton(
                        label: 'Cambiar foto de perfil',
                        icon: Icons.camera_alt_rounded,
                        onTap: () async {
                          final nuevaFoto = await Navigator.push(
                            context,
                            AppRoutes.fade(
                              ChangeProfilePhotoScreen(
                                fotoActual: _datosUsuario!['fotoPerfil'],
                              ),
                            ),
                          );

                          if (nuevaFoto != null) {
                            //1. Actualizar la UI inmediatamente
                            setState(() {
                              _datosUsuario!['fotoPerfil'] = nuevaFoto;
                            });

                            //2. Recargar Firestore para asegurar consistencia
                            await obtenerDatosUsuario();
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildProfileActionButton(
                        label: 'Cambiar contraseña',
                        icon: Icons.lock_rounded,
                        onTap: () {
                          Navigator.push(
                          context,
                          AppRoutes.fade(ChangePasswordScreen()),
                        );
                        },
                      ),
                      const SizedBox(height: 20),
                      _build2FAButton(),
                      const SizedBox(height: 20),
                      _buildLogoutButton(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.cyan,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.cyan, AppColors.blue, AppColors.purple],
                ).createShader(bounds),
                child: const Text(
                  'MI PERFIL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Text(
                'CYBER OPS  //  OPERACIÓN CLASIFICADA',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.purple.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Animación de las órbitas en la tarjeta de usuario
  Widget _buildAvatarOrbit(String? fotoBase64) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo suave
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF4FC3F7),
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ÓRBITA ELÍPTICA AZUL
          AnimatedBuilder(
            animation: _orbitController,
            builder: (_, _) {
              return CustomPaint(
                painter: _EllipseOrbitPainter(
                  progress: _orbitController.value,
                  color: AppColors.cyan,
                  width: 180,
                  height: 110,
                  angle: math.pi / 4,
                  dotSpeed: 1.0,
                ),
                size: const Size(180, 110),
              );
            },
          ),

          // ÓRBITA ELÍPTICA MORADA
          AnimatedBuilder(
            animation: _orbitController,
            builder: (_, _) {
              return CustomPaint(
                painter: _EllipseOrbitPainter(
                  progress: _orbitController.value,
                  color: AppColors.purple,
                  width: 180,
                  height: 110,
                  angle: -math.pi / 4,
                  dotSpeed: -1.0,
                ),
                size: const Size(180, 110),
              );
            },
          ),

          // Avatar
          ScaleTransition(
            scale: _pulseAnimation,
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage: fotoBase64 == null
                  ? null
                  : MemoryImage(
                      base64Decode(fotoBase64),
                    ),
              child: fotoBase64 == null
                  ? const Icon(Icons.person, size: 45, color: Colors.black87)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // DATOS DEL USUARIO — usa _datosUsuario en vez de llamar a Firestore otra vez
  Widget _buildProfileHeader() {
    if (_datosUsuario == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final datos = _datosUsuario!;
    final fotoBase64 = datos['fotoPerfil'] as String?;
    final name = datos['name'] as String? ?? 'Usuario';
    final email = datos['email'] as String? ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarOrbit(fotoBase64),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ESTADÍSTICAS — usa datos reales de Firestore
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
          label: 'Nivel',
          value: '${_datosUsuario!['nivel'] ?? 1}',
          icon: Icons.bolt_rounded,
          color: AppColors.purple,
        ),
        _buildStatCard(
          label: 'Puntos',
          value: '${_datosUsuario!['puntuacion_total'] ?? 0}',
          icon: Icons.emoji_events_rounded,
          color: AppColors.cyan,
        ),
        _buildStatCard(
          label: 'Partidas',
          value: '${_datosUsuario!['partidas_jugadas'] ?? 0}',
          icon: Icons.flag_rounded,
          color: AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // INFORMACIÓN EDITABLE
  Widget _buildEditableInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información personal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(label: 'Nombre', controller: _nameController),
          const SizedBox(height: 12),
          _buildTextField(label: 'Email', controller: _emailController),
          const SizedBox(height: 12),
          _buildTextField(label: 'Descripción', controller: _bioController, maxLines: 3),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
              ),
              onPressed: _guardarCambios,
              icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Guardar cambios',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.purple),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }

  // BOTONES DE ACCIÓN
  Widget _buildProfileActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    _isHoveringProfile.putIfAbsent(label, () => false);
    final isHovering = _isHoveringProfile[label]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringProfile[label] = true),
      onExit: (_) => setState(() => _isHoveringProfile[label] = false),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 58, 
          child: OverflowBox(
            maxHeight: 80, 
            alignment: Alignment.center,
            child: Transform.scale(
              scale: isHovering ? 1.02 : 1.0, 
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isHovering ? AppColors.cyan : AppColors.purple,
                  ),
                  boxShadow: isHovering
                      ? [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: AppStyles.buttonSecondary,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// BOTÓN 2FA
Widget _build2FAButton() {
  _isHoveringProfile.putIfAbsent('2fa', () => false);
  final isHovering = _isHoveringProfile['2fa']!;
  final color = _totpEnabled ? AppColors.cyan : AppColors.purple;

  return MouseRegion(
    onEnter: (_) => setState(() => _isHoveringProfile['2fa'] = true),
    onExit: (_) => setState(() => _isHoveringProfile['2fa'] = false),
    child: GestureDetector(
      onTap: () async {
        if (_totpEnabled) {
          // Confirmar desactivación
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Desactivar 2FA', style: TextStyle(color: Colors.white)),
              content: const Text(
                '¿Estás seguro de que quieres desactivar la autenticación de dos factores?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Desactivar', style: TextStyle(color: AppColors.pink)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _authService.disableTotp();
            setState(() => _totpEnabled = false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('2FA desactivado'),
                backgroundColor: AppColors.purple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        } else {
          final activado = await Navigator.push<bool>(
            context,
            AppRoutes.fade(const TotpSetupScreen()),
          );
          if (activado == true) setState(() => _totpEnabled = true);
        }
      },
      child: SizedBox(
        height: 58,
        child: OverflowBox(
          maxHeight: 80,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: isHovering ? 1.02 : 1.0,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHovering ? AppColors.cyan : color.withValues(alpha: 0.7),
                ),
                boxShadow: isHovering
                    ? [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    _totpEnabled ? Icons.verified_user_rounded : Icons.security_rounded,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _totpEnabled ? 'Autenticación 2FA (activa)' : 'Activar autenticación 2FA',
                      style: AppStyles.buttonSecondary.copyWith(color: color),
                    ),
                  ),
                  Icon(
                    _totpEnabled ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                    color: _totpEnabled ? AppColors.cyan : Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

//BOTÓN CERRAR SESIÓN
Widget _buildLogoutButton() {
  _isHoveringProfile.putIfAbsent('Cerrar sesión', () => false);
  final isHovering = _isHoveringProfile['Cerrar sesión']!;

  return MouseRegion(
    onEnter: (_) => setState(() => _isHoveringProfile['Cerrar sesión'] = true),
    onExit: (_) => setState(() => _isHoveringProfile['Cerrar sesión'] = false),
    child: GestureDetector(
      onTap: _cerrarSesion,
      child: SizedBox(
        height: 58,
        child: OverflowBox(
          maxHeight: 80,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: isHovering ? 1.02 : 1.0,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHovering
                      ? Colors.redAccent.withValues(alpha: 0.9)
                      : Colors.red.withValues(alpha: 0.6),
                ),
                boxShadow: isHovering
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cerrar sesión',
                      style: AppStyles.buttonSecondary.copyWith(
                        color: Colors.red.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _EllipseOrbitPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double width;
  final double height;
  final double angle;
  final double dotSpeed;

  _EllipseOrbitPainter({
    required this.progress,
    required this.color,
    required this.width,
    required this.height,
    required this.angle,
    required this.dotSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rotamos la elipse
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);

    // Órbita nítida
    final orbitPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: height,
    );

    canvas.drawOval(rect, orbitPaint);

    // Punto pegado a la elipse
    final t = progress * 2 * math.pi * (dotSpeed * 4);
    final x = (width / 2) * math.cos(t);
    final y = (height / 2) * math.sin(t);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2 + x, size.height / 2 + y),
      5,
      dotPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------
// REUTILIZAMOS EL BACKGROUND PAINTER DEL MENU
// -----------------------------------------------------------
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
      (angle: progress * 2 * math.pi, radius: 280.0, color: AppColors.purple, size: 3.0),
      (angle: progress * 2 * math.pi + math.pi, radius: 280.0, color: AppColors.blue, size: 3.0),
      (angle: -progress * 2 * math.pi + math.pi / 3, radius: 200.0, color: AppColors.cyan, size: 2.5),
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