import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/music_service.dart';
import '../games/nivel_14/components/backdoor_action.dart';
import '../games/nivel_14/components/backdoor_evidence.dart';
import '../games/nivel_14/data/backdoor_data.dart';
import '../games/nivel_14/nivel14_game.dart';
import '../services/firestore_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';

class Nivel14Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel14Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel14Screen> createState() => _Nivel14ScreenState();
}

class _Nivel14ScreenState extends State<Nivel14Screen> {
  final Nivel14Game _game = Nivel14Game();
  bool _nivelYaCompletado = false;
  bool _resultadoMostrado = false;

  //Fractura
  bool _mostrarFractura = true;

  final List<String> _dialogosFractura = [
    'Llegaste al nivel 14. El malware principal ya no está activo, pero el servidor sigue respirando raro.',
    'Eso suele significar una cosa: una puerta oculta preparada para que el atacante vuelva cuando quiera.',
    'No marques todo lo sospechoso. Busca relación entre acceso remoto, persistencia, cuenta oculta y canal de comunicación.',
    'Cuando tengas el caso claro, analiza la backdoor y después aplica solo las acciones necesarias.',
  ];

  //Tutorial
  bool _mostrarTutorial = false;
  int _pasoTutorial = 0;
  final GlobalKey _servidorKey = GlobalKey();
  final GlobalKey _evidenciasKey = GlobalKey();
  final GlobalKey _respuestaKey = GlobalKey();
  final GlobalKey _intentosKey = GlobalKey();

  BackdoorEvidenceCategory _selectedCategory = BackdoorEvidenceCategory.logs;
  String _message =
      'Investiga el servidor y marca solo las evidencias que formen parte de la backdoor. Tienes 2 análisis y 2 verificaciones.';

  @override
  void initState() {
    super.initState();
    _setupNivel();
  }

