import 'package:cyber_ops/screens/recover_screen.dart';
import 'package:cyber_ops/screens/register_screen.dart';
import 'package:cyber_ops/screens/totp_verify_screen.dart';
import 'package:cyber_ops/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_styles.dart';
import '../services/auth_service.dart';
import 'menu_screen.dart';
import 'package:cyber_ops/config/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para cada campo de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Map<String, bool> _isHovering = {};
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // Controla si la contraseña se ve o no
  bool _obscurePassword = true;
  // Controla si mostrar el spinner de carga
  bool _isLoading = false;

  // Libera los controllers de la memoria al cerrar la pantalla
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Método que se ejecuta al pulsar INICIAR SESIÓN
  Future<void> _handleLogin() async {
    // Validaciones básicas antes de llamar a Firebase
    if (_emailController.text.isEmpty) {
      _showError('Por favor ingresa tu email');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Por favor ingresa tu contraseña');
      return;
    }

    // Mostramos el spinner de carga
    setState(() => _isLoading = true);

    // Llamamos al servicio de autenticación
    final error = await _authService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // Ocultamos el spinner
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {

      if (error == 'EMAIL_NOT_VERIFIED') {

        Navigator.pushReplacement(
          context,
          AppRoutes.fade(
            const VerifyEmailScreen(email: '',),
          ),
        );

        return;
      }
      // Si hay error lo mostramos en rojo
      _showError(error);
    } else {
      // Comprobar si el usuario tiene 2FA activo
      final totp2fa = await _authService.isTotpEnabled();
      if (!mounted) return;

      if (totp2fa) {
        // Redirigir a verificación 2FA sin mostrar menú todavía
        Navigator.pushAndRemoveUntil(
          context,
          AppRoutes.fade(const TotpVerifyScreen()),
          (route) => false,
        );
      } else {
        _showSuccess('¡Acceso concedido! Bienvenido agente.');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          AppRoutes.fade(
            const MenuScreen(),
            settings: const RouteSettings(name: AppRoutes.menu),
          ),
          (route) => false,
        );
      }
    }
  }

  // Muestra un mensaje de error en rojo
  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.pink,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Muestra un mensaje de éxito en morado
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, letterSpacing: 1),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.purple,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Widget BUILDBUTTON para que se vea bien el botón y tenga el zoom y el gradiente //
  Widget _buildButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    _isHovering.putIfAbsent(label, () => false);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering[label] = true),
      onExit: (_) => setState(() => _isHovering[label] = false),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedScale(
          scale: _isHovering[label]! ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
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
                if (isLoading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: isPrimary || _isHovering[label]!
                        ? AppStyles.buttonPrimary
                        : AppStyles.buttonSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),

                  MouseRegion(
                    onEnter: (_) => setState(() => _isHovering['back'] = true),
                    onExit: (_) => setState(() => _isHovering['back'] = false),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: AnimatedScale(
                        scale: _isHovering['back'] ?? false ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: _isHovering['back'] ?? false
                                ? const LinearGradient(
                                    colors: [AppColors.purple, AppColors.blue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _isHovering['back'] ?? false
                                ? null
                                : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isHovering['back'] ?? false
                                  ? Colors.transparent
                                  : AppColors.purple,
                              width: 1.5,
                            ),
                            boxShadow: _isHovering['back'] ?? false
                                ? [
                                    BoxShadow(
                                      color: AppColors.cyan.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _isHovering['back'] ?? false
                                ? Colors.white
                                : AppColors.purple,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── CABECERA ──────────────────────────────────────────
                  const Text(
                    'Accede a tu cuenta',
                    style: AppStyles.screenTitle,
                  ),
                  const SizedBox(height: 25),

                  // ── CAMPO EMAIL ───────────────────────────────────────
                  _CyberField(
                    label: 'CORREO ELECTRÓNICO',
                    hint: 'tucorreo@gmail.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 24),

                  // ── CAMPO CONTRASEÑA ──────────────────────────────────
                  _CyberField(
                    label: 'CONTRASEÑA',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscure: _obscurePassword,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) async {
                      _passwordFocus.unfocus();
                      await _handleLogin();
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.purple,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── OLVIDÉ MI CONTRASEÑA ──────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          AppRoutes.fade(ForgotPasswordScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cyan,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.cyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── BOTÓN INICIAR SESIÓN ──────────────────────────────
                  Center(
                    child: _buildButton(
                      label: 'INICIAR SESIÓN',
                      isPrimary: true,
                      isLoading: _isLoading,
                      onTap: _handleLogin,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── SEPARADOR ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: AppColors.bgCard),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'O',
                          style: TextStyle(
                            color: AppColors.purple.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: AppColors.bgCard),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── PIE DE PÁGINA ─────────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '¿No tienes cuenta? ',
                          style: AppStyles.small.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              AppRoutes.fade(RegisterScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              color: AppColors.cyan,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget reutilizable para cada campo del formulario
class _CyberField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _CyberField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta superior
        Text(label, style: AppStyles.small.copyWith(color: Colors.white)),
        const SizedBox(height: 8),

        // Campo de texto
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.purple.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            filled: true,
            fillColor: AppColors.bgCard,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.bgCard, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.pink, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
