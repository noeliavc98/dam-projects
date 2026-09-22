import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../config/app_colors.dart';
import 'fractura_avatar.dart';

class FracturaDialogo extends StatefulWidget {
  final List<String> dialogos;
  final VoidCallback onFinalizado;
  final String subtitulo;
  final String textoBotonFinal;
  final bool usarVoz;
  final bool permitirSaltarIntro;
  final bool permitirCambiarVoz;
  final double velocidadVoz;
  final double tonoVoz;
  final int milisegundosPorCaracter;

  const FracturaDialogo({
    super.key,
    required this.dialogos,
    required this.onFinalizado,
    this.subtitulo = 'ENTIDAD NO CLASIFICADA',
    this.textoBotonFinal = 'CONTINUAR',
    this.usarVoz = false,
    this.permitirSaltarIntro = false,
    this.permitirCambiarVoz = false,
    this.velocidadVoz = 0.58,
    this.tonoVoz = 0.88,
    this.milisegundosPorCaracter = 24,
  });

  @override
  State<FracturaDialogo> createState() => _FracturaDialogoState();
}

class _FracturaDialogoState extends State<FracturaDialogo> {
  final FlutterTts _tts = FlutterTts();
  int _dialogoActual = 0;
  String _textoMostrado = '';
  bool _escribiendo = false;
  bool _vozActiva = false;
  bool _ttsConfigurado = false;
  int _vozToken = 0;
  List<Map<String, String>> _voces = [];
  int _vozActual = 0;
  String _nombreVoz = 'VOZ';
  Timer? _timer;

  bool get _hablando => _escribiendo || _vozActiva;

