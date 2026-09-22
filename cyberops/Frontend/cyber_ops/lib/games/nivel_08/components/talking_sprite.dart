
//   TalkingSprite(
//     idleFrame: 'assets/smiley_normal.png',
//     talkingFrames: const [
//       'assets/smiley_normal.png',
//       'assets/smiley_glitch.png',
//       'assets/smiley_matrix.png',
//       'assets/smiley_red.png',
//       'assets/smiley_alt.png',
//     ],
//     isSpeaking: _isPlayingAudio,
//     size: const Size(300, 300),
//   )

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TalkingSprite extends StatefulWidget {
  /// Imagen que se muestra cuando NO está hablando.
  final String idleFrame;

  /// Lista de frames que rota mientras habla. 
  final List<String> talkingFrames;

  /// Cuándo está hablando.
  final bool isSpeaking;

  /// Tamaño de la imagen.
  final Size size;

  /// Intervalo mínimo entre swaps (ms).
  final int minSwapMs;

  /// Intervalo máximo entre swaps (ms).
  final int maxSwapMs;

  /// Duración del fade entre frames. 0 = corte seco.
  final Duration crossfade;

  /// Cómo encajar la imagen.
  final BoxFit fit;

  /// Border radius opcional (recorte).
  final BorderRadius? borderRadius;

  const TalkingSprite({
    super.key,
    required this.idleFrame,
    required this.talkingFrames,
    required this.isSpeaking,
    required this.size,
    this.minSwapMs = 90,
    this.maxSwapMs = 180,
    this.crossfade = const Duration(milliseconds: 60),
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : assert(talkingFrames.length >= 1, 'Necesitas al menos 1 frame');

  @override
  State<TalkingSprite> createState() => _TalkingSpriteState();
}

class _TalkingSpriteState extends State<TalkingSprite>
    with TickerProviderStateMixin {
  final _rng = Random();
  Timer? _timer;
  late String _current;
  late AnimationController _pulse;
  // Reloj continuo para bobbing  (cuando habla).
  late AnimationController _vital;

  @override
  void initState() {
    super.initState();
    _current = widget.idleFrame;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    
    _vital = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    if (widget.isSpeaking) {
      _pulse.repeat(reverse: true);
      _startTalking();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(AssetImage(widget.idleFrame), context);
      for (final f in widget.talkingFrames) {
        precacheImage(AssetImage(f), context);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TalkingSprite old) {
    super.didUpdateWidget(old);
    if (widget.isSpeaking && !old.isSpeaking) {
      _pulse.repeat(reverse: true);
      _startTalking();
    } else if (!widget.isSpeaking && old.isSpeaking) {
      _pulse.stop();
      _pulse.value = 0;
      _stopTalking();
    }
  }

  void _startTalking() {
    _timer?.cancel();
    _scheduleNext();
  }

  void _scheduleNext() {
    final delta = widget.maxSwapMs - widget.minSwapMs;
    final ms = widget.minSwapMs + _rng.nextInt(delta <= 0 ? 1 : delta);
    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted || !widget.isSpeaking) return;
      setState(() {
        if (widget.talkingFrames.length == 1) {
          _current = widget.talkingFrames.first;
        } else {
          String next;
          do {
            next = widget.talkingFrames[_rng.nextInt(widget.talkingFrames.length)];
          } while (next == _current);
          _current = next;
        }
      });
      _scheduleNext();
    });
  }

  void _stopTalking() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _current = widget.idleFrame);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _vital.dispose();
    super.dispose();
  }

  // aproximación a sin sin importar dart:math 
  double _sin(double x) {
    const twoPi = 6.283185307179586;
    double a = x % twoPi;
    if (a < 0) a += twoPi;
    final s = a / twoPi;
    return _sinTabla[(s * 64).floor() % 64];
  }

  static const List<double> _sinTabla = [
    0.0, 0.098, 0.195, 0.290, 0.383, 0.471, 0.556, 0.634,
    0.707, 0.773, 0.831, 0.881, 0.924, 0.957, 0.981, 0.995,
    1.0, 0.995, 0.981, 0.957, 0.924, 0.881, 0.831, 0.773,
    0.707, 0.634, 0.556, 0.471, 0.383, 0.290, 0.195, 0.098,
    0.0, -0.098, -0.195, -0.290, -0.383, -0.471, -0.556, -0.634,
    -0.707, -0.773, -0.831, -0.881, -0.924, -0.957, -0.981, -0.995,
    -1.0, -0.995, -0.981, -0.957, -0.924, -0.881, -0.831, -0.773,
    -0.707, -0.634, -0.556, -0.471, -0.383, -0.290, -0.195, -0.098,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _vital]),
      builder: (context, _) {
        // Animaciones base 
        final t = _pulse.value;             // pulso 0..1
        final v = _vital.value * 4 * 6.2832; // tiempo angular continuo

        // Bobbing siempre activo (respiración leve)
        final bobIdle = _sin(v * 0.25) * 1.8;

        // Si está hablando, multiplicamos el movimiento y añadimos shake
        final talking = widget.isSpeaking;
        final bob = talking
            ? bobIdle + _sin(v * 1.2) * 3.0
            : bobIdle;
        // "Cabeceo" lateral cuando habla
        final shakeX = talking
            ? _sin(v * 1.5 + 0.3) * 2.0
            : 0.0;
        // Pequeña rotación 
        final tilt = talking ? _sin(v * 1.0) * 0.012 : 0.0;
        // Escala que late más cuando habla
        final scale = talking ? 1.0 + (t * 0.04) : 1.0;
        final glow = talking ? 0.35 + (t * 0.4) : 0.0;

        // Desplazamiento RGB chromatic aberration cuando habla.
        final aberracion =
            talking ? (1.5 + 1.5 * _sin(v * 2.4)).abs() : 0.0;

        //  Imagen base 
        Widget baseImage = Image.asset(
          _current,
          key: ValueKey(_current),
          width: widget.size.width,
          height: widget.size.height,
          fit: widget.fit,
          errorBuilder: (_, _, _) => Image.asset(
            widget.idleFrame,
            width: widget.size.width,
            height: widget.size.height,
            fit: widget.fit,
          ),
        );

        Widget image = AnimatedSwitcher(
          duration: widget.crossfade,
          child: baseImage,
        );

        // Si habla, montamos 3 capas RGB ligeramente desplazadas para
        // crear efecto glitch / aberración cromática.
        if (talking && aberracion > 0.1) {
          image = Stack(
            children: [
              // Capa roja desplazada a la izquierda
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(-aberracion, 0),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      1, 0, 0, 0, 0,
                      0, 0, 0, 0, 0,
                      0, 0, 0, 0, 0,
                      0, 0, 0, 0.85, 0,
                    ]),
                    child: baseImage,
                  ),
                ),
              ),
              // Capa cyan desplazada a la derecha
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(aberracion, 0),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0, 0, 0, 0, 0,
                      0, 1, 0, 0, 0,
                      0, 0, 1, 0, 0,
                      0, 0, 0, 0.85, 0,
                    ]),
                    child: baseImage,
                  ),
                ),
              ),
              // Capa principal con AnimatedSwitcher en el medio
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: widget.crossfade,
                  child: baseImage,
                ),
              ),
            ],
          );
        }

        Widget sized = SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: image,
        );
        if (widget.borderRadius != null) {
          sized = ClipRRect(borderRadius: widget.borderRadius!, child: sized);
        }

        return Transform.translate(
          offset: Offset(shakeX, bob),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: talking
                    ? BoxDecoration(
                        borderRadius: widget.borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF)
                                .withValues(alpha: glow * 0.6),
                            blurRadius: 24 * (1 + t),
                            spreadRadius: 2 * t,
                          ),
                          BoxShadow(
                            color: const Color(0xFFEC4899)
                                .withValues(alpha: glow * 0.3),
                            blurRadius: 40 * (1 + t),
                          ),
                        ],
                      )
                    : null,
                child: sized,
              ),
            ),
          ),
        );
      },
    );
  }
}
