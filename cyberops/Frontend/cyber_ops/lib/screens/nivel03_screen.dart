import 'dart:async';
import 'package:cyber_ops/config/app_routes.dart';
import 'package:cyber_ops/screens/level_map_screen.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../games/nivel_03/nivel03_game.dart';
import '../games/nivel_01/components/nodo_component.dart';
import '../widgets/level_hud/responsive_game_hud.dart';

class Nivel03Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel03Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel03Screen> createState() => _Nivel03ScreenState();
}

class _Nivel03ScreenState extends State<Nivel03Screen>
    with WidgetsBindingObserver {
  Nivel03Game? _game;
  int _puntos = 0;
  int _vidas = 3;
  bool _cargando = true;
  bool _nivelYaCompletado = false;

  // Estado de la habilidad de invisibilidad
  bool _habilidadActiva = false;
  double _cooldownHabilidad = 0;
  double _duracionRestante = 0;

  List<Map<String, dynamic>> _cola = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Nivel 3, operador.',
    'Esta vez no vas a quedarte mirando una pantalla estática. Vas a entrar en una zona de reconocimiento activo.',
    'Tu objetivo es moverte por el entorno, localizar los nodos del sistema y atacarlos para extraer información. Cada nodo que alcances activará una pregunta: responde correctamente antes de que se agote el tiempo para comprometerlo y sumar puntos.',
    'Pero cuidado. El sistema no está dormido. Si fallas demasiadas respuestas o pierdes el control de la operación, serás detectado.'
    'Usa el movimiento para posicionarte, dispara con precisión y activa la invisibilidad cuando necesites ganar unos segundos de ventaja.',
    'Entra, analiza, responde y sal antes de que el sistema te cierre el paso.',
  ];

  static const List<Map<String, dynamic>> _preguntasLocales = [
    {
      'pregunta': '¿Qué es la ingeniería social en ciberseguridad?',
      'opciones': [
        'Crear programas informáticos',
        'Manipular a personas para obtener información',
        'Reparar ordenadores',
        'Diseñar redes',
      ],
      'correcta': 'Manipular a personas para obtener información',
      'puntos': 100,
    },
    {
      'pregunta':
          '¿Qué tipo de software es diseñado para dañar o infiltrarse en un sistema?',
      'opciones': ['Firewall', 'Antivirus', 'Malware', 'VPN'],
      'correcta': 'Malware',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué significa la autenticación de dos factores (2FA)?',
      'opciones': [
        'Usar dos contraseñas',
        'Usar contraseña y otro método (código, móvil, etc.)',
        'Compartir la cuenta con otra persona',
        'Cambiar la contraseña dos veces',
      ],
      'correcta': 'Usar contraseña y otro método (código, móvil, etc.)',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué hace un ransomware?',
      'opciones': [
        'Borra archivos sin aviso',
        'Roba contraseñas',
        'Bloquea tus archivos y pide dinero',
        'Mejora la seguridad',
      ],
      'correcta': 'Bloquea tus archivos y pide dinero',
      'puntos': 100,
    },
    {
      'pregunta': '¿Por qué es importante actualizar el software?',
      'opciones': [
        'Para ocupar más espacio',
        'Para arreglar fallos de seguridad',
        'Para que funcione más lento',
        'No es importante',
      ],
      'correcta': 'Para arreglar fallos de seguridad',
      'puntos': 100,
    },
    {
      'pregunta': '¿Cuál de estas URLs es probablemente falsa?',
      'opciones': [
        'https://www.amazon.com',
        'https://secure.paypal.com',
        'https://paypal-verificacion.ru',
        'https://www.microsoft.com',
      ],
      'correcta': 'https://paypal-verificacion.ru',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué es un ataque de fuerza bruta?',
      'opciones': [
        'Hackear usando virus',
        'Probar muchas contraseñas hasta acertar',
        'Engañar a una persona',
        'Romper el ordenador físicamente',
      ],
      'correcta': 'Probar muchas contraseñas hasta acertar',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué indica el “https” en una web?',
      'opciones': [
        'Que es más rápida',
        'Que está cifrada y es más segura',
        'Que es gratis',
        'Que tiene publicidad',
      ],
      'correcta': 'Que está cifrada y es más segura',
      'puntos': 100,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (!_mostrarFractura) {
      _iniciarJuego();
    } else {
      setState(() => _cargando = false);
    }
    WidgetsBinding.instance.addObserver(this);
  }

  void _rellenarCola() {
    _cola = List.from(_todasPreguntas)..shuffle();
  }

  Map<String, dynamic> _siguientePregunta() {
    if (_cola.isEmpty) _rellenarCola();
    return _cola.removeAt(0);
  }

  Future<void> _iniciarJuego() async {
    try {
      await MusicService().playNivel2Music(restart: true);
    } catch (e) {
      debugPrint('Error iniciando musica de combate del nivel 3: $e');
    }

    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      final datos = await FirestoreService.obtenerUsuario();
      final nivelUsuario = datos['nivel'] ?? 1;
      if (nivelUsuario > 3) _nivelYaCompletado = true;
    }

    List<Map<String, dynamic>> preguntas = [];
    try {
      preguntas = await ApiService.obtenerPreguntas(
        nivel: 1,
        mision: 1,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (preguntas.isEmpty) preguntas = _preguntasLocales;

    _todasPreguntas = preguntas;
    _rellenarCola();
    setState(() => _cargando = false);

    _game = Nivel03Game(
      onNodoTocado: _mostrarPregunta,
      onEstadoActualizado: (puntos, vidas) {
        if (mounted) {
          setState(() {
            _puntos = puntos;
            _vidas = vidas;
          });
        }
      },
      onJuegoTerminado: _mostrarGameOver,
      onNivelCompletado: _mostrarVictoria,
      onHabilidadActualizada: (activa, cooldown, duracion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _habilidadActiva = activa;
              _cooldownHabilidad = cooldown;
              _duracionRestante = duracion;
            });
          }
        });
      },
    );

    _game!.cargarPreguntas(preguntas);
    if (mounted) setState(() {});
  }

  void _mostrarPregunta(NodoComponent nodo) {
    final pregunta = _siguientePregunta();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoPregunta(
        pregunta: pregunta,
        onRespuesta: (correcta, puntos) {
          Navigator.pop(context);
          if (correcta) {
            _game?.respuestaCorrecta(nodo, puntos);
          } else {
            _game?.respuestaIncorrecta(nodo);
          }
        },
      ),
    );
  }

  Future<void> _reintentarNivel() async {
    Navigator.pop(context);
    try {
      await MusicService().playNivel2Music(restart: true);
    } catch (e) {
      debugPrint('Error reiniciando musica del nivel 3: $e');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppRoutes.fade(
        Nivel03Screen(soloEntrenamiento: widget.soloEntrenamiento),
      ),
    );
  }

  void _mostrarGameOver() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultado(
        titulo: 'MISIÓN FALLIDA',
        subtitulo: 'Has sido detectado por el sistema',
        puntos: _puntos,
        exito: false,
        nivelYaCompletado: _nivelYaCompletado,
        onReintentar: _reintentarNivel,
        onSalir: () {
          Navigator.pop(context); // cierra el diálogo
          Navigator.pushAndRemoveUntil(
            context,
            AppRoutes.fade(LevelMapScreen()),
            (route) => route.settings.name == 'menu', // ✅ para en MenuScreen
          );
        },
      ),
    );
  }

  void _mostrarVictoria() async {
    if (!_nivelYaCompletado) {
      await FirestoreService.guardarPuntuacion(
        puntos: _puntos,
        nivelCompletado: 3,
      );
      await FirestoreService.guardarMision(
        nivel: 3,
        mision: 3,
        puntos: _puntos,
      );
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultado(
        titulo: 'NODO COMPROMETIDO',
        subtitulo: _nivelYaCompletado
            ? 'Modo entrenamiento'
            : 'Infiltración completada con éxito',
        puntos: _puntos,
        exito: true,
        nivelYaCompletado: _nivelYaCompletado,
        onReintentar: _reintentarNivel,
        onSalir: () {
          Navigator.pop(context); // cierra el diálogo
          Navigator.pushAndRemoveUntil(
            context,
            AppRoutes.fade(LevelMapScreen()),
            (route) => route.settings.name == 'menu', // ✅ para en MenuScreen
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarFractura) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Container(
          color: Colors.black.withValues(alpha: 0.80),
          child: FracturaDialogo(
            dialogos: _dialogosFractura,
            subtitulo: 'NIVEL 3 // CONCEPTOS BASE',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () async {
              setState(() {
                _mostrarFractura = false;
                _cargando = true;
              });

              await _iniciarJuego();
            },
          ),
        ),
      );
    }

    if (_cargando || _game == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          // ── JUEGO FLAME ──────────────────────────────────────────────────
          // MouseRegion SIN ocultar el cursor — el ratón es visible siempre
          // onHover actualiza el ángulo de la flecha sin disparar
          // onPointerDown dispara hacia donde se hizo click/tap
          // onPointerMove actualiza la flecha al arrastrar en móvil
          MouseRegion(
            onHover: (event) {
              // Actualiza la flecha según posición del ratón
              _game?.actualizarPuntero(event.localPosition);
            },
            child: Listener(
              onPointerDown: (event) {
                // Click izquierdo o tap → dispara hacia esa posición
                _game?.dispararHaciaOffset(event.localPosition);
              },
              onPointerMove: (event) {
                // Arrastrar en móvil → actualiza la flecha
                _game?.actualizarPuntero(event.localPosition);
              },
              child: GameWidget(game: _game!),
            ),
          ),

          if (_nivelYaCompletado) const GameTrainingBanner(),
          ResponsiveGameHud(
            title: 'RECONOCIMIENTO',
            onBack: () => Navigator.pop(context),
            verticalOffset: _nivelYaCompletado ? 48 : 10,
            compactVerticalOffset: _nivelYaCompletado ? 48 : 10,
            stats: [
              GameHudHearts(lives: _vidas),
              GameHudChip(label: '$_puntos pts'),
            ],
          ),

          // ── BOTÓN INVISIBILIDAD ──────────────────────────────────────────
          Positioned(
            bottom: 28,
            right: 20,
            child: _BotonInvisibilidad(
              activa: _habilidadActiva,
              cooldown: _cooldownHabilidad,
              cooldownMax: 1.0,
              duracionRestante: _duracionRestante,
              duracionMax: 4.0,
              onTap: () => _game?.activarInvisibilidad(),
            ),
          ),

          const GameHintOverlay(
            text:
                'WASD / Joystick para mover - Click / Tap para disparar - E para invisibilidad',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_game == null) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _game!.limpiarInputs();
        if (_game!.juegoActivo && !_game!.preguntaAbierta) {
          _game!.pauseEngine();
        }
        break;
      case AppLifecycleState.resumed:
        if (_game!.juegoActivo && !_game!.preguntaAbierta) {
          _game!.resumeEngine();
        }
        break;
      default:
        break;
    }
  }
}