  @override
  void initState() {
    super.initState();
    _escribirTexto();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.usarVoz) {
      _tts.stop();
    }
    super.dispose();
  }

  Future<void> _configurarVoz() async {
    if (!widget.usarVoz || _ttsConfigurado) return;
    _ttsConfigurado = true;

    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(widget.velocidadVoz);
      await _tts.setPitch(widget.tonoVoz);
      await _tts.setVolume(0.9);
      _tts.setCompletionHandler(_marcarVozTerminada);
      _tts.setCancelHandler(_marcarVozTerminada);
      _tts.setErrorHandler((_) => _marcarVozTerminada());
      await _cargarVoces();
    } catch (e) {
      debugPrint('No se pudo preparar la voz de Fractura: $e');
    }
  }

  Future<void> _cargarVoces() async {
    if (!widget.permitirCambiarVoz || _voces.isNotEmpty) return;

    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is! List) return;

      final voces = raw
          .whereType<Map>()
          .map((voz) {
            return {
              'name': '${voz['name'] ?? ''}',
              'locale': '${voz['locale'] ?? ''}',
            };
          })
          .where((voz) {
            final nombre = (voz['name'] ?? '').toLowerCase();
            final locale = (voz['locale'] ?? '').toLowerCase();
            return locale.startsWith('es') ||
                nombre.contains('spanish') ||
                nombre.contains('espanol');
          })
          .toList();

      if (voces.isEmpty || !mounted) return;
      setState(() {
        _voces = voces;
        _nombreVoz = _nombreCortaVoz(voces.first);
      });
      await _aplicarVoz(0);
    } catch (e) {
      debugPrint('No se pudieron cargar voces para Fractura: $e');
    }
  }

  Future<void> _aplicarVoz(int index) async {
    if (_voces.isEmpty) return;
    final nextIndex = index % _voces.length;
    final voz = _voces[nextIndex];

    try {
      await _tts.setVoice({
        'name': voz['name'] ?? '',
        'locale': voz['locale'] ?? 'es-ES',
      });
      if (!mounted) return;
      setState(() {
        _vozActual = nextIndex;
        _nombreVoz = _nombreCortaVoz(voz);
      });
    } catch (e) {
      debugPrint('No se pudo cambiar la voz de Fractura: $e');
    }
  }

  String _nombreCortaVoz(Map<String, String> voz) {
    final nombre = (voz['name'] ?? '').trim();
    if (nombre.isEmpty) return 'VOZ';
    return nombre.length > 18 ? '${nombre.substring(0, 18)}...' : nombre;
  }

  Future<void> _cambiarVoz() async {
    if (!widget.usarVoz || !widget.permitirCambiarVoz) return;
    await _configurarVoz();
    if (_voces.isEmpty) {
      await _cargarVoces();
    }
    if (_voces.length < 2) return;

    _timer?.cancel();
    _vozToken++;
    await _aplicarVoz(_vozActual + 1);
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _textoMostrado = widget.dialogos[_dialogoActual];
      _escribiendo = false;
      _vozActiva = false;
    });
    _hablar(widget.dialogos[_dialogoActual], _vozToken);
  }

  Future<void> _hablar(String texto, int token) async {
    if (!widget.usarVoz) return;

    try {
      await _configurarVoz();
      if (!mounted || token != _vozToken) return;
      await _tts.stop();
      if (!mounted || token != _vozToken) return;
      setState(() => _vozActiva = true);
      await _tts.speak(texto);
    } catch (e) {
      debugPrint('No se pudo reproducir la voz de Fractura: $e');
      _marcarVozTerminada();
    }
  }

  void _marcarVozTerminada() {
    if (!mounted) return;
    setState(() => _vozActiva = false);
  }

  void _escribirTexto() {
    _timer?.cancel();
    _vozToken++;
    if (widget.usarVoz) {
      _tts.stop();
    }

    final texto = widget.dialogos[_dialogoActual];
    int index = 0;

    setState(() {
      _textoMostrado = '';
      _escribiendo = true;
      _vozActiva = false;
    });

    _hablar(texto, _vozToken);

    _timer = Timer.periodic(
      Duration(milliseconds: widget.milisegundosPorCaracter),
      (timer) {
        if (!mounted) return;

        if (index >= texto.length) {
          timer.cancel();
          setState(() {
            _escribiendo = false;
          });
          return;
        }

        setState(() {
          _textoMostrado += texto[index];
        });

        index++;
      },
    );
  }

  void _saltarIntroCompleta() {
    _timer?.cancel();
    _vozToken++;
    if (widget.usarVoz) {
      _tts.stop();
    }
    widget.onFinalizado();
  }

  void _siguiente() {
    if (_hablando) {
      _timer?.cancel();
      _vozToken++;
      if (widget.usarVoz) {
        _tts.stop();
      }
      setState(() {
        _textoMostrado = widget.dialogos[_dialogoActual];
        _escribiendo = false;
        _vozActiva = false;
      });
      return;
    }

    if (_dialogoActual < widget.dialogos.length - 1) {
      setState(() {
        _dialogoActual++;
      });
      _escribirTexto();
    } else {
      widget.onFinalizado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esUltimo = _dialogoActual == widget.dialogos.length - 1;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: FracturaAvatar(hablando: _hablando, size: 220),
                ),
                const SizedBox(height: 20),
                Text(
                  'FRACTURA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.cyan.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.bgMain.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    _textoMostrado,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${_dialogoActual + 1} / ${widget.dialogos.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: _siguiente,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _hablando
                              ? 'SALTAR'
                              : esUltimo
                              ? widget.textoBotonFinal
                              : 'SIGUIENTE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    if (widget.usarVoz && widget.permitirCambiarVoz)
                      SizedBox(
                        width: 190,
                        child: OutlinedButton.icon(
                          onPressed: _cambiarVoz,
                          icon: const Icon(Icons.record_voice_over_rounded),
                          label: Text(
                            _nombreVoz,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.purple,
                            side: BorderSide(
                              color: AppColors.purple.withValues(alpha: 0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    if (widget.permitirSaltarIntro)
                      SizedBox(
                        width: 170,
                        child: TextButton.icon(
                          onPressed: _saltarIntroCompleta,
                          icon: const Icon(Icons.skip_next_rounded),
                          label: const Text('SALTAR INTRO'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 15),
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
    );
  }
}
