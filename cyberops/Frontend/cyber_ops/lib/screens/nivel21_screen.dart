import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../games/nivel_21/exploit_lab_data.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';

enum _LabTool { recon, logs, hypothesis, validation, containment, report }

enum _AssetState { idle, suspicious, exposed, compromised, contained, fixed }

class Nivel21Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel21Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel21Screen> createState() => _Nivel21ScreenState();
}

class _Nivel21ScreenState extends State<Nivel21Screen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  final Set<String> _selectedEvidence = {};
  final Set<String> _selectedMitigations = {};
  final Set<String> _penalizedEvidence = {};
  final Set<String> _penalizedHypotheses = {};
  final List<LabTimelineEvent> _timeline = [...ExploitLabData.initialTimeline];

  _LabTool _tool = _LabTool.recon;
  String _selectedAssetId = 'api';
  String? _selectedHypothesisId;

  bool _loading = true;
  bool _introVisible = true;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;
  bool _probeRunning = false;
  bool _vulnerabilityConfirmed = false;
  bool _resultShown = false;

  int _integrity = 88;
  int _hintIndex = 0;

  static const List<String> _introDialog = [
    'Entramos en una copia aislada de una infraestructura corporativa.',
    'Aquí no vas a lanzar ataques reales. Vas a investigar si un fallo es explotable, demostrar impacto y cerrar el caso.',
    'El mapa no tiene respuestas pintadas. Cada nodo guarda contexto; tu trabajo es reconstruir una cadena coherente.',
    'Primero observa, luego archiva evidencias, formula una hipótesis, valida en el laboratorio y despues contiene.',
    'Si te bloqueas, pide una pista. Te daré criterio de analista, no la solución.',
  ];

  static const List<String> _hints = [
    'Empieza separando sintomas de causa. Preguntate: que entrada publica existe, que servicio responde, que identidad aparece y que dato queda expuesto.',
    'Una evidencia util explica una parte de la cadena. Una evidencia de hardening puede ser real, pero no siempre explica el incidente.',
    'Una hipotesis solida debe encajar con todos los rastros sin inventar un segundo ataque.',
    'Antes de probar, intenta contar la historia completa con tus propias palabras: origen, permiso, recurso, respuesta e impacto.',
    'Para contener, piensa en capas: corregir causa raiz, reducir superficie, cerrar sesiones abiertas y crear deteccion para el patron.',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _setupLevel();
  }

  Future<void> _setupLevel() async {
    try {
      await MusicService().playNiveles21to25Music();
    } catch (e) {
      debugPrint('Error iniciando música nivel 21: $e');
    }
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final data = await FirestoreService.obtenerUsuario();
        final level = (data['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = level > 21;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 21: $e');
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  LabAsset get _selectedAsset => _assetById(_selectedAssetId);

  VulnerabilityHypothesis? get _selectedHypothesis {
    final id = _selectedHypothesisId;
    if (id == null) return null;
    return ExploitLabData.hypotheses.firstWhere((item) => item.id == id);
  }

  int get _relevantEvidenceCount {
    return ExploitLabData.evidences
        .where((item) => item.relevant && _selectedEvidence.contains(item.id))
        .length;
  }

  int get _noiseCount {
    return ExploitLabData.evidences
        .where((item) => !item.relevant && _selectedEvidence.contains(item.id))
        .length;
  }

  int get _requiredMitigationCount {
    return ExploitLabData.mitigations
        .where(
          (item) => item.required && _selectedMitigations.contains(item.id),
        )
        .length;
  }

  int get _depthMitigationCount {
    return ExploitLabData.mitigations
        .where(
          (item) =>
              item.defensiveDepth && _selectedMitigations.contains(item.id),
        )
        .length;
  }

  int get _harmfulMitigationCount {
    return ExploitLabData.mitigations
        .where((item) => item.harmful && _selectedMitigations.contains(item.id))
        .length;
  }

  bool get _hypothesisCorrect => _selectedHypothesis?.correct ?? false;

  bool get _readyForValidation =>
      _hypothesisCorrect && _relevantEvidenceCount >= 4;

  bool get _requiredMitigationsComplete {
    return ExploitLabData.mitigations
        .where((item) => item.required)
        .every((item) => _selectedMitigations.contains(item.id));
  }

  int get _score {
    final raw =
        280 +
        (_relevantEvidenceCount * 120) -
        (_noiseCount * 45) +
        (_hypothesisCorrect ? 260 : 0) +
        (_vulnerabilityConfirmed ? 330 : 0) +
        (_requiredMitigationCount * 155) +
        (_depthMitigationCount * 60) -
        (_harmfulMitigationCount * 150) +
        ((_integrity - 50).clamp(0, 50) * 5);
    return raw.clamp(0, 2100).toInt();
  }

  String get _phaseLabel {
    if (_requiredMitigationsComplete && _vulnerabilityConfirmed) {
      return 'POSTMORTEM';
    }
    if (_vulnerabilityConfirmed) return 'CONTENCION';
    if (_selectedHypothesisId != null) return 'VALIDACION';
    if (_selectedEvidence.isNotEmpty) return 'INVESTIGACION';
    return 'RECON';
  }

  LabAsset _assetById(String id) {
    return ExploitLabData.assets.firstWhere((item) => item.id == id);
  }

  List<LabEvidence> _evidenceForAsset(String assetId) {
    return ExploitLabData.evidences
        .where((item) => item.assetId == assetId)
        .toList();
  }

  _AssetState _stateForAsset(String assetId) {
    if (_requiredMitigationsComplete &&
        ['edge', 'api', 'auth', 'db', 'siem'].contains(assetId)) {
      return _AssetState.fixed;
    }
    if (_vulnerabilityConfirmed &&
        ['edge', 'api', 'auth', 'db', 'ops'].contains(assetId)) {
      return _selectedMitigations.isNotEmpty
          ? _AssetState.contained
          : _AssetState.compromised;
    }
    if (_selectedHypothesisId != null &&
        ['edge', 'api', 'auth', 'db'].contains(assetId)) {
      return _AssetState.exposed;
    }
    final hasMarkedEvidence = _evidenceForAsset(
      assetId,
    ).any((item) => _selectedEvidence.contains(item.id));
    return hasMarkedEvidence ? _AssetState.suspicious : _AssetState.idle;
  }

  Map<String, _AssetState> get _assetStates {
    return {
      for (final asset in ExploitLabData.assets)
        asset.id: _stateForAsset(asset.id),
    };
  }

  void _addTimeline({
    required String title,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    _timeline.insert(
      0,
      LabTimelineEvent(title: title, detail: detail, icon: icon, color: color),
    );
  }

  void _damage(int amount) {
    _integrity = (_integrity - amount).clamp(0, 100).toInt();
  }

  void _selectAsset(String assetId) {
    setState(() {
      _selectedAssetId = assetId;
      _tool = _LabTool.recon;
    });
  }

  void _toggleEvidence(LabEvidence evidence) {
    setState(() {
      final wasSelected = _selectedEvidence.contains(evidence.id);
      if (wasSelected) {
        _selectedEvidence.remove(evidence.id);
        return;
      }

      _selectedEvidence.add(evidence.id);
      _selectedAssetId = evidence.assetId;
      _penalizedEvidence.add(evidence.id);
      _addTimeline(
        title: 'Evidencia archivada',
        detail: '${_assetById(evidence.assetId).name}: ${evidence.title}',
        icon: Icons.bookmark_added_rounded,
        color: _LabPalette.neutral,
      );
    });

    _checkFailure();
  }

  void _selectHypothesis(VulnerabilityHypothesis hypothesis) {
    setState(() {
      _selectedHypothesisId = hypothesis.id;
      _penalizedHypotheses.add(hypothesis.id);
      _addTimeline(
        title: 'Hipotesis registrada',
        detail: hypothesis.title,
        icon: Icons.psychology_alt_rounded,
        color: _LabPalette.neutral,
      );
      _tool = _LabTool.validation;
    });

    _checkFailure();
  }

  Future<void> _runControlledProbe() async {
    if (_probeRunning || _vulnerabilityConfirmed) return;

    setState(() => _probeRunning = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    setState(() {
      _probeRunning = false;
      if (!_readyForValidation) {
        _damage(14);
        _addTimeline(
          title: 'Prueba no concluyente',
          detail:
              'La cadena planteada aun no sostiene una demostracion de impacto.',
          icon: Icons.science_outlined,
          color: _LabPalette.warning,
        );
        return;
      }

      _vulnerabilityConfirmed = true;
      _damage(4);
      _tool = _LabTool.containment;
      _addTimeline(
        title: 'Impacto validado',
        detail:
            'Un usuario valido puede leer datos administrativos de otro tenant en entorno aislado.',
        icon: Icons.verified_user_rounded,
        color: _LabPalette.accent,
      );
    });

    _checkFailure();
  }

  void _toggleMitigation(MitigationAction action) {
    if (!_vulnerabilityConfirmed) {
      setState(() {
        _tool = _LabTool.validation;
        _addTimeline(
          title: 'Falta validacion',
          detail: 'Primero confirma impacto en el laboratorio seguro.',
          icon: Icons.pending_actions_rounded,
          color: _LabPalette.warning,
        );
      });
      return;
    }

    setState(() {
      final wasSelected = _selectedMitigations.contains(action.id);
      if (wasSelected) {
        _selectedMitigations.remove(action.id);
        return;
      }

      _selectedMitigations.add(action.id);
      _addTimeline(
        title: 'Accion preparada',
        detail: action.title,
        icon: Icons.playlist_add_check_rounded,
        color: _LabPalette.neutral,
      );
    });

    _checkFailure();
  }

  Future<void> _verifyContainment() async {
    if (!_vulnerabilityConfirmed) {
      setState(() {
        _tool = _LabTool.validation;
        _addTimeline(
          title: 'Validacion pendiente',
          detail: 'No se puede cerrar el caso sin demostrar impacto.',
          icon: Icons.science_rounded,
          color: _LabPalette.warning,
        );
      });
      return;
    }

    if (!_requiredMitigationsComplete || _harmfulMitigationCount > 0) {
      setState(() {
        _damage(10 + (_harmfulMitigationCount * 5));
        _addTimeline(
          title: 'Contencion incompleta',
          detail:
              'La respuesta planteada no cubre todavia la cadena completa del incidente.',
          icon: Icons.warning_amber_rounded,
          color: _LabPalette.warning,
        );
      });
      _checkFailure();
      return;
    }

    setState(() {
      _integrity = math.min(100, _integrity + 10);
      _tool = _LabTool.report;
      _addTimeline(
        title: 'Caso contenido',
        detail:
            'La causa raiz queda corregida, la ventana cerrada y la deteccion creada.',
        icon: Icons.task_alt_rounded,
        color: _LabPalette.safe,
      );
    });

    await _saveProgress();
    if (mounted) _showVictory();
  }

  Future<void> _saveProgress() async {
    if (_progresoGuardado || _nivelYaCompletado) return;
    _progresoGuardado = true;

    try {
      await FirestoreService.guardarPuntuacion(
        puntos: _score,
        nivelCompletado: 21,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
        nivel: 21,
        mision: 21,
        puntos: _score,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso del nivel 21: $e');
    }
  }

  void _checkFailure() {
    if (_integrity > 18 || _resultShown || !mounted) return;
    _resultShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LabFailureDialog(
        score: _score,
        integrity: _integrity,
        onRetry: _restartLevel,
        onExit: _exitLevel,
      ),
    );
  }

  void _showVictory() {
    if (_resultShown || !mounted) return;
    _resultShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LabVictoryDialog(
        score: _score,
        integrity: _integrity,
        trainingMode: _nivelYaCompletado,
        onReport: () {
          Navigator.pop(context);
          setState(() {
            _resultShown = false;
            _tool = _LabTool.report;
          });
        },
        onContinue: _exitLevel,
      ),
    );
  }

  void _showHintDialog() {
    showDialog(
      context: context,
      builder: (_) => _HintDialog(
        current: _hintIndex + 1,
        total: _hints.length,
        text: _hints[_hintIndex],
        onNext: _hintIndex < _hints.length - 1
            ? () {
                Navigator.pop(context);
                setState(() => _hintIndex++);
                _showHintDialog();
              }
            : null,
      ),
    );
  }

  void _restartLevel() {
    Navigator.of(context, rootNavigator: true).pop();
    setState(() {
      _selectedEvidence.clear();
      _selectedMitigations.clear();
      _penalizedEvidence.clear();
      _penalizedHypotheses.clear();
      _timeline
        ..clear()
        ..addAll(ExploitLabData.initialTimeline);
      _tool = _LabTool.recon;
      _selectedAssetId = 'api';
      _selectedHypothesisId = null;
      _probeRunning = false;
      _vulnerabilityConfirmed = false;
      _resultShown = false;
      _integrity = 88;
      _hintIndex = 0;
    });
  }

  void _exitLevel() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _LabPalette.accent,
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 1020;
                            return compact
                                ? _buildCompactLayout(constraints)
                                : _buildWideLayout();
                          },
                        ),
                ),
              ],
            ),
            if (_introVisible)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF111827).withValues(alpha: 0.82),
                  child: FracturaDialogo(
                    dialogos: _introDialog,
                    subtitulo: 'NIVEL 21 // EXPLOIT LAB',
                    textoBotonFinal: 'JUGAR',
                    usarVoz: true,
                    permitirSaltarIntro: true,
                    permitirCambiarVoz: true,
                    velocidadVoz: 0.66,
                    milisegundosPorCaracter: 18,
                    onFinalizado: () => setState(() => _introVisible = false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: _LabPalette.ink,
              tooltip: 'Volver al mapa',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.hub_rounded, color: _LabPalette.accent, size: 26),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'NIVEL 21 / EXPLOIT LAB',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _LabPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ],
        );

        final stats = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            _StatPill(
              icon: Icons.timeline_rounded,
              label: 'FASE',
              value: _phaseLabel,
              color: _LabPalette.accent,
            ),
            _StatPill(
              icon: Icons.health_and_safety_rounded,
              label: 'INTEGRIDAD',
              value: '$_integrity%',
              color: _integrity > 55
                  ? _LabPalette.safe
                  : _integrity > 30
                  ? _LabPalette.warning
                  : _LabPalette.danger,
            ),
            _StatPill(
              icon: Icons.fact_check_rounded,
              label: 'MARCADO',
              value: '${_selectedEvidence.length}',
              color: _LabPalette.blue,
            ),
            _HintHeaderButton(
              label: 'PISTAS',
              value:
                  '${math.min(_hintIndex + 1, _hints.length)}/${_hints.length}',
              onTap: _showHintDialog,
            ),
          ],
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _LabPalette.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _LabPalette.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: constraints.maxWidth < 780
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 10), stats],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    stats,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Expanded(child: _buildMapPanel(compact: false)),
                const SizedBox(height: 12),
                SizedBox(height: 168, child: _buildTimelinePanel()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 430,
            child: Column(
              children: [
                _buildToolRail(),
                const SizedBox(height: 10),
                Expanded(child: _buildToolPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BoxConstraints constraints) {
    final narrow = constraints.maxWidth < 560;
    final mapHeight = narrow ? 360.0 : 430.0;
    final timelineHeight = narrow ? 150.0 : 180.0;
    final toolHeight = narrow ? 700.0 : 660.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          SizedBox(height: mapHeight, child: _buildMapPanel(compact: true)),
          const SizedBox(height: 12),
          SizedBox(height: timelineHeight, child: _buildTimelinePanel()),
          const SizedBox(height: 12),
          _buildToolRail(),
          const SizedBox(height: 10),
          SizedBox(height: toolHeight, child: _buildToolPanel()),
        ],
      ),
    );
  }

  Widget _buildMapPanel({required bool compact}) {
    return _LabPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.apartment_rounded, color: _LabPalette.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MAQUETA VIVA: ${_selectedAsset.name}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _LabPalette.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _TinyChip(
                  label: _selectedAsset.zone,
                  color: _selectedAsset.color,
                  filled: false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _MissionFlowStrip(activeTool: _tool),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  Widget map({required bool compactMode}) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return _NetworkDiorama(
                          assets: ExploitLabData.assets,
                          connections: ExploitLabData.connections,
                          states: _assetStates,
                          selectedAssetId: _selectedAssetId,
                          pulse: _pulseController.value,
                          compact: compactMode,
                          onSelect: _selectAsset,
                        );
                      },
                    );
                  }

                  if (!compact) return map(compactMode: false);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(640, constraints.maxWidth),
                      height: constraints.maxHeight,
                      child: map(compactMode: true),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolRail() {
    return _LabPanel(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _LabTool.values.map((tool) {
          return _ToolButton(
            selected: _tool == tool,
            icon: _toolIcon(tool),
            label: _toolLabel(tool),
            onTap: () => setState(() => _tool = tool),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolPanel() {
    return _LabPanel(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: switch (_tool) {
          _LabTool.recon => _buildReconTool(),
          _LabTool.logs => _buildLogsTool(),
          _LabTool.hypothesis => _buildHypothesisTool(),
          _LabTool.validation => _buildValidationTool(),
          _LabTool.containment => _buildContainmentTool(),
          _LabTool.report => _buildReportTool(),
        },
      ),
    );
  }

  Widget _buildReconTool() {
    final evidence = _evidenceForAsset(_selectedAssetId);
    return ListView(
      key: const ValueKey('recon'),
      children: [
        _ToolHeader(
          icon: _selectedAsset.icon,
          color: _selectedAsset.color,
          title: _selectedAsset.name,
          subtitle: _selectedAsset.role,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final service in _selectedAsset.services)
              _TinyChip(label: service, color: _selectedAsset.color),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionLabel(icon: Icons.visibility_rounded, text: 'OBSERVADO'),
        const SizedBox(height: 8),
        for (final item in _selectedAsset.observations)
          _BulletLine(text: item, color: _selectedAsset.color),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: _SectionLabel(
                icon: Icons.manage_search_rounded,
                text: 'EVIDENCIAS DEL NODO',
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _tool = _LabTool.logs),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('VER TODO'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (evidence.isEmpty)
          const _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            text: 'Este nodo no aporta pistas directas al caso.',
          )
        else
          for (final item in evidence)
            _EvidenceTile(
              evidence: item,
              asset: _assetById(item.assetId),
              selected: _selectedEvidence.contains(item.id),
              onTap: () => _toggleEvidence(item),
            ),
      ],
    );
  }

  Widget _buildLogsTool() {
    return ListView(
      key: const ValueKey('logs'),
      children: [
        const _ToolHeader(
          icon: Icons.receipt_long_rounded,
          color: _LabPalette.blue,
          title: 'Visor de evidencias',
          subtitle:
              'Archiva los rastros que te ayuden a reconstruir una cadena tecnica.',
        ),
        const SizedBox(height: 12),
        _WorkflowNote(
          icon: Icons.route_rounded,
          title: 'Criterio de analisis',
          text:
              'No todas las pistas tienen el mismo peso. Busca relacion entre exposicion, identidad, permisos, recurso y efecto observado.',
        ),
        const SizedBox(height: 12),
        for (final item in ExploitLabData.evidences)
          _EvidenceTile(
            evidence: item,
            asset: _assetById(item.assetId),
            selected: _selectedEvidence.contains(item.id),
            onTap: () => _toggleEvidence(item),
          ),
      ],
    );
  }

  Widget _buildHypothesisTool() {
    return ListView(
      key: const ValueKey('hypothesis'),
      children: [
        const _ToolHeader(
          icon: Icons.psychology_alt_rounded,
          color: _LabPalette.violet,
          title: 'Mesa de hipotesis',
          subtitle:
              'Elige una explicacion y comprueba si aguanta la evidencia archivada.',
        ),
        const SizedBox(height: 12),
        _WorkflowNote(
          icon: Icons.fact_check_rounded,
          title: '${_selectedEvidence.length} evidencias archivadas',
          text:
              'Una buena hipotesis no depende de una sola tarjeta: debe explicar el flujo completo del incidente.',
        ),
        const SizedBox(height: 12),
        for (final item in ExploitLabData.hypotheses)
          _HypothesisTile(
            hypothesis: item,
            selected: _selectedHypothesisId == item.id,
            onTap: () => _selectHypothesis(item),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _selectedHypothesisId == null
              ? null
              : () => setState(() => _tool = _LabTool.validation),
          icon: const Icon(Icons.science_rounded),
          label: const Text('PASAR A PRUEBA CONTROLADA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _LabPalette.violet,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationTool() {
    final hypothesis = _selectedHypothesis;
    final hasMinimumWork =
        hypothesis != null &&
        _selectedEvidence.isNotEmpty &&
        !_vulnerabilityConfirmed;

    return ListView(
      key: const ValueKey('validation'),
      children: [
        const _ToolHeader(
          icon: Icons.science_rounded,
          color: _LabPalette.accent,
          title: 'Prueba segura',
          subtitle:
              'El laboratorio simula impacto sin mostrar payloads ni tocar sistemas reales.',
        ),
        const SizedBox(height: 12),
        _TerminalBlock(
          running: _probeRunning,
          lines: [
            'lab@range: abrir caso api-admin',
            'evidencias archivadas: ${_selectedEvidence.length}',
            'hipotesis: ${hypothesis?.title ?? 'sin seleccionar'}',
            if (hasMinimumWork) 'preflight: preparado para intento controlado',
            if (!hasMinimumWork && !_vulnerabilityConfirmed)
              'preflight: selecciona evidencias e hipotesis antes de probar',
            if (_vulnerabilityConfirmed)
              'resultado: impacto confirmado en entorno aislado',
          ],
        ),
        const SizedBox(height: 12),
        if (_vulnerabilityConfirmed)
          const _InsightBox(
            icon: Icons.verified_user_rounded,
            color: _LabPalette.safe,
            title: 'Impacto confirmado',
            text:
                'Un usuario autenticado con rol bajo pudo leer un recurso administrativo de otro tenant porque la API no verifico propiedad del objeto.',
          )
        else
          const _InsightBox(
            icon: Icons.play_circle_outline_rounded,
            color: _LabPalette.accent,
            title: 'Prueba controlada',
            text:
                'La simulacion no muestra payloads reales. Solo confirma si la historia tecnica que planteaste produce impacto en el laboratorio.',
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _probeRunning || _vulnerabilityConfirmed || !hasMinimumWork
              ? null
              : _runControlledProbe,
          icon: _probeRunning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(
            _vulnerabilityConfirmed
                ? 'PRUEBA COMPLETADA'
                : 'EJECUTAR PRUEBA CONTROLADA',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _LabPalette.accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContainmentTool() {
    return ListView(
      key: const ValueKey('containment'),
      children: [
        const _ToolHeader(
          icon: Icons.health_and_safety_rounded,
          color: _LabPalette.safe,
          title: 'Consola de contencion',
          subtitle:
              'Prepara una respuesta completa. La validacion dira si el caso queda cerrado.',
        ),
        const SizedBox(height: 12),
        const _WorkflowNote(
          icon: Icons.layers_rounded,
          title: 'Respuesta por capas',
          text:
              'Una contencion madura no es una sola accion. Piensa en correccion, superficie expuesta, sesiones activas y deteccion posterior.',
        ),
        const SizedBox(height: 12),
        for (final item in ExploitLabData.mitigations)
          _MitigationTile(
            action: item,
            selected: _selectedMitigations.contains(item.id),
            locked: !_vulnerabilityConfirmed,
            onTap: () => _toggleMitigation(item),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _vulnerabilityConfirmed ? _verifyContainment : null,
          icon: const Icon(Icons.task_alt_rounded),
          label: const Text('VALIDAR CONTENCION'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _LabPalette.safe,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportTool() {
    final hypothesis = _selectedHypothesis;
    final selectedEvidence = ExploitLabData.evidences
        .where((item) => _selectedEvidence.contains(item.id))
        .toList();
    final selectedMitigations = ExploitLabData.mitigations
        .where((item) => _selectedMitigations.contains(item.id))
        .toList();

    return ListView(
      key: const ValueKey('report'),
      children: [
        const _ToolHeader(
          icon: Icons.description_rounded,
          color: _LabPalette.ink,
          title: 'Informe tecnico',
          subtitle:
              'Resumen profesional del caso, impacto, evidencias y controles.',
        ),
        const SizedBox(height: 12),
        _ReportSummary(
          score: _score,
          integrity: _integrity,
          complete: _requiredMitigationsComplete && _vulnerabilityConfirmed,
        ),
        const SizedBox(height: 12),
        _ReportSection(
          title: 'Causa raiz',
          body: hypothesis?.correct == true
              ? hypothesis!.lesson
              : 'La causa raiz no ha quedado demostrada todavia.',
        ),
        _ReportSection(
          title: 'Impacto',
          body: _vulnerabilityConfirmed
              ? 'Lectura no autorizada de datos administrativos entre tenants usando una cuenta valida de bajo privilegio.'
              : 'Pendiente de validacion controlada.',
        ),
        _ReportSection(
          title: 'Evidencias seleccionadas',
          body: selectedEvidence.isEmpty
              ? 'Sin evidencias marcadas.'
              : selectedEvidence.map((item) => '- ${item.title}').join('\n'),
        ),
        _ReportSection(
          title: 'Mitigaciones aplicadas',
          body: selectedMitigations.isEmpty
              ? 'Sin mitigaciones aplicadas.'
              : selectedMitigations.map((item) => '- ${item.title}').join('\n'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _requiredMitigationsComplete && _vulnerabilityConfirmed
              ? _verifyContainment
              : () => setState(() => _tool = _LabTool.containment),
          icon: const Icon(Icons.flag_rounded),
          label: Text(
            _requiredMitigationsComplete && _vulnerabilityConfirmed
                ? 'CERRAR MISION'
                : 'VOLVER A CONTENCION',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _LabPalette.ink,
            side: const BorderSide(color: _LabPalette.line),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelinePanel() {
    return _LabPanel(child: _TimelinePanel(events: _timeline));
  }

  String _toolLabel(_LabTool tool) {
    return switch (tool) {
      _LabTool.recon => 'Mapa',
      _LabTool.logs => 'Logs',
      _LabTool.hypothesis => 'Hipotesis',
      _LabTool.validation => 'Prueba',
      _LabTool.containment => 'Contencion',
      _LabTool.report => 'Informe',
    };
  }

  IconData _toolIcon(_LabTool tool) {
    return switch (tool) {
      _LabTool.recon => Icons.travel_explore_rounded,
      _LabTool.logs => Icons.receipt_long_rounded,
      _LabTool.hypothesis => Icons.psychology_alt_rounded,
      _LabTool.validation => Icons.science_rounded,
      _LabTool.containment => Icons.health_and_safety_rounded,
      _LabTool.report => Icons.description_rounded,
    };
  }
}

class _LabPalette {
  static const panel = Color(0xFF0D0D2B);
  static const panelAlt = Color(0xFF121235);
  static const ink = Color(0xFFF6F8FF);
  static const muted = Color(0xFF9A9AA5);
  static const line = Color(0xFF1A1A4A);
  static const neutral = Color(0xFFB8C2D9);
  static const active = Color(0xFF050816);
  static const accent = Color(0xFF0F766E);
  static const safe = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE11D48);
  static const blue = Color(0xFF2563EB);
  static const violet = Color(0xFF7C3AED);
}

class _LabPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _LabPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _LabPalette.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _LabPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _LabPalette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintHeaderButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _HintHeaderButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Pedir una pista',
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
        label: Text('$label $value'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _LabPalette.ink,
          side: const BorderSide(color: _LabPalette.line),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _MissionFlowStrip extends StatelessWidget {
  final _LabTool activeTool;

  const _MissionFlowStrip({required this.activeTool});

  static const List<({IconData icon, String label, _LabTool tool})> _steps = [
    (
      icon: Icons.travel_explore_rounded,
      label: 'Explora',
      tool: _LabTool.recon,
    ),
    (icon: Icons.receipt_long_rounded, label: 'Archiva', tool: _LabTool.logs),
    (
      icon: Icons.psychology_alt_rounded,
      label: 'Hipotesis',
      tool: _LabTool.hypothesis,
    ),
    (icon: Icons.science_rounded, label: 'Prueba', tool: _LabTool.validation),
    (
      icon: Icons.health_and_safety_rounded,
      label: 'Conten',
      tool: _LabTool.containment,
    ),
    (icon: Icons.description_rounded, label: 'Informe', tool: _LabTool.report),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            _MissionStepChip(
              icon: _steps[i].icon,
              label: '${i + 1}. ${_steps[i].label}',
              selected: activeTool == _steps[i].tool,
            ),
            if (i < _steps.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _LabPalette.muted,
                  size: 18,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MissionStepChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _MissionStepChip({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _LabPalette.active : _LabPalette.panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? _LabPalette.active : _LabPalette.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : _LabPalette.ink,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _LabPalette.ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _TinyChip({
    required this.label,
    required this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? color : _LabPalette.ink,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _LabPalette.active : _LabPalette.panelAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _LabPalette.active : _LabPalette.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : _LabPalette.ink,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _LabPalette.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ToolHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.26)),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _LabPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _LabPalette.muted,
                  height: 1.35,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _LabPalette.ink, size: 17),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: _LabPalette.ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6, right: 9),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _LabPalette.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final LabEvidence evidence;
  final LabAsset asset;
  final bool selected;
  final VoidCallback onTap;

  const _EvidenceTile({
    required this.evidence,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _LabPalette.ink : asset.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : _LabPalette.panelAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : _LabPalette.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_evidenceIcon(evidence.kind), color: color, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      evidence.title,
                      style: const TextStyle(
                        color: _LabPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? color : _LabPalette.muted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                evidence.signal,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                evidence.detail,
                style: const TextStyle(
                  color: _LabPalette.muted,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 8),
                const _TinyChip(
                  label: 'ARCHIVADA',
                  color: _LabPalette.ink,
                  filled: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _evidenceIcon(EvidenceKind kind) {
    return switch (kind) {
      EvidenceKind.config => Icons.tune_rounded,
      EvidenceKind.log => Icons.article_rounded,
      EvidenceKind.identity => Icons.badge_rounded,
      EvidenceKind.data => Icons.storage_rounded,
      EvidenceKind.network => Icons.route_rounded,
    };
  }
}

class _HypothesisTile extends StatelessWidget {
  final VulnerabilityHypothesis hypothesis;
  final bool selected;
  final VoidCallback onTap;

  const _HypothesisTile({
    required this.hypothesis,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _LabPalette.ink : _LabPalette.violet;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : _LabPalette.panelAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? color : _LabPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schema_rounded, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hypothesis.title,
                      style: const TextStyle(
                        color: _LabPalette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  _TinyChip(
                    label: selected ? 'SELECCIONADA' : 'HIPOTESIS',
                    color: color,
                    filled: selected,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hypothesis.summary,
                style: const TextStyle(
                  color: _LabPalette.muted,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Hipotesis cargada para la prueba controlada.',
                    style: TextStyle(
                      color: _LabPalette.ink,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MitigationTile extends StatelessWidget {
  final MitigationAction action;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _MitigationTile({
    required this.action,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _LabPalette.ink : _LabPalette.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: locked ? 0.55 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.10)
                  : _LabPalette.panelAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? color : _LabPalette.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              action.title,
                              style: const TextStyle(
                                color: _LabPalette.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _TinyChip(
                            label: selected ? 'PREPARADA' : 'ACCION',
                            color: color,
                            filled: selected,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.summary,
                        style: const TextStyle(
                          color: _LabPalette.muted,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Text(
                            'Accion incluida en la propuesta de contencion.',
                            style: TextStyle(
                              color: _LabPalette.ink,
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _WorkflowNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _WorkflowNote({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _LabPalette.panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _LabPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _LabPalette.ink, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _LabPalette.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: _LabPalette.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalBlock extends StatelessWidget {
  final bool running;
  final List<String> lines;

  const _TerminalBlock({required this.running, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263544)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFFD7FBE8),
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.45,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines) Text('> $line'),
            if (running) const Text('> ejecutando simulacion segura...'),
          ],
        ),
      ),
    );
  }
}

class _InsightBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _InsightBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: _LabPalette.ink,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  final List<LabTimelineEvent> events;

  const _TimelinePanel({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
          icon: Icons.timeline_rounded,
          text: 'TIMELINE DEL INCIDENTE',
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                width: 235,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: event.color.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(event.icon, color: event.color, size: 20),
                    const SizedBox(height: 7),
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LabPalette.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        event.detail,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _LabPalette.muted,
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NetworkDiorama extends StatelessWidget {
  final List<LabAsset> assets;
  final List<LabConnection> connections;
  final Map<String, _AssetState> states;
  final String selectedAssetId;
  final double pulse;
  final bool compact;
  final ValueChanged<String> onSelect;

  const _NetworkDiorama({
    required this.assets,
    required this.connections,
    required this.states,
    required this.selectedAssetId,
    required this.pulse,
    required this.compact,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final nodeSize = compact ? 62.0 : 74.0;
        final labelWidth = compact ? 86.0 : 112.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DioramaPainter(
                    assets: assets,
                    connections: connections,
                    states: states,
                    selectedAssetId: selectedAssetId,
                    pulse: pulse,
                  ),
                ),
              ),
              for (final asset in assets)
                Positioned(
                  left: (asset.position.dx * width) - (labelWidth / 2),
                  top: (asset.position.dy * height) - (nodeSize / 2),
                  width: labelWidth,
                  child: _AssetBeacon(
                    asset: asset,
                    state: states[asset.id] ?? _AssetState.idle,
                    selected: selectedAssetId == asset.id,
                    size: nodeSize,
                    compact: compact,
                    onTap: () => onSelect(asset.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AssetBeacon extends StatelessWidget {
  final LabAsset asset;
  final _AssetState state;
  final bool selected;
  final bool compact;
  final double size;
  final VoidCallback onTap;

  const _AssetBeacon({
    required this.asset,
    required this.state,
    required this.selected,
    required this.compact,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stateColor = _stateColor(state, asset.color);

    return Tooltip(
      message: '${asset.name}: ${asset.role}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _LabPalette.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? _LabPalette.active : stateColor,
                  width: selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: stateColor.withValues(alpha: selected ? 0.30 : 0.18),
                    blurRadius: selected ? 18 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(child: Icon(asset.icon, color: stateColor, size: 28)),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: stateColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: BoxConstraints(maxWidth: compact ? 82 : 108),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _LabPalette.panel.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _LabPalette.line),
              ),
              child: Text(
                asset.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _LabPalette.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _stateColor(_AssetState state, Color fallback) {
    return switch (state) {
      _AssetState.idle => fallback,
      _AssetState.suspicious => _LabPalette.neutral,
      _AssetState.exposed => _LabPalette.neutral,
      _AssetState.compromised => _LabPalette.danger,
      _AssetState.contained => _LabPalette.accent,
      _AssetState.fixed => _LabPalette.safe,
    };
  }
}

class _DioramaPainter extends CustomPainter {
  final List<LabAsset> assets;
  final List<LabConnection> connections;
  final Map<String, _AssetState> states;
  final String selectedAssetId;
  final double pulse;

  _DioramaPainter({
    required this.assets,
    required this.connections,
    required this.states,
    required this.selectedAssetId,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF8FBFD);
    canvas.drawRect(Offset.zero & size, background);

    _drawGrid(canvas, size);
    _drawZones(canvas, size);
    _drawConnections(canvas, size);
    _drawTrafficPulse(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _LabPalette.line.withValues(alpha: 0.52)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawZones(Canvas canvas, Size size) {
    final zones = [
      (const Rect.fromLTWH(0.03, 0.08, 0.28, 0.84), 'INTERNET / DMZ'),
      (const Rect.fromLTWH(0.34, 0.10, 0.34, 0.80), 'SERVICIOS'),
      (const Rect.fromLTWH(0.71, 0.10, 0.26, 0.80), 'DATOS / OPS'),
    ];

    for (final zone in zones) {
      final rect = Rect.fromLTWH(
        zone.$1.left * size.width,
        zone.$1.top * size.height,
        zone.$1.width * size.width,
        zone.$1.height * size.height,
      );
      final paint = Paint()
        ..color = _LabPalette.accent.withValues(alpha: 0.045)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = _LabPalette.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        border,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: zone.$2,
          style: const TextStyle(
            color: _LabPalette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 16);
      textPainter.paint(canvas, rect.topLeft + const Offset(10, 8));
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    for (final connection in connections) {
      final from = _assetById(connection.from).position;
      final to = _assetById(connection.to).position;
      final fromPoint = Offset(from.dx * size.width, from.dy * size.height);
      final toPoint = Offset(to.dx * size.width, to.dy * size.height);
      final involved =
          connection.from == selectedAssetId ||
          connection.to == selectedAssetId ||
          _isHot(connection.from) ||
          _isHot(connection.to);
      final hot = _isHot(connection.from) || _isHot(connection.to);
      final paint = Paint()
        ..color = (hot ? _LabPalette.danger : _LabPalette.blue).withValues(
          alpha: involved ? 0.62 : 0.24,
        )
        ..strokeWidth = involved ? 3 : 2
        ..style = PaintingStyle.stroke;

      final mid = Offset(
        (fromPoint.dx + toPoint.dx) / 2,
        (fromPoint.dy + toPoint.dy) / 2,
      );
      final control = mid + Offset(0, connection.critical ? -35 : 26);
      final path = Path()
        ..moveTo(fromPoint.dx, fromPoint.dy)
        ..quadraticBezierTo(control.dx, control.dy, toPoint.dx, toPoint.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _drawTrafficPulse(Canvas canvas, Size size) {
    for (final connection in connections) {
      final from = _assetById(connection.from).position;
      final to = _assetById(connection.to).position;
      final hot = _isHot(connection.from) || _isHot(connection.to);
      if (!hot) continue;

      final start = Offset(from.dx * size.width, from.dy * size.height);
      final end = Offset(to.dx * size.width, to.dy * size.height);
      final point = Offset.lerp(start, end, pulse)!;
      final color = hot ? _LabPalette.danger : _LabPalette.accent;
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.72)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, hot ? 5.5 : 4, pulsePaint);
    }
  }

  LabAsset _assetById(String id) {
    return assets.firstWhere((item) => item.id == id);
  }

  bool _isHot(String assetId) {
    final state = states[assetId] ?? _AssetState.idle;
    return state == _AssetState.compromised;
  }

  @override
  bool shouldRepaint(covariant _DioramaPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.states != states ||
        oldDelegate.selectedAssetId != selectedAssetId;
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LabPalette.panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _LabPalette.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: _LabPalette.safe),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _LabPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  final int score;
  final int integrity;
  final bool complete;

  const _ReportSummary({
    required this.score,
    required this.integrity,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (complete ? _LabPalette.safe : _LabPalette.warning).withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: complete ? _LabPalette.safe : _LabPalette.warning,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _TinyChip(
            label: complete ? 'CASO CERRADO' : 'CASO ABIERTO',
            color: complete ? _LabPalette.safe : _LabPalette.warning,
          ),
          _TinyChip(
            label: complete ? '$score XP' : 'XP pendiente',
            color: _LabPalette.violet,
          ),
          _TinyChip(label: '$integrity% integridad', color: _LabPalette.accent),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final String body;

  const _ReportSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _LabPalette.panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _LabPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _LabPalette.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: const TextStyle(
              color: _LabPalette.muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabVictoryDialog extends StatelessWidget {
  final int score;
  final int integrity;
  final bool trainingMode;
  final VoidCallback onReport;
  final VoidCallback onContinue;

  const _LabVictoryDialog({
    required this.score,
    required this.integrity,
    required this.trainingMode,
    required this.onReport,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _LabPalette.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _LabPalette.safe),
            boxShadow: [
              BoxShadow(
                color: _LabPalette.safe.withValues(alpha: 0.22),
                blurRadius: 32,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: _LabPalette.safe,
                size: 50,
              ),
              const SizedBox(height: 14),
              const Text(
                'EXPLOIT CONTENIDO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _LabPalette.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trainingMode
                    ? 'Informe generado en modo entrenamiento.'
                    : 'Causa raiz corregida y nivel 22 desbloqueado.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _LabPalette.muted,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _TinyChip(label: '$score XP', color: _LabPalette.violet),
                  _TinyChip(
                    label: '$integrity% integridad',
                    color: _LabPalette.safe,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReport,
                      icon: const Icon(Icons.description_rounded),
                      label: const Text('INFORME'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _LabPalette.ink,
                        side: const BorderSide(color: _LabPalette.line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('CONTINUAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LabPalette.safe,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
    );
  }
}

class _HintDialog extends StatelessWidget {
  final int current;
  final int total;
  final String text;
  final VoidCallback? onNext;

  const _HintDialog({
    required this.current,
    required this.total,
    required this.text,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _LabPalette.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _LabPalette.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: _LabPalette.warning,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PISTA $current/$total',
                      style: const TextStyle(
                        color: _LabPalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                text,
                style: const TextStyle(
                  color: _LabPalette.muted,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _LabPalette.ink,
                        side: const BorderSide(color: _LabPalette.line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('CERRAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LabPalette.active,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _LabPalette.line,
                        disabledForegroundColor: _LabPalette.muted,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(onNext == null ? 'ULTIMA' : 'SIGUIENTE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabFailureDialog extends StatelessWidget {
  final int score;
  final int integrity;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _LabFailureDialog({
    required this.score,
    required this.integrity,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _LabPalette.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _LabPalette.danger),
            boxShadow: [
              BoxShadow(
                color: _LabPalette.danger.withValues(alpha: 0.24),
                blurRadius: 32,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gpp_bad_rounded,
                color: _LabPalette.danger,
                size: 50,
              ),
              const SizedBox(height: 14),
              const Text(
                'LABORATORIO INESTABLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _LabPalette.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demasiadas decisiones sin evidencia degradaron la investigacion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _LabPalette.muted,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _TinyChip(label: '$score XP', color: _LabPalette.violet),
                  _TinyChip(
                    label: '$integrity% integridad',
                    color: _LabPalette.danger,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('REINTENTAR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _LabPalette.ink,
                        side: const BorderSide(color: _LabPalette.line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onExit,
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('MAPA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LabPalette.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
    );
  }
}
