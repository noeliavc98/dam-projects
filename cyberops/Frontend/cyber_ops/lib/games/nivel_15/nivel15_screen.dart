import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'nivel15_game.dart';
import '../../services/music_service.dart';
import '../../services/firestore_service.dart';

const _bg = Color(0xFF0A0613);
const _cyan = Color(0xFF00E5FF);
const _purple = Color(0xFF8B5CF6);
const _pink = Color(0xFFEC4899);
const _red = Color(0xFFFF4E6B);
const _green = Color(0xFF10F985);
const _amber = Color(0xFFFFC857);

class Nivel15Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel15Screen({super.key, this.soloEntrenamiento = false});
  @override
  State<Nivel15Screen> createState() => _Nivel15ScreenState();
}

class _Nivel15ScreenState extends State<Nivel15Screen>
    with TickerProviderStateMixin {
  late Nivel15Game game;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;
  String respuesta = '';
  String _msgFracturaCompleto = 'Observa bien.\nCada pregunta es una grieta.';

  bool mostrarOverlay = false;
  Map<String, dynamic> resultado = {};
  int? cartaSeleccionada;
  List<String> respuestasCartas = ['', '', '', ''];
  bool _glitchActivo = false;
  bool _vibrando = false;
  final List<Map<String, String>> _pistas = [];
  bool _escaneando = false;
  String _pidEscaneado = '';
  String _estadoEscaneado = '';
  String _firmaEscaneado = '';
  Timer? _scanTimer;
  String _fracturaImg = 'assets/images/nivel_08/fractura_neutral.png';
  String _msgFracturaVisible = '';
  Timer? _typewriterTimer;
  int _talkFrame = 0;
  Color _glitchColor = const Color(0xFFFF4E6B);

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Un rootkit no ataca. Se esconde.',
    'Se entierra en el kernel. Reescribe lo que el sistema considera real.',
    'El antivirus no lo ve. El usuario no lo siente. Solo tú sabes que está ahí.',
    'Control total. Sin dejar rastro.',
    'Tienes varias pistas para acertar si es rootkit o no. Pero cuidado, cada pregunta es una grieta.',
    'Si haces demasiadas, el sospechoso se dará cuenta de que lo estás investigando.',
  ];

  @override
  void initState() {
    super.initState();
    game = Nivel15Game();
    MusicService().playNiveles11to15Music().catchError(
      (e) => debugPrint('Error iniciando música del nivel 15: $e'),
    );
    _setupNivel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarEscaneo());
  }

  Future<void> _setupNivel() async {
    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
      return;
    }
    try {
      final datos = await FirestoreService.obtenerUsuario();
      final nivelUsuario = (datos['nivel'] as num?)?.toInt() ?? 1;
      _nivelYaCompletado = nivelUsuario > 15;
    } catch (e) {
      debugPrint('No se pudo comprobar progreso del nivel 15: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _guardarProgreso() async {
    if (_progresoGuardado || _nivelYaCompletado || widget.soloEntrenamiento) return;
    _progresoGuardado = true;
    try {
      await FirestoreService.guardarPuntuacion(
        puntos: game.xp,
        nivelCompletado: 15,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
        nivel: 15,
        mision: 15,
        puntos: game.xp,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso del nivel 15: $e');
    }
  }

  void _preguntar(int i) {
    if (game.preguntasUsadas[i]) return;
    if (!game.puedeHacerMasPreguntas) {
      setState(() {
        _msgFracturaCompleto =
            'Solo puedes hacer ${game.maxPreguntasLab} pregunta(s) en este lab.\nDecide tu veredicto.';
      });
      return;
    }
    final pr = game.hacerPregunta(i);
    setState(() {
      respuesta = pr.respuesta;
      cartaSeleccionada = i;
      respuestasCartas[i] = pr.respuesta;
      _pistas.add({'texto': pr.pistaTexto, 'tipo': pr.pistaTipo});
    });
    _setMsgFractura(
      pr.reaccionFractura,
      img: 'assets/images/nivel_08/fractura_atenta.png',
    );
  }

  void _analizar() {
    int usadas = game.preguntasUsadas.where((u) => u).length;
    if (usadas == 0) {
      setState(() {
        _msgFracturaCompleto = 'Haz al menos una pregunta antes.';
        _msgFracturaVisible = 'Haz al menos una pregunta antes.';
      });
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0820),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _purple, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: _pink.withOpacity(0.3),
                blurRadius: 80,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _purple.withOpacity(0.4)),
                ),
                child: Text(
                  '// PROTOCOLO DE ANÁLISIS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: _purple.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _purple.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(0.6),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.gavel_rounded,
                    color: _purple,
                    size: 42,
                    shadows: [Shadow(color: _purple, blurRadius: 16)],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'TU VEREDICTO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  shadows: [Shadow(color: _purple, blurRadius: 12)],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 60,
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _purple.withOpacity(0),
                      _purple,
                      _purple.withOpacity(0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '¿Es este proceso un rootkit?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 12,
                    color: _amber.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Preguntas usadas: ${game.preguntasUsadas.where((u) => u).length}/4',
                    style: TextStyle(
                      color: _amber.withOpacity(0.8),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _veredicto(true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _red, width: 2),
                    boxShadow: [
                      BoxShadow(color: _red.withOpacity(0.5), blurRadius: 20),
                      BoxShadow(
                        color: _red.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dangerous_outlined, color: _red, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'ES EL ROOTKIT',
                        style: TextStyle(
                          color: _red,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontSize: 14,
                          shadows: [Shadow(color: _red, blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _veredicto(false);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green, width: 2),
                    boxShadow: [
                      BoxShadow(color: _green.withOpacity(0.4), blurRadius: 20),
                      BoxShadow(
                        color: _green.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_outlined, color: _green, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'ES INOCENTE',
                        style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontSize: 14,
                          shadows: [Shadow(color: _green, blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'CANCELAR',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _iniciarEscaneo() {
    final s = game.sospechoso;
    _scanTimer?.cancel();
    setState(() {
      _escaneando = true;
      _pidEscaneado = '';
      _estadoEscaneado = '';
      _firmaEscaneado = '';
    });
    final pasos = <Map<String, String>>[];
    for (int i = 1; i <= s.pid.length; i++) {
      pasos.add({'pid': s.pid.substring(0, i)});
    }
    for (int i = 1; i <= s.estado.length; i++) {
      pasos.add({'estado': s.estado.substring(0, i)});
    }
    for (int i = 1; i <= s.firma.length; i++) {
      pasos.add({'firma': s.firma.substring(0, i)});
    }
    int idx = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 35), (t) {
      if (idx >= pasos.length) {
        t.cancel();
        setState(() => _escaneando = false);
        return;
      }
      final paso = pasos[idx];
      setState(() {
        if (paso.containsKey('pid')) _pidEscaneado = paso['pid']!;
        if (paso.containsKey('estado')) _estadoEscaneado = paso['estado']!;
        if (paso.containsKey('firma')) _firmaEscaneado = paso['firma']!;
      });
      idx++;
    });
  }

  void _setMsgFractura(String texto, {String? img}) {
    _typewriterTimer?.cancel();
    setState(() {
      _msgFracturaCompleto = texto;
      _msgFracturaVisible = '';
      _msgFracturaCompleto = texto;
      if (img != null) _fracturaImg = img;
    });
    int idx = 0;
    _talkFrame = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 25), (t) {
      if (idx >= _msgFracturaCompleto.length) {
        t.cancel();
        setState(() => _talkFrame = 0);
        return;
      }
      idx++;
      setState(() {
        _msgFracturaVisible = _msgFracturaCompleto.substring(0, idx);
        if (idx % 4 == 0) _talkFrame = (_talkFrame + 1) % 3;
      });
    });
  }

  void _activarGlitch(Color color) {
    setState(() {
      _glitchActivo = true;
      _glitchColor = color;
      _vibrando = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _glitchActivo = false;
          _vibrando = false;
        });
      }
    });
  }

  void _veredicto(bool esRootkit) {
    final r = game.darVeredicto(esRootkit);
    bool ok = r['correcto'] ?? false;
    _activarGlitch(ok ? _green : _red);
    setState(() {
      resultado = r;
    });
    if (game.vidas <= 0) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _mostrarGameOver();
      });
      return;
    }
    if (ok) {
      if (game.labActual >= 2) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _mostrarVictoria();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _siguiente();
        });
      }
    }
  }

