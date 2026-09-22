import 'dart:async';
import 'package:cyber_ops/games/nivel_24/components/privilege_binary.dart';
import 'package:cyber_ops/games/nivel_24/components/privilege_file.dart';
import 'package:cyber_ops/games/nivel_24/data/privilege_data.dart';
import 'package:cyber_ops/games/nivel_24/nivel24_game.dart';
import 'package:flutter/material.dart';
import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/services/firestore_service.dart';
import 'package:cyber_ops/services/music_service.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';

 
class Nivel24Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel24Screen({super.key, this.soloEntrenamiento = false});
 
  @override
  State<Nivel24Screen> createState() => _Nivel24ScreenState();
}
 
class _Nivel24ScreenState extends State<Nivel24Screen>
    with TickerProviderStateMixin {
  late final Nivel24Game _game;
  bool _nivelYaCompletado = false;
  bool _resultadoMostrado = false;
 
  // ── ANIMACIONES ───────────────────────────────────────────────────────────
  late AnimationController _nodeController;
  late AnimationController _glowController;
  Timer? _cronjobTimer;
 
  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Estás dentro del servidor de MegaCorp, pero con acceso mínimo.',
    'Tu objetivo: escalar desde GUEST hasta ROOT encadenando tres vulnerabilidades reales.',
    'Cada fase desbloquea la siguiente. Dos errores por fase y el sistema te expulsa.',
    'Empieza explorando el sistema de archivos. Las credenciales no siempre están donde las esperas.',
  ];
 
  // ── TUTORIAL ──────────────────────────────────────────────────────────────
  bool _mostrarTutorial = false;
  int _pasoTutorial = 0;
  final GlobalKey _arbolKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _faseKey = GlobalKey();
  final GlobalKey _mensajeKey = GlobalKey();
 
  @override
  void initState() {
    super.initState();
    _game = Nivel24Game();
    _game.onCronjobTick = _onCronjobTick;
 
    _nodeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
 
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
 
    _setupNivel();
  }
 
  @override
  void dispose() {
    _nodeController.dispose();
    _glowController.dispose();
    _cronjobTimer?.cancel();
    super.dispose();
  }
 
  // ── SETUP ─────────────────────────────────────────────────────────────────
 
  Future<void> _setupNivel() async {
    try {
      await MusicService().playNiveles21to25Music();
    } catch (e) {
      debugPrint('Error iniciando música nivel 24: $e');
    }
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final datos = await FirestoreService.obtenerUsuario();
        final nivelUsuario = (datos['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = nivelUsuario > 24;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 24: $e');
      }
    }
    if (mounted) setState(() {});
  }
 
  // ── CALLBACKS ─────────────────────────────────────────────────────────────
 
  void _onCronjobTick() {
    if (!mounted) return;
    setState(() {});
    if (_game.failed || _game.completed) {
      _cronjobTimer?.cancel();
      if (_game.failed) _mostrarGameOver();
      if (_game.completed) _mostrarVictoria();
    }
  }
 
  void _iniciarTimerCronjob() {
    _cronjobTimer?.cancel();
    _cronjobTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _game.tickCronjob(1.0);
    });
  }
 
  // ── ACCIONES DE JUEGO ─────────────────────────────────────────────────────
 
  void _confirmarArchivos() {
    final eraFase1 = !_game.fase1Completada;
    setState(() => _game.confirmarArchivos());
    if (eraFase1 && _game.fase1Completada) _nodeController.forward(from: 0);
    if (_game.failed) _mostrarGameOver();
  }
 
  void _confirmarBinario() {
    final eraFase2 = !_game.fase2Completada;
    setState(() => _game.confirmarBinario());
    if (eraFase2 && _game.fase2Completada) {
      _nodeController.forward(from: 0);
      _iniciarTimerCronjob();
    }
    if (_game.failed) _mostrarGameOver();
  }
 
  void _confirmarComando() {
    setState(() => _game.confirmarComando());
    if (_game.completed) {
      _cronjobTimer?.cancel();
      _mostrarVictoria();
    }
    if (_game.failed) {
      _cronjobTimer?.cancel();
      _mostrarGameOver();
    }
  }
 
  // ── RESULTADOS ────────────────────────────────────────────────────────────
 
  void _mostrarGameOver() {
    if (_resultadoMostrado || !mounted) return;
    _resultadoMostrado = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoResultado(
        exito: false,
        xp: _game.xp,
        rango: '',
        entrenamiento: _nivelYaCompletado,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Nivel24Screen(soloEntrenamiento: widget.soloEntrenamiento),
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
          nivelCompletado: 24,
          soloEntrenamiento: widget.soloEntrenamiento,
        );
        await FirestoreService.guardarMision(
          nivel: 24,
          mision: 24,
          puntos: _game.xp,
        );
      } catch (e) {
        debugPrint('No se pudo guardar progreso del nivel 24: $e');
      }
    }
 
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoResultado(
        exito: true,
        xp: _game.xp,
        rango: _game.rangoFinal,
        entrenamiento: _nivelYaCompletado,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Nivel24Screen(soloEntrenamiento: widget.soloEntrenamiento),
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
 
  // ── TUTORIAL ──────────────────────────────────────────────────────────────
 
  List<_TutorialStep> get _tutorialSteps => [
        _TutorialStep(
          targetKey: _arbolKey,
          titulo: 'Árbol de privilegios',
          descripcion:
              'Los 4 nodos muestran tu nivel de acceso actual. Completa cada fase para desbloquear el siguiente escalón hacia ROOT.',
          alignment: const Alignment(0, -0.5),
        ),
        _TutorialStep(
          targetKey: _headerKey,
          titulo: 'Nivel de acceso y XP',
          descripcion:
              'El header muestra tu rol actual en el sistema y los XP acumulados. Cada fallo penaliza puntos.',
          alignment: const Alignment(0, -0.75),
        ),
        _TutorialStep(
          targetKey: _faseKey,
          titulo: 'Panel de fase activa',
          descripcion:
              'Aquí interactúas con la fase actual. Analiza con cuidado antes de confirmar — tienes solo 2 intentos.',
          alignment: const Alignment(0, 0.2),
        ),
        _TutorialStep(
          targetKey: _mensajeKey,
          titulo: 'Terminal del sistema',
          descripcion:
              'El sistema responde aquí tras cada acción. Lee los mensajes con atención, te dan pistas sobre tus errores.',
          alignment: const Alignment(0, 0.55),
        ),
      ];
 
  void _avanzarTutorial() {
    if (_pasoTutorial >= _tutorialSteps.length - 1) {
      setState(() => _mostrarTutorial = false);
      return;
    }
    setState(() => _pasoTutorial++);
  }
 
  void _saltarTutorial() => setState(() => _mostrarTutorial = false);
 
  // ── BUILD ─────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;
                return isMobile
                    ? _buildMobileLayout()
                    : _buildDesktopLayout();
              },
            ),
 
            // ── Fractura intro ──
            if (_mostrarFractura)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.80),
                  child: FracturaDialogo(
                    dialogos: _dialogosFractura,
                    subtitulo: 'NIVEL 24 // ESCALADA DE PRIVILEGIOS',
                    textoBotonFinal: 'JUGAR',
                    usarVoz: true,
                    permitirSaltarIntro: true,
                    permitirCambiarVoz: true,
                    velocidadVoz: 0.66,
                    milisegundosPorCaracter: 18,
                    onFinalizado: () => setState(() {
                      _mostrarFractura = false;
                      _mostrarTutorial = true;
                    }),
                  ),
                ),
              ),
 
            // ── Tutorial overlay ──
            if (!_mostrarFractura && _mostrarTutorial)
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
 
  // ── LAYOUTS ───────────────────────────────────────────────────────────────
 
  Widget _buildMobileLayout() {
    return Column(
      children: [
        KeyedSubtree(key: _headerKey, child: _buildHeader()),
        KeyedSubtree(key: _arbolKey, child: _buildArbolPrivilegios(horizontal: false)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              KeyedSubtree(key: _faseKey, child: _buildFaseActiva()),
              const SizedBox(height: 12),
              KeyedSubtree(key: _mensajeKey, child: _buildTerminal()),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        KeyedSubtree(key: _headerKey, child: _buildHeader()),
        KeyedSubtree(key: _arbolKey, child: _buildArbolPrivilegios(horizontal: true)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: KeyedSubtree(key: _faseKey, child: _buildFaseActiva()),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 320,
                  child: KeyedSubtree(key: _mensajeKey, child: _buildTerminal()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
 
  // ── HEADER ────────────────────────────────────────────────────────────────
 
  Widget _buildHeader() {
    final accessColor = _accessColor(_game.nivelAcceso);
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.cyan, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NIVEL 24 · ESCALADA DE PRIVILEGIOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'usuario activo: ${_accessLabel(_game.nivelAcceso)}',
                  style: TextStyle(
                    color: accessColor,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          if (_nivelYaCompletado) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.purple.withOpacity(0.4)),
              ),
              child: const Text(
                'ENTRENAMIENTO',
                style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _buildStatChip(
              'ACCESO', _accessLabel(_game.nivelAcceso), accessColor),
          const SizedBox(width: 8),
          _buildStatChip('XP', '${_game.xp}', AppColors.purple),
        ],
      ),
    );
  }
 
  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 8,
                  letterSpacing: 1.4)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
 
  // ── ÁRBOL DE PRIVILEGIOS ──────────────────────────────────────────────────
 
  Widget _buildArbolPrivilegios({required bool horizontal}) {
    final levels = AccessLevel.values;
 
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: horizontal
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildNodosConConectores(levels, horizontal: true),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildNodosConConectores(levels, horizontal: false),
            ),
    );
  }
 
  List<Widget> _buildNodosConConectores(
      List<AccessLevel> levels, {required bool horizontal}) {
    final widgets = <Widget>[];
    for (int i = 0; i < levels.length; i++) {
      widgets.add(_buildNodo(levels[i]));
      if (i < levels.length - 1) {
        widgets.add(_buildConector(levels[i]));
      }
    }
    return widgets;
  }
 
  Widget _buildNodo(AccessLevel level) {
    final isCurrent = _game.nivelAcceso == level;
    final isUnlocked = level.index <= _game.nivelAcceso.index;
    final color = _accessColor(level);
 
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity =
            isCurrent ? 0.3 + (_glowController.value * 0.4) : 0.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? color.withOpacity(0.15)
                    : AppColors.bgMain.withOpacity(0.5),
                border: Border.all(
                  color: isUnlocked ? color : AppColors.border,
                  width: isCurrent ? 2.5 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: color.withOpacity(glowOpacity), blurRadius: 18, spreadRadius: 3)]
                    : null,
              ),
              child: Center(
                child: Icon(
                  _accessIcon(level),
                  size: 22,
                  color: isUnlocked ? color : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _accessLabel(level),
              style: TextStyle(
                color: isUnlocked ? color : AppColors.textMuted,
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w500,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
            if (isCurrent)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.6 + _glowController.value * 0.4),
                ),
              )
            else
              const SizedBox(height: 9),
          ],
        );
      },
    );
  }
 
  Widget _buildConector(AccessLevel level) {
    final isUnlocked = level.index < _game.nivelAcceso.index;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUnlocked
                ? [_accessColor(level), _accessColor(AccessLevel.values[level.index + 1])]
                : [AppColors.border, AppColors.border],
          ),
        ),
      ),
    );
  }
 
  // ── FASE ACTIVA ───────────────────────────────────────────────────────────
 
  Widget _buildFaseActiva() {
    switch (_game.faseActual) {
      case Fase24.files:
        return _buildFaseArchivos();
      case Fase24.suid:
        return _buildFaseSuid();
      case Fase24.cronjob:
        return _buildFaseCronjob();
      case Fase24.completed:
      case Fase24.failed:
        return const SizedBox.shrink();
    }
  }
 
  // ── FASE 1 — Archivos ─────────────────────────────────────────────────────
 
  Widget _buildFaseArchivos() {
    return _Panel(
      titulo: 'FASE 1 · RECONOCIMIENTO',
      subtitulo: 'Localiza los archivos con credenciales expuestas',
      icono: Icons.manage_search_rounded,
      intentosRestantes: Nivel24Game.maxIntentosPorFase - _game.intentosFase1,
      child: Column(
        children: [
          ...PrivilegeData.archivos.map((archivo) {
            final seleccionado =
                _game.archivosSeleccionados.contains(archivo.id);
            return _ArchivoTile(
              archivo: archivo,
              seleccionado: seleccionado,
              onTap: () => setState(() => _game.toggleArchivo(archivo.id)),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _game.archivosSeleccionados.isEmpty
                  ? null
                  : _confirmarArchivos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                disabledBackgroundColor: AppColors.bgMain,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'CONFIRMAR SELECCIÓN',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ── FASE 2 — SUID ─────────────────────────────────────────────────────────
 
  Widget _buildFaseSuid() {
    return _Panel(
      titulo: 'FASE 2 · EXPLOTACIÓN SUID',
      subtitulo: 'Identifica el binario con permisos SUID mal configurados',
      icono: Icons.terminal_rounded,
      intentosRestantes: Nivel24Game.maxIntentosPorFase - _game.intentosFase2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.bgMain,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              r'$ find / -perm -u=s -type f 2>/dev/null',
              style: TextStyle(
                color: AppColors.cyan,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          ...PrivilegeData.binarios.map((binario) {
            final seleccionado = _game.binarioSeleccionado == binario.id;
            return _BinarioTile(
              binario: binario,
              seleccionado: seleccionado,
              onTap: () => setState(() => _game.seleccionarBinario(binario.id)),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _game.binarioSeleccionado == null
                  ? null
                  : _confirmarBinario,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                disabledBackgroundColor: AppColors.bgMain,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'EXPLOTAR BINARIO',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ── FASE 3 — Cronjob ──────────────────────────────────────────────────────
 
  Widget _buildFaseCronjob() {
    final progreso =
        _game.segundosRestantes / Nivel24Game.cronjobDuracionSegundos;
    final timerColor = progreso > 0.5
        ? AppColors.cyan
        : progreso > 0.25
            ? Colors.orange
            : AppColors.pink;
 
    return _Panel(
      titulo: 'FASE 3 · INYECCIÓN CRONJOB',
      subtitulo: 'Inyecta un comando en el script de root antes de que se ejecute',
      icono: Icons.settings_input_component_rounded,
      intentosRestantes: Nivel24Game.maxIntentosPorFase - _game.intentosFase3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timer visual
          Row(
            children: [
              Text(
                'TIEMPO: ${_game.segundosRestantes}s',
                style: TextStyle(
                  color: timerColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progreso,
                    backgroundColor: AppColors.bgMain,
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
 
          // Crontab viewer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgMain,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('# /etc/crontab',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 11)),
                const SizedBox(height: 8),
                ...PrivilegeData.cronjobs.map((cron) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${cron.schedule}  ${cron.usuario}  ${cron.rutaScript}',
                        style: TextStyle(
                          color: cron.esVulnerable
                              ? AppColors.cyan
                              : AppColors.textMuted,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: cron.esVulnerable
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
 
          const Text(
            'SELECCIONA EL COMANDO A INYECTAR:',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
 
          ...PrivilegeData.comandosDisponibles.map((cmd) {
            final seleccionado = _game.comandoInyectado == cmd;
            return GestureDetector(
              onTap: () => setState(() => _game.seleccionarComando(cmd)),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? AppColors.cyan.withOpacity(0.12)
                      : AppColors.bgMain.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: seleccionado
                        ? AppColors.cyan.withOpacity(0.6)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      seleccionado
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color:
                          seleccionado ? AppColors.cyan : AppColors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '> $cmd',
                        style: TextStyle(
                          color: seleccionado
                              ? AppColors.cyan
                              : Colors.white.withOpacity(0.7),
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
 
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _game.comandoInyectado == null ? null : _confirmarComando,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink,
                disabledBackgroundColor: AppColors.bgMain,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'INYECTAR COMANDO',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ── TERMINAL DE MENSAJES ──────────────────────────────────────────────────
 
  Widget _buildTerminal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyan.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.pink, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Container(width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: Colors.orange, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: AppColors.cyan, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(
                'megacorp-srv01 ~ \$',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                    fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Text(
            _game.mensajeSistema,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
 
  // ── HELPERS ───────────────────────────────────────────────────────────────
 
  Color _accessColor(AccessLevel level) {
    switch (level) {
      case AccessLevel.guest:
        return AppColors.textMuted;
      case AccessLevel.user:
        return AppColors.cyan;
      case AccessLevel.admin:
        return Colors.orange;
      case AccessLevel.root:
        return AppColors.pink;
    }
  }
 
  String _accessLabel(AccessLevel level) {
    switch (level) {
      case AccessLevel.guest:
        return 'GUEST';
      case AccessLevel.user:
        return 'USER';
      case AccessLevel.admin:
        return 'ADMIN';
      case AccessLevel.root:
        return 'ROOT';
    }
  }
 
  IconData _accessIcon(AccessLevel level) {
    switch (level) {
      case AccessLevel.guest:
        return Icons.person_outline_rounded;
      case AccessLevel.user:
        return Icons.lock_open_rounded;
      case AccessLevel.admin:
        return Icons.admin_panel_settings_rounded;
      case AccessLevel.root:
        return Icons.key_rounded;
    }
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═════════════════════════════════════════════════════════════════════════════
 
// ── Panel genérico ────────────────────────────────────────────────────────────
 
class _Panel extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final int intentosRestantes;
  final Widget child;
 
  const _Panel({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.intentosRestantes,
    required this.child,
  });
 
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
            final tieneAlturaLimitada = constraints.hasBoundedHeight;

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
                    Row(
                        children: [
                        Icon(
                            icono, 
                            size:18
                            ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                titulo,
                                style: TextStyle(
                                    color: AppColors.cyan.withOpacity(0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                ),
                                ),
                                Text(
                                subtitulo,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 11,
                                ),
                                ),
                            ],
                            ),
                        ),
                        Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                            color: intentosRestantes > 1
                                ? AppColors.cyan.withOpacity(0.1)
                                : AppColors.pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: intentosRestantes > 1
                                    ? AppColors.cyan.withOpacity(0.35)
                                    : AppColors.pink.withOpacity(0.35),
                            ),
                            ),
                            child: Text(
                            '$intentosRestantes intentos',
                            style: TextStyle(
                                color: intentosRestantes > 1
                                    ? AppColors.cyan
                                    : AppColors.pink,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                            ),
                            ),
                        ),
                        ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 14),

                    if (tieneAlturaLimitada)
                        Expanded(
                            child: SingleChildScrollView(
                            child: child,
                            ),
                        )
                    else
                        child,
                    ],
                ),
            );
            },
    );
    }
}
 
// ── Tile de archivo ───────────────────────────────────────────────────────────
 
class _ArchivoTile extends StatelessWidget {
  final PrivilegeFile archivo;
  final bool seleccionado;
  final VoidCallback onTap;
 
  const _ArchivoTile({
    required this.archivo,
    required this.seleccionado,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final color = seleccionado ? AppColors.cyan : AppColors.purple;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? color.withOpacity(0.1)
              : AppColors.bgMain.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionado ? color.withOpacity(0.5) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
                archivo.icono, 
                color: seleccionado ? AppColors.cyan : AppColors.purple,
                size: 20,
                ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    archivo.nombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    archivo.ruta,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    archivo.descripcion,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      archivo.contenidoSimulado,
                      style: const TextStyle(
                          color: Colors.green,
                          fontFamily: 'monospace',
                          fontSize: 10,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              seleccionado
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Tile de binario ───────────────────────────────────────────────────────────
 
class _BinarioTile extends StatelessWidget {
  final PrivilegeBinary binario;
  final bool seleccionado;
  final VoidCallback onTap;
 
  const _BinarioTile({
    required this.binario,
    required this.seleccionado,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final color = seleccionado ? AppColors.cyan : AppColors.purple;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? color.withOpacity(0.1)
              : AppColors.bgMain.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionado ? color.withOpacity(0.5) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    binario.nombre,
                    style: TextStyle(
                        color: seleccionado ? AppColors.cyan : Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${binario.permisos}  ${binario.propietario}',
                    style: TextStyle(
                        color: binario.permisos.contains('s')
                            ? Colors.orange
                            : AppColors.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    binario.descripcion,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              seleccionado
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Diálogo de resultado ──────────────────────────────────────────────────────
 
class _DialogoResultado extends StatelessWidget {
  final bool exito;
  final int xp;
  final String rango;
  final bool entrenamiento;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;
 
  const _DialogoResultado({
    required this.exito,
    required this.xp,
    required this.rango,
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
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 30)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
              color: color,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              exito ? 'ACCESO ROOT CONSEGUIDO' : 'ACCESO DENEGADO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            if (exito && rango.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                rango,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                    letterSpacing: 2),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              '$xp XP',
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            if (entrenamiento) ...[
              const SizedBox(height: 8),
              Text(
                'Modo entrenamiento · puntos no guardados',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.purple.withOpacity(0.65), fontSize: 11),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReintentar,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.purple.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('REINTENTAR',
                    style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
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
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  exito ? 'CONTINUAR' : 'SALIR',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── Tutorial ──────────────────────────────────────────────────────────────────
 
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
    final ctx = paso.targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
 
  @override
  Widget build(BuildContext context) {
    final target = _targetRect();
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(builder: (context, constraints) {
          const cardWidth = 320.0;
          const margin = 18.0;
          final size = constraints.biggest;
          final left =
              ((paso.alignment.x + 1) / 2) * (size.width - cardWidth);
          final top = ((paso.alignment.y + 1) / 2) * (size.height - 200);
 
          return Stack(children: [
            Positioned.fill(
              child: ClipPath(
                clipper: _HoleClipper(target),
                child: Container(color: Colors.black.withOpacity(0.75)),
              ),
            ),
            if (target != null)
              Positioned.fromRect(
                rect: target.inflate(6),
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.cyan.withOpacity(0.9), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.cyan.withOpacity(0.3),
                            blurRadius: 20)
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: left.clamp(margin, size.width - cardWidth - margin),
              top: top.clamp(margin, size.height - 230),
              child: SizedBox(
                width: cardWidth,
                child: _TutorialCard(
                  paso: paso,
                  pasoActual: pasoActual,
                  totalPasos: totalPasos,
                  onContinuar: onContinuar,
                  onSaltar: onSaltar,
                ),
              ),
            ),
          ]);
        }),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('TUTORIAL $pasoActual/$totalPasos',
                style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const Spacer(),
            TextButton(
              onPressed: onSaltar,
              child: Text('SALTAR',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(paso.titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(paso.descripcion,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.45)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                pasoActual == totalPasos ? 'ENTENDIDO' : 'SIGUIENTE',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
class _HoleClipper extends CustomClipper<Path> {
  final Rect? target;
  const _HoleClipper(this.target);
 
  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (target != null) {
      path.addRRect(RRect.fromRectAndRadius(
          target!.inflate(8), const Radius.circular(14)));
    }
    return path;
  }
 
  @override
  bool shouldReclip(covariant _HoleClipper old) => old.target != target;
}