  Future<void> _setupNivel() async {
    try {
      await MusicService().playNiveles11to15Music();
    } catch (e) {
      debugPrint('Error iniciando música del nivel 14: $e');
    }
    _nivelYaCompletado = widget.soloEntrenamiento;

    if (!widget.soloEntrenamiento) {
      try {
        final datos = await FirestoreService.obtenerUsuario();
        final nivelUsuario = (datos['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = nivelUsuario > 14;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 14: $e');
      }
    }

    if (mounted) setState(() {});
  }

  List<BackdoorEvidence> get _filteredEvidences {
    return _game.evidences
        .where((evidence) => evidence.category == _selectedCategory)
        .toList();
  }

  void _toggleEvidence(BackdoorEvidence evidence) {
    setState(() {
      _game.toggleEvidence(evidence);
      _message = evidence.explanation;
    });
  }

  void _analyzeBackdoor() {
    setState(() {
      _message = _game.analyzeBackdoor();
    });
    if (_game.failed) {
      _mostrarGameOver();
    }
  }

  void _toggleAction(BackdoorAction action) {
    setState(() {
      _game.toggleAction(action);
      _message = action.feedback;
    });
  }

  Future<void> _verifySystem() async {
    setState(() {
      _message = _game.verifySystem();
    });
    if (_game.completed) {
      await _mostrarVictoria();
    } else if (_game.failed) {
      _mostrarGameOver();
    }
  }

  void _mostrarGameOver() {
    if (_resultadoMostrado || !mounted) return;
    _resultadoMostrado = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultadoNivel14(
        titulo: 'MISIÓN FALLIDA',
        subtitulo: 'El atacante ha recuperado acceso al servidor',
        puntos: _game.xp,
        integridad: _game.integrity,
        exito: false,
        entrenamiento: false,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Nivel14Screen(soloEntrenamiento: widget.soloEntrenamiento),
            ),
          );
        },
        onSalir: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _mostrarVictoria() async {
    if (_resultadoMostrado) return;
    _resultadoMostrado = true;

    if (!_nivelYaCompletado) {
      try {
        await FirestoreService.guardarPuntuacion(
          puntos: _game.xp,
          nivelCompletado: 14,
          soloEntrenamiento: widget.soloEntrenamiento,
        );
        await FirestoreService.guardarMision(
          nivel: 14,
          mision: 14,
          puntos: _game.xp,
        );
      } catch (e) {
        debugPrint('No se pudo guardar progreso del nivel 14: $e');
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultadoNivel14(
        titulo: 'BACKDOOR NEUTRALIZADA',
        subtitulo: _nivelYaCompletado
            ? 'Modo entrenamiento'
            : 'Puerta oculta cerrada con éxito',
        puntos: _game.xp,
        integridad: _game.integrity,
        exito: true,
        entrenamiento: _nivelYaCompletado,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Nivel14Screen(soloEntrenamiento: widget.soloEntrenamiento),
            ),
          );
        },
        onSalir: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  List<_TutorialStep> get _tutorialSteps => [
    _TutorialStep(
      targetKey: _servidorKey,
      titulo: 'Servidor comprometido',
      descripcion:
          'Lee el resumen del caso. Te da el contexto para distinguir actividad normal de una puerta oculta.',
      alignment: const Alignment(-0.75, -0.15),
    ),
    _TutorialStep(
      targetKey: _evidenciasKey,
      titulo: 'Evidencias por categoría',
      descripcion:
          'Revisa cada pestaña y marca solo las evidencias conectadas con la backdoor. No todo lo técnico es malicioso.',
      alignment: const Alignment(0, -0.15),
    ),
    _TutorialStep(
      targetKey: _respuestaKey,
      titulo: 'Respuesta al incidente',
      descripcion:
          'Cuando identifiques la backdoor, se desbloquearán acciones. El color no te dirá cuáles son seguras.',
      alignment: const Alignment(0.65, -0.10),
    ),
    _TutorialStep(
      targetKey: _intentosKey,
      titulo: 'Intentos limitados',
      descripcion:
          'Tienes pocos análisis y verificaciones. Si marcas falsos positivos o dejas piezas fuera, perderás integridad.',
      alignment: const Alignment(0.55, -0.78),
    ),
  ];

  void _avanzarTutorial() {
    if (_pasoTutorial >= _tutorialSteps.length - 1) {
      _saltarTutorial();
      return;
    }

    setState(() {
      _pasoTutorial++;
    });
  }

  void _saltarTutorial() {
    setState(() {
      _mostrarTutorial = false;
      _pasoTutorial = 0;
    });
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
            subtitulo: 'NIVEL 14 // BACKDOOR',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () async {
              setState(() {
                _mostrarFractura = false;
                _mostrarTutorial = true;
              });
            },
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 900;

                      if (isMobile) {
                        return _buildMobileLayout();
                      }

                      return _buildDesktopLayout();
                    },
                  ),
                ),
              ],
            ),
            if (_mostrarTutorial)
            _TutorialOverlay(
              paso: _tutorialSteps[_pasoTutorial],
              pasoActual: _pasoTutorial + 1,
              totalPasos: _tutorialSteps.length,
              onContinuar: _avanzarTutorial,
              onSaltar: _saltarTutorial,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver al mapa',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.cyan,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'NIVEL 14 · BACKDOOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          _buildStat('INTEGRIDAD', '${_game.integrity}%', AppColors.cyan),
          const SizedBox(width: 8),
          KeyedSubtree(
            key: _intentosKey,
            child: _buildStat(
              'INTENTOS',
              '${Nivel14Game.maxAnalysisAttempts - _game.analysisAttempts}/${Nivel14Game.maxVerificationAttempts - _game.verificationAttempts}',
              AppColors.pink,
            ),
          ),
          const SizedBox(width: 8),
          _buildStat('XP', '${_game.xp}', AppColors.purple),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 8,
              letterSpacing: 1.4,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: KeyedSubtree(key: _servidorKey, child: _buildStatusPanel()),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: KeyedSubtree(
              key: _evidenciasKey,
              child: _buildEvidencePanel(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: KeyedSubtree(
              key: _respuestaKey,
              child: _buildResponsePanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        KeyedSubtree(key: _servidorKey, child: _buildStatusPanel()),
        const SizedBox(height: 12),
        SizedBox(
          height: 480,
          child: KeyedSubtree(
            key: _evidenciasKey,
            child: _buildEvidencePanel(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 480,
          child: KeyedSubtree(
            key: _respuestaKey,
            child: _buildResponsePanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPanel() {
    return _Panel(
      title: 'SERVIDOR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BackdoorData.serverName,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            BackdoorData.alertTitle,
            style: const TextStyle(
              color: AppColors.pink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            BackdoorData.alertDescription,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          _buildMessageBox(),
        ],
      ),
    );
  }

  Widget _buildMessageBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Text(
        _message,
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _buildEvidencePanel() {
    return _Panel(
      title: 'EVIDENCIAS',
      child: Expanded(
        child: Column(
          children: [
            _buildCategoryTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredEvidences.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final evidence = _filteredEvidences[index];
                  final selected = _game.selectedEvidenceIds.contains(
                    evidence.id,
                  );

                  return _EvidenceTile(
                    evidence: evidence,
                    selected: selected,
                    onTap: () => _toggleEvidence(evidence),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _game.analysisDone ? null : _analyzeBackdoor,
                child: Text(
                  'ANALIZAR BACKDOOR (${Nivel14Game.maxAnalysisAttempts - _game.analysisAttempts})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BackdoorEvidenceCategory.values.map((category) {
        final selected = category == _selectedCategory;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.cyan.withValues(alpha: 0.12)
                  : AppColors.bgMain.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppColors.cyan.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Text(
              category.label,
              style: TextStyle(
                color: selected
                    ? AppColors.cyan
                    : Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResponsePanel() {
    return _Panel(
      title: 'RESPUESTA',
      child: Expanded(
        child: Column(
          children: [
            Expanded(
              child: _game.containmentUnlocked
                  ? ListView.separated(
                      itemCount: _game.actions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final action = _game.actions[index];
                        final selected = _game.selectedActionIds.contains(
                          action.id,
                        );

                        return _ActionTile(
                          action: action,
                          selected: selected,
                          onTap: () => _toggleAction(action),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Identifica la backdoor para desbloquear las acciones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _game.containmentUnlocked ? _verifySystem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  disabledBackgroundColor: AppColors.bgMain,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'VERIFICAR SISTEMA (${Nivel14Game.maxVerificationAttempts - _game.verificationAttempts})',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
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

class _DialogoResultadoNivel14 extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int puntos;
  final int integridad;
  final bool exito;
  final bool entrenamiento;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _DialogoResultadoNivel14({
    required this.titulo,
    required this.subtitulo,
    required this.puntos,
    required this.integridad,
    required this.exito,
    required this.entrenamiento,
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
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30)],
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
              textAlign: TextAlign.center,
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
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$puntos XP',
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'INTEGRIDAD $integridad%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            if (entrenamiento) ...[
              const SizedBox(height: 8),
              Text(
                'Modo entrenamiento - puntos no guardados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.purple.withValues(alpha: 0.78),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReintentar,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
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

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.cyan.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final BackdoorEvidence evidence;
  final bool selected;
  final VoidCallback onTap;

  const _EvidenceTile({
    required this.evidence,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.cyan : AppColors.purple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.bgMain.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evidence.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    evidence.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evidence.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.4,
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

class _ActionTile extends StatelessWidget {
  final BackdoorAction action;
  final bool selected;
  final VoidCallback onTap;

  const _ActionTile({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.cyan : AppColors.purple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.bgMain.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.55) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.type.label,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      height: 1.4,
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

class _TutorialOverlay extends StatefulWidget {
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

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  Rect? _targetRect() {
    final ctx = widget.paso.targetKey.currentContext;
    if (ctx == null) return null;
    final renderBox = ctx.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return null;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect();

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final cardWidth = (size.width * 0.32).clamp(260.0, 360.0);
            const margin = 18.0;

            final left =
                ((widget.paso.alignment.x + 1) / 2) * (size.width - cardWidth);
            final top =
                ((widget.paso.alignment.y + 1) / 2) * (size.height - 190);

            return Stack(
              children: [
                Positioned.fill(
                  child: ClipPath(
                    clipper: _TutorialHoleClipper(target),
                    child: Container(
                        color: Colors.black.withValues(alpha: 0.72)),
                  ),
                ),
                if (target != null)
                  Positioned.fromRect(
                    rect: target.inflate(6),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.9),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.35),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: left.clamp(margin, size.width - cardWidth - margin),
                  top: top.clamp(margin, size.height - 220),
                  child: SizedBox(
                    width: cardWidth,
                    child: _TutorialCard(
                      paso: widget.paso,
                      pasoActual: widget.pasoActual,
                      totalPasos: widget.totalPasos,
                      onContinuar: widget.onContinuar,
                      onSaltar: widget.onSaltar,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final _TutorialStep paso;
  final int pasoActual;
  final int totalPasos;
  final VoidCallback onContinuar;
  final VoidCallback onSaltar;

  const _TutorialCard({
    required this.paso,
    required this.pasoActual,
    required this.totalPasos,
    required this.onContinuar,
    required this.onSaltar,
  });

  @override
  Widget build(BuildContext context) {
    final esUltimo = pasoActual == totalPasos;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24),
        ],
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
                  color: AppColors.purple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSaltar,
                child: Text(
                  'SALTAR',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            paso.titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            paso.descripcion,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                esUltimo ? 'ENTENDIDO' : 'SIGUIENTE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
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
      final hole = RRect.fromRectAndRadius(
        target!.inflate(8),
        const Radius.circular(16),
      );
      fullPath.addRRect(hole);
    }

    return fullPath;
  }

  @override
  bool shouldReclip(covariant _TutorialHoleClipper oldClipper) {
    return oldClipper.target != target;
  }
}
