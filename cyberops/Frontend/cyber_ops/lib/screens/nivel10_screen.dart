import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/games/nivel_10/components/nivel10_state.dart';
import 'package:cyber_ops/games/nivel_10/nivel10_game.dart';
import 'package:cyber_ops/games/nivel_10/widgets/acto1_widget.dart';
import 'package:cyber_ops/games/nivel_10/widgets/acto2_widget.dart';
import 'package:cyber_ops/games/nivel_10/widgets/acto3_widget.dart';
import 'package:cyber_ops/games/nivel_10/widgets/resultados_widget.dart';
import 'package:cyber_ops/services/firestore_service.dart';
import 'package:cyber_ops/services/music_service.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';

class Nivel10Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel10Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel10Screen> createState() => _Nivel10ScreenState();
}

class _Nivel10ScreenState extends State<Nivel10Screen> {
  Nivel10Game? _game;
  bool _cargando = true;

  //TUTORIAL ACTO 1
  bool _mostrarTutorial = true;
  int _pasoTutorial = 0;
  final GlobalKey _hudKey = GlobalKey();
  final GlobalKey _objetivoKey = GlobalKey();
  final GlobalKey _editorKey = GlobalKey();
  final GlobalKey _credibilidadKey = GlobalKey();

  //TUTORIAL ACTO 3
  bool _mostrarTutorialActo3 = true;
  int _pasoTutorialActo3 = 0;
  final GlobalKey _acto3ContextoKey = GlobalKey();
  final GlobalKey _acto3EmailKey = GlobalKey();
  final GlobalKey _acto3RevelacionKey = GlobalKey();
  final GlobalKey _acto3DecisionKey = GlobalKey();

  //FRACTURA
  LevelAct? _dialogoFracturaActo = LevelAct.act1;
  final Set<LevelAct> _dialogosFracturaMostrados = {LevelAct.act1};
  List<String> _dialogosFractura(LevelAct acto) {
    switch (acto) {
      case LevelAct.act1:
        return [
          '¡Llegamos al nivel 10! Operación phishing.',
          'Consiste en tres actos que te iré explicando.',
          'Primero vas a construir un correo falso poniéndote en la piel de un hacker.',
          'Observa el objetivo, usa las pistas y elige las piezas más creíbles.',
        ];
      case LevelAct.act2:
        return [
          'Ahora cambiamos el rol.',
          'Vas a revisar una bandeja de entrada. Desliza a la izquierda si es phishing o a la derecha si te parece legítimo.',
          'También puedes usar los botones inferiores. Fíjate en remitente, asunto, enlaces y adjuntos.'
              'Tienes solo 2 minutos para completar el acto. ¡Suerte!',
        ];
      case LevelAct.act3:
        return [
          'Última fase, ya casi terminas el nivel.',
          'Inspecciona los elementos sospechosos antes de decidir si bloqueas el mensaje o lo dejas pasar.',
        ];
      case LevelAct.results:
        return [];
    }
  }

  // Estado reflejado desde el game para reconstruir la UI
  int _puntos = 0;
  int _actoActual = 1;
  int _vidas = 3;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;

  @override
  void initState() {
    super.initState();
    _iniciarJuego();
  }

  Future<void> _iniciarJuego() async {
    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
    } else {
      try {
        final datos = await FirestoreService.obtenerUsuario();
        final nivelUsuario = (datos['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = nivelUsuario > 10;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 10: $e');
      }
    }

    if (!mounted) return;

    MusicService().stopMusic();
    _game = Nivel10Game(
      onActoCambiado: _onActoCambiado,
      onNivelCompletado: _onNivelCompletado,
      onJuegoTerminado: _onJuegoTerminado,
      onEstadoActualizado: _onEstadoActualizado,
    );
    setState(() => _cargando = false);
  }

  // ── CALLBACKS DESDE EL GAME ───────────────────────────────────────────────

  void _onActoCambiado() {
    if (!mounted) return;

    final acto = _game!.actoActual;

    setState(() {
      _actoActual = acto.index + 1;
    });

    _mostrarFracturaParaActo(acto);
  }

  void _mostrarFracturaParaActo(LevelAct acto) {
    if (acto == LevelAct.results || _dialogosFracturaMostrados.contains(acto)) {
      return;
    }

    if (acto == LevelAct.act2) {
      _game?.pausarTemporizadorActo2();
    }

    setState(() {
      _dialogosFracturaMostrados.add(acto);
      _dialogoFracturaActo = acto;
    });
  }

