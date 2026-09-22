import 'package:cyber_ops/games/nivel_01/components/nodo_component.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../games/nivel_05/nivel05_game.dart';
import 'package:cyber_ops/config/app_routes.dart';
import 'package:cyber_ops/screens/level_map_screen.dart';
import '../widgets/level_hud/responsive_game_hud.dart';

class Nivel05Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel05Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel05Screen> createState() => _Nivel05ScreenState();
}

class _Nivel05ScreenState extends State<Nivel05Screen> {
  Nivel05Game? _game;
  int _puntos = 0;
  int _vidas = 3;
  bool _cargando = true;
  bool _nivelYaCompletado = false;
  bool _mostrarAdvertencia = false;

  List<Map<String, dynamic>> _cola = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    '¡Bienvenid@ al nivel 5!',
    'Cuidado con este nivel, te advierto que es mucho más difícil que los demás.',
    'Te explico: solo hay un nodo desbloqueado al que tendrás que acceder para responder a la pregunta, que se bloqueará y cambiará de posición pasados unos segundos.',
    'Te atacan más enemigos, así que atento.',
    'Los nodos van aumentando su velocidad a lo largo del tiempo, por lo que no te duermas y trata de ser rápido.',
    'Nos vemos en el siguiente nivel. ¡Suerte!',
  ];

  static const List<Map<String, dynamic>> _preguntasLocales = [
    {
      'pregunta':
          '¿Qué es una VPN y cómo ayuda a proteger la comunicación en redes Wi-Fi?',
      'opciones': [
        'Una red de alta velocidad que evita el sniffing',
        'Un protocolo de cifrado para proteger la comunicación inalámbrica',
        'Una solución que cifra el tráfico y oculta la IP del usuario',
        'Una técnica de autenticación para redes Wi-Fi',
      ],
      'correcta':
          'Una solución que cifra el tráfico y oculta la IP del usuario',
      'puntos': 100,
    },
    {
      'pregunta':
          '¿Cuál es el propósito principal de la Inspección Profunda de Paquetes (DPI)?',
      'opciones': [
        'Optimizar el rendimiento de la red',
        'Detectar amenazas y controlar el tráfico de manera precisa',
        'Facilitar el acceso a contenido restringido',
        'Proteger la privacidad de los usuarios',
      ],
      'correcta': 'Detectar amenazas y controlar el tráfico de manera precisa',
      'puntos': 100,
    },
    {
      'pregunta':
          '¿En qué capa del modelo OSI operan los firewalls de filtrado de paquetes?',
      'opciones': [
        'Capa de aplicación',
        'Capa de transporte',
        'Capa de red',
        'Capa de enlace de datos',
      ],
      'correcta': 'Capa de red',
      'puntos': 150,
    },
    {
      'pregunta':
          '¿Cuál es la principal diferencia entre un hacker ético y un Black-Hat?',
      'opciones': [
        'Un hacker ético roba información, mientras que un Black-Hat protege los sistemas',
        'Un hacker ético trabaja con la autorización de la empresa, mientras que un Black-Hat realiza actividades ilegales',
        'Un hacker ético se especializa en redes sociales, mientras que un Black-Hat se especializa en sistemas operativos',
        'Un hacker ético no tiene conocimientos informáticos avanzados, mientras que un Black-Hat sí los tiene',
      ],
      'correcta':
          'Un hacker ético trabaja con la autorización de la empresa, mientras que un Black-Hat realiza actividades ilegales',
      'puntos': 150,
    },
    {
      'pregunta':
          '¿Qué tipo de análisis se realiza para evaluar el impacto de un incidente de seguridad en la organización?',
      'opciones': [
        'Análisis de vulnerabilidades',
        'Análisis de riesgos',
        'Análisis de impacto empresarial',
        'Análisis de calidad del software',
      ],
      'correcta': 'Análisis de impacto empresarial',
      'puntos': 200,
    },
    {
      'pregunta':
          '¿Cuál de las siguientes no es una ventaja de Python para la automatización de tareas?',
      'opciones': [
        'Sintaxis clara y legible',
        'Amplio soporte de bibliotecas',
        'Alta velocidad de ejecución comparada con C++',
        'Multiplataforma',
      ],
      'correcta': 'Alta velocidad de ejecución comparada con C++',
      'puntos': 200,
    },
    {
      'pregunta':
          'Se hace pasar por una empresa o una organización de confianza para engañar al usuario...',
      'opciones': [
        ' Script-kiddie',
        ' APTs',
        'Phisher',
        'Criminales organizados',
      ],
      'correcta': 'Phisher',
      'puntos': 200,
    },
    {
      'pregunta': '¿Qué es un ataque de día cero o Zero-day?',
      'opciones': [
        'Vulnerabilidades que el atacante descubre antes que el fabricante las parchee',
        'Interrumpir el funcionamiento normal de un sitio web o una red',
        'El envío de información de manera segura',
        'Los criterios elevados de seguridad',
      ],
      'correcta':
          'Vulnerabilidades que el atacante descubre antes que el fabricante las parchee',
      'puntos': 150,
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
      debugPrint('Error iniciando musica de combate del nivel 5: $e');
    }

    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      final datos = await FirestoreService.obtenerUsuario();
      final nivelUsuario = datos['nivel'] ?? 1;
      if (nivelUsuario > 5) _nivelYaCompletado = true;
    }

    List<Map<String, dynamic>> preguntas = [];
    try {
      preguntas = await ApiService.obtenerPreguntas(
        nivel: 5,
        mision: 5,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (preguntas.isEmpty) preguntas = _preguntasLocales;

    _todasPreguntas = preguntas;
    _rellenarCola();
    setState(() => _cargando = false);

    _game = Nivel05Game(
      onNodoTocado: _mostrarPregunta,
      onEstadoActualizado: (puntos, vidas) {
        if (mounted) {
          setState(() {
            _puntos = puntos;
            _vidas = vidas;
          });
        }
      },
      onPrimerFalloPregunta: () {
        setState(() => _mostrarAdvertencia = true);
      },
      onJuegoTerminado: _mostrarGameOver,
      onNivelCompletado: _mostrarVictoria,
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
      debugPrint('Error reiniciando musica del nivel 5: $e');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Nivel05Screen(soloEntrenamiento: widget.soloEntrenamiento),
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
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _mostrarVictoria() async {
    if (!_nivelYaCompletado) {
      await FirestoreService.guardarPuntuacion(
        puntos: _puntos,
        nivelCompletado: 5,
      );
      await FirestoreService.guardarMision(
        nivel: 5,
        mision: 5,
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
            subtitulo: 'NIVEL 5 // CONCEPTOS BASE',
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

          // ── BANNER MODO ENTRENAMIENTO ─────────────────────────────────────
          if (_nivelYaCompletado) const GameTrainingBanner(),

          ResponsiveGameHud(
            title: 'RECONOCIMIENTO',
            onBack: () => Navigator.pop(context),
            verticalOffset: _nivelYaCompletado ? 48 : 10,
            compactVerticalOffset: _nivelYaCompletado ? 48 : 10,
            stats: [
              GameHudHearts(lives: _vidas),
              if (_mostrarAdvertencia)
                const GameHudChip(
                  label: 'Ultimo intento',
                  color: Colors.red,
                  icon: Icons.warning_amber_rounded,
                ),
              GameHudChip(label: '$_puntos pts'),
            ],
          ),

          const GameHintOverlay(
            text: 'WASD / Joystick para mover - Click / Tap para disparar',
          ),
        ],
      ),
    );
  }
}

// ── DIÁLOGO PREGUNTA ──────────────────────────────────────────────────────────
class _DialogoPregunta extends StatelessWidget {
  final Map<String, dynamic> pregunta;
  final void Function(bool correcta, int puntos) onRespuesta;

  const _DialogoPregunta({required this.pregunta, required this.onRespuesta});

  @override
  Widget build(BuildContext context) {
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
                    '+${pregunta['puntos']} pts',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              pregunta['pregunta'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...List<String>.from(pregunta['opciones'] ?? []).map(
              (opcion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    final esCorrecta = opcion == pregunta['correcta'];
                    onRespuesta(esCorrecta, pregunta['puntos'] as int);
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
