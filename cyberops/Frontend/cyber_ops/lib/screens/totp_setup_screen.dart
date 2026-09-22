import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/config/app_styles.dart';
import 'package:cyber_ops/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';


class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _codeController = TextEditingController();

  late final String _secret;
  late final String _qrUrl;

  bool _loading = false;
  bool _confirmed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _secret = _auth.generateTotpSecret();
    final email = FirebaseAuth.instance.currentUser?.email ?? 'usuario';
    _qrUrl =
        'otpauth://totp/CyberOps:$email?secret=$_secret&issuer=CyberOps&algorithm=SHA1&digits=6&period=30';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Introduce los 6 dígitos del código');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    // Guardamos el secreto temporalmente para poder validar con validateTotpCode
    await _auth.saveTotpSecret(_secret);
    final valido = await _auth.validateTotpCode(code);

    if (!valido) {
      // Si el código no es válido, desactivamos para no dejar un secreto sin confirmar
      await _auth.disableTotp();
      setState(() {
        _loading = false;
        _error = 'Código incorrecto. Asegúrate de haber escaneado el QR correctamente.';
      });
      return;
    }

    setState(() {
      _loading = false;
      _confirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.purple, AppColors.cyan],
          ).createShader(bounds),
          child: const Text('ACTIVAR 2FA', style: AppStyles.body),
        ),
      ),
      body: SafeArea(
        child: _confirmed ? _buildSuccess() : _buildSetup(),
      ),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paso 1
          _buildStepHeader('1', 'Instala una app autenticadora'),
          const SizedBox(height: 8),
          const Text(
            'Descarga Google Authenticator o Authy en tu móvil si aún no la tienes.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Paso 2 — QR
          _buildStepHeader('2', 'Escanea el código QR'),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: _qrUrl,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Clave manual
          const Text(
            'O introduce la clave manualmente:',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _secret));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Clave copiada al portapapeles'),
                  backgroundColor: AppColors.purple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _secret,
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Paso 3 — confirmar código
          _buildStepHeader('3', 'Confirma el código generado'),
          const SizedBox(height: 12),
          const Text(
            'Abre tu app autenticadora e introduce el código de 6 dígitos para verificar que todo funciona.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(
                color: AppColors.purple.withValues(alpha: 0.3),
                fontSize: 28,
                letterSpacing: 12,
              ),
              filled: true,
              fillColor: AppColors.bgCard,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.pink, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.pink, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),

          // Botón activar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'ACTIVAR 2FA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.cyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              '2FA ACTIVADO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu cuenta está protegida con autenticación de dos factores. A partir de ahora necesitarás tu app autenticadora para iniciar sesión.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'VOLVER AL PERFIL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.purple, AppColors.cyan]),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
