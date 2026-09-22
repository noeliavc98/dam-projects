import 'package:cyber_ops/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../games/nivel_01/nivel01_game.dart';
import '../games/nivel_01/components/nodo_component.dart';
import 'level_map_screen.dart';
import '../widgets/fractura/fractura_dialogo.dart';
import '../widgets/level_hud/responsive_game_hud.dart';

class Nivel01Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel01Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel01Screen> createState() => _Nivel01ScreenState();
}

class _Nivel01ScreenState extends State<Nivel01Screen> {
  Nivel01Game? _game;
  int _puntos = 0;
  int _vidas = 3;
  bool _cargando = true;
  bool _nivelYaCompletado = false;


  List<Map<String, dynamic>> _cola = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Bienvenido al primer nivel, operador.',
    'Empezamos con reconocimiento básico. Vas a controlar un dron dentro de una red y tu objetivo será localizar nodos del sistema.',
    'Muévete con WASD o joystick, apunta con el cursor y dispara hacia los nodos. Cuando entres en contacto con uno, el sistema lanzará una pregunta de ciberseguridad. Si respondes bien, el nodo quedará comprometido y ganarás puntos.',
    'Necesitas comprometer varios nodos para completar la misión. Pero cuidado: cada respuesta incorrecta activará una alerta, perderás una vida y aparecerán defensas enemigas.',
    'Observa la red, alcanza los nodos y responde con cabeza. Este es tu primer acceso real.',
  ];

  static const List<Map<String, dynamic>> _preguntasLocales = [
    {
      'pregunta': '¿Qué herramienta se usa para escanear puertos abiertos?',
      'opciones': ['Wireshark', 'Nmap', 'Metasploit', 'Burp Suite'],
      'correcta': 'Nmap',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué significa OSINT?',
      'opciones': [
        'Open Source Intelligence',
        'Online Security Internet Tool',
        'Operative System Internal Network',
        'Open System Intrusion Network',
      ],
      'correcta': 'Open Source Intelligence',
      'puntos': 100,
    },
    {
      'pregunta': '¿Cuál es el puerto por defecto de HTTPS?',
      'opciones': ['80', '21', '443', '22'],
      'correcta': '443',
      'puntos': 150,
    },
    {
      'pregunta': '¿Qué protocolo usa el comando ping?',
      'opciones': ['TCP', 'UDP', 'ICMP', 'FTP'],
      'correcta': 'ICMP',
      'puntos': 150,
    },
    {
      'pregunta': '¿Qué herramienta analiza tráfico de red en tiempo real?',
      'opciones': ['Nmap', 'John the Ripper', 'Wireshark', 'Hydra'],
      'correcta': 'Wireshark',
      'puntos': 200,
    },
    {
      'pregunta': '¿Qué significa TTL en una respuesta ping?',
      'opciones': [
        'Time To Live',
        'Total Transfer Length',
        'Terminal Transfer Layer',
        'Tunnel Transport Link',
      ],
      'correcta': 'Time To Live',
      'puntos': 200,
    },
    {
      'pregunta': '¿Qué es un banner grabbing?',
      'opciones': [
        'Robar el logo de una web',
        'Obtener información de servicios mediante sus mensajes de bienvenida',
        'Capturar paquetes de red',
        'Escanear vulnerabilidades web',
      ],
      'correcta':
          'Obtener información de servicios mediante sus mensajes de bienvenida',
      'puntos': 200,
    },
    {
      'pregunta': '¿Qué tipo de reconocimiento NO interactúa con el objetivo?',
      'opciones': [
        'Reconocimiento activo',
        'Reconocimiento pasivo',
        'Escaneo de puertos',
        'Fingerprinting',
      ],
      'correcta': 'Reconocimiento pasivo',
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
      debugPrint('Error iniciando musica de combate del nivel 1: $e');
    }

    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      final datos = await FirestoreService.obtenerUsuario();
      final nivelUsuario = datos['nivel'] ?? 1;
      if (nivelUsuario > 1) _nivelYaCompletado = true;
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

    _game = Nivel01Game(
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
      debugPrint('Error reiniciando musica del nivel 1: $e');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppRoutes.fade(
        Nivel01Screen(soloEntrenamiento: widget.soloEntrenamiento),
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
            AppRoutes.fade(const LevelMapScreen()),
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
        nivelCompletado: 1,
      );
      await FirestoreService.guardarMision(
        nivel: 1,
        mision: 1,
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
            AppRoutes.fade(const LevelMapScreen()),
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
            subtitulo: 'NIVEL 1 // CONCEPTOS BASE',
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
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
        children: [
          MouseRegion(
            onHover: (event) {
              _game?.actualizarPuntero(event.localPosition);
            },
            child: Listener(
              onPointerDown: (event) {
                _game?.dispararHaciaOffset(event.localPosition);
              },
              onPointerMove: (event) {
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
