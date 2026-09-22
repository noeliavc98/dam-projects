import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../games/nivel_22/components/spoofing_packet.dart';
import '../games/nivel_22/data/spoofing_data.dart';
import '../games/nivel_22/nivel22_game.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';

// ── Breakpoints ────────────────────────────────────────────────────────────────
double _pad(double w)     => w < 380 ? 10.0 : (w < 600 ? 14.0 : 20.0);
bool   _isWide(double w)  => w >= 600;
double _phoneW(double w)  => math.min(240.0, w * 0.58).clamp(170.0, 240.0);

class Nivel22Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel22Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel22Screen> createState() => _Nivel22ScreenState();
}

class _Nivel22ScreenState extends State<Nivel22Screen>
    with TickerProviderStateMixin {
  final Nivel22Game _game = Nivel22Game();

  bool _loading            = true;
  bool _nivelYaCompletado  = false;
  bool _progresoGuardado   = false;

  late AnimationController _feedbackCtrl;
  late Animation<double>   _feedbackOpacity;
  Color _feedbackColor = Colors.transparent;

  late AnimationController _bgCtrl;

  Timer? _timer;
  int    _segundosRestantes = Nivel22Game.segundosDeteccion;
  double _timerProgress     = 1.0;

  bool _esperandoSiguiente = false;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _feedbackOpacity =
        CurvedAnimation(parent: _feedbackCtrl, curve: Curves.easeOut);

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _setupLevel();
  }

  Future<void> _setupLevel() async {
    try {
      await MusicService().playNiveles21to25Music();
    } catch (e) {
      debugPrint('Error iniciando música nivel 22: $e');
    }
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final data  = await FirestoreService.obtenerUsuario();
        final level = (data['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = level > 22;
      } catch (e) {
        debugPrint('Nivel 22 — no se pudo verificar progreso: $e');
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _iniciarTimerDeteccion() {
    _timer?.cancel();
    setState(() {
      _segundosRestantes  = Nivel22Game.segundosDeteccion;
      _timerProgress      = 1.0;
      _esperandoSiguiente = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _segundosRestantes--;
        _timerProgress = _segundosRestantes / Nivel22Game.segundosDeteccion;
      });
      if (_segundosRestantes <= 0) {
        t.cancel();
        _onDeteccionExpirada();
      }
    });
  }

  void _onDeteccionExpirada() {
    if (_esperandoSiguiente) return;
    setState(() => _game.deteccionExpirada());
    _mostrarFeedback(correcto: false);
    _postDeteccion();
  }

  // ── Respuestas SMS ─────────────────────────────────────────────────────────

  void _responderSmsEmisor(int idx) {
    final correcto = _game.responderSmsEmisor(idx);
    _mostrarFeedback(correcto: correcto);
    setState(() {});
    _checkFaseCreacion();
  }

  void _responderSmsMensaje(int idx) {
    final correcto = _game.responderSmsMensaje(idx);
    _mostrarFeedback(correcto: correcto);
    setState(() {});
    _checkFaseCreacion();
  }

  void _responderSmsNombre(int idx) {
    final correcto = _game.responderSmsNombre(idx);
    _mostrarFeedback(correcto: correcto);
    setState(() {});
    _checkFaseCreacion();
  }

  // ── Respuestas Email ───────────────────────────────────────────────────────

  void _responderEmailFrom(int idx) {
    final correcto = _game.responderEmailFrom(idx);
    _mostrarFeedback(correcto: correcto);
    setState(() {});
    _checkFaseCreacion();
  }

  void _responderEmailMensaje(int idx) {
    final correcto = _game.responderEmailMensaje(idx);
    _mostrarFeedback(correcto: correcto);
    setState(() {});
    _checkFaseCreacion();
  }

  void _responderEmailNombre(int idx) {
    final correcto = _game.responderEmailNombre(idx);
    _mostrarFeedback(correcto: correcto);
    setState(() {});
    _checkFaseCreacion();
  }

  void _checkFaseCreacion() {
    if (_game.fase == Nivel22Phase.fallado) {
      Future.delayed(const Duration(milliseconds: 900), _mostrarDerrota);
    }
  }

  // ── Respuesta Detección ────────────────────────────────────────────────────

  void _responderDeteccion(bool esReal) {
    if (_esperandoSiguiente) return;
    _timer?.cancel();
    final correcto = _game.responderDeteccion(esReal);
    _mostrarFeedback(correcto: correcto);
    setState(() => _esperandoSiguiente = true);
    _postDeteccion();
  }

  void _postDeteccion() {
    final fase = _game.fase;
    if (fase == Nivel22Phase.fallado) {
      Future.delayed(const Duration(milliseconds: 900), _mostrarDerrota);
    } else if (fase == Nivel22Phase.completado) {
      Future.delayed(const Duration(milliseconds: 900), () {
        _guardarProgreso();
        _mostrarVictoria();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() => _game.ultimaAccionCorrecta = null);
        _iniciarTimerDeteccion();
      });
    }
  }

  void _mostrarFeedback({required bool correcto}) {
    setState(() {
      _feedbackColor =
          correcto ? const Color(0xFF00FF88) : const Color(0xFFFF4444);
    });
    _feedbackCtrl.forward(from: 0).then((_) => _feedbackCtrl.reverse());
  }

  // ── Progreso ───────────────────────────────────────────────────────────────

  Future<void> _guardarProgreso() async {
    if (_progresoGuardado || _nivelYaCompletado) return;
    _progresoGuardado = true;
    try {
      await FirestoreService.guardarPuntuacion(
        puntos: _game.xp,
        nivelCompletado: 22,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
          nivel: 22, mision: 22, puntos: _game.xp);
    } catch (e) {
      _progresoGuardado = false;
    }
  }

  // ── Diálogos resultado ─────────────────────────────────────────────────────

  void _mostrarVictoria() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        exito: true,
        xp: _game.xp,
        aciertos: _game.aciertos,
        errores: _game.errores,
        nivelRendimiento: _game.nivelRendimiento,
        entrenamiento: _nivelYaCompletado,
        onReintentar: _reintentar,
        onSalir: _salir,
      ),
    );
  }

  void _mostrarDerrota() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        exito: false,
        xp: _game.xp,
        aciertos: _game.aciertos,
        errores: _game.errores,
        nivelRendimiento: _game.nivelRendimiento,
        entrenamiento: _nivelYaCompletado,
        onReintentar: _reintentar,
        onSalir: _salir,
      ),
    );
  }

  void _reintentar() {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Nivel22Screen(soloEntrenamiento: widget.soloEntrenamiento),
      ),
    );
  }

  void _salir() {
    Navigator.pop(context);
    Navigator.pop(context);
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

    if (_game.fase == Nivel22Phase.intro) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: FracturaDialogo(
            subtitulo: 'SPOOFING // OPERACIÓN SUPLANTACIÓN',
            textoBotonFinal: 'INICIAR OPERACIÓN',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 1.0,
            milisegundosPorCaracter: 20,
            dialogos: const [
              'Agente, el spoofing es el arte de la suplantación digital. Un atacante falsifica su identidad — número de teléfono, correo o URL — para que la víctima crea que se comunica con alguien de confianza.',
              'En esta operación trabajarás en dos frentes. Primero aprenderás a CONSTRUIR un ataque de spoofing: elegirás el emisor, redactarás el mensaje y nombrarás la técnica.',
              'Parte 1 — Creación: construirás dos ataques reales. Uno por SMS suplantando a un banco o empresa de mensajería. Otro por email impersonando a un ejecutivo o al departamento IT.',
              'Parte 2 — Detección: cambias de rol. Recibirás SMS, correos y páginas web. Debes decidir si son legítimos o intentos de spoofing. Tendrás tiempo limitado para analizar cada uno.',
              'Cada decisión correcta suma XP. Los errores cuestan vidas. Analiza el dominio, la urgencia, los caracteres sospechosos. Un experto en ciberseguridad no cae en el engaño.',
            ],
            onFinalizado: () {
              setState(() => _game.fase = Nivel22Phase.tutorial);
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
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, child) =>
                    CustomPaint(painter: _BgPainter(_bgCtrl.value)),
              ),
            ),
            AnimatedBuilder(
              animation: _feedbackOpacity,
              builder: (_, child) => Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: _feedbackColor
                        .withValues(alpha: _feedbackOpacity.value * 0.15),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _buildTopBar(),
                if (_nivelYaCompletado) _buildTrainingBanner(),
                Expanded(child: _buildBody()),
              ],
            ),
            if (_game.fase == Nivel22Phase.tutorial)
              _TutorialOverlay(
                onContinuar: () => setState(() => _game.iniciarSms()),
              ),
            if (_game.fase == Nivel22Phase.entreCreacion)
              _EntreRondasOverlay(
                titulo: '✓ PRUEBA SMS COMPLETADA',
                subtitulo: 'PRUEBA 2 — CONSTRUYE UN ATAQUE POR EMAIL',
                descripcion:
                    'Ahora construirás un correo electrónico de spoofing. '
                    'Elige el campo "De:" correcto (dominio falsificado) '
                    'y redacta el mensaje de engaño adecuado.',
                aciertos: _game.aciertos,
                errores: _game.errores,
                xp: _game.xp,
                colorAccent: Colors.orangeAccent,
                labelBoton: 'INICIAR PRUEBA EMAIL',
                onContinuar: () => setState(() => _game.iniciarEmail()),
              ),
            if (_game.fase == Nivel22Phase.entrePartes)
              _EntreRondasOverlay(
                titulo: '✓ PARTE 1 COMPLETADA',
                subtitulo: 'PARTE 2 — DETECTA LOS ATAQUES',
                descripcion:
                    'Ahora cambias de rol. Recibirás SMS, correos y páginas web. '
                    'Debes identificar cuáles son legítimos y cuáles son ataques de spoofing. '
                    'Tienes ${Nivel22Game.segundosDeteccion}s por mensaje.',
                aciertos: _game.aciertos,
                errores: _game.errores,
                xp: _game.xp,
                colorAccent: AppColors.cyan,
                labelBoton: 'INICIAR DETECCIÓN',
                onContinuar: () {
                  setState(() => _game.iniciarDeteccion());
                  _iniciarTimerDeteccion();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final fase = _game.fase;
    late String faseLabel;
    late Color faseColor;

    if (fase == Nivel22Phase.pruebasSms || fase == Nivel22Phase.tutorial) {
      faseLabel = 'PARTE 1 · SMS';
      faseColor = const Color(0xFF4CAF50);
    } else if (fase == Nivel22Phase.pruebasEmail ||
        fase == Nivel22Phase.entreCreacion) {
      faseLabel = 'PARTE 1 · EMAIL';
      faseColor = Colors.orangeAccent;
    } else if (fase == Nivel22Phase.deteccion ||
        fase == Nivel22Phase.entrePartes) {
      faseLabel = 'PARTE 2 · DETECCIÓN';
      faseColor = AppColors.cyan;
    } else {
      faseLabel = 'SPOOFING';
      faseColor = AppColors.cyan;
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final narrow = w < 400;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
            bottom: BorderSide(color: AppColors.cyan.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            // ── Izquierda: botón volver + título (si cabe) ──
            IconButton(
              tooltip: 'Volver al mapa',
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.cyan, size: 18),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 6),
            if (!narrow)
              const Text(
                'SPOOFING — NIVEL 22',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            // ── Derecha: badge + vidas + XP, ocupa todo el espacio restante
            //    y se auto-alinea a la derecha. Flexible en el badge evita
            //    overflow si el texto es muy largo en pantallas pequeñas. ──
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: faseColor.withValues(alpha: 0.7)),
                        borderRadius: BorderRadius.circular(4),
                        color: faseColor.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        faseLabel,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: faseColor,
                          fontFamily: 'monospace',
                          fontSize: narrow ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(
                    Nivel22Game.vidasIniciales,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(
                        Icons.favorite,
                        size: narrow ? 13 : 15,
                        color: i < _game.vidas
                            ? Colors.redAccent
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_game.xp} XP',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontFamily: 'monospace',
                      fontSize: narrow ? 11 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
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

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_game.fase) {
      case Nivel22Phase.pruebasSms:
        return _buildSmsPrueba();
      case Nivel22Phase.pruebasEmail:
        return _buildEmailPrueba();
      case Nivel22Phase.deteccion:
        return _buildDeteccion();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Prueba SMS ─────────────────────────────────────────────────────────────

  Widget _buildSmsPrueba() {
    final prueba = _game.smsActual;
    if (prueba == null) return const SizedBox.shrink();
    final paso = _game.smsPaso;

    return LayoutBuilder(builder: (context, constraints) {
      final w    = constraints.maxWidth;
      final p    = _pad(w);
      final wide = _isWide(w);

      final header = _buildProgresoCreacion(
        titulo: 'PRUEBA 1 · SMS SPOOFING',
        scenarioActual: _game.smsScenarioIdx + 1,
        totalScenarios: SpoofingData.pruebasSms.length,
        paso: paso,
        objetivo: prueba.descripcionObjetivo,
      );
      final mockup = _buildPhoneMockup(
        emisor: _game.smsEmisorElegido,
        mensaje: _game.smsMensajeElegido,
        paso: paso,
        availableWidth: wide ? (w - p * 2) * 0.4 : w - p * 2,
      );
      final opciones = _buildOpciones(
        paso: paso,
        opcionesPaso0: prueba.opcionesEmisor,
        opcionesPaso1: prueba.opcionesMensaje,
        opcionesPaso2: prueba.opcionesNombreAtaque,
        onPaso0: _responderSmsEmisor,
        onPaso1: _responderSmsMensaje,
        onPaso2: _responderSmsNombre,
        labelPaso0: '¿CUÁL DEBE SER EL EMISOR (REMITENTE)?',
        labelPaso1: '¿CUÁL ES EL MENSAJE DE ENGAÑO CORRECTO?',
      );
      final accion = _game.ultimaAccionCorrecta;
      final feedback = accion != null
          ? _FeedbackBanner(
              correcto: accion,
              pista: accion ? null : _game.ultimaPistaRelevante,
            )
          : null;

      return SingleChildScrollView(
        padding: EdgeInsets.all(p),
        child: Column(
          children: [
            header,
            SizedBox(height: p),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: mockup),
                  SizedBox(width: p),
                  Expanded(flex: 6, child: opciones),
                ],
              )
            else ...[
              mockup,
              SizedBox(height: p),
              opciones,
            ],
            if (feedback != null) ...[
              SizedBox(height: p),
              feedback,
            ],
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  // ── Prueba Email ───────────────────────────────────────────────────────────

  Widget _buildEmailPrueba() {
    final prueba = _game.emailActual;
    if (prueba == null) return const SizedBox.shrink();
    final paso = _game.emailPaso;

    return LayoutBuilder(builder: (context, constraints) {
      final w    = constraints.maxWidth;
      final p    = _pad(w);
      final wide = _isWide(w);

      final header = _buildProgresoCreacion(
        titulo: 'PRUEBA 2 · EMAIL SPOOFING',
        scenarioActual: _game.emailScenarioIdx + 1,
        totalScenarios: SpoofingData.pruebasEmail.length,
        paso: paso,
        objetivo: prueba.descripcionObjetivo,
      );
      final mockup = _buildEmailMockup(
        from: _game.emailFromElegido,
        mensaje: _game.emailMensajeElegido,
        paso: paso,
      );
      final opciones = _buildOpciones(
        paso: paso,
        opcionesPaso0: prueba.opcionesFrom,
        opcionesPaso1: prueba.opcionesMensaje,
        opcionesPaso2: prueba.opcionesNombreAtaque,
        onPaso0: _responderEmailFrom,
        onPaso1: _responderEmailMensaje,
        onPaso2: _responderEmailNombre,
        labelPaso0: '¿CUÁL DEBE SER EL CAMPO "DE:" (FROM)?',
        labelPaso1: '¿CUÁL ES EL MENSAJE DE ENGAÑO CORRECTO?',
      );
      final accion = _game.ultimaAccionCorrecta;
      final feedback = accion != null
          ? _FeedbackBanner(
              correcto: accion,
              pista: accion ? null : _game.ultimaPistaRelevante,
            )
          : null;

      return SingleChildScrollView(
        padding: EdgeInsets.all(p),
        child: Column(
          children: [
            header,
            SizedBox(height: p),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: mockup),
                  SizedBox(width: p),
                  Expanded(flex: 5, child: opciones),
                ],
              )
            else ...[
              mockup,
              SizedBox(height: p),
              opciones,
            ],
            if (feedback != null) ...[
              SizedBox(height: p),
              feedback,
            ],
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  // ── Detección ──────────────────────────────────────────────────────────────

  Widget _buildDeteccion() {
    final item = _game.deteccionActual;
    if (item == null) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final w    = constraints.maxWidth;
      final p    = _pad(w);
      final wide = _isWide(w);

      return SingleChildScrollView(
        padding: EdgeInsets.all(p),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 680 : double.infinity),
            child: Column(
              children: [
                _buildTimerBar(),
                SizedBox(height: p * 0.7),
                Row(
                  children: [
                    Text(
                      'MENSAJE ${_game.deteccionIdx + 1} / ${SpoofingData.itemsDeteccion.length}',
                      style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'monospace',
                        fontSize: w < 380 ? 9 : 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    _TipoBadge(tipo: item.tipo),
                  ],
                ),
                SizedBox(height: p * 0.85),
                _buildDeteccionMockup(item, availableWidth: w - p * 2),
                SizedBox(height: p),
                Text(
                  '¿ES ESTE MENSAJE LEGÍTIMO O UN ATAQUE DE SPOOFING?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontFamily: 'monospace',
                    fontSize: w < 380 ? 9 : 10,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: p * 0.85),
                Row(
                  children: [
                    Expanded(
                      child: _DecisionButton(
                        label: '✓  LEGÍTIMO',
                        color: const Color(0xFF00CC66),
                        enabled: !_esperandoSiguiente,
                        onTap: () => _responderDeteccion(true),
                      ),
                    ),
                    SizedBox(width: p * 0.85),
                    Expanded(
                      child: _DecisionButton(
                        label: '✗  FALSO',
                        color: Colors.redAccent,
                        enabled: !_esperandoSiguiente,
                        onTap: () => _responderDeteccion(false),
                      ),
                    ),
                  ],
                ),
                if (_game.ultimaAccionCorrecta != null) ...[
                  SizedBox(height: p),
                  _FeedbackBanner(
                    correcto: _game.ultimaAccionCorrecta!,
                    pista: _game.ultimaAccionCorrecta! ? null : _game.ultimaExplicacion,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Timer bar ──────────────────────────────────────────────────────────────

  Widget _buildTimerBar() {
    final color = _timerProgress > 0.5
        ? AppColors.cyan
        : _timerProgress > 0.25
            ? Colors.orange
            : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIEMPO DE ANÁLISIS',
              style: TextStyle(
                  color: color,
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 1.5),
            ),
            Text(
              '${_segundosRestantes}s',
              style: TextStyle(
                  color: color,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
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
    );
  }

  // ── Shared UI ──────────────────────────────────────────────────────────────

  Widget _buildProgresoCreacion({
    required String titulo,
    required int scenarioActual,
    required int totalScenarios,
    required int paso,
    required String objetivo,
  }) {
    const pasos = ['1. EMISOR', '2. MENSAJE', '3. NOMBRE ATAQUE'];
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 380;
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: narrow ? 10 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(titulo,
                      style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: narrow ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
                const SizedBox(width: 8),
                Text('ESC. $scenarioActual/$totalScenarios',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontFamily: 'monospace',
                        fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (i) {
                final activo    = i == paso;
                final completado = i < paso;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 3,
                          decoration: BoxDecoration(
                            color: completado
                                ? const Color(0xFF00FF88)
                                : activo
                                    ? AppColors.cyan
                                    : Colors.white12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pasos[i],
                          style: TextStyle(
                            color: completado
                                ? const Color(0xFF00FF88)
                                : activo
                                    ? AppColors.cyan
                                    : Colors.white24,
                            fontFamily: 'monospace',
                            fontSize: 7,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location_rounded,
                    color: Color(0xFFFFCC00), size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    objetivo,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: narrow ? 10 : 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOpciones({
    required int paso,
    required List<String> opcionesPaso0,
    required List<String> opcionesPaso1,
    required List<String> opcionesPaso2,
    required void Function(int) onPaso0,
    required void Function(int) onPaso1,
    required void Function(int) onPaso2,
    String labelPaso0 = '¿CUÁL DEBE SER EL EMISOR?',
    String labelPaso1 = '¿CUÁL ES EL MENSAJE CORRECTO?',
  }) {
    final String pregunta;
    final List<String> opciones;
    final void Function(int) onTap;

    switch (paso) {
      case 0:
        pregunta = labelPaso0;
        opciones = opcionesPaso0;
        onTap    = onPaso0;
        break;
      case 1:
        pregunta = labelPaso1;
        opciones = opcionesPaso1;
        onTap    = onPaso1;
        break;
      default:
        pregunta = '¿CÓMO SE LLAMA ESTE TIPO DE ATAQUE?';
        opciones = opcionesPaso2;
        onTap    = onPaso2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pregunta,
          style: const TextStyle(
            color: Colors.white38,
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...opciones.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OpcionButton(
              label: e.value,
              onTap: () => onTap(e.key),
            ),
          ),
        ),
      ],
    );
  }

  // ── Phone mockup ───────────────────────────────────────────────────────────

  Widget _buildPhoneMockup({
    required String? emisor,
    required String? mensaje,
    required int paso,
    double availableWidth = 300,
  }) {
    final w = _phoneW(availableWidth);
    return Center(
      child: Container(
        width: w,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF333333), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.signal_cellular_alt,
                      color: Colors.white54, size: 11),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      emisor ?? '???',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: emisor != null ? Colors.white : Colors.white24,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.battery_full,
                      color: Colors.white54, size: 11),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 110, maxHeight: 160),
              child: mensaje != null
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          mensaje,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, height: 1.4),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        paso == 0
                            ? 'Elige el emisor primero...'
                            : 'Elige el mensaje...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ),
            Container(
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
              ),
              child: const Center(
                child: Icon(Icons.home, color: Colors.white38, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Email mockup ───────────────────────────────────────────────────────────

  Widget _buildEmailMockup({
    required String? from,
    required String? mensaje,
    required int paso,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1020),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF111830),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_outlined,
                    color: Colors.orangeAccent, size: 14),
                SizedBox(width: 8),
                Text(
                  'NUEVO MENSAJE — BORRADOR',
                  style: TextStyle(
                    color: Colors.white38,
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _emailField('Para:', 'victima@empresa.es', Colors.white54),
                const SizedBox(height: 6),
                _emailField(
                  'De:',
                  from ?? (paso == 0 ? '[ seleccionar ]' : '...'),
                  from != null ? Colors.orangeAccent : Colors.white24,
                ),
                const SizedBox(height: 6),
                _emailField(
                    'Asunto:', 'Acción urgente requerida', Colors.white54),
                const Divider(color: Colors.white12, height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080D1C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mensaje ??
                        (paso <= 1
                            ? 'Cuerpo del mensaje...'
                            : 'Selecciona el mensaje'),
                    style: TextStyle(
                      color:
                          mensaje != null ? Colors.white70 : Colors.white24,
                      fontSize: 11,
                      height: 1.5,
                      fontStyle: mensaje == null
                          ? FontStyle.italic
                          : FontStyle.normal,
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

  Widget _emailField(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white38,
                fontFamily: 'monospace',
                fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                color: valueColor,
                fontFamily: 'monospace',
                fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ── Detección mockups ──────────────────────────────────────────────────────

  Widget _buildDeteccionMockup(DeteccionItem item,
      {double availableWidth = 300}) {
    switch (item.tipo) {
      case TipoDeteccion.sms:
        return _deteccionSms(item, availableWidth: availableWidth);
      case TipoDeteccion.email:
        return _deteccionEmail(item);
      case TipoDeteccion.web:
        return _deteccionWeb(item);
    }
  }

  Widget _deteccionSms(DeteccionItem item, {double availableWidth = 300}) {
    final w = _phoneW(availableWidth);
    return Center(
      child: Container(
        width: w,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF333333), width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.signal_cellular_alt,
                      color: Colors.white54, size: 11),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.emisor,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.battery_full,
                      color: Colors.white54, size: 11),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    item.cuerpo,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, height: 1.4),
                  ),
                ),
              ),
            ),
            Container(
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
              ),
              child: const Center(
                child: Icon(Icons.home, color: Colors.white38, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deteccionEmail(DeteccionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF111830),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.inbox_outlined, color: Colors.white38, size: 14),
                SizedBox(width: 8),
                Text(
                  'CORREO RECIBIDO',
                  style: TextStyle(
                      color: Colors.white38,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 1),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _emailField('De:', item.emisor, Colors.white70),
                const SizedBox(height: 4),
                _emailField('Asunto:', item.asunto, Colors.white),
                const Divider(color: Colors.white12, height: 16),
                Text(
                  item.cuerpo,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deteccionWeb(DeteccionItem item) {
    final esHttps = item.emisor.startsWith('https');
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1020),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C2E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          esHttps
                              ? Icons.lock_outline
                              : Icons.lock_open_outlined,
                          size: 10,
                          color: esHttps ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.emisor,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.cuerpo,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge tipo detección ───────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  final TipoDeteccion tipo;
  const _TipoBadge({required this.tipo});

  Color get _color {
    switch (tipo) {
      case TipoDeteccion.sms:   return const Color(0xFF4CAF50);
      case TipoDeteccion.email: return Colors.orangeAccent;
      case TipoDeteccion.web:   return AppColors.cyan;
    }
  }

  String get _label {
    switch (tipo) {
      case TipoDeteccion.sms:   return 'SMS';
      case TipoDeteccion.email: return 'EMAIL';
      case TipoDeteccion.web:   return 'WEB';
    }
  }

  IconData get _icon {
    switch (tipo) {
      case TipoDeteccion.sms:   return Icons.sms_outlined;
      case TipoDeteccion.email: return Icons.email_outlined;
      case TipoDeteccion.web:   return Icons.language_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 10),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Opción button ──────────────────────────────────────────────────────────────

class _OpcionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OpcionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF7F77DD).withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF7F77DD).withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.radio_button_unchecked,
                  color: Color(0xFF7F77DD), size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Decision button ────────────────────────────────────────────────────────────

class _DecisionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.6) : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: enabled ? color : Colors.white24,
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feedback banner ────────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool correcto;
  final String? pista;
  const _FeedbackBanner({required this.correcto, this.pista});

  @override
  Widget build(BuildContext context) {
    final color  = correcto ? const Color(0xFF00FF88) : Colors.orangeAccent;
    final icon   = correcto ? Icons.check_circle_outline : Icons.info_outline;
    final titulo = correcto ? '✓ CORRECTO' : '✗ INCORRECTO — PISTA';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
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
                if (pista != null && pista!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    pista!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
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

// ── Tutorial overlay ───────────────────────────────────────────────────────────

class _TutorialOverlay extends StatelessWidget {
  final VoidCallback onContinuar;
  const _TutorialOverlay({required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onContinuar,
      child: Container(
        color: Colors.black.withValues(alpha: 0.82),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 60),
                GestureDetector(
                  onTap: onContinuar,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF7F77DD), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7F77DD)
                              .withValues(alpha: 0.35),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science_outlined,
                                color: Color(0xFF7F77DD), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'CÓMO FUNCIONA ESTA OPERACIÓN',
                                style: TextStyle(
                                  color: Color(0xFF7F77DD),
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '📱 PARTE 1 — CREAR ATAQUES\n'
                          'Verás una interfaz de teléfono o de correo. '
                          'Con las pistas proporcionadas, debes elegir el emisor correcto, '
                          'el mensaje de engaño adecuado y nombrar la técnica utilizada.\n\n'
                          '🛡 PARTE 2 — DETECTAR ATAQUES\n'
                          'Recibirás mensajes (SMS, emails y webs). '
                          'Tienes ${Nivel22Game.segundosDeteccion}s para decidir si cada uno '
                          'es LEGÍTIMO o un intento de SPOOFING.\n\n'
                          'Cada respuesta correcta suma XP. Tres errores = misión fallida.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'INICIAR PARTE 1 →',
                            style: TextStyle(
                              color: Color(0xFF7F77DD),
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
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

// ── Entre rondas overlay ───────────────────────────────────────────────────────

class _EntreRondasOverlay extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final int aciertos;
  final int errores;
  final int xp;
  final Color colorAccent;
  final String labelBoton;
  final VoidCallback onContinuar;

  const _EntreRondasOverlay({
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.aciertos,
    required this.errores,
    required this.xp,
    required this.colorAccent,
    required this.labelBoton,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colorAccent.withValues(alpha: 0.3),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: colorAccent, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitulo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorAccent,
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      descripcion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _statRow('Aciertos', '$aciertos',
                        const Color(0xFF00FF88)),
                    const SizedBox(height: 6),
                    _statRow('Errores', '$errores', Colors.orangeAccent),
                    const SizedBox(height: 6),
                    _statRow('XP acumulado', '$xp', AppColors.cyan),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onContinuar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorAccent,
                          foregroundColor: Colors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          labelBoton,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
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

// ── Diálogo resultado ──────────────────────────────────────────────────────────

class _ResultDialog extends StatelessWidget {
  final bool exito;
  final int xp;
  final int aciertos;
  final int errores;
  final String nivelRendimiento;
  final bool entrenamiento;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _ResultDialog({
    required this.exito,
    required this.xp,
    required this.aciertos,
    required this.errores,
    required this.nivelRendimiento,
    required this.entrenamiento,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = exito ? const Color(0xFF00FF88) : Colors.redAccent;
    final titulo =
        exito ? 'OPERACIÓN COMPLETADA' : 'OPERACIÓN FALLIDA';
    final subtitulo = exito
        ? 'Has dominado la creación y detección de ataques de spoofing'
        : 'Demasiados errores. El atacante pasó desapercibido.';
    final total = SpoofingData.pruebasSms.length * 3 +
        SpoofingData.pruebasEmail.length * 3 +
        SpoofingData.itemsDeteccion.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  exito
                      ? Icons.verified_rounded
                      : Icons.gpp_bad_outlined,
                  color: accentColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16,
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
                const SizedBox(height: 20),
                if (exito)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      nivelRendimiento,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _row('XP obtenido', '$xp', AppColors.cyan),
                const SizedBox(height: 8),
                _row('Correctos', '$aciertos / $total',
                    const Color(0xFF00FF88)),
                const SizedBox(height: 8),
                _row('Errores', '$errores', Colors.orangeAccent),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSalir,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'SALIR',
                          style: TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReintentar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'REINTENTAR',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
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

// ── Fondo animado ──────────────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  final double progress;
  _BgPainter(this.progress);

  static final _rng = math.Random(42);
  static final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(
      x:      _rng.nextDouble(),
      y:      _rng.nextDouble(),
      speed:  0.03 + _rng.nextDouble() * 0.05,
      offset: _rng.nextDouble(),
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF7F77DD).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      final t  = (progress + p.offset) % 1.0;
      final px = p.x * size.width;
      final py = (p.y + t * p.speed * 20) % 1.0 * size.height;
      dotPaint.color = const Color(0xFF7F77DD).withValues(alpha: 0.25);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(px, py), width: 12, height: 4),
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, speed, offset;
  const _Particle(
      {required this.x,
      required this.y,
      required this.speed,
      required this.offset});
}
