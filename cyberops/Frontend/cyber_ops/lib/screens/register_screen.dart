import 'package:cyber_ops/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_styles.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Map<String, bool> _isHovering = {};
  //Foco a los diferentes campos del registro //
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();


  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validaciones básicas
    if (_usernameController.text.isEmpty) {
      _showError('Por favor ingresa un usuario');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showError('Por favor ingresa un email');
      return;
    }
    if (!_isValidEmail(_emailController.text)) {
      _showError('Por favor ingresa un email válido (ej: usuario@gmail.com)');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Por favor ingresa una contraseña');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (!_isStrongPassword(_passwordController.text)) {
      _showError(
        'La contraseña debe contener al menos:\n'
        '• Una letra mayúscula\n'
        '• Un carácter especial',
      );
      return;
    }

    // ── CORRECCIÓN: activamos el spinner ANTES de llamar a Firebase ──
    setState(() => _isLoading = true);

    final error = await _authService.registerUser(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    // Desactivamos el spinner siempre, haya error o no
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;~/`]').hasMatch(password);
    return hasUppercase && hasSpecialChar;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.pink,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  // Widget BUILD BUTTON para crear el botón de crear cuenta // 
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
                        color: AppColors.cyan.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : (isPrimary
                      ? [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.35),
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
      body: Stack(
        children: [
          SafeArea(
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
                          color: _isHovering['back'] ?? false ? null : AppColors.bgCard,
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
                                    color: AppColors.cyan.withOpacity(0.4),
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
                      const Text(
                        'Crea tu cuenta',
                        style: AppStyles.screenTitle,
                      ),
                      const SizedBox(height: 15),
                        // CAMPOS //

                      _CyberField(
                        label: 'USUARIO',
                        hint: 'tu_usuario',
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        focusNode: _usernameFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                      ),
                      const SizedBox(height: 20),

                      _CyberField(
                        label: 'CORREO ELECTRÓNICO',
                        hint: 'tucorreo@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 20),

                      _CyberField(
                        label: 'CONTRASEÑA',
                        hint: '',
                        controller: _passwordController,
                        obscure: _obscurePassword,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
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
                      const SizedBox(height: 20),

                      _CyberField(
                        label: 'CONFIRMAR CONTRASEÑA',
                        hint: '',
                        controller: _confirmPasswordController,
                        obscure: _obscureConfirmPassword,
                        focusNode: _confirmPasswordFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleRegister(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.purple,
                            size: 20,
                          ),
                          onPressed: () => setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildButton(
                        label: 'CREAR CUENTA',
                        isPrimary: true,
                        isLoading: _isLoading,
                        onTap: _handleRegister,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

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
        Text(label, style: AppStyles.small.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
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
              borderSide: const BorderSide(
                color: AppColors.bgCard,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.purple,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.pink,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}