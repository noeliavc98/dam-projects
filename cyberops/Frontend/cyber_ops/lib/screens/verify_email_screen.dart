import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/config/app_routes.dart';
import 'package:cyber_ops/config/app_styles.dart';
import 'package:cyber_ops/screens/menu_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class VerifyEmailScreen extends StatefulWidget {

  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends State<VerifyEmailScreen> {

  bool _isLoading = false;

  bool _canResend = true;
  int _secondsLeft = 30;

  Timer? _timer;

  Future<void> _checkVerification() async {

    setState(() => _isLoading = true);

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      await user?.reload();

      final refreshedUser =
          FirebaseAuth.instance.currentUser;

      if (refreshedUser != null &&
          refreshedUser.emailVerified) {

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          AppRoutes.fade(const MenuScreen()),
        );

      } else {

        _showMessage(
          'Aún no has verificado tu correo',
        );
      }

    } catch (e) {

      _showMessage(
        'Error comprobando verificación',
      );

    } finally {

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendEmail() async {

    if (!_canResend) return;

    try {

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage('No hay usuario autenticado');
        return;
      }

      await user.reload();

      await user.sendEmailVerification();

      _showMessage(
        'Correo reenviado correctamente',
      );

      setState(() {});
      
      _startCooldown();

    } on FirebaseAuthException catch (e) {

      _showMessage(
        _mapFirebaseError(e.code),
      );

    } catch (e) {

      _showMessage(
        'No se pudo reenviar el correo',
      );
    }
  }

  String _mapFirebaseError(String code) {

    switch (code) {

      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';

      case 'network-request-failed':
        return 'Error de conexión';

      case 'user-token-expired':
        return 'La sesión ha expirado';

      default:
        return 'Error al reenviar correo';
    }
  }

  void _startCooldown() {

    _canResend = false;
    _secondsLeft = 30;

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {

        if (_secondsLeft == 0) {

          timer.cancel();

          if (mounted) {
            setState(() {
              _canResend = true;
            });
          }

        } else {

          if (mounted) {
            setState(() {
              _secondsLeft--;
            });
          }
        }
      },
    );
  }

  Future<void> _backToLogin() async {

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pop(context);
  }

  void _showMessage(String message) {

    ScaffoldMessenger.of(context)
        .clearSnackBars();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.purple,
      ),
    );
  }

  @override
  void dispose() {

    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bgMain,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),

            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                crossAxisAlignment:
                    CrossAxisAlignment.center,

                children: [

                  const Icon(
                    Icons.mark_email_read_rounded,
                    size: 90,
                    color: AppColors.purple,
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Verifica tu correo',
                    style: AppStyles.screenTitle,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Te hemos enviado un enlace de verificación a:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.email,
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Por motivos de seguridad, debes verificar tu identidad antes de acceder a CyberOps.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Si no encuentras el email, revisa en Spam.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,

                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _checkVerification,

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.purple,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'YA LO HE VERIFICADO',
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextButton(
                    onPressed: _canResend ? _resendEmail : null,

                    child: Text(
                      _canResend
                        ? 'Reenviar correo'
                        : 'Reintenta en $_secondsLeft s',
                      style: TextStyle(
                        color: AppColors.cyan,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: _backToLogin,

                    child: const Text(
                      'Volver al login',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}