// ── BOTÓN HABILIDAD INVISIBILIDAD ─────────────────────────────────────────────
class _BotonInvisibilidad extends StatelessWidget {
  final bool activa;
  final double cooldown;
  final double cooldownMax;
  final double duracionRestante;
  final double duracionMax;
  final VoidCallback onTap;

  const _BotonInvisibilidad({
    required this.activa,
    required this.cooldown,
    required this.cooldownMax,
    required this.duracionRestante,
    required this.duracionMax,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enCooldown = cooldown > 0;
    final disponible = !activa && !enCooldown;

    // Color del botón según estado
    final color = activa
        ? AppColors.cyan
        : enCooldown
        ? AppColors.cyan.withValues(alpha: 0.25)
        : AppColors.cyan.withValues(alpha: 0.7);

    // Progreso del arco: durante invisibilidad muestra duración restante,
    // durante cooldown muestra el tiempo restante de espera
    final double progreso = activa
        ? duracionRestante / duracionMax
        : enCooldown
        ? cooldown / cooldownMax
        : 0.0;

    return GestureDetector(
      onTap: disponible ? onTap : null,
      child: SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arco de progreso
            if (activa || enCooldown)
              SizedBox(
                width: 62,
                height: 62,
                child: CircularProgressIndicator(
                  value: progreso,
                  strokeWidth: 2.5,
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    activa
                        ? AppColors.cyan.withValues(alpha: 0.8)
                        : AppColors.cyan.withValues(alpha: 0.25),
                  ),
                ),
              ),

            // Cuerpo del botón
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activa
                    ? AppColors.cyan.withValues(alpha: 0.15)
                    : AppColors.bgCard,
                border: Border.all(color: color, width: activa ? 2.0 : 1.5),
                boxShadow: activa
                    ? [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    activa
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    activa
                        ? '${duracionRestante.ceil()}s'
                        : enCooldown
                        ? '${(cooldown * 2).ceil()}⬤'
                        : 'E',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DIÁLOGO PREGUNTA ──────────────────────────────────────────────────────────
class _DialogoPregunta extends StatefulWidget {
  final Map<String, dynamic> pregunta;
  final void Function(bool correcta, int puntos) onRespuesta;

  const _DialogoPregunta({required this.pregunta, required this.onRespuesta});

  @override
  State<_DialogoPregunta> createState() => _DialogoPreguntaState();
}

class _DialogoPreguntaState extends State<_DialogoPregunta> {
  static const int _duracion = 20;
  int _segundosRestantes = _duracion;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosRestantes <= 1) {
        t.cancel();
        if (mounted) {
          Navigator.pop(context);
          widget.onRespuesta(false, 0);
        }
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _segundosRestantes <= 10
        ? Colors.redAccent
        : AppColors.cyan;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.2),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.terminal_rounded,
                    color: AppColors.cyan,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'NODO DETECTADO',
                  style: TextStyle(
                    color: AppColors.cyan.withValues(alpha: 0.7),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${widget.pregunta['puntos']} pts',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _segundosRestantes / _duracion,
                      backgroundColor: timerColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_segundosRestantes s',
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.pregunta['pregunta'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...List<String>.from(widget.pregunta['opciones'] ?? []).map(
              (opcion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    _timer?.cancel();
                    final esCorrecta = opcion == widget.pregunta['correcta'];
                    widget.onRespuesta(
                      esCorrecta,
                      widget.pregunta['puntos'] as int,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      opcion,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DIÁLOGO RESULTADO ─────────────────────────────────────────────────────────
class _DialogoResultado extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int puntos;
  final bool exito;
  final bool nivelYaCompletado;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _DialogoResultado({
    required this.titulo,
    required this.subtitulo,
    required this.puntos,
    required this.exito,
    required this.nivelYaCompletado,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final color = exito ? AppColors.cyan : AppColors.pink;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$puntos PUNTOS',
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            if (nivelYaCompletado && exito) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.purple.withValues(alpha: 0.7),
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Modo entrenamiento — puntos no guardados',
                      style: TextStyle(
                        color: AppColors.purple.withValues(alpha: 0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReintentar,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.purple.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSalir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  exito ? 'CONTINUAR' : 'SALIR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