  void _onEstadoActualizado(int puntos, int acto) {
    if (!mounted) return;
    setState(() {
      _puntos = puntos;
      _actoActual = acto;
      _vidas = _game!.vidas;
    });
  }

  Future<void> _guardarProgresoNivel(int puntos) async {
    if (_progresoGuardado || _nivelYaCompletado) return;

    _progresoGuardado = true;
    try {
      await FirestoreService.guardarPuntuacion(
        puntos: puntos,
        nivelCompletado: 10,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
        nivel: 10,
        mision: 10,
        puntos: puntos,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso del nivel 10: $e');
    }
  }

  void _onNivelCompletado(int puntos) async {
    await _guardarProgresoNivel(puntos);
    if (!mounted) return;
    setState(() {
      _puntos = puntos;
      _actoActual = 4; // results
    });
  }

  void _onJuegoTerminado() {
    if (!mounted) return;
    // Navega a la pantalla de game over o menú principal
    // Ajusta según vuestra navegación
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

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
          // ── Flame Game de fondo (gestiona timers y estado) ──
          GameWidget(game: _game!),

          // ── UI Flutter encima ──
          SafeArea(
            child: Column(
              children: [
                _HudWidget(puntos: _puntos, vidas: _vidas, acto: _actoActual),
                if (_nivelYaCompletado) const _TrainingBanner(),
                Expanded(child: _buildActoActual()),
              ],
            ),
          ),
          if (_dialogoFracturaActo != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: FracturaDialogo(
                  dialogos: _dialogosFractura(_dialogoFracturaActo!),
                  subtitulo: 'NIVEL 10 // OPERACIÓN PHISHING',
                  textoBotonFinal: 'JUGAR',
                  usarVoz: true,
                  permitirSaltarIntro: true,
                  permitirCambiarVoz: true,
                  velocidadVoz: 0.66,
                  milisegundosPorCaracter: 18,
                  onFinalizado: () {
                    final acto = _dialogoFracturaActo;

                    if (acto == LevelAct.act1) {
                      MusicService().playNiveles6to10Music();
                    }

                    setState(() {
                      _dialogoFracturaActo = null;
                    });

                    if (acto == LevelAct.act2) {
                      _game?.reanudarTemporizadorActo2();
                    }
                  },
                ),
              ),
            ),
          if (_dialogoFracturaActo == null &&
              _mostrarTutorial &&
              _actoActual == 1)
            _TutorialOverlay(
              paso: _tutorialSteps[_pasoTutorial],
              pasoActual: _pasoTutorial + 1,
              totalPasos: _tutorialSteps.length,
              onContinuar: _avanzarTutorial,
              onSaltar: _saltarTutorial,
            ),
          if (_dialogoFracturaActo == null &&
              _mostrarTutorialActo3 &&
              _actoActual == 3)
            _TutorialOverlay(
              paso: _tutorialStepsActo3[_pasoTutorialActo3],
              pasoActual: _pasoTutorialActo3 + 1,
              totalPasos: _tutorialStepsActo3.length,
              onContinuar: _avanzarTutorialActo3,
              onSaltar: _saltarTutorialActo3,
            ),
        ],
      ),
    );
  }

  Widget _buildActoActual() {
    switch (_game!.actoActual) {
      case LevelAct.act1:
        return Acto1Widget(
          game: _game!,
          hudKey: _hudKey,
          objetivoKey: _objetivoKey,
          editorKey: _editorKey,
          credibilidadKey: _credibilidadKey,
        );
      case LevelAct.act2:
        return Acto2Widget(game: _game!);
      case LevelAct.act3:
        return Acto3Widget(
          game: _game!,
          contextoKey: _acto3ContextoKey,
          emailKey: _acto3EmailKey,
          revelacionKey: _acto3RevelacionKey,
          decisionKey: _acto3DecisionKey,
        );
      case LevelAct.results:
        return ResultadosWidget(
          game: _game!,
          modoEntrenamiento: _nivelYaCompletado,
          onSalir: () {
            Navigator.of(context).pop();
          },
        );
    }
  }

  //Lista para frases del tutorial acto 1
  List<_TutorialStep> get _tutorialSteps => [
    _TutorialStep(
      targetKey: _hudKey,
      titulo: 'Panel de misión',
      descripcion:
          'Aquí verás el acto actual, tus vidas y la XP que vas consiguiendo durante la operación.',
      alignment: const Alignment(0, -0.75),
    ),
    _TutorialStep(
      targetKey: _objetivoKey,
      titulo: 'Información del objetivo',
      descripcion:
          'Lee el contexto antes de actuar. Estas pistas te ayudan a elegir las opciones más creíbles.',
      alignment: const Alignment(-0.45, -0.05),
    ),
    _TutorialStep(
      targetKey: _editorKey,
      titulo: 'Editor de ataque',
      descripcion:
          'Selecciona una opción en cada paso para construir el email. Cada decisión cambia la credibilidad.',
      alignment: const Alignment(0.68, 0),
    ),
    _TutorialStep(
      targetKey: _credibilidadKey,
      titulo: 'Credibilidad y lanzamiento',
      descripcion:
          'Cuando hayas completado todas las piezas, revisa la puntuación y lanza el ataque para pasar al siguiente acto.',
      alignment: const Alignment(0.25, -0.05),
    ),
  ];

  //Lista para frases del tutorial acto 3
  List<_TutorialStep> get _tutorialStepsActo3 => [
    _TutorialStep(
      targetKey: _acto3ContextoKey,
      titulo: 'Contexto de alerta',
      descripcion:
          'Aquí verás el resumen del caso y cuántas pistas has revisado antes de tomar una decisión.',
      alignment: const Alignment(-0.35, -0.25),
    ),
    _TutorialStep(
      targetKey: _acto3EmailKey,
      titulo: 'Email inspeccionable',
      descripcion:
          'Toca los elementos resaltados del correo para analizar remitente, enlaces y contenido.',
      alignment: const Alignment(0.68, 0.35),
    ),
    _TutorialStep(
      targetKey: _acto3RevelacionKey,
      titulo: 'Análisis de pistas',
      descripcion:
          'Cada elemento que inspecciones mostrará aquí una explicación para ayudarte a decidir.',
      alignment: const Alignment(0.35, -0.85),
    ),
    _TutorialStep(
      targetKey: _acto3DecisionKey,
      titulo: 'Decisión final',
      descripcion:
          'Cuando hayas inspeccionado todo, decide si bloqueas el email o lo dejas pasar.',
      alignment: const Alignment(0.35, -0.35),
    ),
  ];

  //Métodos para avanzar y saltar tutorial acto 1
  void _avanzarTutorial() {
    if (_pasoTutorial >= _tutorialSteps.length - 1) {
      _saltarTutorial();
      return;
    }

    setState(() => _pasoTutorial++);
  }

  void _saltarTutorial() {
    setState(() {
      _mostrarTutorial = false;
      _pasoTutorial = 0;
    });
  }

  //Métodos para avanzar y saltar tutorial acto 3
  void _avanzarTutorialActo3() {
    if (_pasoTutorialActo3 >= _tutorialStepsActo3.length - 1) {
      _saltarTutorialActo3();
      return;
    }

    setState(() => _pasoTutorialActo3++);
  }

  void _saltarTutorialActo3() {
    setState(() {
      _mostrarTutorialActo3 = false;
      _pasoTutorialActo3 = 0;
    });
  }
}

