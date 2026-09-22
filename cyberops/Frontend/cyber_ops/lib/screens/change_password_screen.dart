import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final Map<String, bool> _isHovering = {};

  bool _isLoading = false;
  bool _passwordChanged = false;
  bool _showCurrentPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;


  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showError("Por favor completa todos los campos");
      return;
    }

    if (newPass.length < 6) {
      _showError("La nueva contraseña debe tener al menos 6 caracteres");
      return;
    }

    if (newPass != confirm) {
      _showError("Las contraseñas no coinciden");
      return;
    }

    if (current == newPass) {
      _showError("La nueva contraseña no puede ser igual a la actual");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      //Validaciones primero (LOCAL)
      if (!_isStrongPassword(newPass)) {
        _showError("Contraseña demasiado débil");
        return;
      }

      // 1. Reautenticación obligatoria
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. Cambiar contraseña
      await user.updatePassword(newPass);

      if (!mounted) return;

      setState(() {
        _passwordChanged = true;
        _isLoading = false;
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showError("La contraseña actual es incorrecta");
      } else if (e.code == 'requires-recent-login') {
        _showError("Vuelve a iniciar sesión para continuar");
      } else {
        _showError("Error al cambiar la contraseña");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.pink,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isStrongPassword(String password) {
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;~/`]').hasMatch(password);

    return hasUppercase && hasLowercase && hasNumber && hasSpecialChar;
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
                children: [
                  // VOLVER
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
                  const SizedBox(height: 25),

                  const Text('Cambiar contraseña', style: AppStyles.screenTitle),
                  const SizedBox(height: 8),
                  _passwordChanged
                      ? _buildSuccessState()
                      : _buildFormState(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // FORMULARIO
  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Introduce tu contraseña actual y tu nueva contraseña.',
          style: AppStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        _CyberField(
          label: 'CONTRASEÑA ACTUAL',
          hint: '••••••••',
          controller: _currentPassController,
          obscure: !_showCurrentPass,
          suffixIcon: IconButton(
            icon: Icon(
              _showCurrentPass
                ? Icons.visibility_outlined 
                : Icons.visibility_off_outlined,
              color: AppColors.purple,
              size: 20,
            ),
            onPressed: () => setState(() {
              _showCurrentPass = !_showCurrentPass;
            }),
          ), keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 24),

        _CyberField(
          label: 'NUEVA CONTRASEÑA',
          hint: '••••••••',
          controller: _newPassController,
          obscure: !_showNewPass,
          suffixIcon: IconButton(
            icon: Icon(
               _showNewPass
                ? Icons.visibility_outlined 
                : Icons.visibility_off_outlined,
              color: AppColors.purple,
              size: 20,
            ),
            onPressed: () => setState(() {
              _showNewPass = !_showNewPass;
            }),
          ), keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 24),

        _CyberField(
          label: 'CONFIRMAR CONTRASEÑA',
          hint: '••••••••',
          controller: _confirmController,
          obscure: !_showConfirmPass,
          suffixIcon: IconButton(
            icon: Icon(
              _showConfirmPass
                ? Icons.visibility_outlined 
                : Icons.visibility_off_outlined,
              color: AppColors.purple,
              size: 20,
            ),
            onPressed: () => setState(() {
              _showConfirmPass = !_showConfirmPass;
            }),
          ), keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleChangePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('GUARDAR CAMBIOS', style: AppStyles.buttonPrimary),
          ),
        ),
      ],
    );
  }

  // ÉXITO
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
            Icons.lock_open_rounded,
            color: AppColors.purple,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),

        const Text('CONTRASEÑA ACTUALIZADA', style: AppStyles.subtitle),
        const SizedBox(height: 12),

        Text(
          'Tu contraseña ha sido cambiada correctamente.',
          style: AppStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('VOLVER', style: AppStyles.buttonPrimary),
          ),
        ),
      ],
    );
  }
}

// CAMPO REUTILIZABLE
class _CyberField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const _CyberField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.suffixIcon, required this.keyboardType
    
    
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
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 15
            ),
          cursorColor: AppColors.cyan,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.cyan),
            filled: true,
            fillColor: AppColors.bgCard,
            suffixIcon: suffixIcon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffixIcon,
                ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.bgCard, 
                width: 1.2
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.purple, 
                width: 1.5
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