import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../games/nivel_19/components/soc_alert.dart';
import '../games/nivel_19/nivel19_game.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';

// ── Fases del tutorial ────────────────────────────────────────────────────────
enum _TutorialStep { alertCard, btnEscalar, btnIgnorar, btnContener, timer, done }

class Nivel19Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel19Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel19Screen> createState() => _Nivel19ScreenState();
}

class _Nivel19ScreenState extends State<Nivel19Screen>
    with TickerProviderStateMixin {
  final Nivel19Game _game = Nivel19Game();

  bool _loading = true;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;

  // Tutorial
  _TutorialStep _tutorialStep = _TutorialStep.alertCard;

  // Temporizador de alerta
  Timer? _alertTimer;
  int _segundosRestantes = Nivel19Game.segundosRonda1;
  double _timerProgress = 1.0;

  // Animación de entrada de tarjeta
  late AnimationController _cardSlideCtrl;
  late Animation<Offset> _cardSlideAnim;
  late Animation<double> _cardFadeAnim;

  // Animación de propagación (red background)
  late AnimationController _propagacionCtrl;

  // Feedback de acción (flash verde/rojo)
  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackOpacity;
  Color _feedbackColor = Colors.transparent;

  // GlobalKeys para el tutorial highlight
  final GlobalKey _keyCard = GlobalKey();
  final GlobalKey _keyEscalar = GlobalKey();
  final GlobalKey _keyIgnorar = GlobalKey();
  final GlobalKey _keyContener = GlobalKey();
  final GlobalKey _keyTimer = GlobalKey();

  @override
  void initState() {
    super.initState();
    MusicService().stopMusic();

    _cardSlideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1.0, // empieza visible para que el tutorial muestre la tarjeta
    );
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardSlideCtrl, curve: Curves.easeOut));

    // La opacidad arranca en 0 y solo sube en el último 35% del recorrido
    _cardFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardSlideCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _propagacionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _feedbackOpacity = CurvedAnimation(
      parent: _feedbackCtrl,
      curve: Curves.easeOut,
    );

    _setupLevel();
  }

  Future<void> _setupLevel() async {
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final data = await FirestoreService.obtenerUsuario();
        final level = (data['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = level > 19;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso nivel 19: $e');
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _cardSlideCtrl.dispose();
    _propagacionCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // ── Timer de alerta ────────────────────────────────────────────────────────

  void _iniciarTimerAlerta() {
    _alertTimer?.cancel();
    final total = _game.segundosActuales;
    setState(() {
      _segundosRestantes = total;
      _timerProgress = 1.0;
    });

    _alertTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _segundosRestantes--;
        _timerProgress = _segundosRestantes / total;
      });
      if (_segundosRestantes <= 0) {
        t.cancel();
        _onAlertaExpirada();
      }
    });

    _cardSlideCtrl.forward(from: 0);
  }

  void _detenerTimer() {
    _alertTimer?.cancel();
  }

  void _onAlertaExpirada() {
    if (_game.fase != Nivel19Phase.ronda1 &&
        _game.fase != Nivel19Phase.ronda2) {
      return;
    }
    _mostrarFeedback(correcto: false, propagacion: true);
    setState(() => _game.alertaExpirada());
    _postAccion();
  }

  // ── Acciones del jugador ───────────────────────────────────────────────────

  void _responder(AlertAccion accion) {
    if (_game.fase != Nivel19Phase.ronda1 &&
        _game.fase != Nivel19Phase.ronda2) {
      return;
    }
    _detenerTimer();
    final correcto = _game.responder(accion);
    _mostrarFeedback(correcto: correcto, propagacion: false);
    setState(() {});
    _postAccion();
  }

  void _postAccion() {
    final fase = _game.fase;
    if (fase == Nivel19Phase.fallado) {
      Future.delayed(const Duration(milliseconds: 900), _mostrarDerrota);
    } else if (fase == Nivel19Phase.completado) {
      Future.delayed(const Duration(milliseconds: 900), () {
        _guardarProgreso();
        _mostrarVictoria();
      });
    } else if (fase == Nivel19Phase.entreRondas) {
      // No lanzar siguiente tarjeta aún; se hace desde el diálogo
    } else {
      // Ocultar la tarjeta actual antes de mostrar la siguiente
      _cardSlideCtrl.value = 0;
      Future.delayed(const Duration(milliseconds: 800), _iniciarTimerAlerta);
    }
  }

  void _mostrarFeedback({required bool correcto, required bool propagacion}) {
    setState(() {
      _feedbackColor = correcto
          ? const Color(0xFF00FF88)
          : propagacion
              ? const Color(0xFFFF4444)
              : const Color(0xFFFF8800);
    });
    _feedbackCtrl.forward(from: 0).then((_) {
      _feedbackCtrl.reverse();
    });
  }

  // ── Tutorial ───────────────────────────────────────────────────────────────

  void _avanzarTutorial() {
    setState(() {
      switch (_tutorialStep) {
        case _TutorialStep.alertCard:
          _tutorialStep = _TutorialStep.btnEscalar;
        case _TutorialStep.btnEscalar:
          _tutorialStep = _TutorialStep.btnIgnorar;
        case _TutorialStep.btnIgnorar:
          _tutorialStep = _TutorialStep.btnContener;
        case _TutorialStep.btnContener:
          _tutorialStep = _TutorialStep.timer;
        case _TutorialStep.timer:
          _tutorialStep = _TutorialStep.done;
          _game.iniciarRonda1();
          _iniciarTimerAlerta();
        case _TutorialStep.done:
          break;
      }
    });
  }

  // ── Progreso ───────────────────────────────────────────────────────────────

  Future<void> _guardarProgreso() async {
    if (_progresoGuardado || _nivelYaCompletado) return;
    _progresoGuardado = true;
    try {
      await FirestoreService.guardarPuntuacion(
        puntos: _game.xp,
        nivelCompletado: 19,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
        nivel: 19,
        mision: 19,
        puntos: _game.xp,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso nivel 19: $e');
    }
  }

  // ── Diálogos de resultado ──────────────────────────────────────────────────

  void _mostrarVictoria() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        exito: true,
        xp: _game.xp,
        aciertos: _game.aciertos,
        errores: _game.errores,
        expiradas: _game.alertasExpiradas,
        nivelRendimiento: _game.nivelRendimiento,
        entrenamiento: _nivelYaCompletado,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Nivel19Screen(soloEntrenamiento: widget.soloEntrenamiento),
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

  void _mostrarDerrota() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        exito: false,
        xp: _game.xp,
        aciertos: _game.aciertos,
        errores: _game.errores,
        expiradas: _game.alertasExpiradas,
        nivelRendimiento: _game.nivelRendimiento,
        entrenamiento: _nivelYaCompletado,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Nivel19Screen(soloEntrenamiento: widget.soloEntrenamiento),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    // Pantalla de intro con Fractura
    if (_game.fase == Nivel19Phase.intro) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter(progress: 0))),
              FracturaDialogo(
                subtitulo: 'NIVEL 19 // SOC-CENTRO DE OPERACIONES DE SEGURIDAD',
                textoBotonFinal: 'JUGAR',
                usarVoz: true,
                permitirSaltarIntro: true,
                permitirCambiarVoz: true,
                velocidadVoz: 1.00,
                milisegundosPorCaracter: 20,
                dialogos: const [
                  'Bienvenido al SOC. Aquí las amenazas no esperan.',
                  'Recibirás alertas en tiempo real de nuestro SIEM. Cada una tiene un contador.',
                  'Tú decides: ¿Escalar al equipo de respuesta? ¿Ignorar como falso positivo? ¿Contener el sistema afectado?',
                  'Una decisión errónea tiene consecuencias. No actuar a tiempo también.',
                  'Ronda 1: tendrás 14 segundos por alerta. Ronda 2: solo 7. Es un ataque coordinado.',
                  'El mapa de red del fondo muestra cómo se propagan las amenazas ignoradas. No dejes que llegue al núcleo.',
                ],
                onFinalizado: () {
                  MusicService().playNivel17Music();
                  setState(() => _game.fase = Nivel19Phase.tutorial);
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
        child: Stack(
          children: [
            // Fondo: mapa de red animado
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _propagacionCtrl,
                builder: (_, x) => CustomPaint(
                  painter: _GridPainter(
                    progress: _propagacionCtrl.value,
                    threatLevel: _game.errores + _game.alertasExpiradas,
                  ),
                ),
              ),
            ),

            // Flash de feedback
            AnimatedBuilder(
              animation: _feedbackOpacity,
              builder: (_, y) => Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: _feedbackColor.withValues(alpha: _feedbackOpacity.value * 0.18),
                  ),
                ),
              ),
            ),

            // Contenido principal
            Column(
              children: [
                _buildTopBar(),
                if (_nivelYaCompletado) _buildTrainingBanner(),
                Expanded(child: _buildBody()),
              ],
            ),

            // Overlay de tutorial
            if (_game.fase == Nivel19Phase.tutorial)
              _TutorialOverlay(
                step: _tutorialStep,
                keyCard: _keyCard,
                keyEscalar: _keyEscalar,
                keyIgnorar: _keyIgnorar,
                keyContener: _keyContener,
                keyTimer: _keyTimer,
                onNext: _avanzarTutorial,
              ),

            // Panel entre rondas
            if (_game.fase == Nivel19Phase.entreRondas)
              _EntreRondasOverlay(
                aciertos: _game.aciertos,
                errores: _game.errores,
                xp: _game.xp,
                onContinuar: () {
                  setState(() => _game.iniciarRonda2());
                  _iniciarTimerAlerta();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.cyan.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver al mapa',
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cyan, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          const Text(
            'SOC — NIVEL 19',
            style: TextStyle(
              color: AppColors.cyan,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Indicador de ronda
          _RondaChip(
            ronda: _game.fase == Nivel19Phase.ronda2 ? 2 : 1,
            activa: _game.fase == Nivel19Phase.ronda1 || _game.fase == Nivel19Phase.ronda2,
          ),
          const SizedBox(width: 12),
          // Vidas
          Row(
            children: List.generate(
              Nivel19Game.vidasIniciales,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.favorite,
                  size: 16,
                  color: i < _game.vidas ? Colors.redAccent : Colors.grey.shade800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // XP
          Text(
            '${_game.xp} XP',
            style: const TextStyle(
              color: AppColors.cyan,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2A1A00),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Text(
        'MODO ENTRENAMIENTO',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFBA7517),
          fontFamily: 'monospace',
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(builder: (context, constraints) {
      final alerta = _game.alertaActual;
      final enJuego = _game.fase == Nivel19Phase.ronda1 ||
          _game.fase == Nivel19Phase.ronda2 ||
          _game.fase == Nivel19Phase.tutorial;

      if (!enJuego || alerta == null) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          const SizedBox(height: 12),
          // Barra de progreso del timer
          Key(_keyTimer.toString()) == const Key('')
              ? const SizedBox.shrink()
              : const SizedBox.shrink(),
          _buildTimerBar(),
          const SizedBox(height: 16),
          // Tarjeta de alerta
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SlideTransition(
                    position: _cardSlideAnim,
                    child: FadeTransition(
                      opacity: _cardFadeAnim,
                      child: _AlertCard(
                        key: _keyCard,
                        alerta: alerta,
                        tutorialActive: _game.fase == Nivel19Phase.tutorial &&
                            _tutorialStep == _TutorialStep.alertCard,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botones de acción
                  _buildActionButtons(alerta),
                  const SizedBox(height: 24),
                  // Feedback de la última alerta
                  if (_game.ultimaAccionCorrecta != null)
                    _FeedbackBanner(
                      correcto: _game.ultimaAccionCorrecta!,
                      explicacion: _game.ultimaExplicacion,
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTimerBar() {
    final color = _timerProgress > 0.5
        ? AppColors.cyan
        : _timerProgress > 0.25
            ? Colors.orange
            : Colors.red;

    return Padding(
      key: _keyTimer,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIEMPO DE RESPUESTA',
                style: TextStyle(
                  color: color,
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${_segundosRestantes}s',
                style: TextStyle(
                  color: color,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _timerProgress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SocAlert alerta) {
    final enTutorial = _game.fase == Nivel19Phase.tutorial;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            key: _keyEscalar,
            label: 'ESCALAR',
            icono: Icons.arrow_upward_rounded,
            color: const Color(0xFF378ADD),
            descripcion: 'Sube al equipo de respuesta',
            destacado: enTutorial && _tutorialStep == _TutorialStep.btnEscalar,
            onPressed: enTutorial
                ? (_tutorialStep == _TutorialStep.btnEscalar ? _avanzarTutorial : null)
                : () => _responder(AlertAccion.escalar),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            key: _keyIgnorar,
            label: 'IGNORAR',
            icono: Icons.block_rounded,
            color: const Color(0xFF888888),
            descripcion: 'Falso positivo',
            destacado: enTutorial && _tutorialStep == _TutorialStep.btnIgnorar,
            onPressed: enTutorial
                ? (_tutorialStep == _TutorialStep.btnIgnorar ? _avanzarTutorial : null)
                : () => _responder(AlertAccion.ignorar),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            key: _keyContener,
            label: 'CONTENER',
            icono: Icons.shield_rounded,
            color: const Color(0xFFD4537E),
            descripcion: 'Aislar sistema afectado',
            destacado: enTutorial && _tutorialStep == _TutorialStep.btnContener,
            onPressed: enTutorial
                ? (_tutorialStep == _TutorialStep.btnContener ? _avanzarTutorial : null)
                : () => _responder(AlertAccion.contener),
          ),
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _RondaChip extends StatelessWidget {
  final int ronda;
  final bool activa;

  const _RondaChip({required this.ronda, required this.activa});

  @override
  Widget build(BuildContext context) {
    final color = ronda == 2 ? Colors.redAccent : AppColors.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        'RONDA $ronda${ronda == 2 ? ' ⚡' : ''}',
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SocAlert alerta;
  final bool tutorialActive;

  const _AlertCard({super.key, required this.alerta, this.tutorialActive = false});

  Color get _severidadColor {
    switch (alerta.severidad) {
      case AlertSeveridad.baja:
        return const Color(0xFF1D9E75);
      case AlertSeveridad.media:
        return const Color(0xFFBA7517);
      case AlertSeveridad.alta:
        return const Color(0xFFD4537E);
      case AlertSeveridad.critica:
        return Colors.red;
    }
  }

  String get _severidadLabel {
    switch (alerta.severidad) {
      case AlertSeveridad.baja:
        return 'BAJA';
      case AlertSeveridad.media:
        return 'MEDIA';
      case AlertSeveridad.alta:
        return 'ALTA';
      case AlertSeveridad.critica:
        return 'CRÍTICA';
    }
  }

  String get _categoriaLabel {
    switch (alerta.categoria) {
      case AlertCategoria.autenticacion:
        return 'AUTH';
      case AlertCategoria.red:
        return 'RED';
      case AlertCategoria.endpoint:
        return 'ENDPOINT';
      case AlertCategoria.malware:
        return 'MALWARE';
      case AlertCategoria.sistema:
        return 'SISTEMA';
      case AlertCategoria.acceso:
        return 'ACCESO';
    }
  }

  IconData get _categoriaIcono {
    switch (alerta.categoria) {
      case AlertCategoria.autenticacion:
        return Icons.lock_outline;
      case AlertCategoria.red:
        return Icons.wifi_rounded;
      case AlertCategoria.endpoint:
        return Icons.computer_rounded;
      case AlertCategoria.malware:
        return Icons.coronavirus_outlined;
      case AlertCategoria.sistema:
        return Icons.dns_rounded;
      case AlertCategoria.acceso:
        return Icons.person_search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tutorialActive
              ? const Color(0xFF3399FF)
              : _severidadColor.withValues(alpha: 0.5),
          width: tutorialActive ? 2.5 : 1.5,
        ),
        boxShadow: tutorialActive
            ? [
                BoxShadow(
                  color: const Color(0xFF3399FF).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [
                BoxShadow(
                  color: _severidadColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la alerta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _severidadColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(_categoriaIcono, color: _severidadColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alerta.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SeveridadBadge(label: _severidadLabel, color: _severidadColor),
                const SizedBox(width: 8),
                _CategoriaBadge(label: _categoriaLabel),
              ],
            ),
          ),
          // Cuerpo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              alerta.descripcion,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          // ID de alerta
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Text(
              'ALERT-ID: ${alerta.id.toUpperCase()}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeveridadBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SeveridadBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _CategoriaBadge extends StatelessWidget {
  final String label;

  const _CategoriaBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontFamily: 'monospace',
          fontSize: 9,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  final String descripcion;
  final bool destacado;
  final VoidCallback? onPressed;

  const _ActionButton({
    super.key,
    required this.label,
    required this.icono,
    required this.color,
    required this.descripcion,
    this.destacado = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: destacado
            ? [
                BoxShadow(
                  color: const Color(0xFF3399FF).withValues(alpha: 0.6),
                  blurRadius: 18,
                  spreadRadius: 3,
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: onPressed != null
                  ? color.withValues(alpha: destacado ? 0.25 : 0.15)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: destacado
                    ? const Color(0xFF3399FF)
                    : onPressed != null
                        ? color.withValues(alpha: 0.6)
                        : Colors.white12,
                width: destacado ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icono,
                  color: onPressed != null ? color : Colors.white24,
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed != null ? color : Colors.white24,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descripcion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onPressed != null
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.white12,
                    fontSize: 9,
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

class _FeedbackBanner extends StatelessWidget {
  final bool correcto;
  final String explicacion;

  const _FeedbackBanner({required this.correcto, required this.explicacion});

  @override
  Widget build(BuildContext context) {
    final color = correcto ? const Color(0xFF00FF88) : Colors.orangeAccent;
    final icono = correcto ? Icons.check_circle_outline : Icons.info_outline;
    final titulo = correcto ? 'DECISIÓN CORRECTA' : 'ATENCIÓN';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explicacion,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.4,
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

// ── Overlay de tutorial ────────────────────────────────────────────────────────

class _TutorialOverlay extends StatelessWidget {
  final _TutorialStep step;
  final GlobalKey keyCard;
  final GlobalKey keyEscalar;
  final GlobalKey keyIgnorar;
  final GlobalKey keyContener;
  final GlobalKey keyTimer;
  final VoidCallback onNext;

  const _TutorialOverlay({
    required this.step,
    required this.keyCard,
    required this.keyEscalar,
    required this.keyIgnorar,
    required this.keyContener,
    required this.keyTimer,
    required this.onNext,
  });

  String get _mensaje {
    switch (step) {
      case _TutorialStep.alertCard:
        return 'Cada alerta llega desde el SIEM con título, descripción, severidad y categoría. Lee bien los detalles antes de decidir.';
      case _TutorialStep.btnEscalar:
        return 'ESCALAR: envía el incidente al equipo de respuesta (Nivel 2). Úsalo cuando la amenaza sea real pero necesites más análisis.';
      case _TutorialStep.btnIgnorar:
        return 'IGNORAR: descarta la alerta como falso positivo. Correcto para tráfico o actividad legítima esperada.';
      case _TutorialStep.btnContener:
        return 'CONTENER: aísla el sistema afectado de la red. Para infecciones activas o compromisos confirmados.';
      case _TutorialStep.timer:
        return 'La barra muestra el tiempo que tienes para responder. Si se agota, la amenaza avanza y pierdes una vida.';
      case _TutorialStep.done:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (step == _TutorialStep.done) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onNext,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Stack(
          children: [
            // Tooltip en la parte inferior
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3399FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3399FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_outlined, color: Color(0xFF3399FF), size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'TUTORIAL SOC',
                            style: TextStyle(
                              color: Color(0xFF3399FF),
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'TOCA PARA CONTINUAR',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontFamily: 'monospace',
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _mensaje,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
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

// ── Overlay entre rondas ───────────────────────────────────────────────────────

class _EntreRondasOverlay extends StatelessWidget {
  final int aciertos;
  final int errores;
  final int xp;
  final VoidCallback onContinuar;

  const _EntreRondasOverlay({
    required this.aciertos,
    required this.errores,
    required this.xp,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.3),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              const Text(
                'RONDA 1 COMPLETADA',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚡ EL ATACANTE INTENSIFICA EL ASALTO',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _StatRow(label: 'Alertas correctas', value: '$aciertos / 8', color: const Color(0xFF00FF88)),
              const SizedBox(height: 6),
              _StatRow(label: 'Errores cometidos', value: '$errores', color: Colors.orangeAccent),
              const SizedBox(height: 6),
              _StatRow(label: 'XP acumulado', value: '$xp', color: AppColors.cyan),
              const SizedBox(height: 24),
              const Text(
                'RONDA 2: SOLO TENDRÁS 7 SEGUNDOS POR ALERTA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinuar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'INICIAR RONDA 2',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Diálogo de resultado ───────────────────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  final bool exito;
  final int xp;
  final int aciertos;
  final int errores;
  final int expiradas;
  final String nivelRendimiento;
  final bool entrenamiento;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _ResultDialog({
    required this.exito,
    required this.xp,
    required this.aciertos,
    required this.errores,
    required this.expiradas,
    required this.nivelRendimiento,
    required this.entrenamiento,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = exito ? const Color(0xFF00FF88) : Colors.redAccent;
    final titulo = exito ? 'MISIÓN CUMPLIDA' : 'BRECHA DE SEGURIDAD';
    final subtitulo = exito
        ? 'El SOC contuvo todos los incidentes con éxito'
        : 'Demasiadas amenazas sin respuesta. La red fue comprometida';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor, width: 2),
          boxShadow: [
            BoxShadow(color: accentColor.withValues(alpha: 0.25), blurRadius: 30)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.verified_rounded : Icons.gpp_bad_outlined,
              color: accentColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (exito)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  nivelRendimiento,
                  style: TextStyle(
                    color: accentColor,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _StatRow(label: 'XP obtenido', value: '$xp', color: AppColors.cyan),
            const SizedBox(height: 8),
            _StatRow(label: 'Alertas correctas', value: '$aciertos / 16', color: const Color(0xFF00FF88)),
            const SizedBox(height: 8),
            _StatRow(label: 'Decisiones erróneas', value: '$errores', color: Colors.orangeAccent),
            const SizedBox(height: 8),
            _StatRow(label: 'Alertas expiradas', value: '$expiradas', color: Colors.redAccent),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSalir,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('SALIR', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReintentar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'REINTENTAR',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painter del fondo (mapa de red) ───────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final double progress;
  final int threatLevel;

  _GridPainter({required this.progress, this.threatLevel = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final threatColor = Color.lerp(
      const Color(0xFF00FFAA),
      Colors.red,
      (threatLevel / 8).clamp(0.0, 1.0),
    )!;

    final gridPaint = Paint()
      ..color = threatColor.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    // Grid horizontal
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Grid vertical
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Nodos de la red
    final nodos = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.6),
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.85),
    ];

    final linePaint = Paint()
      ..color = threatColor.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    // Conexiones
    final conexiones = [
      [0, 1], [1, 2], [1, 4], [3, 4], [4, 5],
      [3, 6], [4, 7], [5, 8], [0, 3], [2, 5],
    ];

    for (final conn in conexiones) {
      canvas.drawLine(nodos[conn[0]], nodos[conn[1]], linePaint);
    }

    // Pulso de propagación (cuando hay amenazas)
    if (threatLevel > 0) {
      final pulseRadius = 20.0 + 15.0 * math.sin(progress * math.pi * 2);
      final pulsePaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.15 * (threatLevel / 8).clamp(0.1, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      for (int i = 0; i < math.min(threatLevel, nodos.length); i++) {
        canvas.drawCircle(nodos[i], pulseRadius, pulsePaint);
      }
    }

    // Nodos
    for (int i = 0; i < nodos.length; i++) {
      final isCompromised = i < threatLevel;
      final nodePaint = Paint()
        ..color = isCompromised
            ? Colors.red.withValues(alpha: 0.6)
            : threatColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodos[i], 4.0, nodePaint);

      if (isCompromised) {
        final ringPaint = Paint()
          ..color = Colors.red.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(nodos[i], 8.0 + 4.0 * progress, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.progress != progress || old.threatLevel != threatLevel;
}