class _TrainingBanner extends StatelessWidget {
  const _TrainingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.45)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, color: AppColors.purple, size: 14),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'MODO ENTRENAMIENTO - Progreso no guardado',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.purple,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HUD SUPERIOR ─────────────────────────────────────────────────────────────

class _HudWidget extends StatelessWidget {
  final int puntos;
  final int vidas;
  final int acto;

  const _HudWidget({
    required this.puntos,
    required this.vidas,
    required this.acto,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    final backButton = IconButton(
      tooltip: 'Volver al mapa',
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: AppColors.purple,
      ),
      onPressed: () => Navigator.pop(context),
    );
    final title = Text(
      'NIVEL 10 · OPERACIÓN PHISHING',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 1,
      ),
    );
    final actoLabel = Text(
      'ACTO $acto DE 4',
      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
    );
    final hearts = Row(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.favorite_rounded,
            color: i < vidas ? AppColors.pink : AppColors.pink.withValues(alpha: 0.2),
            size: 18,
          ),
        ),
      ),
    );
    final xpChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$puntos XP',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.purple,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              children: [
                Row(
                  children: [
                    backButton,
                    const SizedBox(width: 8),
                    Expanded(child: title),
                    const SizedBox(width: 8),
                    xpChip,
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [actoLabel, const Spacer(), hearts]),
              ],
            )
          : Row(
              children: [
                // Flecha ir para atrás
                backButton,
                const SizedBox(width: 10),
                Text(
                  'NIVEL 10 · OPERACIÓN PHISHING',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ACTO $acto DE 4',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                // Vidas
                Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: i < vidas
                            ? AppColors.pink
                            : AppColors.pink.withValues(alpha: 0.2),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // XP
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgMain,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$puntos XP',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TutorialStep {
  final GlobalKey targetKey;
  final String titulo;
  final String descripcion;
  final Alignment alignment;

  const _TutorialStep({
    required this.targetKey,
    required this.titulo,
    required this.descripcion,
    required this.alignment,
  });
}

class _TutorialOverlay extends StatelessWidget {
  final _TutorialStep paso;
  final int pasoActual;
  final int totalPasos;
  final VoidCallback onContinuar;
  final VoidCallback onSaltar;

  const _TutorialOverlay({
    required this.paso,
    required this.pasoActual,
    required this.totalPasos,
    required this.onContinuar,
    required this.onSaltar,
  });

  Rect? _targetRect() {
    final context = paso.targetKey.currentContext;
    if (context == null) return null;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect()?.inflate(8);
    final size = MediaQuery.sizeOf(context);
    final cardWidth = (size.width - 32).clamp(280.0, 360.0).toDouble();

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onContinuar,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipPath(
                clipper: _TutorialHoleClipper(target),
                child: Container(color: Colors.black.withValues(alpha: 0.72)),
              ),
            ),
            if (target != null)
              Positioned.fromRect(
                rect: target,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyan, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.22),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const margin = 16.0;
                  const gap = 14.0;
                  const estimatedCardHeight = 220.0;

                  double left;
                  double top;

                  if (target != null) {
                    final puedeIrDebajo =
                        target.bottom + gap + estimatedCardHeight <
                        constraints.maxHeight - margin;

                    final puedeIrEncima =
                        target.top - gap - estimatedCardHeight > margin;

                    left = target.center.dx - cardWidth / 2;

                    if (puedeIrDebajo) {
                      top = target.bottom + gap;
                    } else if (puedeIrEncima) {
                      top = target.top - estimatedCardHeight - gap;
                    } else {
                      top = margin + ((paso.alignment.y + 1) / 2) *
                          (constraints.maxHeight - estimatedCardHeight - margin * 2);
                    }
                  } else {
                    left = margin + ((paso.alignment.x + 1) / 2) *
                        (constraints.maxWidth - cardWidth - margin * 2);

                    top = margin + ((paso.alignment.y + 1) / 2) *
                        (constraints.maxHeight - estimatedCardHeight - margin * 2);
                  }

                  left = left.clamp(
                    margin,
                    constraints.maxWidth - cardWidth - margin,
                  );

                  top = top.clamp(
                    margin,
                    constraints.maxHeight - estimatedCardHeight - margin,
                  );

                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: top,
                        child: SizedBox(
                          width: cardWidth,
                          child: _TutorialCard(
                            paso: paso,
                            pasoActual: pasoActual,
                            totalPasos: totalPasos,
                            onSaltar: onSaltar,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final _TutorialStep paso;
  final int pasoActual;
  final int totalPasos;
  final VoidCallback onSaltar;

  const _TutorialCard({
    required this.paso,
    required this.pasoActual,
    required this.totalPasos,
    required this.onSaltar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.55)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TUTORIAL $pasoActual/$totalPasos',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSaltar,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'SALTAR',
                  style: TextStyle(fontSize: 11, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            paso.titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            paso.descripcion,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Icon(Icons.touch_app_outlined, color: AppColors.cyan, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toca la pantalla para continuar',
                  style: TextStyle(fontSize: 11, color: AppColors.cyan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TutorialHoleClipper extends CustomClipper<Path> {
  final Rect? target;

  const _TutorialHoleClipper(this.target);

  @override
  Path getClip(Size size) {
    final fullPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);

    if (target != null) {
      fullPath.addRRect(
        RRect.fromRectAndRadius(target!, const Radius.circular(12)),
      );
    }

    return fullPath;
  }

  @override
  bool shouldReclip(covariant _TutorialHoleClipper oldClipper) {
    return oldClipper.target != target;
  }
}
