
// Importamos Flutter para crear la interfaz visual
import 'package:cyber_ops/config/app_routes.dart';
import 'package:cyber_ops/screens/menu_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Importamos la librería matemática para calcular posiciones

// Importamos los colores y estilos del proyecto
import '../config/app_colors.dart';
import '../config/app_styles.dart';
// Importamos la pantalla principal
import 'home_screen.dart';

// SplashScreen es la pantalla de carga con estilo hackeo de sistema
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Controlador principal de la animación de entrada del logo
  late AnimationController _logoController;
  // Controlador de las barras de carga (loop continuo)
  late AnimationController _barsController;
  // Controlador del parpadeo del texto de sistema
  late AnimationController _blinkController;

  // Animación de opacidad del logo
  late Animation<double> _fadeAnimation;
  // Animación de escala del logo
  late Animation<double> _scaleAnimation;
  // Animación de parpadeo del cursor
  late Animation<double> _blinkAnimation;

  // Lista de mensajes que simulan un hackeo de sistema
  final List<String> _systemMessages = [
    'INICIANDO SISTEMA...',
    'VERIFICANDO CREDENCIALES...',
    'ACCEDIENDO A LA RED...',
    'DESCIFRANDO PROTOCOLOS...',
    'ESTABLECIENDO CONEXIÓN...',
    'ACCESO CONCEDIDO',
  ];

  // Índice del mensaje actual que se está mostrando
  int _currentMessage = 0;
  // Progreso total de carga (de 0.0 a 1.0)
  double _totalProgress = 0.0;
  // Lista de barras de carga individuales con su progreso
  final List<double> _barProgress = [0.0, 0.0, 0.0, 0.0,0.0];
  // Nombres de cada barra de carga
  final List<String> _barLabels = [
    'SISTEMA',
    'RED',
    'CIFRADO',
    'ACCESO',
    'IDENTIFICACIÓN'
    

  ];

  @override
  void initState() {
    super.initState();

    // Controlador del logo: animación de entrada de 1.5 segundos
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Controlador de las barras: loop de 3 segundos
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Controlador del parpadeo: loop rápido de 0.8 segundos
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Logo aparece de transparente a visible
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Logo aparece de pequeño a tamaño normal
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Cursor parpadea entre visible e invisible
    _blinkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Arrancamos la animación del logo
    _logoController.forward();

    // Después de 0.5 segundos empezamos a llenar las barras
    Future.delayed(const Duration(milliseconds: 500), () {
      _startLoadingSequence();
    });

    _checkAuth();

  }

  Future<void> _checkAuth() async {

    await Future.delayed(const Duration(seconds: 5));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {

      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          AppRoutes.fade(const MenuScreen()),
        );

        return;
      }

      // si no está verificado → logout
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      AppRoutes.fade(const HomeScreen()),
    );
  }

  // _startLoadingSequence llena las barras de carga una por una
  void _startLoadingSequence() async {
    // Recorremos cada barra de carga
    for (int i = 0; i < _barLabels.length; i++) {
      // Llenamos la barra actual de 0 a 1 en pasos pequeños
      for (double p = 0.0; p <= 1.05; p += 0.05) {
        // Esperamos un poco entre cada paso para ver la animación
        await Future.delayed(const Duration(milliseconds: 10));
        if (!mounted) return;
        setState(() {
          // Actualizamos el progreso de la barra actual
          _barProgress[i] = p.clamp(0.0, 1.0);
          // El progreso total es el promedio de todas las barras
          _totalProgress = _barProgress.reduce((a, b) => a + b) / _barProgress.length;
          // Cambiamos el mensaje según qué barra se está llenando
          _currentMessage = (i * 1.2).floor().clamp(0, _systemMessages.length - 2);
        });
      }
      // Pequeña pausa entre barras
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Cuando todas las barras están llenas mostramos "ACCESO CONCEDIDO"
    if (mounted) {
      setState(() {
        _currentMessage = _systemMessages.length - 1;
        _totalProgress = 1.0;
      });
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _barsController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [

          // ── FONDO CON LÍNEAS DE CUADRÍCULA ──────────────────────────────
          // Dibujamos una cuadrícula sutil de fondo estilo terminal
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),

          // ── CONTENIDO PRINCIPAL ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── LOGO CENTRADO ──────────────────────────────────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 250,
                              height: 250,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── TÍTULO ────────────────────────────────────────────
                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppColors.purple, AppColors.blue, AppColors.cyan],
                      ).createShader(bounds),
                      child: const Text(
                        'CYBER OPS',
                        style: AppStyles.titleMain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── LÍNEA SEPARADORA ──────────────────────────────────
                  Container(
                    height: 1,
                    color: AppColors.purple.withValues(alpha: 0.3),
                  ),

                  const SizedBox(height: 20),

                  // ── MENSAJE DE SISTEMA ────────────────────────────────
                  Row(
                    children: [
                      // Prefijo de terminal
                      Text(
                        '> ',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Mensaje actual del sistema
                      Text(
                        _systemMessages[_currentMessage],
                        style: TextStyle(
                          color: _currentMessage == _systemMessages.length - 1
                              ? const Color.fromARGB(255, 30, 212, 6)
                              : AppColors.purple,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      // Cursor parpadeante estilo terminal
                      AnimatedBuilder(
                        animation: _blinkAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _blinkAnimation.value,
                            child: Text(
                              ' █',
                              style: TextStyle(
                                color: AppColors.purple,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── BARRAS DE CARGA INDIVIDUALES ──────────────────────
                  // Mostramos una barra por cada módulo del sistema
                  ...List.generate(_barLabels.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabecera de la barra: nombre y porcentaje
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _barLabels[index],
                                style: TextStyle(
                                  color: AppColors.purple.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  letterSpacing: 3,
                                ),
                              ),
                              Text(
                                // Mostramos el porcentaje de esa barra
                                '${(_barProgress[index] * 100).toInt()}%',
                                style: TextStyle(
                                  color: _barProgress[index] >= 1.0
                                      ? AppColors.cyan
                                      : AppColors.purple,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Barra de progreso
                          Stack(
                            children: [
                              // Fondo de la barra (vacío)
                              Container(
                                height: 4,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Relleno de la barra (progreso actual)
                              FractionallySizedBox(
                                widthFactor: _barProgress[index],
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _barProgress[index] >= 1.0
                                          ? [AppColors.cyan, AppColors.blue]
                                          : [AppColors.purple, AppColors.blue],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.purple.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  

                  const SizedBox(height: 16),

                  // ── BARRA DE PROGRESO TOTAL ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROGRESO TOTAL',
                        style: TextStyle(
                          color: AppColors.purple.withValues(alpha: 0.6),
                          fontSize: 15,
                          fontFamily: 'monospace',
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        '${(_totalProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: _totalProgress >= 1.0
                              ? AppColors.cyan
                              : AppColors.purple,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Barra de progreso total más gruesa
                  Stack(
                    children: [
                      Container(
                        height: 15,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _totalProgress,
                        child: Container(
                          height: 15,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _totalProgress >= 1.0
                                  ? [AppColors.cyan, AppColors.blue, AppColors.purple]
                                  : [AppColors.purple, AppColors.blue],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _GridPainter dibuja una cuadrícula sutil de fondo estilo terminal
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // Dibujamos líneas verticales cada 40 píxeles
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Dibujamos líneas horizontales cada 40 píxeles
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}