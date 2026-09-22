import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
// TODO: importar nivel04_game.dart y nodo_component.dart
import 'level_map_screen.dart';
import '../games/nivel_04/nivel04_game.dart';
import '../widgets/level_hud/responsive_game_hud.dart';

class Nivel04Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel04Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel04Screen> createState() => _Nivel04ScreenState();
}

class _Nivel04ScreenState extends State<Nivel04Screen> {
  dynamic _game;
  int _puntos = 0;
  int _vidas = 3;
  bool _cargando = true;
  bool _nivelYaCompletado = false;

  List<Map<String, dynamic>> _cola = [];
  List<Map<String, dynamic>> _todasPreguntas = [];

  static const List<Map<String, dynamic>> _preguntasLocales = [
    {
      'pregunta': '¿Qué es phishing?',
      'opciones': [
        'Un ataque con correos o webs falsas',
        'Un antivirus',
        'Un firewall',
        'Una copia de seguridad',
      ],
      'correcta': 'Un ataque con correos o webs falsas',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué señal indica un correo sospechoso?',
      'opciones': [
        'Urgencia y enlaces raros',
        'Buena ortografía',
        'Remitente conocido',
        'Firma corporativa',
      ],
      'correcta': 'Urgencia y enlaces raros',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué es spear phishing?',
      'opciones': [
        'Phishing dirigido a una persona concreta',
        'Un ataque DDoS',
        'Un virus de móvil',
        'Un tipo de cifrado',
      ],
      'correcta': 'Phishing dirigido a una persona concreta',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué debes hacer ante un enlace dudoso?',
      'opciones': [
        'No abrirlo y verificar la fuente',
        'Abrirlo rápido',
        'Compartirlo',
        'Responder con datos',
      ],
      'correcta': 'No abrirlo y verificar la fuente',
      'puntos': 100,
    },
    {
      'pregunta': '¿Cómo detectar una web falsa?',
      'opciones': [
        'Revisando dominio y HTTPS',
        'Por tener colores bonitos',
        'Por cargar rápido',
        'Por pedir contraseña',
      ],
      'correcta': 'Revisando dominio y HTTPS',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué es whaling?',
      'opciones': [
        'Phishing dirigido a directivos',
        'Un firewall avanzado',
        'Un backup cifrado',
        'Un ataque físico',
      ],
      'correcta': 'Phishing dirigido a directivos',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué NO debes hacer con un correo sospechoso?',
      'opciones': [
        'Descargar adjuntos',
        'Reportarlo',
        'Verificar remitente',
        'Ignorarlo',
      ],
      'correcta': 'Descargar adjuntos',
      'puntos': 100,
    },
    {
      'pregunta': '¿Cuál es una buena defensa contra phishing?',
      'opciones': [
        'Doble factor de autenticación',
        'Usar la misma clave',
        'Desactivar alertas',
        'Compartir contraseñas',
      ],
      'correcta': 'Doble factor de autenticación',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué indica un dominio como paypaI.com?',
      'opciones': [
        'Posible suplantación',
        'Dominio oficial seguro',
        'Actualización legítima',
        'Servidor interno',
      ],
      'correcta': 'Posible suplantación',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué es smishing?',
      'opciones': [
        'Phishing por SMS',
        'Phishing por llamada',
        'Ataque WiFi',
        'Robo de cookies',
      ],
      'correcta': 'Phishing por SMS',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué es vishing?',
      'opciones': [
        'Phishing por llamada telefónica',
        'Ataque por USB',
        'Correo cifrado',
        'Escaneo de red',
      ],
      'correcta': 'Phishing por llamada telefónica',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué dato nunca deberías enviar por email?',
      'opciones': ['Contraseña', 'Nombre público', 'Horario', 'Color favorito'],
      'correcta': 'Contraseña',
      'puntos': 100,
    },
    {
      'pregunta':
          '¿Qué hacer si una web pide iniciar sesión de forma sospechosa?',
      'opciones': [
        'Cerrar y entrar desde la web oficial',
        'Poner la clave',
        'Probar varias claves',
        'Enviar captura',
      ],
      'correcta': 'Cerrar y entrar desde la web oficial',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué ayuda a comprobar un remitente?',
      'opciones': [
        'Revisar el email completo',
        'Mirar solo el nombre',
        'Confiar en el logo',
        'Abrir el adjunto',
      ],
      'correcta': 'Revisar el email completo',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué suele buscar un ataque de phishing?',
      'opciones': [
        'Robar credenciales',
        'Mejorar seguridad',
        'Actualizar drivers',
        'Limpiar caché',
      ],
      'correcta': 'Robar credenciales',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué archivo adjunto puede ser peligroso?',
      'opciones': [
        'Factura.exe',
        'Manual.pdf oficial',
        'Imagen propia',
        'Calendario interno',
      ],
      'correcta': 'Factura.exe',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué debes hacer si ya hiciste clic en un enlace falso?',
      'opciones': [
        'Cambiar contraseña y avisar',
        'No decir nada',
        'Seguir navegando',
        'Reenviar el enlace',
      ],
      'correcta': 'Cambiar contraseña y avisar',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué significa MFA?',
      'opciones': [
        'Autenticación multifactor',
        'Malware falso activo',
        'Mapa de firewall',
        'Modo fuera de ataque',
      ],
      'correcta': 'Autenticación multifactor',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué URL parece más segura?',
      'opciones': [
        'https://banco.com',
        'http://banco-login.ru',
        'https://banco.seguro.xyz',
        'http://premio-gratis.com',
      ],
      'correcta': 'https://banco.com',
      'puntos': 100,
    },
    {
      'pregunta': '¿Qué debe hacerse con un intento de phishing en empresa?',
      'opciones': [
        'Reportarlo al equipo de seguridad',
        'Borrarlo sin avisar',
        'Responder al atacante',
        'Abrirlo en otro navegador',
      ],
      'correcta': 'Reportarlo al equipo de seguridad',
      'puntos': 100,
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarJuego();
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
      debugPrint('Error iniciando musica de combate del nivel 4: $e');
    }

    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      final datos = await FirestoreService.obtenerUsuario();
      final nivelUsuario = datos['nivel'] ?? 1;
      if (nivelUsuario > 4) _nivelYaCompletado = true;
    }