void _mostrarGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoResultado(
        titulo: 'MISION FALLIDA',
        subtitulo: 'El rootkit te ha vencido',
        puntos: game.xp,
        exito: false,
        soloEntrenamiento: widget.soloEntrenamiento,
        onReintentar: () {
          Navigator.pop(ctx);
          _reiniciar();
        },
        onSalir: () {
          Navigator.pop(ctx);
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  void _mostrarVictoria() {
    _guardarProgreso();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoResultado(
        titulo: 'MISION CUMPLIDA',
        subtitulo: 'Has identificado todos los procesos',
        puntos: game.xp,
        exito: true,
        soloEntrenamiento: widget.soloEntrenamiento,
        onReintentar: () {
          Navigator.pop(ctx);
          _reiniciar();
        },
        onSalir: () {
          Navigator.pop(ctx);
          Navigator.of(context).maybePop();
        },
      ),
    );
  }

  void _reiniciar() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarEscaneo());
    setState(() {
      game.reset();
      respuesta = '';
      cartaSeleccionada = null;
      respuestasCartas = ['', '', '', ''];
      _pistas.clear();
      mostrarOverlay = false;
      _msgFracturaCompleto = 'Observa bien.\nCada pregunta es una grieta.';
    });
  }

  void _siguiente() {
    game.siguienteLab();
    setState(() {
      mostrarOverlay = false;
      respuesta = '';
      cartaSeleccionada = null;
      respuestasCartas = ['', '', '', ''];
      _pistas.clear();
    });
    final mensaje = game.labActual == 1
        ? 'Nuevo sospechoso.\nSolo te dejo 2 preguntas. Elige bien.'
        : 'El ultimo.\nUna sola pregunta. Sin margen de error.';
    final img = game.labActual == 2
        ? 'assets/images/nivel_08/fractura_alerta.png'
        : 'assets/images/nivel_08/fractura_atenta.png';
    _setMsgFractura(mensaje, img: img);
    setState(() {});
  }

  Future<void> _salirDelNivel() async {
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomPaint(painter: _CircuitBgPainter(), size: Size.infinite),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final isNarrow = w < 650;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      _buildMiddleSection(
                        isNarrow: isNarrow,
                        availableWidth: w,
                      ),
                      _buildCableSection(isNarrow: isNarrow),
                      _buildFlipCards(isNarrow: isNarrow),
                      const SizedBox(height: 14),
                      _buildBottomBar(isNarrow: isNarrow),
                    ],
                  ),
                );
              },
            ),
          ),
          if (mostrarOverlay) _buildOverlay(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Volver al mapa',
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _cyan,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: _cyan, width: 1.5),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: _cyan.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Text(
                'NIVEL 15: ROOTKIT',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 3,
                  color: _cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                Icons.favorite,
                size: 22,
                color: i < game.vidas
                    ? _pink
                    : _pink.withValues(alpha: 0.2),
                shadows: i < game.vidas
                    ? [
                        Shadow(
                          color: _pink.withValues(alpha: 0.9),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Middle section ──────────────────────────────────────────────────────────

  Widget _buildMiddleSection({
    required bool isNarrow,
    required double availableWidth,
  }) {
    final cardSize = isNarrow
        ? (availableWidth * 0.45).clamp(140.0, 200.0)
        : 240.0;

    if (isNarrow) {
      return Column(
        children: [
          Center(child: _buildSuspectCard(cardSize)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFracturaPanel()),
              const SizedBox(width: 10),
              Expanded(child: _buildSuspectInfoPanel()),
            ],
          ),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: _buildFracturaPanel(),
          ),
          const SizedBox(width: 14),
          _buildSuspectCard(cardSize),
          const SizedBox(width: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: _buildSuspectInfoPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildFracturaPanel() {
    return _hudPanel(
      color: _cyan,
      titulo: 'FRACTURA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 400),
                builder: (ctx, val, child) {
                  final hablando =
                      _msgFracturaVisible.length <
                          _msgFracturaCompleto.length &&
                      _msgFracturaCompleto.isNotEmpty;
                  final scale = hablando
                      ? 1.0 +
                            (sin(
                                  DateTime.now().millisecondsSinceEpoch /
                                      100,
                                ) *
                                0.04)
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _cyan.withValues(
                            alpha: hablando ? 0.9 : 0.4,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withValues(
                              alpha: hablando ? 0.7 : 0.3,
                            ),
                            blurRadius: hablando ? 18 : 8,
                          ),
                          BoxShadow(
                            color: _cyan.withValues(
                              alpha: hablando ? 0.4 : 0.15,
                            ),
                            blurRadius: hablando ? 32 : 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          hablando
                              ? 'assets/images/nivel_08/fractura_talk_0${_talkFrame + 1}.png'
                              : _fracturaImg,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _msgFracturaVisible.isEmpty
                        ? _msgFracturaCompleto
                        : _msgFracturaVisible,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_pistas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '// PISTAS ACUMULADAS',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 2,
                color: _amber.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _pistas.map((p) {
                final culpa = p['tipo'] == 'CULPA';
                final c = culpa ? _red : _green;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: c.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    p['texto']!,
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1,
                      color: c,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuspectCard(double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: size,
      height: size,
      transform: _glitchActivo
          ? Matrix4.translationValues(
              (Random().nextDouble() - 0.5) * 8,
              (Random().nextDouble() - 0.5) * 4,
              0,
            )
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: _glitchActivo
            ? _glitchColor.withValues(alpha: 0.18)
            : const Color(0xFF1A0410),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _glitchActivo ? _glitchColor : _red,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (_glitchActivo ? _glitchColor : _red)
                .withValues(alpha: 0.7),
            blurRadius: 40,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: (_glitchActivo ? _glitchColor : _pink)
                .withValues(alpha: 0.5),
            blurRadius: 80,
            spreadRadius: 14,
          ),
          BoxShadow(
            color: (_glitchActivo ? _glitchColor : _pink)
                .withValues(alpha: 0.25),
            blurRadius: 120,
            spreadRadius: 25,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: _red.withValues(alpha: 0.6),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: size * 0.56,
              fontWeight: FontWeight.w900,
              color: _red,
              shadows: [
                Shadow(
                  color: _pink.withValues(alpha: 0.9),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuspectInfoPanel() {
    final s = game.sospechoso;
    return _hudPanel(
      color: _red,
      titulo: 'SOSPECHOSO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statRow(
            'PID:',
            _escaneando ? '${_pidEscaneado}_' : s.pid,
            _cyan,
          ),
          const SizedBox(height: 6),
          _statRow(
            'ESTADO:',
            _escaneando
                ? _estadoEscaneado +
                      (_estadoEscaneado.length < s.estado.length ? '_' : '')
                : s.estado,
            _cyan,
          ),
          const SizedBox(height: 6),
          _statRow(
            'FIRMA:',
            _escaneando
                ? _firmaEscaneado +
                      (_firmaEscaneado.length < s.firma.length ? '_' : '')
                : s.firma,
            _red,
          ),
        ],
      ),
    );
  }

  // ── Cable ───────────────────────────────────────────────────────────────────

  Widget _buildCableSection({required bool isNarrow}) {
    return SizedBox(
      height: isNarrow ? 180.0 : 320.0,
      width: double.infinity,
      child: CustomPaint(
        painter: _CablePainter(
          vibrandoColor: _vibrando ? _glitchColor : null,
        ),
      ),
    );
  }

  // ── Flip cards ──────────────────────────────────────────────────────────────

  Widget _buildFlipCards({required bool isNarrow}) {
    Widget card(int i) {
      final p = game.preguntas[i];
      final usado = game.preguntasUsadas[i];
      final colores = [_cyan, _purple, _cyan, _pink];
      return _FlipCard(
        key: ValueKey(
          'lab${game.labActual}-c$i-u${usado ? 1 : 0}-r${respuestasCartas[i].hashCode}',
        ),
        color: _vibrando ? _glitchColor : colores[i],
        usado: usado,
        pregunta: p.texto,
        respuesta: respuestasCartas[i],
        onTap: () => _preguntar(i),
      );
    }

    Widget cardRow(int a, int b) => Row(
      children: [
        Expanded(child: card(a)),
        const SizedBox(width: 8),
        Expanded(child: card(b)),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: _vibrando
          ? Matrix4.translationValues(
              (Random().nextDouble() - 0.5) * 5,
              (Random().nextDouble() - 0.5) * 3,
              0,
            )
          : Matrix4.identity(),
      child: isNarrow
          ? Column(
              children: [
                cardRow(0, 1),
                const SizedBox(height: 8),
                cardRow(2, 3),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? 0 : 6,
                      right: i == 3 ? 0 : 6,
                    ),
                    child: card(i),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar({required bool isNarrow}) {
    final s = game.sospechoso;

    final respuestaBox = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0820),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _cyan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: _cyan.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Text(
        respuesta.isEmpty ? s.respuestaInicial : '"$respuesta"',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.75),
          height: 1.4,
        ),
      ),
    );

    final progressWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESO DEL LAB',
          style: TextStyle(
            fontSize: 8,
            letterSpacing: 2,
            color: _cyan.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(8, (i) {
            final activo = i < (game.sinconia * 8).floor();
            return Container(
              margin: const EdgeInsets.only(right: 3),
              width: 14,
              height: 10,
              decoration: BoxDecoration(
                color: activo ? _cyan : Colors.transparent,
                border: Border.all(
                  color: _cyan.withValues(alpha: activo ? 1.0 : 0.4),
                  width: 1,
                ),
                boxShadow: activo
                    ? [
                        BoxShadow(
                          color: _cyan.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );

    final xpWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: _red, width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: _red.withValues(alpha: 0.3), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'XP',
            style: TextStyle(
              fontSize: 11,
              color: _red,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            game.xp.toString().padLeft(4, '0'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );

    final analyzeButton = GestureDetector(
      onTap: _analizar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0828),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _purple, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.5),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, size: 16, color: _purple),
            SizedBox(width: 8),
            Text(
              'ANALIZAR SOSPECHOSO',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: _purple),
          ],
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          respuestaBox,
          const SizedBox(height: 14),
          Center(child: analyzeButton),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [progressWidget, xpWidget],
          ),
        ],
      );
    }

    return Column(
      children: [
        respuestaBox,
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            progressWidget,
            const Spacer(),
            analyzeButton,
            const Spacer(),
            xpWidget,
          ],
        ),
      ],
    );
  }

  Widget _hudPanel({
    required Color color,
    required String titulo,
    required Widget child,
  }) {
    return CustomPaint(
      painter: _HudPanelPainter(color: color),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 3,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: color.withOpacity(0.3)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color colorValor) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: colorValor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay() {
    final bool ok = resultado['correcto'] ?? false;
    final int xpG = resultado['xp'] ?? 0;
    final String titulo = ok
        ? (game.sospechoso.esRootkit
              ? 'ROOTKIT CONFIRMADO'
              : 'INOCENTE CONFIRMADO')
        : (game.sospechoso.esRootkit ? 'FALSO NEGATIVO' : 'FALSO POSITIVO');
    return Container(
      color: _bg.withValues(alpha: 0.94),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0820),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ok ? _green : _red, width: 2),
              boxShadow: [
                BoxShadow(
                  color: (ok ? _green : _red).withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: ok ? _green : _red,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '+$xpG XP',
                style: const TextStyle(
                  fontSize: 26,
                  color: _amber,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: game.labActual < 2
                    ? _siguiente
                    : () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _purple, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    game.labActual < 2 ? 'SIGUIENTE LAB' : 'NIVEL COMPLETADO',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 4,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _CircuitBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _cyan.withOpacity(0.025)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CablePainter extends CustomPainter {
  final Color? vibrandoColor;
  _CablePainter({this.vibrandoColor});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final positions = [
      size.width * 0.125,
      size.width * 0.375,
      size.width * 0.625,
      size.width * 0.875,
    ];
    final colorFinales = [_cyan, _purple, _cyan, _pink];
    for (int i = 0; i < 4; i++) {
      final x = positions[i];
      final colorFinal = vibrandoColor ?? colorFinales[i];
      final startX = cx + (i - 1.5) * 10;
      final path = Path()
        ..moveTo(startX, 0)
        ..lineTo(startX, 30)
        ..lineTo(x, 80)
        ..lineTo(x, size.height - 12);
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: vibrandoColor != null
            ? [vibrandoColor!, vibrandoColor!, vibrandoColor!]
            : [_pink, _purple, colorFinal],
      ).createShader(Rect.fromLTRB(x - 30, 0, x + 30, size.height));
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..color = colorFinal.withOpacity(0.2)
          ..strokeWidth = 18
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..strokeWidth = 9
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(
        Offset(x, size.height - 10),
        9,
        Paint()
          ..color = _bg
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, size.height - 10),
        9,
        Paint()
          ..color = colorFinal
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        Offset(x, size.height - 10),
        9,
        Paint()
          ..color = colorFinal.withOpacity(0.4)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(x, size.height - 10),
        3,
        Paint()
          ..color = colorFinal
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _FlipCard extends StatefulWidget {
  final Color color;
  final bool usado;
  final String pregunta;
  final String respuesta;
  final VoidCallback onTap;
  const _FlipCard({
    super.key,
    required this.color,
    required this.usado,
    required this.pregunta,
    required this.respuesta,
    required this.onTap,
  });
  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.usado) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.usado && !old.usado) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (ctx, _) {
          final t = _anim.value;
          final mostrarFrente = t < 0.5;
          final angulo = t * 3.14159;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angulo),
            child: Container(
              height: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0820),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.usado
                      ? const Color(0xFF10F985).withOpacity(0.6)
                      : widget.color,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.usado ? const Color(0xFF10F985) : widget.color)
                            .withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: mostrarFrente
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 32,
                          color: widget.color,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 1,
                          color: widget.color.withOpacity(0.3),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.pregunta,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.95),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 28,
                            color: Color(0xFF10F985),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: const Color(0xFF10F985).withOpacity(0.4),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Center(
                              child: Text(
                                widget.respuesta,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                  fontStyle: FontStyle.italic,
                                  height: 1.3,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _DialogoResultado extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int puntos;
  final bool exito;
  final bool soloEntrenamiento;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _DialogoResultado({
    required this.titulo,
    required this.subtitulo,
    required this.puntos,
    required this.exito,
    this.soloEntrenamiento = false,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final color = exito ? _cyan : _pink;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 30)],
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
                color: _purple,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            if (soloEntrenamiento) ...[
              const SizedBox(height: 10),
              const Text(
                'MODO ENTRENAMIENTO · No se guardará progreso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReintentar,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _purple.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(
                    color: _purple,
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

class _HudPanelPainter extends CustomPainter {
  final Color color;
  _HudPanelPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final l = 12.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final glow = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final p in [glow, paint]) {
      canvas.drawLine(const Offset(0, 0), Offset(l, 0), p);
      canvas.drawLine(const Offset(0, 0), Offset(0, l), p);
      canvas.drawLine(Offset(w - l, 0), Offset(w, 0), p);
      canvas.drawLine(Offset(w, 0), Offset(w, l), p);
      canvas.drawLine(Offset(0, h - l), Offset(0, h), p);
      canvas.drawLine(Offset(0, h), Offset(l, h), p);
      canvas.drawLine(Offset(w - l, h), Offset(w, h), p);
      canvas.drawLine(Offset(w, h - l), Offset(w, h), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
