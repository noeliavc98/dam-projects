import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';

enum _FirewallPhase { intro, triage, builder, results }

enum _Zone { any, internet, web, database, admin, lan }

enum _Protocol { any, tcp, udp, icmp }

enum _Decision { allow, deny }

class Nivel16Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel16Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel16Screen> createState() => _Nivel16ScreenState();
}

class _Nivel16ScreenState extends State<Nivel16Screen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _packetController;
  late final ScrollController _scrollController;

  _FirewallPhase _phase = _FirewallPhase.intro;
  bool _loading = true;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;
  bool _simulating = false;
  bool _victory = false;
  bool _defeat = false;
  bool _showRuleHint = false;
  bool _completionDialogShown = false;
  bool _failureDialogShown = false;

  int _score = 0;
  int _triageIndex = 0;
  int _triageCorrect = 0;
  int _criticalFailures = 0;
  int _falsePositives = 0;
  int _policyAttempts = 0;

  _Zone _ruleSource = _Zone.internet;
  _Zone _ruleDestination = _Zone.web;
  _Protocol _ruleProtocol = _Protocol.tcp;
  int _rulePort = 443;
  _Decision _ruleDecision = _Decision.allow;
  bool _ruleLog = false;

  final List<_FirewallRule> _rules = [];
  final List<_SimulationLog> _logs = [];

  static const int _maxPolicyAttempts = 3;

  static final List<_TrafficPacket> _triagePackets = [
    _TrafficPacket(
      id: 't1',
      title: 'Cliente web legitimo',
      source: _Zone.internet,
      destination: _Zone.web,
      protocol: _Protocol.tcp,
      port: 443,
      expected: _Decision.allow,
      lesson: 'HTTPS hacia el servidor web publico debe pasar.',
    ),
    _TrafficPacket(
      id: 't2',
      title: 'SSH externo a administracion',
      source: _Zone.internet,
      destination: _Zone.admin,
      protocol: _Protocol.tcp,
      port: 22,
      expected: _Decision.deny,
      malicious: true,
      critical: true,
      lesson: 'SSH de Internet a admin expone una puerta directa.',
    ),
    _TrafficPacket(
      id: 't3',
      title: 'Base de datos expuesta',
      source: _Zone.internet,
      destination: _Zone.database,
      protocol: _Protocol.tcp,
      port: 3306,
      expected: _Decision.deny,
      malicious: true,
      critical: true,
      lesson: 'MySQL nunca deberia quedar abierto a Internet.',
    ),
    _TrafficPacket(
      id: 't4',
      title: 'DNS desde la LAN',
      source: _Zone.lan,
      destination: _Zone.internet,
      protocol: _Protocol.udp,
      port: 53,
      expected: _Decision.allow,
      lesson: 'La LAN necesita resolver dominios para navegar.',
    ),
    _TrafficPacket(
      id: 't5',
      title: 'Sondeo ICMP desde fuera',
      source: _Zone.internet,
      destination: _Zone.web,
      protocol: _Protocol.icmp,
      port: 0,
      expected: _Decision.deny,
      malicious: true,
      lesson: 'No todo diagnostico externo debe atravesar el perimetro.',
    ),
  ];

  static final List<_TrafficPacket> _simulationPackets = [
    _TrafficPacket(
      id: 's1',
      title: 'Cliente visita la web',
      source: _Zone.internet,
      destination: _Zone.web,
      protocol: _Protocol.tcp,
      port: 443,
      expected: _Decision.allow,
      critical: true,
      lesson: 'El servicio publico debe seguir disponible.',
    ),
    _TrafficPacket(
      id: 's2',
      title: 'Intento SSH externo',
      source: _Zone.internet,
      destination: _Zone.admin,
      protocol: _Protocol.tcp,
      port: 22,
      expected: _Decision.deny,
      malicious: true,
      critical: true,
      lesson: 'Administracion solo deberia entrar desde redes internas.',
    ),
    _TrafficPacket(
      id: 's3',
      title: 'Ataque directo a DB',
      source: _Zone.internet,
      destination: _Zone.database,
      protocol: _Protocol.tcp,
      port: 3306,
      expected: _Decision.deny,
      malicious: true,
      critical: true,
      lesson: 'Una DB publica es una fuga esperando turno.',
    ),
    _TrafficPacket(
      id: 's4',
      title: 'Web consulta la DB',
      source: _Zone.web,
      destination: _Zone.database,
      protocol: _Protocol.tcp,
      port: 3306,
      expected: _Decision.allow,
      critical: true,
      lesson: 'La aplicacion web si necesita hablar con la base de datos.',
    ),
    _TrafficPacket(
      id: 's5',
      title: 'DNS de usuarios internos',
      source: _Zone.lan,
      destination: _Zone.internet,
      protocol: _Protocol.udp,
      port: 53,
      expected: _Decision.allow,
      lesson: 'Bloquear DNS rompe navegacion y servicios.',
    ),
    _TrafficPacket(
      id: 's6',
      title: 'HTTP sin cifrar',
      source: _Zone.internet,
      destination: _Zone.web,
      protocol: _Protocol.tcp,
      port: 80,
      expected: _Decision.deny,
      malicious: true,
      lesson: 'Forzar HTTPS reduce exposicion y errores humanos.',
    ),
    _TrafficPacket(
      id: 's7',
      title: 'RDP hacia admin',
      source: _Zone.internet,
      destination: _Zone.admin,
      protocol: _Protocol.tcp,
      port: 3389,
      expected: _Decision.deny,
      malicious: true,
      critical: true,
      lesson: 'RDP expuesto suele convertirse en incidente.',
    ),
    _TrafficPacket(
      id: 's8',
      title: 'Admin accede por SSH',
      source: _Zone.admin,
      destination: _Zone.web,
      protocol: _Protocol.tcp,
      port: 22,
      expected: _Decision.allow,
      lesson: 'El acceso administrativo debe estar limitado a origen fiable.',
    ),
    _TrafficPacket(
      id: 's9',
      title: 'Escaneo ICMP externo',
      source: _Zone.internet,
      destination: _Zone.web,
      protocol: _Protocol.icmp,
      port: 0,
      expected: _Decision.deny,
      malicious: true,
      lesson: 'El firewall tambien reduce ruido de reconocimiento.',
    ),
  ];

  static const List<_FirewallRule> _recommendedRules = [
    _FirewallRule(
      label: 'WEB publica por HTTPS',
      source: _Zone.internet,
      destination: _Zone.web,
      protocol: _Protocol.tcp,
      port: 443,
      decision: _Decision.allow,
      log: false,
    ),
    _FirewallRule(
      label: 'Web consulta base de datos',
      source: _Zone.web,
      destination: _Zone.database,
      protocol: _Protocol.tcp,
      port: 3306,
      decision: _Decision.allow,
      log: true,
    ),
    _FirewallRule(
      label: 'DNS para LAN',
      source: _Zone.lan,
      destination: _Zone.internet,
      protocol: _Protocol.udp,
      port: 53,
      decision: _Decision.allow,
      log: false,
    ),
    _FirewallRule(
      label: 'Admin SSH controlado',
      source: _Zone.admin,
      destination: _Zone.web,
      protocol: _Protocol.tcp,
      port: 22,
      decision: _Decision.allow,
      log: true,
    ),
    _FirewallRule(
      label: 'Deny all final',
      source: _Zone.any,
      destination: _Zone.any,
      protocol: _Protocol.any,
      port: 0,
      decision: _Decision.deny,
      log: true,
    ),
  ];

  _TrafficPacket get _displayPacket {
    if (_phase == _FirewallPhase.triage) {
      return _triagePackets[_triageIndex.clamp(0, _triagePackets.length - 1)];
    }
    final scaledProgress = _packetController.value * _simulationPackets.length;
    final index = scaledProgress.floor() % _simulationPackets.length;
    return _simulationPackets[index];
  }

  double get _packetTravelProgress {
    if (_phase == _FirewallPhase.triage) return _packetController.value;

    final scaledProgress = _packetController.value * _simulationPackets.length;
    return scaledProgress - scaledProgress.floorToDouble();
  }

  bool get _routeChecklistComplete {
    return _recommendedRules.every(
      (rule) => _rules.any((saved) => _sameRule(saved, rule)),
    );
  }

  _Decision _displayPacketAction(_TrafficPacket packet) {
    if (_phase == _FirewallPhase.triage) return packet.expected;
    return _evaluatePacket(packet).action;
  }

  @override
  void initState() {
    super.initState();
    MusicService().stopMusic();
    _scrollController = ScrollController();
    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _setupLevel();
  }

  Future<void> _setupLevel() async {
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final data = await FirestoreService.obtenerUsuario();
        final level = (data['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = level > 16;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 16: $e');
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _packetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    if (_progresoGuardado || _nivelYaCompletado) return;
    _progresoGuardado = true;

    try {
      await FirestoreService.guardarPuntuacion(
        puntos: _score,
        nivelCompletado: 16,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
        nivel: 16,
        mision: 16,
        puntos: _score,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso del nivel 16: $e');
    }
  }

  void _answerTriage(_Decision decision) {
    final packet = _triagePackets[_triageIndex];
    final correct = decision == packet.expected;

    setState(() {
      if (correct) {
        _triageCorrect++;
        _score += 80;
      }
      _logs.insert(
        0,
        _SimulationLog(
          packet: packet,
          action: decision,
          matchedRuleLabel: 'decision manual',
          logged: true,
          correct: correct,
          note: correct ? 'Lectura correcta del paquete.' : packet.lesson,
        ),
      );

      if (_triageIndex < _triagePackets.length - 1) {
        _triageIndex++;
      } else {
        _phase = _FirewallPhase.builder;
      }
    });
  }

  void _addRule() {
    setState(() {
      _rules.add(
        _FirewallRule(
          label: 'Regla ${_rules.length + 1}',
          source: _ruleSource,
          destination: _ruleDestination,
          protocol: _ruleProtocol,
          port: _rulePort,
          decision: _ruleDecision,
          log: _ruleLog,
        ),
      );
      _showRuleHint = false;
    });
  }

  _FirewallRule? _nextMissingRecommendedRule() {
    for (final rule in _recommendedRules) {
      if (!_rules.any((saved) => _sameRule(saved, rule))) return rule;
    }
    return null;
  }

  bool _sameRule(_FirewallRule a, _FirewallRule b) {
    return a.source == b.source &&
        a.destination == b.destination &&
        a.protocol == b.protocol &&
        a.port == b.port &&
        a.decision == b.decision &&
        (!b.log || a.log);
  }

  void _showNextRuleHint() {
    if (_nextMissingRecommendedRule() == null) return;
    setState(() => _showRuleHint = true);
  }

  void _moveRule(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _rules.length) return;
    setState(() {
      final rule = _rules.removeAt(index);
      _rules.insert(newIndex, rule);
    });
  }

  void _deleteRule(int index) {
    setState(() => _rules.removeAt(index));
  }

  Future<void> _runSimulation() async {
    if (_simulating || _defeat) return;

    setState(() {
      _simulating = true;
      _logs.clear();
      _criticalFailures = 0;
      _falsePositives = 0;
    });

    await Future<void>.delayed(const Duration(milliseconds: 550));

    int simulationScore = _triageCorrect * 80;
    int criticalFailures = 0;
    int falsePositives = 0;
    final logs = <_SimulationLog>[];

    for (final packet in _simulationPackets) {
      final result = _evaluatePacket(packet);
      final correct = result.action == packet.expected;

      if (correct) {
        simulationScore += 100;
        if (packet.malicious &&
            result.action == _Decision.deny &&
            result.logged) {
          simulationScore += 20;
        }
      } else {
        simulationScore -= packet.critical ? 130 : 70;
        if (packet.critical) criticalFailures++;
        if (packet.expected == _Decision.allow &&
            result.action == _Decision.deny) {
          falsePositives++;
        }
      }

      logs.add(
        _SimulationLog(
          packet: packet,
          action: result.action,
          matchedRuleLabel: result.ruleLabel,
          logged: result.logged,
          correct: correct,
          note: correct ? _successNote(packet, result) : _failureNote(packet),
        ),
      );
    }

    final clampedScore = simulationScore.clamp(0, 1200).toInt();
    final allRoutesCorrect = logs.every((log) => log.correct);
    final victory = _routeChecklistComplete && allRoutesCorrect;
    final nextAttempts = victory ? _policyAttempts : _policyAttempts + 1;
    final defeat =
        !victory &&
        (nextAttempts >= _maxPolicyAttempts || criticalFailures >= 3);

    if (!mounted) return;
    setState(() {
      _logs
        ..clear()
        ..addAll(logs);
      _score = clampedScore;
      _criticalFailures = criticalFailures;
      _falsePositives = falsePositives;
      _victory = victory;
      _defeat = defeat;
      _policyAttempts = nextAttempts;
      _phase = _FirewallPhase.results;
      _simulating = false;
    });

    if (victory) {
      await _saveProgress();
      if (mounted && !_completionDialogShown) {
        _completionDialogShown = true;
        _showMissionCompletedDialog();
      }
    } else if (defeat && mounted && !_failureDialogShown) {
      _failureDialogShown = true;
      _showMissionFailedDialog();
    }
  }

  _FirewallResult _evaluatePacket(_TrafficPacket packet) {
    for (int i = 0; i < _rules.length; i++) {
      final rule = _rules[i];
      if (rule.matches(packet)) {
        return _FirewallResult(
          action: rule.decision,
          ruleLabel: '${i + 1}. ${rule.label}',
          logged: rule.log,
        );
      }
    }

    return const _FirewallResult(
      action: _Decision.deny,
      ruleLabel: 'deny implicito',
      logged: false,
    );
  }

  String _successNote(_TrafficPacket packet, _FirewallResult result) {
    if (packet.malicious && result.action == _Decision.deny) {
      return result.logged
          ? 'Ataque bloqueado y registrado.'
          : 'Ataque bloqueado. Faltaria registro para investigarlo despues.';
    }
    if (result.action == _Decision.allow) {
      return 'Servicio legitimo disponible.';
    }
    return 'Ruido reducido en el perimetro.';
  }

  String _failureNote(_TrafficPacket packet) {
    if (packet.expected == _Decision.allow) {
      return 'Falso positivo: la regla rompe un servicio necesario.';
    }
    return packet.lesson;
  }

  void _volverAlMapa() {
    Navigator.of(context).pop();
  }

  void _reiniciarNivel() {
    setState(() {
      _phase = _FirewallPhase.triage;
      _simulating = false;
      _victory = false;
      _defeat = false;
      _showRuleHint = false;
      _completionDialogShown = false;
      _failureDialogShown = false;
      _score = 0;
      _triageIndex = 0;
      _triageCorrect = 0;
      _criticalFailures = 0;
      _falsePositives = 0;
      _policyAttempts = 0;
      _ruleSource = _Zone.internet;
      _ruleDestination = _Zone.web;
      _ruleProtocol = _Protocol.tcp;
      _rulePort = 443;
      _ruleDecision = _Decision.allow;
      _ruleLog = false;
      _rules.clear();
      _logs.clear();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _showMissionCompletedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _MissionCompletedDialog(
          score: _score,
          trainingMode: _nivelYaCompletado,
          onReview: () => Navigator.of(dialogContext).pop(),
          onContinue: () {
            Navigator.of(dialogContext).pop();
            _volverAlMapa();
          },
        );
      },
    );
  }

  void _showMissionFailedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _MissionFailedDialog(
          score: _score,
          attempts: _policyAttempts,
          maxAttempts: _maxPolicyAttempts,
          onRetry: () {
            Navigator.of(dialogContext).pop();
            _reiniciarNivel();
          },
          onExit: () {
            Navigator.of(dialogContext).pop();
            _volverAlMapa();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    if (_phase == _FirewallPhase.intro) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _IntroGridPainter())),
              FracturaDialogo(
                subtitulo: 'NIVEL 16 // FIREWALL-CONTROL DE FRONTERA',
                textoBotonFinal: 'JUGAR',
                usarVoz: true,
                permitirSaltarIntro: true,
                permitirCambiarVoz: true,
                velocidadVoz: 0.66,
                milisegundosPorCaracter: 18,
                dialogos: const [
                  'Un firewall no es una pared. Es una lista de decisiones.',
                  'Cada paquete trae una historia: origen, destino, protocolo y puerto.',
                  'Tu trabajo sera permitir lo necesario, bloquear lo peligroso y registrar lo sospechoso.',
                  'Recuerda el principio: permite solo lo que la misión necesita. Lo demás, fuera.',
                ],
                onFinalizado: () {
                  MusicService().playNivel17Music();
                  setState(() => _phase = _FirewallPhase.triage);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_nivelYaCompletado) _buildTrainingBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final map = _buildNetworkMap();
        final panel = switch (_phase) {
          _FirewallPhase.triage => _buildTriagePanel(),
          _FirewallPhase.builder => _buildBuilderPanel(),
          _FirewallPhase.results => _buildResultsPanel(),
          _FirewallPhase.intro => const SizedBox.shrink(),
        };

        if (compact) {
          final mapHeight = constraints.maxWidth < 560 ? 260.0 : 340.0;
          return ScrollConfiguration(
            behavior: const _FirewallScrollBehavior(),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                primary: false,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SizedBox(height: mapHeight, child: map),
                    const SizedBox(height: 12),
                    panel,
                  ],
                ),
              ),
            ),
          );
        }

        final mapHeight = math.max(520.0, constraints.maxHeight - 28);
        final panelWidth = constraints.maxWidth < 1180 ? 390.0 : 430.0;
        return ScrollConfiguration(
          behavior: const _FirewallScrollBehavior(),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              primary: false,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 28),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: SizedBox(height: mapHeight, child: map),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(width: panelWidth, child: panel),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final phaseLabel = switch (_phase) {
      _FirewallPhase.triage => 'ACTO 1 // INSPECCION',
      _FirewallPhase.builder => 'ACTO 2 // POLITICA',
      _FirewallPhase.results => 'INFORME FINAL',
      _FirewallPhase.intro => 'INTRO',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final titleRow = Row(
            children: [
              IconButton(
                tooltip: 'Volver al mapa',
                onPressed: _volverAlMapa,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.cyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'NIVEL 16 - FIREWALL LAB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _MetricPill(label: phaseLabel, value: '$_score XP'),
              _MetricPill(label: 'REGLAS', value: '${_rules.length}'),
              _MetricPill(
                label: 'INTENTOS',
                value:
                    '${(_maxPolicyAttempts - _policyAttempts).clamp(0, _maxPolicyAttempts)}',
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [titleRow, const SizedBox(height: 8), metrics],
            );
          }

          return Row(
            children: [
              Expanded(child: titleRow),
              const SizedBox(width: 10),
              metrics,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrainingBanner() {
    return Container(
      width: double.infinity,
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
          Text(
            'MODO ENTRENAMIENTO - Progreso no guardado',
            style: TextStyle(
              color: AppColors.purple,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkMap() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.06),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AnimatedBuilder(
          animation: _packetController,
          builder: (context, _) {
            final packet = _displayPacket;
            return CustomPaint(
              painter: _FirewallMapPainter(
                packet: packet,
                action: _displayPacketAction(packet),
                progress: _packetTravelProgress,
                rules: _rules.length,
                blocked: _logs
                    .where((log) => log.action == _Decision.deny)
                    .length,
                allowed: _logs
                    .where((log) => log.action == _Decision.allow)
                    .length,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTriagePanel() {
    final packet = _triagePackets[_triageIndex];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('ACTO 1'),
          const SizedBox(height: 8),
          const Text(
            'Inspeccion rapida',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Decide si el paquete debe cruzar el firewall. Mira origen, destino, protocolo y puerto.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _PacketCard(packet: packet),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DecisionButton(
                  label: 'PERMITIR',
                  icon: Icons.check_rounded,
                  color: AppColors.cyan,
                  onTap: () => _answerTriage(_Decision.allow),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DecisionButton(
                  label: 'BLOQUEAR',
                  icon: Icons.block_rounded,
                  color: AppColors.pink,
                  onTap: () => _answerTriage(_Decision.deny),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressRail(
            current: _triageIndex + 1,
            total: _triagePackets.length,
            correct: _triageCorrect,
          ),
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MiniLog(log: _logs.first),
          ],
        ],
      ),
    );
  }

  Widget _buildBuilderPanel() {
    final guideCompleted = _recommendedRules
        .map((rule) => _rules.any((saved) => _sameRule(saved, rule)))
        .toList();
    final guideReady = guideCompleted.every((done) => done);
    final nextHint = _nextMissingRecommendedRule();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('ACTO 2'),
          const SizedBox(height: 8),
          const Text(
            'Construye la politica',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Objetivo: deja pasar solo los servicios necesarios y cierra el resto por defecto.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _GuidedChecklist(completed: guideCompleted),
          if (_showRuleHint && nextHint != null) ...[
            const SizedBox(height: 12),
            _RuleHintCard(
              rule: nextHint,
              onClose: () => setState(() => _showRuleHint = false),
            ),
          ],
          const SizedBox(height: 12),
          _buildRuleEditor(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: guideReady ? null : _showNextRuleHint,
            icon: const Icon(Icons.lightbulb_rounded),
            label: Text(guideReady ? 'RUTA COMPLETA' : 'VER PISTA'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cyan,
              side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.45)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _rules.isEmpty || _simulating ? null : _runSimulation,
            icon: _simulating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: const Text('SIMULAR POLITICA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: AppColors.bgMain,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('TABLA DE REGLAS'),
          const SizedBox(height: 8),
          if (_rules.isEmpty)
            _EmptyRulesCard()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _RuleCard(
                  index: index,
                  rule: _rules[index],
                  onUp: () => _moveRule(index, -1),
                  onDown: () => _moveRule(index, 1),
                  onDelete: () => _deleteRule(index),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRuleEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _responsivePair(
            _EnumDropdown<_Zone>(
              label: 'Origen',
              value: _ruleSource,
              values: _Zone.values,
              labelFor: _zoneLabel,
              onChanged: (value) => setState(() => _ruleSource = value),
            ),
            _EnumDropdown<_Zone>(
              label: 'Destino',
              value: _ruleDestination,
              values: _Zone.values,
              labelFor: _zoneLabel,
              onChanged: (value) => setState(() => _ruleDestination = value),
            ),
          ),
          const SizedBox(height: 8),
          _responsivePair(
            _EnumDropdown<_Protocol>(
              label: 'Protocolo',
              value: _ruleProtocol,
              values: _Protocol.values,
              labelFor: _protocolLabel,
              onChanged: (value) => setState(() => _ruleProtocol = value),
            ),
            _portDropdown(),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final allow = _ActionChoice(
                selected: _ruleDecision == _Decision.allow,
                label: 'Permitir',
                icon: Icons.check_rounded,
                color: AppColors.cyan,
                onTap: () => setState(() => _ruleDecision = _Decision.allow),
              );
              final deny = _ActionChoice(
                selected: _ruleDecision == _Decision.deny,
                label: 'Bloquear',
                icon: Icons.block_rounded,
                color: AppColors.pink,
                onTap: () => setState(() => _ruleDecision = _Decision.deny),
              );
              final log = Tooltip(
                message: 'Registrar eventos que coincidan con esta regla',
                child: FilterChip(
                  selected: _ruleLog,
                  onSelected: (value) => setState(() => _ruleLog = value),
                  label: const Text('LOG'),
                  avatar: const Icon(Icons.receipt_long_rounded, size: 16),
                  selectedColor: AppColors.purple.withValues(alpha: 0.35),
                  backgroundColor: AppColors.bgCard,
                  labelStyle: const TextStyle(color: Colors.white),
                  checkmarkColor: AppColors.cyan,
                ),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    allow,
                    const SizedBox(height: 8),
                    deny,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: log),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: allow),
                  const SizedBox(width: 8),
                  Expanded(child: deny),
                  const SizedBox(width: 8),
                  log,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addRule,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ANADIR REGLA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _responsivePair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(children: [first, const SizedBox(height: 8), second]);
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 8),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _portDropdown() {
    const ports = [0, 80, 443, 22, 3306, 53, 3389];
    return DropdownButtonFormField<int>(
      key: ValueKey(_rulePort),
      initialValue: _rulePort,
      dropdownColor: AppColors.bgCard,
      decoration: _inputDecoration('Puerto'),
      items: ports
          .map(
            (port) => DropdownMenuItem<int>(
              value: port,
              child: Text(port == 0 ? '*' : '$port'),
            ),
          )
          .toList(),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      onChanged: (value) => setState(() => _rulePort = value ?? 0),
    );
  }

  Widget _buildResultsPanel() {
    final resultColor = _victory ? AppColors.cyan : AppColors.pink;
    final sectionLabel = _victory
        ? 'DEFENSA ESTABLE'
        : _defeat
        ? 'MISION FALLIDA'
        : 'POLITICA INCOMPLETA';
    final title = _victory
        ? 'Firewall operativo'
        : _defeat
        ? 'Firewall comprometido'
        : 'Ajusta las reglas';
    final subtitle = _victory
        ? 'Todas las rutas han sido clasificadas correctamente.'
        : _defeat
        ? 'La politica dejo rutas mal clasificadas o agotaste los intentos.'
        : 'Para completar el nivel debes acertar todas las rutas.';
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(sectionLabel),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: resultColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultTile(
                  label: 'Puntuacion',
                  value: '$_score',
                  color: resultColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultTile(
                  label: 'Criticos',
                  value: '$_criticalFailures',
                  color: _criticalFailures == 0
                      ? AppColors.cyan
                      : AppColors.pink,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultTile(
                  label: 'Falsos +',
                  value: '$_falsePositives',
                  color: _falsePositives <= 2 ? AppColors.cyan : AppColors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionLabel('LOGS'),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _LogCard(log: _logs[index]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _defeat
                      ? _reiniciarNivel
                      : () => setState(() => _phase = _FirewallPhase.builder),
                  icon: Icon(
                    _defeat ? Icons.refresh_rounded : Icons.tune_rounded,
                  ),
                  label: Text(_defeat ? 'REINTENTAR' : 'AJUSTAR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan,
                    side: BorderSide(
                      color: AppColors.cyan.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _victory || _defeat
                      ? _volverAlMapa
                      : _runSimulation,
                  icon: Icon(
                    _victory || _defeat
                        ? Icons.map_rounded
                        : Icons.replay_rounded,
                  ),
                  label: Text(
                    _victory
                        ? 'FINALIZAR'
                        : _defeat
                        ? 'SALIR'
                        : 'PROBAR',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: resultColor,
                    foregroundColor: _victory ? AppColors.bgMain : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficPacket {
  final String id;
  final String title;
  final _Zone source;
  final _Zone destination;
  final _Protocol protocol;
  final int port;
  final _Decision expected;
  final bool malicious;
  final bool critical;
  final String lesson;

  const _TrafficPacket({
    required this.id,
    required this.title,
    required this.source,
    required this.destination,
    required this.protocol,
    required this.port,
    required this.expected,
    required this.lesson,
    this.malicious = false,
    this.critical = false,
  });
}

class _FirewallRule {
  final String label;
  final _Zone source;
  final _Zone destination;
  final _Protocol protocol;
  final int port;
  final _Decision decision;
  final bool log;

  const _FirewallRule({
    required this.label,
    required this.source,
    required this.destination,
    required this.protocol,
    required this.port,
    required this.decision,
    required this.log,
  });

  bool matches(_TrafficPacket packet) {
    final sourceOk = source == _Zone.any || source == packet.source;
    final destinationOk =
        destination == _Zone.any || destination == packet.destination;
    final protocolOk = protocol == _Protocol.any || protocol == packet.protocol;
    final portOk = port == 0 || port == packet.port;
    return sourceOk && destinationOk && protocolOk && portOk;
  }
}

class _FirewallResult {
  final _Decision action;
  final String ruleLabel;
  final bool logged;

  const _FirewallResult({
    required this.action,
    required this.ruleLabel,
    required this.logged,
  });
}

class _SimulationLog {
  final _TrafficPacket packet;
  final _Decision action;
  final String matchedRuleLabel;
  final bool logged;
  final bool correct;
  final String note;

  const _SimulationLog({
    required this.packet,
    required this.action,
    required this.matchedRuleLabel,
    required this.logged,
    required this.correct,
    required this.note,
  });
}

String _zoneLabel(_Zone zone) {
  return switch (zone) {
    _Zone.any => 'Cualquiera',
    _Zone.internet => 'Internet',
    _Zone.web => 'Web DMZ',
    _Zone.database => 'Base datos',
    _Zone.admin => 'Admin',
    _Zone.lan => 'LAN',
  };
}

String _protocolLabel(_Protocol protocol) {
  return switch (protocol) {
    _Protocol.any => '*',
    _Protocol.tcp => 'TCP',
    _Protocol.udp => 'UDP',
    _Protocol.icmp => 'ICMP',
  };
}

String _decisionLabel(_Decision decision) {
  return decision == _Decision.allow ? 'ALLOW' : 'DENY';
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
    filled: true,
    fillColor: AppColors.bgCard,
    isDense: true,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.cyan),
    ),
  );
}

class _EnumDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      dropdownColor: AppColors.bgCard,
      decoration: _inputDecoration(label),
      items: values
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
          )
          .toList(),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.purple,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirewallScrollBehavior extends MaterialScrollBehavior {
  const _FirewallScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
}

class _PacketCard extends StatelessWidget {
  final _TrafficPacket packet;

  const _PacketCard({required this.packet});

  @override
  Widget build(BuildContext context) {
    final color = packet.malicious ? AppColors.pink : AppColors.cyan;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                packet.malicious
                    ? Icons.warning_amber_rounded
                    : Icons.public_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  packet.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PacketFact(label: 'Origen', value: _zoneLabel(packet.source)),
          _PacketFact(label: 'Destino', value: _zoneLabel(packet.destination)),
          _PacketFact(
            label: 'Servicio',
            value:
                '${_protocolLabel(packet.protocol)} ${packet.port == 0 ? '*' : packet.port}',
          ),
        ],
      ),
    );
  }
}

class _PacketFact extends StatelessWidget {
  final String label;
  final String value;

  const _PacketFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == AppColors.cyan
            ? AppColors.bgMain
            : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  final int current;
  final int total;
  final int correct;

  const _ProgressRail({
    required this.current,
    required this.total,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: current / total,
          minHeight: 7,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
        ),
        const SizedBox(height: 8),
        Text(
          '$current/$total inspeccionados - $correct aciertos',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MiniLog extends StatelessWidget {
  final _SimulationLog log;

  const _MiniLog({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: log.correct
            ? AppColors.cyan.withValues(alpha: 0.10)
            : AppColors.pink.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: log.correct
              ? AppColors.cyan.withValues(alpha: 0.28)
              : AppColors.pink.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        log.note,
        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
      ),
    );
  }
}

class _GuideStep {
  final String title;
  final String detail;

  const _GuideStep({required this.title, required this.detail});
}

class _GuidedChecklist extends StatelessWidget {
  final List<bool> completed;

  const _GuidedChecklist({required this.completed});

  static const _steps = [
    _GuideStep(
      title: 'Abrir web HTTPS',
      detail: 'La web publica debe aceptar trafico seguro.',
    ),
    _GuideStep(
      title: 'Conectar web con DB',
      detail: 'La aplicacion web puede consultar su base de datos.',
    ),
    _GuideStep(
      title: 'Resolver DNS interno',
      detail: 'La red interna necesita resolver dominios.',
    ),
    _GuideStep(
      title: 'Admin controlado',
      detail: 'La administracion debe salir de un origen fiable.',
    ),
    _GuideStep(
      title: 'Cerrar el resto',
      detail: 'Lo no autorizado cae al final por defecto.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final done = completed.where((value) => value).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: AppColors.cyan, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ruta recomendada',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$done/${_steps.length}',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: done / _steps.length,
            minHeight: 5,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
          ),
          const SizedBox(height: 8),
          Text(
            'Pulsa VER PISTA si necesitas parametros, pero crea cada regla a mano.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _steps.length; i++) ...[
            _GuideStepRow(
              step: _steps[i],
              completed: i < completed.length && completed[i],
            ),
            if (i != _steps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _GuideStepRow extends StatelessWidget {
  final _GuideStep step;
  final bool completed;

  const _GuideStepRow({required this.step, required this.completed});

  @override
  Widget build(BuildContext context) {
    final color = completed ? AppColors.cyan : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: completed
                ? AppColors.cyan.withValues(alpha: 0.18)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Icon(
            completed ? Icons.check_rounded : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  color: completed ? Colors.white : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.detail,
                style: TextStyle(
                  color: color.withValues(alpha: completed ? 0.86 : 0.72),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RuleHintCard extends StatelessWidget {
  final _FirewallRule rule;
  final VoidCallback onClose;

  const _RuleHintCard({required this.rule, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = rule.decision == _Decision.allow
        ? AppColors.cyan
        : AppColors.pink;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rule.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ocultar pista',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HintChip(label: 'Origen', value: _zoneLabel(rule.source)),
              _HintChip(label: 'Destino', value: _zoneLabel(rule.destination)),
              _HintChip(label: 'Proto', value: _protocolLabel(rule.protocol)),
              _HintChip(
                label: 'Puerto',
                value: rule.port == 0 ? '*' : '${rule.port}',
              ),
              _HintChip(label: 'Accion', value: _decisionLabel(rule.decision)),
              _HintChip(label: 'Log', value: rule.log ? 'SI' : 'NO'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Selecciona esos valores manualmente en el editor y pulsa ANADIR REGLA.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  final String value;

  const _HintChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActionChoice extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChoice({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.20) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? color : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'La tabla esta vacia. Revisa la ruta, pide una pista si hace falta y crea la primera regla manualmente.',
        style: TextStyle(color: AppColors.textMuted, height: 1.5),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final int index;
  final _FirewallRule rule;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.index,
    required this.rule,
    required this.onUp,
    required this.onDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = rule.decision == _Decision.allow
        ? AppColors.cyan
        : AppColors.pink;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_zoneLabel(rule.source)} -> ${_zoneLabel(rule.destination)}  '
                  '${_protocolLabel(rule.protocol)}:${rule.port == 0 ? '*' : rule.port}  '
                  '${_decisionLabel(rule.decision)}${rule.log ? '  LOG' : ''}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Subir',
            onPressed: onUp,
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            color: AppColors.textMuted,
          ),
          IconButton(
            tooltip: 'Bajar',
            onPressed: onDown,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            color: AppColors.textMuted,
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.pink,
          ),
        ],
      ),
    );
  }
}

class _MissionCompletedDialog extends StatelessWidget {
  final int score;
  final bool trainingMode;
  final VoidCallback onReview;
  final VoidCallback onContinue;

  const _MissionCompletedDialog({
    required this.score,
    required this.trainingMode,
    required this.onReview,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgMain,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.50)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.20),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.cyan,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'MISION COMPLETADA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trainingMode
                    ? 'Firewall superado en modo entrenamiento.'
                    : 'Firewall desplegado y politica validada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '$score XP',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              if (trainingMode) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'Modo entrenamiento - progreso no guardado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final reviewButton = OutlinedButton(
                    onPressed: onReview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      side: BorderSide(
                        color: AppColors.purple.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'VER INFORME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                  final continueButton = ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: AppColors.bgMain,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        reviewButton,
                        const SizedBox(height: 10),
                        continueButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: reviewButton),
                      const SizedBox(width: 10),
                      Expanded(child: continueButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionFailedDialog extends StatelessWidget {
  final int score;
  final int attempts;
  final int maxAttempts;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const _MissionFailedDialog({
    required this.score,
    required this.attempts,
    required this.maxAttempts,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgMain,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pink.withValues(alpha: 0.50)),
            boxShadow: [
              BoxShadow(
                color: AppColors.pink.withValues(alpha: 0.20),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gpp_bad_rounded,
                color: AppColors.pink,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'MISION FALLIDA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.pink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El firewall dejo rutas criticas abiertas o agotaste los intentos de politica.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.66),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _HintChip(label: 'Puntuacion', value: '$score XP'),
                  _HintChip(label: 'Intentos', value: '$attempts/$maxAttempts'),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final retryButton = OutlinedButton(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: BorderSide(
                        color: AppColors.cyan.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'REINTENTAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  );
                  final exitButton = ElevatedButton(
                    onPressed: onExit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'VOLVER AL MAPA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        retryButton,
                        const SizedBox(height: 10),
                        exitButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: retryButton),
                      const SizedBox(width: 10),
                      Expanded(child: exitButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final _SimulationLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = log.correct ? AppColors.cyan : AppColors.pink;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.action == _Decision.allow
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_rounded,
                color: color,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_decisionLabel(log.action)} // ${log.packet.title}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (log.logged)
                const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.purple,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_zoneLabel(log.packet.source)} -> ${_zoneLabel(log.packet.destination)} '
            '${_protocolLabel(log.packet.protocol)}:${log.packet.port == 0 ? '*' : log.packet.port}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            log.note,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coincidencia: ${log.matchedRuleLabel}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FirewallMapPainter extends CustomPainter {
  final _TrafficPacket packet;
  final _Decision action;
  final double progress;
  final int rules;
  final int blocked;
  final int allowed;

  _FirewallMapPainter({
    required this.packet,
    required this.action,
    required this.progress,
    required this.rules,
    required this.blocked,
    required this.allowed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    final nodes = <_Zone, Offset>{
      _Zone.internet: Offset(size.width * 0.12, size.height * 0.50),
      _Zone.web: Offset(size.width * 0.72, size.height * 0.27),
      _Zone.database: Offset(size.width * 0.84, size.height * 0.54),
      _Zone.admin: Offset(size.width * 0.70, size.height * 0.78),
      _Zone.lan: Offset(size.width * 0.52, size.height * 0.78),
    };
    final firewall = Offset(size.width * 0.42, size.height * 0.50);

    _drawConnections(canvas, nodes, firewall);
    _drawFirewall(canvas, firewall, size);
    for (final entry in nodes.entries) {
      _drawNode(
        canvas,
        entry.value,
        _zoneLabel(entry.key),
        _nodeColor(entry.key),
      );
    }

    _drawPacket(
      canvas,
      nodes[packet.source]!,
      firewall,
      nodes[packet.destination]!,
    );
    _drawCounters(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.07)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.cyan.withValues(alpha: 0.10), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _drawConnections(
    Canvas canvas,
    Map<_Zone, Offset> nodes,
    Offset firewall,
  ) {
    final line = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.25)
      ..strokeWidth = 2;

    for (final entry in nodes.entries) {
      canvas.drawLine(entry.value, firewall, line);
    }
  }

  void _drawFirewall(Canvas canvas, Offset center, Size size) {
    final rect = Rect.fromCenter(
      center: center,
      width: math.min(140, size.width * 0.20),
      height: math.min(190, size.height * 0.48),
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawRRect(
      rrect,
      Paint()..color = AppColors.bgCard.withValues(alpha: 0.95),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppColors.cyan.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final brickPaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double y = rect.top + 24; y < rect.bottom - 14; y += 24) {
      canvas.drawLine(
        Offset(rect.left + 12, y),
        Offset(rect.right - 12, y),
        brickPaint,
      );
    }
    for (double y = rect.top + 12; y < rect.bottom - 16; y += 24) {
      final offset = ((y / 24).floor().isEven) ? 0.0 : 18.0;
      for (double x = rect.left + 18 + offset; x < rect.right - 10; x += 36) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 20), brickPaint);
      }
    }

    _drawText(
      canvas,
      'FIREWALL',
      center + const Offset(0, -8),
      AppColors.cyan,
      13,
      bold: true,
      align: TextAlign.center,
    );
    _drawText(
      canvas,
      '$rules reglas',
      center + const Offset(0, 14),
      AppColors.textMuted,
      11,
      align: TextAlign.center,
    );
  }

  void _drawNode(Canvas canvas, Offset center, String label, Color color) {
    canvas.drawCircle(
      center,
      35,
      Paint()..color = color.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..color = color.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(center, 12, Paint()..color = color);
    _drawText(
      canvas,
      label,
      center + const Offset(0, 48),
      Colors.white.withValues(alpha: 0.86),
      11,
      align: TextAlign.center,
    );
  }

  void _drawPacket(Canvas canvas, Offset source, Offset firewall, Offset dest) {
    final denied = action == _Decision.deny;
    final color = denied
        ? AppColors.pink
        : packet.malicious
        ? AppColors.pink
        : AppColors.cyan;

    final Offset packetPos;
    if (denied) {
      final t = (progress / 0.74).clamp(0.0, 1.0).toDouble();
      packetPos = Offset.lerp(
        source,
        firewall,
        Curves.easeOutCubic.transform(t),
      )!;
      _drawPacketTrail(canvas, source, packetPos, color);
      if (progress > 0.74) {
        _drawBlockedPulse(canvas, firewall, color);
      }
    } else {
      final firstLeg = progress < 0.48;
      final t = firstLeg ? progress / 0.48 : (progress - 0.48) / 0.52;
      final from = firstLeg ? source : firewall;
      final to = firstLeg ? firewall : dest;
      packetPos = Offset.lerp(from, to, Curves.easeInOutCubic.transform(t))!;
      _drawPacketTrail(canvas, from, packetPos, color);
    }

    canvas.drawCircle(
      packetPos,
      13 + math.sin(progress * math.pi * 2) * 2,
      Paint()..color = color.withValues(alpha: 0.20),
    );
    canvas.drawCircle(packetPos, 6, Paint()..color = color);

    final label =
        '${_protocolLabel(packet.protocol)}:${packet.port == 0 ? '*' : packet.port}';
    _drawText(
      canvas,
      label,
      packetPos + const Offset(0, -26),
      color,
      10,
      bold: true,
      align: TextAlign.center,
    );
  }

  void _drawPacketTrail(Canvas canvas, Offset from, Offset to, Color color) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color.withValues(alpha: 0.32)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBlockedPulse(Canvas canvas, Offset center, Color color) {
    final pulse = ((progress - 0.74) / 0.26).clamp(0.0, 1.0).toDouble();
    canvas.drawCircle(
      center,
      22 + pulse * 18,
      Paint()
        ..color = color.withValues(alpha: (1 - pulse) * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _drawText(
      canvas,
      'DENY',
      center + const Offset(0, 44),
      color,
      11,
      bold: true,
      align: TextAlign.center,
    );
  }

  void _drawCounters(Canvas canvas, Size size) {
    _drawText(
      canvas,
      'ALLOW $allowed   DENY $blocked',
      Offset(size.width - 120, 26),
      AppColors.textMuted,
      11,
      align: TextAlign.center,
    );
  }

  Color _nodeColor(_Zone zone) {
    return switch (zone) {
      _Zone.internet => AppColors.pink,
      _Zone.web => AppColors.cyan,
      _Zone.database => AppColors.purple,
      _Zone.admin => const Color(0xFFFFC857),
      _Zone.lan => const Color(0xFF10F985),
      _Zone.any => Colors.white,
    };
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double size, {
    bool bold = false,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FirewallMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.packet != packet ||
        oldDelegate.action != action ||
        oldDelegate.rules != rules ||
        oldDelegate.blocked != blocked ||
        oldDelegate.allowed != allowed;
  }
}

class _IntroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.purple.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.cyan.withValues(alpha: 0.16), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