    List<Map<String, dynamic>> preguntas = [];
    try {
      preguntas = await ApiService.obtenerPreguntas(
        nivel: 4,
        mision: 1,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    if (preguntas.isEmpty) preguntas = _preguntasLocales;

    _todasPreguntas = preguntas;
    _rellenarCola();
    setState(() => _cargando = false);

    // TODO: instanciar Nivel04Game
    _game = Nivel04Game(
      onNodoTocado: _mostrarPregunta,
      onEstadoActualizado: (puntos, vidas) {
        if (mounted)
          setState(() {
            _puntos = puntos;
            _vidas = vidas;
          });
      },
      onJuegoTerminado: _mostrarGameOver,
      onNivelCompletado: _mostrarVictoria,
    );
    _game!.cargarPreguntas(preguntas);

    if (mounted) setState(() {});
  }

  void _mostrarPregunta(dynamic nodo) {
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
            setState(() => _puntos += puntos);
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
      debugPrint('Error reiniciando musica del nivel 4: $e');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Nivel04Screen(soloEntrenamiento: widget.soloEntrenamiento),
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LevelMapScreen()),
            (route) => route.settings.name == 'menu',
          );
        },
      ),
    );
  }

  void _mostrarVictoria() async {
    if (!_nivelYaCompletado) {
      await FirestoreService.guardarPuntuacion(
        puntos: _puntos,
        nivelCompletado: 4,
      );
      await FirestoreService.guardarMision(
        nivel: 4,
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
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LevelMapScreen()),
            (route) => route.settings.name == 'menu',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          border: Border.all(color: AppColors.cyan.withOpacity(0.5)),
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
                    color: AppColors.cyan.withOpacity(0.1),
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
                    color: AppColors.cyan.withOpacity(0.7),
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
                    color: AppColors.purple.withOpacity(0.2),
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
                        color: AppColors.purple.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.5),
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
                  color: AppColors.purple.withOpacity(0.1),
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
                      color: AppColors.purple.withOpacity(0.7),
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Modo entrenamiento — puntos no guardados',
                      style: TextStyle(
                        color: AppColors.purple.withOpacity(0.7),
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
