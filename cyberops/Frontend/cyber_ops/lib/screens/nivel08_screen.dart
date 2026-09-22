import 'dart:async';
import 'dart:math';
import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../games/nivel_08/nivel08_game.dart';
import '../games/nivel_08/components/elemento_nivel08.dart';
import '../games/nivel_08/components/talking_sprite.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';

enum _PantallaNivel08 { juego, victoria, gameOver }

class Nivel08Screen extends StatefulWidget {
  final bool soloEntrenamiento; 
  const Nivel08Screen({super.key, this.soloEntrenamiento = false});
  
  @override
  State<Nivel08Screen> createState() => _Nivel08ScreenState();
}

class _Nivel08ScreenState extends State<Nivel08Screen>
    with TickerProviderStateMixin {
  static const _bgDeep = Color(0xFF050817);
  static const _cyan = Color(0xFF00E5FF);
  static const _purple = Color(0xFF8B5CF6);
  static const _purpleSoft = Color(0xFFC4B5FD);
  static const _pink = Color(0xFFEC4899);
  static const _green = Color(0xFF10F985);
  static const _amber = Color(0xFFFFC857);
  static const _red = Color(0xFFFF4E6B);

  final Nivel08Game _game = Nivel08Game();
  final FlutterTts _tts = FlutterTts();

  bool _hablando = false;
  EstadoFractura _poseFractura = EstadoFractura.neutral;
  String _fraseFractura = '';
  bool _introVozIniciada = false;
  _PantallaNivel08 _pantalla = _PantallaNivel08.juego;
  bool _progresoGuardado = false;

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Las bases de datos guardan todo: usuarios, contraseñas, transacciones, secretos.',
    'Y la mayoría hablan SQL. Un lenguaje diseñado para consultar... y para ser manipulado.',
    'SQL Injection es una de las vulnerabilidades más antiguas y más explotadas del mundo.',
    'La idea es simple: si una aplicación no filtra lo que introduces, puedes alterar la consulta que ejecuta.',
    'En vez de buscar tu usuario, la base de datos ejecutará lo que tú le digas.',
    'Hoy vas a ver cómo funciona desde dentro. Nada de teoría vacía.',
    'Prepárate para hablar directamente con la base de datos.',
    ];

  ResultadoEjecucion? _ultimoResultado;

  List<PiezaSql> _arsenalMezclado = [];
  int _labMezcladoIdx = -1;

  List<PiezaSql> _arsenalParaMostrar() {
    if (_labMezcladoIdx != _game.labActualIdx) {
      _labMezcladoIdx = _game.labActualIdx;
      _arsenalMezclado = List<PiezaSql>.from(_game.labActual.arsenal)
        ..shuffle();
    }
    return _arsenalMezclado;
  }

  List<Map<String, String>> _vocesEs = [];
  int _vozIdx = 0;
  String _vozActualNombre = '—';

  late final AnimationController _cintaCtrl;
  final List<_PiezaEnCinta> _cinta = [];
  int _proximaOleadaSeg = 0;
  int _labQueEstaCorriendo = -1;
  static const double _duracionCintaSeg = 22.0;
  static const int _intervaloOleadaSeg = 18;

  @override
  void initState() {
    super.initState();
    _setupTts();

    _cintaCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..addListener(_tickCinta)
          ..repeat();
    _resetCintaParaLab();
    _actualizarGuia();
  }

  double get _t => _cintaCtrl.value * 60.0 + _ciclosCompletos * 60.0;
  int _ciclosCompletos = 0;
  double _vUltima = 0;

  void _resetCintaParaLab() {
    _labQueEstaCorriendo = _game.labActualIdx;
    _cinta.clear();
    _proximaOleadaSeg = 0;
    _ciclosCompletos = 0;
    _vUltima = 0;
    _generarOleadaSiToca();
  }

  void _tickCinta() {
    if (_game.labActualIdx != _labQueEstaCorriendo && !_game.nivelCompletado) {
      _resetCintaParaLab();
      return;
    }

    if (_cintaCtrl.value < _vUltima) _ciclosCompletos++;
    _vUltima = _cintaCtrl.value;

    final t = _t;

    _cinta.removeWhere((p) => t - p.tiempoEntrada > _duracionCintaSeg);
    _generarOleadaSiToca();

    if (mounted) setState(() {});
  }

  void _generarOleadaSiToca() {
    final t = _t;
    if (t < _proximaOleadaSeg) return;
    if (_game.nivelCompletado) return;
    final lab = _game.labActual;
    final mezcladas = List<PiezaSql>.from(lab.arsenal)..shuffle();
    final cuantas = 4;
    for (int i = 0; i < cuantas && i < mezcladas.length; i++) {
      _cinta.add(
        _PiezaEnCinta(
          pieza: mezcladas[i],
          tiempoEntrada: t + i * 0.4,
          fila: i % 2,
        ),
      );
    }
    _proximaOleadaSeg = t.toInt() + _intervaloOleadaSeg;
  }

  void _cogerDeCinta(_PiezaEnCinta p) {
    _onPiezaTap(p.pieza);
    setState(() {
      _cinta.remove(p);
      _ultimoIdAnadido = p.pieza.id;
    });
  }

  String? _ultimoIdAnadido;

  double _seno(double x) {
    const twoPi = 6.283185307179586;
    double a = x % twoPi;
    if (a < 0) a += twoPi;

    final s = a / twoPi;
    return _sinTabla[(s * 64).floor() % 64];
  }

  static const List<double> _sinTabla = [
    0.0,
    0.098,
    0.195,
    0.290,
    0.383,
    0.471,
    0.556,
    0.634,
    0.707,
    0.773,
    0.831,
    0.881,
    0.924,
    0.957,
    0.981,
    0.995,
    1.0,
    0.995,
    0.981,
    0.957,
    0.924,
    0.881,
    0.831,
    0.773,
    0.707,
    0.634,
    0.556,
    0.471,
    0.383,
    0.290,
    0.195,
    0.098,
    0.0,
    -0.098,
    -0.195,
    -0.290,
    -0.383,
    -0.471,
    -0.556,
    -0.634,
    -0.707,
    -0.773,
    -0.831,
    -0.881,
    -0.924,
    -0.957,
    -0.981,
    -0.995,
    -1.0,
    -0.995,
    -0.981,
    -0.957,
    -0.924,
    -0.881,
    -0.831,
    -0.773,
    -0.707,
    -0.634,
    -0.556,
    -0.471,
    -0.383,
    -0.290,
    -0.195,
    -0.098,
  ];

  void _actualizarGuia() {
    final lab = _game.labActual;
    final cats = _game.payload.map((p) => p.categoria).toSet();
    final faltan = lab.categoriasNecesarias
        .where((c) => !cats.contains(c))
        .toList();

    String texto;
    EstadoFractura pose;

    if (cats.contains(CategoriaPieza.trampa)) {
      texto =
          'Esa pieza es DESTRUCTIVA. Borra datos, no abre puertas. Si la ejecutas, el sistema te detecta. Quítala.';
      pose = EstadoFractura.alerta;
    } else if (_game.payload.isEmpty) {
      texto = _game.labActual.numero == 1
          ? 'Primero, rompe el login con una comilla y una condicion verdadera.'
          : _game.labActual.numero == 2
          ? 'Despues, usa UNION para pedir el email de la tabla de usuarios.'
          : 'Por ultimo, evita escribir OR usando otro operador.';
      pose = EstadoFractura.atenta;
    } else if (cats.length == 1 && cats.first == CategoriaPieza.senuelo) {
      texto =
          'Eso es solo un nombre. Por sí solo no abre nada — necesitas las técnicas reales.';
      pose = EstadoFractura.pensando;
    } else if (faltan.isEmpty) {
      texto = 'Lo tienes. Ejecuta. ';
      pose = EstadoFractura.aprobando;
    } else {
      final next = faltan.first;
      switch (next) {
        case CategoriaPieza.escape:
          texto = 'Falta romper la cadena. Una comilla. Pieza morada.';
          pose = EstadoFractura.pensando;
          break;
        case CategoriaPieza.bypass:
          texto = 'Necesitas que el servidor crea que es verdad. Pieza cyan.';
          pose = EstadoFractura.pensando;
          break;
        case CategoriaPieza.silencio:
          texto = 'Falta callar el resto. Pieza ámbar.';
          pose = EstadoFractura.pensando;
          break;
        case CategoriaPieza.extraer:
          texto = 'Para que te diga lo que no debe... UNION. Pieza verde.';
          pose = EstadoFractura.pensando;
          break;
        case CategoriaPieza.senuelo:
          texto = 'Un nombre cualquiera. "admin" suena familiar.';
          pose = EstadoFractura.pensando;
          break;
        case CategoriaPieza.trampa:
          texto = 'Esa no. Esa solo deja cenizas.';
          pose = EstadoFractura.alerta;
          break;
      }
    }

    final cambioPose = _poseFractura != pose;
    final cambioFrase = _fraseFractura != texto;
    setState(() {
      _fraseFractura = texto;
      _poseFractura = pose;
    });

    final esContextoEducativo =
        cats.contains(CategoriaPieza.trampa) ||
        (cats.length == 1 && cats.first == CategoriaPieza.senuelo);
    if (cambioFrase &&
        (pose == EstadoFractura.alerta ||
            pose == EstadoFractura.aprobando ||
            (esContextoEducativo && cambioPose))) {
      return;
    }
  }

  Future<void> _setupTts() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(0.3);
      await _tts.setVolume(1.0);

      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      try {
        final dynamic raw = await _tts.getVoices;
        if (raw is List) {
          final voces = raw
              .map((v) => Map<String, String>.from(v as Map))
              .toList();
          Map<String, String>? mejor;
          bool nameContiene(Map<String, String> v, List<String> ns) {
            final n = (v['name'] ?? '').toLowerCase();
            return ns.any((x) => n.contains(x));
          }

          mejor = voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                nameContiene(v, ['jorge']) &&
                nameContiene(v, ['mejorada']) &&
                (v['locale'] ?? '').toLowerCase().startsWith('es-es'),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                nameContiene(v, ['eddy']) &&
                (v['locale'] ?? '').toLowerCase().startsWith('es'),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                nameContiene(v, ['rocko', 'rocco']) &&
                (v['locale'] ?? '').toLowerCase().startsWith('es'),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                nameContiene(v, ['pablo']) &&
                (v['locale'] ?? '').toLowerCase().startsWith('es'),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                nameContiene(v, ['microsoft']) &&
                (v['locale'] ?? '').toLowerCase().startsWith('es') &&
                !nameContiene(v, ['helena', 'sabina', 'paulina', 'laura']),
            orElse: () => null,
          );

          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) => v != null && nameContiene(v, ['jorge']),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) => v != null && nameContiene(v, ['diego']),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                nameContiene(v, ['juan']) &&
                (v['locale'] ?? '').toLowerCase().startsWith('es'),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) => v != null && nameContiene(v, ['enrique']),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                nameContiene(v, ['google']) &&
                (v['locale'] ?? '').toLowerCase().startsWith('es'),
            orElse: () => null,
          );
          mejor ??= voces.cast<Map<String, String>?>().firstWhere(
            (v) =>
                v != null &&
                (v['locale'] ?? '').toLowerCase().startsWith('es') &&
                !nameContiene(v, [
                  'monica',
                  'paulina',
                  'helena',
                  'sabina',
                  'laura',
                  'esperanza',
                  'marisol',
                ]),
            orElse: () => null,
          );
          final esVoces = voces.where((v) {
            final loc = (v['locale'] ?? '').toLowerCase();
            final name = (v['name'] ?? '').toLowerCase();
            return loc.startsWith('es') ||
                name.contains('spanish') ||
                name.contains('español') ||
                name.contains('espanol');
          }).toList();
          if (esVoces.isNotEmpty) {
            _vocesEs = esVoces;
            if (mejor != null) {
              final idx = esVoces.indexWhere(
                (v) => v['name'] == mejor!['name'],
              );
              _vozIdx = idx >= 0 ? idx : 0;
            }
            await _aplicarVoz(_vozIdx);
          }
        }
      } catch (e) {}
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted || _vocesEs.isNotEmpty) return;
      try {
        final dynamic raw = await _tts.getVoices;
        if (raw is List) {
          final voces = raw
              .map((v) => Map<String, String>.from(v as Map))
              .toList();
          final esVoces = voces.where((v) {
            final loc = (v['locale'] ?? '').toLowerCase();
            return loc.startsWith('es');
          }).toList();
          if (esVoces.isNotEmpty && mounted) {
            setState(() {
              _vocesEs = esVoces;
              _vozActualNombre = esVoces[0]['name'] ?? '—';
            });
            await _aplicarVoz(0);
          }
        }
      } catch (_) {}
    });
    _tts.setStartHandler(() {
      if (mounted) setState(() => _hablando = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _hablando = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _hablando = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _hablando = false);
    });
  }

  Future<void> _hablar(String texto) async {
    try {
      await _tts.stop();
      await _setupTts();
      await _tts.speak(texto);
    } catch (_) {}
  }

  Future<void> _guardarProgresoNivel() async {
    if (_progresoGuardado || widget.soloEntrenamiento) return;
    _progresoGuardado = true;
    await FirestoreService.guardarPuntuacion(
      puntos: _game.xp,
      nivelCompletado: 8,
      soloEntrenamiento: widget.soloEntrenamiento,
    );
    await FirestoreService.guardarMision(nivel: 8, mision: 8, puntos: _game.xp);
  }

  Future<void> _saltarIntroVoz() async {
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _introVozIniciada = true;
      _hablando = false;
    });
  }

  Future<void> _aplicarVoz(int idx) async {
    if (_vocesEs.isEmpty) return;
    final v = _vocesEs[idx % _vocesEs.length];
    try {
      await _tts.setVoice({
        'name': v['name'] ?? '',
        'locale': v['locale'] ?? 'es-ES',
      });
      setState(() {
        _vozIdx = idx % _vocesEs.length;
        _vozActualNombre = v['name'] ?? '—';
      });
    } catch (e) {}
  }

  Future<void> _siguienteVoz() async {
    if (_vocesEs.isEmpty) return;
    await _aplicarVoz(_vozIdx + 1);
    await _tts.stop();
    _hablar('Soy FRACTURA. Esta es mi voz.');
  }

  void _onPiezaTap(PiezaSql p) {
    setState(() {
      _game.anadirPieza(p);
    });
    _actualizarGuia();
  }

  void _quitarUltima() {
    setState(() {
      _game.quitarUltima();
    });
    _actualizarGuia();
  }

  void _limpiar() {
    setState(() {
      _game.limpiarPayload();
      _ultimoResultado = null;
    });
    _actualizarGuia();
  }

  Future<void> _ejecutar() async {
    final r = _game.ejecutar();
    setState(() {
      _ultimoResultado = r;
    });
    switch (r.tipo) {
      case TipoResultado.exito:
        if (_game.nivelCompletado) {
          _hablar('Has entrado. La grieta cedió.');
          await _guardarProgresoNivel();
          setState(() {
            _pantalla = _PantallaNivel08.victoria;
            _fraseFractura = 'Has entrado. La grieta cedió.';
            _poseFractura = EstadoFractura.triunfal;
          });
        } else {
          setState(() {
            _fraseFractura = _game.labActual.numero == 1
                ? 'Primero, rompe el login con una comilla y una condicion verdadera.'
                : _game.labActual.numero == 2
                ? 'Despues, usa UNION para pedir el email de la tabla de usuarios.'
                : 'Por ultimo, evita escribir OR usando otro operador.';
            _poseFractura = EstadoFractura.aprobando;
          });
          _hablar(_fraseFractura);
        }
        break;
      case TipoResultado.trampaEjecutada:
        setState(() {
          _fraseFractura =
              'Esa pieza era una trampa. Te has revelado al sistema.';
          _poseFractura = EstadoFractura.alerta;
        });
        _hablar(_fraseFractura);
        if (_game.gameOver) {
          setState(() {
            _pantalla = _PantallaNivel08.gameOver;
            _fraseFractura = 'Conexión bloqueada. Te quedaste sin vidas.';
            _poseFractura = EstadoFractura.alerta;
          });
        }
        break;
      case TipoResultado.payloadIncompleto:
        setState(() {
          _fraseFractura = 'Casi. Aún falta algo más para tu intrusión.';
          _poseFractura = EstadoFractura.pensando;
        });
        _hablar(_fraseFractura);
        if (_game.gameOver) {
          setState(() {
            _pantalla = _PantallaNivel08.gameOver;
            _fraseFractura = 'Conexión bloqueada. Te quedaste sin vidas.';
            _poseFractura = EstadoFractura.alerta;
          });
        }
        break;
      case TipoResultado.payloadVacio:
        break;
    }
  }

  void _reintentar() {
    setState(() {
      _game.reset();
      _ultimoResultado = null;
      _pantalla = _PantallaNivel08.juego;
      _labMezcladoIdx = -1;
      _arsenalMezclado = [];
      _fraseFractura = 'Otra oportunidad. ';
      _poseFractura = EstadoFractura.atenta;
    });
    _resetCintaParaLab();
    _hablar(_fraseFractura);
  }

  @override
  void dispose() {
    _cintaCtrl.dispose();
    _tts.stop();
    super.dispose();
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
            subtitulo: 'NIVEL 8 // SQL INJECTION',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () async {
              setState(() {
                _mostrarFractura = false;
              });
              MusicService().playNiveles6to10Music();
              await _ejecutar();
            },
          ),
        ),
      );
    }
    final contenido = switch (_pantalla) {
      _PantallaNivel08.juego => _buildJuego(),
      _PantallaNivel08.victoria => _buildVictoria(),
      _PantallaNivel08.gameOver => _buildGameOver(),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: contenido),
    );
  }

  Widget _fractura({required double size, BorderRadius? radius}) {
    final asset = _poseFractura.assetPath;

    return TalkingSprite(
      idleFrame: asset,
      talkingFrames: const [
        'assets/images/nivel_08/fractura_talk_01.png',
        'assets/images/nivel_08/fractura_talk_02.png',
        'assets/images/nivel_08/fractura_talk_03.png',
        'assets/images/nivel_08/fractura_talk_glitch.png',
        'assets/images/nivel_08/fractura_talk_matrix.png',
      ],
      isSpeaking: _hablando,
      size: Size(size, size),
      minSwapMs: 320,
      maxSwapMs: 680,
      crossfade: const Duration(milliseconds: 120),
      fit: BoxFit.cover,
      borderRadius: radius,
    );
  }

  Widget _buildVictoria() {
    return _buildVictoriaNivel08();
  }

  Widget _buildGameOver() {
    return _buildDerrotaNivel08();
  }

  Widget _buildVictoriaNivel08() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final esMovil = constraints.maxWidth < 600;
      final titleSize = esMovil ? 20.0 : 34.0;
      final spriteSize = esMovil ? 130.0 : 210.0;
      return Stack(
        children: [
          const Positioned.fill(child: _FondoCyber()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(esMovil ? 16 : 24),
                child: Container(
                  padding: EdgeInsets.all(esMovil ? 20 : 28),
                  decoration: BoxDecoration(
                    color: _bgDeep.withValues(alpha: 0.92),
                    border: Border.all(color: _cyan.withValues(alpha: 0.65)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _cyan.withValues(alpha: 0.28),
                        blurRadius: 44,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: _pink.withValues(alpha: 0.18),
                        blurRadius: 58,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'INTRUSIÓN COMPLETADA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: esMovil ? 2 : 5,
                          shadows: [
                            Shadow(color: _cyan, blurRadius: 18),
                            Shadow(
                              color: _pink.withValues(alpha: 0.75),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La grieta cedió. El sistema abrió la puerta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: esMovil ? 12 : 14,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(esMovil ? 10 : 14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _cyan.withValues(alpha: 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _cyan.withValues(alpha: 0.35),
                              blurRadius: 38,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: _pink.withValues(alpha: 0.28),
                              blurRadius: 52,
                            ),
                          ],
                        ),
                        child: TalkingSprite(
                          idleFrame: EstadoFractura.triunfal.assetPath,
                          talkingFrames: const [
                            'assets/images/nivel_08/fractura_talk_01.png',
                            'assets/images/nivel_08/fractura_talk_02.png',
                            'assets/images/nivel_08/fractura_talk_03.png',
                            'assets/images/nivel_08/fractura_talk_glitch.png',
                          ],
                          isSpeaking: true,
                          size: Size(spriteSize, spriteSize),
                          minSwapMs: 320,
                          maxSwapMs: 680,
                          crossfade: const Duration(milliseconds: 120),
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(spriteSize / 2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'FRACTURA',
                        style: TextStyle(
                          color: _cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'La grieta cedió. Buen trabajo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: esMovil ? 12 : 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_game.xp} XP',
                        style: TextStyle(
                          color: _amber,
                          fontSize: esMovil ? 18 : 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _reintentar,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _pink.withValues(alpha: 0.75),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  'REPETIR LAB',
                                  style: TextStyle(
                                    color: _pink,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cyan,
                                foregroundColor: _bgDeep,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  'VOLVER AL MAPA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDerrotaNivel08() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final esMovil = constraints.maxWidth < 650;
      final spriteSize = esMovil ? 120.0 : 190.0;
      final fracturaCentro = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(esMovil ? 8 : 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _red.withValues(alpha: 0.75)),
              boxShadow: [
                BoxShadow(
                  color: _red.withValues(alpha: 0.38),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.16),
                  blurRadius: 26,
                ),
              ],
            ),
            child: TalkingSprite(
              idleFrame: 'assets/images/nivel_08/fractura_alerta_roja.png',
              talkingFrames: const [
                'assets/images/nivel_08/fractura_alerta_roja.png',
                'assets/images/nivel_08/fractura_talk_glitch.png',
                'assets/images/nivel_08/fractura_talk_01.png',
              ],
              isSpeaking: true,
              size: Size(spriteSize, spriteSize),
              minSwapMs: 320,
              maxSwapMs: 680,
              crossfade: const Duration(milliseconds: 100),
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(spriteSize / 2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Te vio. Cerró la puerta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );

      final panelMision = _buildDerrotaPanel(
        titulo: 'MISIÓN FALLIDA',
        lineas: const [
          'SERVIDOR: login.php bloqueado',
          'VIDAS: agotadas',
          'RESPUESTA: payload rechazado',
        ],
        color: _red,
      );

      final panelRegistro = _buildDerrotaPanel(
        titulo: 'REGISTRO DE SEGURIDAD',
        lineas: const [
          '> ALERTA - payload rechazado',
          '> login.php - conexión cerrada',
          '> sesión terminada',
        ],
        color: _pink,
      );

      final botones = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _reintentar,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _red.withValues(alpha: 0.8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: _bgDeep,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'VOLVER AL MAPA',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

      return Stack(
        children: [
          const Positioned.fill(child: _FondoCyber()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(esMovil ? 16 : 24),
                child: Container(
                  padding: EdgeInsets.all(esMovil ? 20 : 28),
                  decoration: BoxDecoration(
                    color: _bgDeep.withValues(alpha: 0.92),
                    border: Border.all(color: _red.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _red.withValues(alpha: 0.28),
                        blurRadius: 42,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONEXIÓN BLOQUEADA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: esMovil ? 22 : 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: esMovil ? 2 : 5,
                          shadows: [
                            Shadow(color: _red, blurRadius: 18),
                            Shadow(
                              color: _cyan.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El sistema detectó la intrusión.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: esMovil ? 12 : 14,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 26),
                      if (esMovil) ...[
                        fracturaCentro,
                        const SizedBox(height: 14),
                        panelMision,
                        const SizedBox(height: 10),
                        panelRegistro,
                      ] else
                        Row(
                          children: [
                            Expanded(child: panelMision),
                            const SizedBox(width: 18),
                            fracturaCentro,
                            const SizedBox(width: 18),
                            Expanded(child: panelRegistro),
                          ],
                        ),
                      const SizedBox(height: 24),
                      botones,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDerrotaPanel({
    required String titulo,
    required List<String> lineas,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 14),
          for (final linea in lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                linea,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJuego() {
    final lab = _game.labActual;
    return Stack(
      children: [
        const Positioned.fill(child: _FondoCyber()),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final esMovil = constraints.maxWidth < 600;
            final panelWidth = constraints.maxWidth < 900 ? 220.0 : 290.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(lab, esMovil: esMovil),
                Expanded(
                  child: esMovil
                      ? _buildJuegoMovil(lab)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: panelWidth,
                                child: _buildPanelFracturaGrande(lab),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: _buildColumnaContenido(lab)),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildJuegoMovil(Lab lab) {
    return Column(
      children: [
        _buildFracturaCompacto(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMisionPanel(lab),
                const SizedBox(height: 10),
                _buildVictima(lab),
                const SizedBox(height: 10),
                _buildCodigo(lab),
                const SizedBox(height: 10),
                _buildArsenal(lab),
                const SizedBox(height: 10),
                _buildConsola(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFracturaCompacto() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cyan.withValues(alpha: 0.08), Colors.transparent],
        ),
        border: Border(
          bottom: BorderSide(color: _cyan.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          _fractura(size: 52, radius: BorderRadius.circular(8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _fraseFractura.isEmpty
                  ? 'Observa, analiza, actúa.'
                  : _fraseFractura,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 11,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _introVozIniciada
                ? null
                : () {
                    setState(() => _introVozIniciada = true);
                    _hablar(_fraseFractura);
                  },
            child: Icon(
              Icons.record_voice_over_outlined,
              color: _cyan.withValues(alpha: _introVozIniciada ? 0.3 : 0.8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnaContenido(Lab lab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMisionPanel(lab),
        const SizedBox(height: 10),
        Expanded(
          flex: 4,
          child: LayoutBuilder(
            builder: (ctx, c) {
              if (c.maxWidth < 480) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildVictima(lab),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCodigo(lab),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(child: _buildVictima(lab)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(child: _buildCodigo(lab)),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(child: _buildArsenal(lab)),
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(child: _buildConsola()),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPanelFracturaGrande(Lab lab) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(child: _LluviaCodigo(controller: _cintaCtrl)),
          ),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.8,
                  colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _green, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ENLACE ACTIVO',
                      style: TextStyle(
                        color: _green.withValues(alpha: 0.9),
                        fontSize: 10,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _hablando ? '·· TX' : 'RX',
                      style: TextStyle(
                        color: _hablando
                            ? _cyan.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Center(
                  child: _fractura(
                    size: 250,
                    radius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ShaderMask(
                    shaderCallback: (b) =>
                        LinearGradient(colors: [_cyan, _pink]).createShader(b),
                    child: const Text(
                      'FRACTURA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '— ENTIDAD NO CLASIFICADA —',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _cyan.withValues(alpha: _hablando ? 1.0 : 0.4),
                                _cyan.withValues(alpha: _hablando ? 0.6 : 0.1),
                              ],
                            ),
                            boxShadow: _hablando
                                ? [BoxShadow(color: _cyan, blurRadius: 6)]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _introVozIniciada
                                      ? null
                                      : () {
                                          setState(
                                            () => _introVozIniciada = true,
                                          );
                                          _hablar(_fraseFractura);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cyan,
                                    foregroundColor: _bgDeep,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'INICIAR VOZ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _introVozIniciada
                                    ? _saltarIntroVoz
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _pink.withValues(alpha: 0.7),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'SALTAR',
                                  style: TextStyle(
                                    color: _pink,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'LO QUE NECESITAS',
                  style: TextStyle(
                    color: _amber,
                    fontSize: 10,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Marca cada paso al añadir su pieza',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                    letterSpacing: 1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                ...lab.categoriasNecesarias.map((cat) {
                  final yaTengo = _game.payload
                      .map((p) => p.categoria)
                      .contains(cat);
                  final c = _colorCategoria(cat);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            yaTengo
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: yaTengo ? _green : c.withValues(alpha: 0.6),
                            size: 14,
                            shadows: yaTengo
                                ? [Shadow(color: _green, blurRadius: 8)]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _etiquetaCategoria(cat),
                                style: TextStyle(
                                  color: yaTengo ? _green : c.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _explicacionCategoria(cat),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 9,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () async {
                      if (_vocesEs.isEmpty) {
                        try {
                          final dynamic raw = await _tts.getVoices;
                          if (raw is List) {
                            final voces = raw
                                .map((v) => Map<String, String>.from(v as Map))
                                .toList();
                            final esVoces = voces.where((v) {
                              final loc = (v['locale'] ?? '').toLowerCase();
                              return loc.startsWith('es');
                            }).toList();
                            if (esVoces.isNotEmpty) {
                              setState(() {
                                _vocesEs = esVoces;
                              });
                              await _aplicarVoz(0);
                              _hablar('Soy FRACTURA. Esta es mi voz.');
                            }
                          }
                        } catch (_) {}
                      } else {
                        await _siguienteVoz();
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _cyan.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.graphic_eq,
                            color: _cyan.withValues(alpha: 0.8),
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _vocesEs.isEmpty
                                  ? 'VOZ · pulsar para detectar'
                                  : 'VOZ · ${_vozActualNombre.length > 22 ? "${_vozActualNombre.substring(0, 22)}..." : _vozActualNombre} (${_vozIdx + 1}/${_vocesEs.length})',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 9,
                                letterSpacing: 1,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Text(
                            '→',
                            style: TextStyle(
                              color: _cyan.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _cintaCtrl,
                  builder: (ctx, _) {
                    final t = _cintaCtrl.value * 60.0;
                    return Row(
                      children: List.generate(10, (i) {
                        final fase = (t * 1.6 + i * 0.35) % 1.0;
                        final h = _hablando
                            ? (3.0 + 16.0 * (0.5 + 0.5 * _seno(fase * 6.28)))
                            : 3.0 + 2.0 * (0.5 + 0.5 * _seno(t * 0.4 + i));
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1.5,
                            ),
                            child: Container(
                              height: h,
                              decoration: BoxDecoration(
                                color: _hablando
                                    ? _cyan.withValues(alpha: 0.8)
                                    : _cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: _hablando
                                    ? [
                                        BoxShadow(
                                          color: _cyan.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Lab lab, {bool esMovil = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 8 : 14,
        vertical: esMovil ? 6 : 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _cyan.withValues(alpha: 0.4), width: 1),
        ),
        gradient: LinearGradient(
          colors: [_cyan.withValues(alpha: 0.06), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver al mapa',
            icon: Icon(Icons.arrow_back_ios_new, color: _cyan, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (esMovil)
                  Text(
                    'NV 08 · INTRUSIÓN SQL',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) =>
                            LinearGradient(colors: [_cyan, _pink]).createShader(b),
                        child: const Text(
                          'INTRUSIÓN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '/ NV 08',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  esMovil
                      ? 'LAB ${_game.labActual.numero}/3 · ${lab.titulo}'
                      : '▸ SQL INJECTION  ▸ LAB ${_game.labActual.numero}/3  ▸ ${lab.titulo}',
                  style: TextStyle(
                    color: _cyan.withValues(alpha: 0.6),
                    fontSize: 9,
                    letterSpacing: esMovil ? 1 : 4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              final activa = i < _game.vidas;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  activa ? Icons.favorite : Icons.favorite_border,
                  color: activa ? _pink : Colors.white24,
                  size: 18,
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '${_game.xp} XP',
            style: TextStyle(
              color: _amber,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: esMovil ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisionPanel(Lab lab) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_amber.withValues(alpha: 0.12), _amber.withValues(alpha: 0.02)],
        ),
        border: Border(left: BorderSide(color: _amber, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Text(
            '▸ MISIÓN',
            style: TextStyle(
              color: _amber,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              lab.mision,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictima(Lab lab) {
    final payloadTxt = _game.payloadTexto();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: 0.04),
        border: Border.all(color: _cyan.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '▸ OBJETIVO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              Text('● ONLINE', style: TextStyle(color: _green, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF14182E),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lab.victimaUrl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'USUARIO',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _bgDeep,
                    border: Border.all(color: _cyan),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payloadTxt.isEmpty ? '_____' : payloadTxt,
                    style: TextStyle(
                      color: _cyan,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'CONTRASEÑA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _bgDeep,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '••••••••',
                    style: TextStyle(
                      color: Colors.white24,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_cyan, _pink]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '▸ ACCEDER ◂',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _bgDeep,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodigo(Lab lab) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.04),
        border: Border.all(color: _purple.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '▸ SERVIDOR · login.php',
            style: TextStyle(color: _purpleSoft, fontSize: 9, letterSpacing: 3),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lab.codigoLineas.length, (i) {
                final esVuln = i == lab.lineaVulnerable;
                final num = (i + 1).toString().padLeft(2, '0');
                return Container(
                  decoration: esVuln
                      ? BoxDecoration(
                          color: _red.withValues(alpha: 0.12),
                          border: Border(
                            left: BorderSide(color: _red, width: 2),
                          ),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        num,
                        style: TextStyle(
                          color: Colors.white24,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          lab.codigoLineas[i],
                          style: TextStyle(
                            color: esVuln
                                ? _red.withValues(alpha: 0.95)
                                : Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.1),
              border: Border(left: BorderSide(color: _red, width: 2)),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
            ),
            child: Text(
              lab.avisoCodigo,
              style: TextStyle(color: _red, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArsenal(Lab lab) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_pink.withValues(alpha: 0.08), _purple.withValues(alpha: 0.05)],
        ),
        border: Border.all(color: _pink.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '▸▸ ARSENAL DE ATAQUE',
                style: TextStyle(
                  color: _pink,
                  fontSize: 13,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'haz click en una pieza para añadirla a tu payload',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${_arsenalParaMostrar().length} piezas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _arsenalParaMostrar()
                .map((p) => _piezaArsenal(p))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _piezaArsenal(PiezaSql p) {
    return AnimatedBuilder(
      animation: _cintaCtrl,
      builder: (context, _) {
        final offset = (p.id.hashCode.abs() % 100) / 100.0;
        final fase = ((_cintaCtrl.value * 60.0 / 1.6) + offset) % 1.0;
        final pulse = 0.3 + 0.35 * _seno(fase * 6.283185307179586);
        return _PiezaConHover(
          onTap: () => _onPiezaTap(p),
          child: _piezaButtonBig(p, pulse: pulse, util: false),
        );
      },
    );
  }

  Widget _construirCinta() {
    return LayoutBuilder(
      builder: (ctx, c) {
        final ancho = c.maxWidth;
        final t = _t;
        return Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Text(
                        '→',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.05),
                                _red.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SE PIERDE',
                        style: TextStyle(
                          color: _red.withValues(alpha: 0.7),
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: 50,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.transparent, _red.withValues(alpha: 0.3)],
                        ),
                      ),
                    ),
                  ),
                ),
                ..._cinta.map((p) {
                  final age = t - p.tiempoEntrada;
                  if (age < 0) {
                    return const SizedBox.shrink();
                  }
                  final progress = (age / _duracionCintaSeg).clamp(0.0, 1.0);
                  final x = progress * (ancho - 75);
                  double opacity;
                  if (progress < 0.03) {
                    opacity = progress / 0.03;
                  } else if (progress > 0.93) {
                    opacity = (1.0 - progress) / 0.07;
                  } else {
                    opacity = 1.0;
                  }
                  opacity = opacity.clamp(0.0, 1.0);
                  final yBase = p.fila == 0 ? 2.0 : 44.0;
                  final bob =
                      (4 * (0.5 + 0.5 * _seno(t * 1.6 + p.fila * 1.2))) - 2;
                  return Positioned(
                    left: x,
                    top: yBase + bob,
                    child: Opacity(
                      opacity: opacity,
                      child: _PiezaConHover(
                        onTap: () => _cogerDeCinta(p),
                        child: _piezaButton(p.pieza, onTap: () {}),
                      ),
                    ),
                  );
                }),
                if (_cinta.isEmpty)
                  Center(
                    child: Text(
                      'esperando primera oleada...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _piezaButtonBig(
    PiezaSql p, {
    required double pulse,
    required bool util,
  }) {
    final c = _colorCategoria(p.categoria);

    final mostrarEtiqueta =
        p.categoria != CategoriaPieza.trampa &&
        p.categoria != CategoriaPieza.senuelo;
    final etiqueta = mostrarEtiqueta ? _etiquetaCategoria(p.categoria) : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18 + 0.05 * pulse),
        border: Border.all(color: c, width: util ? 1.5 : 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.25 + 0.45 * pulse),
            blurRadius: 10 + 14 * pulse,
            spreadRadius: util ? 0.5 : 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarEtiqueta) ...[
            Text(
              etiqueta,
              style: TextStyle(
                color: c,
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
          ] else ...[
            const SizedBox(height: 13),
          ],
          Text(
            p.token,
            style: TextStyle(
              color: c,
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              shadows: util
                  ? [Shadow(color: c.withValues(alpha: pulse), blurRadius: 8)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _piezaButton(PiezaSql p, {required VoidCallback onTap}) {
    final c = _colorCategoria(p.categoria);
    final etiqueta = _etiquetaCategoria(p.categoria);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.18),
          border: Border.all(color: c, width: 1),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.25), blurRadius: 8)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              etiqueta,
              style: TextStyle(
                color: c,
                fontSize: 8,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              p.token,
              style: TextStyle(
                color: c,
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorCategoria(CategoriaPieza c) {
    switch (c) {
      case CategoriaPieza.escape:
        return _purpleSoft;
      case CategoriaPieza.bypass:
        return _cyan;
      case CategoriaPieza.extraer:
        return _green;
      case CategoriaPieza.silencio:
        return _amber;
      case CategoriaPieza.senuelo:
        return _pink;
      case CategoriaPieza.trampa:
        return _red;
    }
  }

  String _etiquetaCategoria(CategoriaPieza c) {
    switch (c) {
      case CategoriaPieza.escape:
        return 'ESCAPE';
      case CategoriaPieza.bypass:
        return 'BYPASS';
      case CategoriaPieza.extraer:
        return 'EXTRAER';
      case CategoriaPieza.silencio:
        return 'SILENCIO';
      case CategoriaPieza.senuelo:
        return 'SEÑUELO';
      case CategoriaPieza.trampa:
        return '⚠ TRAMPA';
    }
  }

  String _explicacionCategoria(CategoriaPieza c) {
    switch (c) {
      case CategoriaPieza.escape:
        return 'rompe el campo';
      case CategoriaPieza.bypass:
        return 'fuerza un "sí" del servidor';
      case CategoriaPieza.extraer:
        return 'saca datos escondidos';
      case CategoriaPieza.silencio:
        return 'anula el resto de la consulta';
      case CategoriaPieza.senuelo:
        return 'distractor opcional';
      case CategoriaPieza.trampa:
        return 'destruye, no entra';
    }
  }

  Widget _buildConsola() {
    final r = _ultimoResultado;
    Color colorRespuesta = Colors.white70;
    if (r != null) {
      switch (r.tipo) {
        case TipoResultado.exito:
          colorRespuesta = _green;
          break;
        case TipoResultado.trampaEjecutada:
          colorRespuesta = _red;
          break;
        case TipoResultado.payloadIncompleto:
          colorRespuesta = _amber;
          break;
        case TipoResultado.payloadVacio:
          colorRespuesta = Colors.white60;
          break;
      }
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cyan.withValues(alpha: 0.06),
        border: Border.all(color: _cyan, width: 1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.15), blurRadius: 18)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '▸▸ CONSOLA DE INYECCIÓN',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 11,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.backspace_outlined,
                  color: Colors.white54,
                  size: 18,
                ),
                tooltip: 'Quitar última',
                onPressed: _quitarUltima,
              ),
              TextButton(
                onPressed: _limpiar,
                child: const Text(
                  'LIMPIAR',
                  style: TextStyle(color: Colors.white54, letterSpacing: 2),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _ejecutar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: _bgDeep,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  '▶ EJECUTAR',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: Colors.white12,
                width: 1,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '▸ TU PAYLOAD',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                _game.payload.isEmpty
                    ? Text(
                        '(haz click en piezas de la cinta para añadirlas)',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: _game.payload.asMap().entries.map((entry) {
                          final p = entry.value;
                          final esUltima =
                              entry.key == _game.payload.length - 1 &&
                              _ultimoIdAnadido == p.id;
                          final c = _colorCategoria(p.categoria);
                          final tile = Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.25),
                              border: Border.all(color: c),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: esUltima
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.6),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              p.token,
                              style: TextStyle(
                                color: c,
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                          if (!esUltima) return tile;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.elasticOut,
                            builder: (ctx, v, child) {
                              return Transform.scale(
                                scale: 0.4 + 0.6 * v,
                                child: Opacity(
                                  opacity: v.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: tile,
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: _cyan.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r == null) ...[
                  Text(
                    '› esperando ejecución...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ] else ...[
                  Text(
                    '› ${r.sqlGenerado}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.respuestaServidor,
                    style: TextStyle(
                      color: colorRespuesta,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PiezaEnCinta {
  final PiezaSql pieza;
  final double tiempoEntrada;
  final int fila;

  _PiezaEnCinta({
    required this.pieza,
    required this.tiempoEntrada,
    required this.fila,
  });
}

class _PiezaConHover extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PiezaConHover({required this.child, required this.onTap});

  @override
  State<_PiezaConHover> createState() => _PiezaConHoverState();
}

class _PiezaConHoverState extends State<_PiezaConHover> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_hover) scale = 1.1;
    if (_down) scale = 0.92;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _FondoCyber extends StatelessWidget {
  const _FondoCyber();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.2,
          colors: [
            const Color(0xFF1A1F4A),
            const Color(0xFF0A0E27),
            const Color(0xFF050817),
          ],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _LluviaCodigo extends StatefulWidget {
  final AnimationController controller;
  const _LluviaCodigo({required this.controller});

  @override
  State<_LluviaCodigo> createState() => _LluviaCodigoState();
}

class _ColumnaLluvia {
  final double xRel;
  final double velocidad;
  final List<String> caracteres;
  final double offset;
  final int largo;
  final Color color;

  _ColumnaLluvia({
    required this.xRel,
    required this.velocidad,
    required this.caracteres,
    required this.offset,
    required this.largo,
    required this.color,
  });
}

class _LluviaCodigoState extends State<_LluviaCodigo> {
  late List<_ColumnaLluvia> _columnas;
  static const String _alfabeto =
      '0123456789アカサタナハマヤラワイキシチニヒミリヰウクスツヌフムユルヱエケセテネヘメレヲ';

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    const paleta = [
      Color(0xFF00E5FF),
      Color(0xFF00E5FF),
      Color(0xFF00E5FF),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF10F985),
    ];
    _columnas = List.generate(14, (i) {
      return _ColumnaLluvia(
        xRel: i / 14.0,
        velocidad: 0.35 + rng.nextDouble() * 0.85,
        caracteres: List.generate(
          18,
          (_) => _alfabeto[rng.nextInt(_alfabeto.length)],
        ),
        offset: rng.nextDouble(),
        largo: 8 + rng.nextInt(8),
        color: paleta[rng.nextInt(paleta.length)],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (ctx, _) {
        return CustomPaint(
          painter: _LluviaCodigoPainter(
            columnas: _columnas,
            t: widget.controller.value * 60.0,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _LluviaCodigoPainter extends CustomPainter {
  final List<_ColumnaLluvia> columnas;
  final double t;
  static const double _altLetra = 14.0;

  _LluviaCodigoPainter({required this.columnas, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    for (final col in columnas) {
      final x = col.xRel * size.width;
      final cicloLargo = size.height + col.largo * _altLetra;
      final progreso =
          ((t * col.velocidad * 30) + col.offset * cicloLargo) % cicloLargo;
      final yHead = progreso - col.largo * _altLetra;

      for (int i = 0; i < col.largo; i++) {
        final y = yHead + i * _altLetra;
        if (y < -_altLetra || y > size.height) continue;
        final dist = (col.largo - 1 - i) / col.largo;
        final brillo = (1.0 - dist).clamp(0.0, 1.0);
        final esHead = i == col.largo - 1;
        final cy = y + _altLetra / 2;
        final cx = x + 3;
        if (esHead) {
          canvas.drawCircle(
            Offset(cx, cy),
            6,
            Paint()
              ..color = col.color.withValues(alpha: 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
          canvas.drawCircle(
            Offset(cx, cy),
            2.4,
            Paint()..color = const Color(0xFFFFFFFF),
          );
        } else {
          canvas.drawCircle(
            Offset(cx, cy),
            1.4 + brillo * 0.6,
            Paint()..color = col.color.withValues(alpha: 0.15 + brillo * 0.5),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LluviaCodigoPainter old) =>
      old.t != t || old.columnas != columnas;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
