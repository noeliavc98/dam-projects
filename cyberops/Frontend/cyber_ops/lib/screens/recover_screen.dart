import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_styles.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final Map<String, bool> _isHovering = {};
  final FocusNode _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showError('Por favor ingresa tu email');
      return;
    }
    if (!_isValidEmail(_emailController.text)) {
      _showError('Por favor ingresa un email válido (ej: usuario@gmail.com)');
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      setState(() => _emailSent = true);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

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

  // ── BUILDBUTTON ───────────────────────────────────────────────────────────
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
            width: double.infinity,
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

                  // ── BOTÓN VOLVER ────────────────────────────────────
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

                  // ── CABECERA ─────────────────────────────────────────
                  const Text('Recuperar contraseña', style: AppStyles.screenTitle),
                  const SizedBox(height: 8),

                  // ── CONTENIDO DINÁMICO ────────────────────────────────
                  _emailSent ? _buildSuccessState() : _buildFormState(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── FORMULARIO ────────────────────────────────────────────────────────────
  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
          style: AppStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.75,
          ),
        ),
        const SizedBox(height: 15),

        _CyberField(
          label: 'CORREO ELECTRÓNICO',
          hint: 'tucorreo@gmail.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          focusNode: _emailFocus,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            _emailFocus.unfocus();
            _handleForgotPassword();
          },
        ),
        const SizedBox(height: 24),

        _buildButton(
          label: 'ENVIAR ENLACE',
          isPrimary: true,
          isLoading: _isLoading,
          onTap: _handleForgotPassword,
        ),
      ],
    );
  }

  // ── CONFIRMACIÓN ──────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.purple.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.purple,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),

        const Text('CORREO ENVIADO', style: AppStyles.subtitle),
        const SizedBox(height: 12),

        Text(
          'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
          style: AppStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        _buildButton(
          label: 'VOLVER AL LOGIN',
          isPrimary: true,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

// ── CyberField ────────────────────────────────────────────────────────────────
class _CyberField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _CyberField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.small.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: AppColors.cyan,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.purple.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            filled: true,
            fillColor: AppColors.bgCard,
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