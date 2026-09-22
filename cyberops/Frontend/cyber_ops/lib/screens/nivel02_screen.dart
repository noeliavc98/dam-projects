import 'package:cyber_ops/services/music_service.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../games/nivel_02/nivel02_game.dart';
import '../games/nivel_01/components/nodo_component.dart';
import 'package:cyber_ops/screens/level_map_screen.dart';
import 'package:cyber_ops/config/app_routes.dart';
import '../widgets/level_hud/responsive_game_hud.dart';

// Conservamos la HUD de nivel 01
class Nivel02Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel02Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel02Screen> createState() => _Nivel02ScreenState();
}

class _Nivel02ScreenState extends State<Nivel02Screen> {
  Nivel02Game? _game;
  int _puntos = 0;
  int _vidas = 3;
  int _combo = 0;
  bool _cargando = true;
  bool _nivelYaCompletado = false;
  int _incidentesActivos = 0;
  int _incidentesResueltos = 0;
  int _incidentesObjetivo = 5;
  bool _escudoDisponible = false;
  List<Map<String, dynamic>> _cola = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Buen trabajo superando el primer nivel, operador. Continuamos al nivel 2.',
    'Ahora cambiamos de enfoque: ya no estás infiltrando una red, estás defendiéndola.',
    'Aparecerán incidentes en distintos nodos del sistema. Tu trabajo es moverte hasta los nodos vulnerables o en alerta y resolverlos respondiendo correctamente a las preguntas.',
    'Cada incidente resuelto suma puntos y aumenta tu combo. Si encadenas aciertos, cargarás un escudo de red capaz de limpiar los incidentes activos de golpe.'
    'Pero no te relajes. Los incidentes tienen tiempo límite. Si tardas demasiado o respondes mal, el nodo puede quedar comprometido, aparecerán defensas enemigas y perderás vidas.',
    'Resuelve cinco incidentes para asegurar la red.',
  ];

  // Preguntas locales temporales del nivel 2
  static const List<Map<String, dynamic>> _preguntasLocales = [
    {
      'pregunta': '¿Qué dispositivo filtra tráfico entre redes?',
      'opciones': ['Switch', 'Router', 'Firewall', 'Proxy'],
      'correcta': 'Firewall',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué debes hacer ante un correo sospechoso?',
      'opciones': [
        'Abrir enlaces',
        'Descargar adjuntos',
        'Ignorarlo o reportarlo',
        'Responder al remitente',
      ],
      'correcta': 'Ignorarlo o reportarlo',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué tipo de ataque busca saturar un servicio?',
      'opciones': ['Phishing', 'DDoS', 'SQL Injection', 'Spoofing'],
      'correcta': 'DDoS',
      'puntos': 150,
    },
    {
      'pregunta': '¿Qué medida ayuda a proteger contraseñas?',
      'opciones': [
        'Usar la misma en todo',
        'Autenticación multifactor',
        'Compartirla por correo',
        'Guardarla en texto plano',
      ],
      'correcta': 'Autenticación multifactor',
      'puntos': 150,
    },
    {
      'pregunta': '¿Qué acción reduce el riesgo de malware?',
      'opciones': [
        'Desactivar antivirus',
        'Instalar software desconocido',
        'Actualizar el sistema',
        'Ignorar alertas',
      ],
      'correcta': 'Actualizar el sistema',
      'puntos': 200,
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
      // 1. Paramos la música anterior (menú/mapa)
      await MusicService().playNivel2Music(restart: true);
    } catch (e) {
      debugPrint('Error iniciando musica de combate del nivel 2: $e');
    }
    // ✅ Verificar si el nivel ya está completado
    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      final datos = await FirestoreService.obtenerUsuario();
      final nivelUsuario = datos['nivel'] ?? 1;
      if (nivelUsuario > 2) _nivelYaCompletado = true;
    }

    List<Map<String, dynamic>> preguntas = [];
    try {
      preguntas = await ApiService.obtenerPreguntas(
        nivel: 2,
        mision: 1,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (preguntas.isEmpty) preguntas = _preguntasLocales;

    _todasPreguntas = preguntas;
    _rellenarCola();
    setState(() => _cargando = false);
    _game = Nivel02Game(
      onNodoTocado: _mostrarPregunta,
      onEstadoActualizado: (puntos, vidas) {
        if (mounted) {
          setState(() {
            _puntos = puntos;
            _vidas = vidas;
            _combo = _game?.combo ?? 0;
            _incidentesActivos = _game?.incidentesActivos ?? 0;
            _incidentesResueltos = _game?.incidentesResueltos ?? 0;
            _incidentesObjetivo = _game?.incidentesObjetivo ?? 5;
            _escudoDisponible = _game?.escudoDisponible ?? false;
          });
        }
      },
      onJuegoTerminado: _mostrarGameOver,
      onNivelCompletado: _mostrarVictoria,
    );

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
      debugPrint('Error reiniciando musica del nivel 2: $e');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppRoutes.fade(
        Nivel02Screen(soloEntrenamiento: widget.soloEntrenamiento),
      ),
    );
  }

  void _mostrarGameOver() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultado(
        titulo: 'RED COMPROMETIDA',
        subtitulo: 'La defensa ha fallado',
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

  @override
  void dispose() {
    super.dispose();
  }

  void _mostrarVictoria() async {
    // ✅ Solo guardar si NO está en modo entrenamiento
    if (!_nivelYaCompletado) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService.guardarPuntuacion(
          puntos: _puntos,
          nivelCompletado: 2,
        );
        await FirestoreService.guardarMision(
          nivel: 2,
          mision: 1,
          puntos: _puntos,
        );
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultado(
        titulo: 'RED ASEGURADA',
        subtitulo: _nivelYaCompletado
            ? 'Modo entrenamiento — puntuación no guardada'
            : 'Has defendido la infraestructura con éxito',
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
            subtitulo: 'NIVEL 2 // CONCEPTOS BASE',
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
            title: 'DEFENSA DE RED',
            onBack: () => Navigator.pop(context),
            verticalOffset: _nivelYaCompletado ? 48 : 10,
            compactVerticalOffset: _nivelYaCompletado ? 48 : 10,
            stats: [
              GameHudStatChip(
                label: 'INCIDENTES',
                value: '$_incidentesActivos',
                color: AppColors.pink,
                icon: Icons.warning_amber_rounded,
              ),
              GameHudStatChip(
                label: 'OBJETIVO',
                value: '$_incidentesResueltos/$_incidentesObjetivo',
                color: AppColors.cyan,
                icon: Icons.shield_rounded,
              ),
              GameHudHearts(lives: _vidas),
              if (_combo > 1) GameHudChip(label: 'x$_combo'),
              GameHudChip(label: '$_puntos pts'),
            ],
          ),
          if (_escudoDisponible)
            Positioned(
              right: 40,
              bottom: 46,
              child: GestureDetector(
                onTap: () {
                  _game?.usarEscudoRed();
                  setState(() {
                    _escudoDisponible = _game?.escudoDisponible ?? false;
                    _incidentesActivos = _game?.incidentesActivos ?? 0;
                  });
                },
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgCard,
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.cyan,
                    size: 26,
                  ),
                ),
              ),
            ),
          if (_escudoDisponible)
            Positioned(
              right: 33,
              bottom: 24,
              child: Text(
                'ESCUDO',
                style: TextStyle(
                  color: AppColors.cyan.withValues(alpha: 0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
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
                    Icons.shield_rounded,
                    color: AppColors.cyan,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'INCIDENTE DETECTADO',
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
