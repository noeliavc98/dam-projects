import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../games/nivel_07/nivel07_game.dart';
import '../games/nivel_07/components/datos_nivel07.dart';

class Nivel07Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel07Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel07Screen> createState() => _Nivel07ScreenState();
}

class _Nivel07ScreenState extends State<Nivel07Screen> {
  final _game = Nivel07Game();
  final TextEditingController _guessController = TextEditingController();

  //Fractura
  bool _mostrarFractura = true;
  bool _mostrarFracturaFinal = false;

  int _mobileIndex = 1;
  bool _gameOver = false;
  bool _nivelYaCompletado = false;
  bool _guardando = false;
  String _feedback =
      'Introduce una clave de ${DatosNivel07.password.length} caracteres. Los aciertos exactos se marcarán en verde.';

  @override
  void initState() {
    super.initState();
    _setupNivel();
  }

  Future<void> _setupNivel() async {
    _nivelYaCompletado = widget.soloEntrenamiento;
    if (!widget.soloEntrenamiento) {
      try {
        final datos = await FirestoreService.obtenerUsuario();
        final nivelUsuario = datos['nivel'] ?? 1;
        _nivelYaCompletado = nivelUsuario > 7;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 7: $e');
      }
    }

    try {
      await MusicService().playNiveles6to10Music();
    } catch (e) {
      debugPrint('Error iniciando musica del nivel 7: $e');
    }

    if (mounted) setState(() {});
  }

  Future<void> _salirDelNivel() async {
    if (!mounted) return;
    Navigator.pop(context);
  }


  Future<void> _submitGuess() async {
    if (_guardando) return;

    final texto = _guessController.text.trim().toLowerCase();
    if (texto.length != DatosNivel07.password.length) {
      setState(() {
        _feedback =
            'La clave debe tener exactamente ${DatosNivel07.password.length} caracteres.';
      });
      return;
    }

    if (!RegExp(r'^[a-z0-9]+$').hasMatch(texto)) {
      setState(() {
        _feedback =
            'Solo se permiten letras minúsculas y números en este laboratorio.';
      });
      return;
    }

    final resultado = _game.submitGuess(texto);
    _guessController.clear();

    setState(() {
      _feedback = resultado.feedback;
      if (resultado.gameOver) _gameOver = true;
    });

    if (_gameOver) return;

    if (resultado.correcto) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await _completarReto();
    }
  }

  Future<void> _completarReto() async {
    setState(() => _guardando = true);

    if (!_nivelYaCompletado) {
      try {
        await FirestoreService.guardarPuntuacion(
          puntos: DatosNivel07.puntosNivel,
          nivelCompletado: 7,
          soloEntrenamiento: widget.soloEntrenamiento,
        );
        await FirestoreService.guardarMision(
          nivel: 7,
          mision: 1,
          puntos: DatosNivel07.puntosNivel,
        );
      } catch (e) {
        debugPrint('No se pudo guardar progreso del nivel 7: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _guardando = false;
      _mostrarFracturaFinal = true;
    });
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  void _reiniciarNivel() {
    _game.reiniciar();
    setState(() {
      _guessController.clear();
      _gameOver = false;
      _feedback =
          'Introduce una clave de ${DatosNivel07.password.length} caracteres. Los aciertos exactos se marcarán en verde.';
    });
  }

  Widget _buildGameOverView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.heart_broken_rounded,
                  color: Color(0xFFEF4444),
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'SIN VIDAS',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Has agotado las 3 vidas tras ${_game.intentos} intentos.\nLos sistemas de seguridad han bloqueado el acceso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reiniciarNivel,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('REINTENTAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _salirDelNivel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'SALIR',
                      style: TextStyle(letterSpacing: 2),
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

  Widget _buildDialogView({
    required List<String> lines,
    required int index,
    required String subtitle,
    required VoidCallback onNext,
    required bool isLast,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imgSize = (constraints.maxWidth * 0.35).clamp(100.0, 220.0);
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
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.30),
                  ),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: 'Volver al mapa',
                        child: _IconButtonFrame(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () async => _salirDelNivel(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _NarratorImage(size: imgSize),
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
                      subtitle,
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          lines[index],
                          key: ValueKey('$subtitle-$index'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${index + 1} / ${lines.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          isLast ? 'CONTINUAR' : 'SIGUIENTE',
                          style: const TextStyle(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainLevelView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) return _buildJuegoDesktop();
        if (constraints.maxWidth >= 600) return _buildJuegoTablet();
        return _buildJuegoMobile();
      },
    );
  }

  Widget _buildJuegoMobile() {
    final header = _LevelHeader(
      xp: _game.xp,
      attempts: _game.intentos,
      vidas: _game.vidas,
      training: _nivelYaCompletado,
      onExit: _salirDelNivel,
    );

    return Column(
      children: [
        header,
        Expanded(
          child: IndexedStack(
            index: _mobileIndex,
            children: [
              const _NarrativeColumn(),
              _buildTerminalPanel(),
              _buildMetricsPanel(),
            ],
          ),
        ),
        NavigationBar(
          backgroundColor: AppColors.bgCard,
          indicatorColor: AppColors.cyan.withValues(alpha: 0.15),
          selectedIndex: _mobileIndex,
          onDestinationSelected: (value) => setState(() => _mobileIndex = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Narrador',
            ),
            NavigationDestination(
              icon: Icon(Icons.terminal_outlined),
              selectedIcon: Icon(Icons.terminal_rounded),
              label: 'Terminal',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Estado',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJuegoTablet() {
    final sidebarHeight = MediaQuery.of(context).size.height * 0.28;
    final center = _TerminalWordleCard(
      controller: _guessController,
      guesses: _game.guesses,
      feedback: _feedback,
      saving: _guardando,
      onSubmit: _submitGuess,
    );
    final right = _MetricsColumn(
      attempts: _game.intentos,
      correctPositions: _game.posicionesCorrectas,
      bestPattern: _game.mejorPatron,
      hints: _game.pistasVisibles,
      nextHintIn: _game.intentos >= DatosNivel07.pistasDesbloqueables.length * 2
          ? 0
          : 2 - (_game.intentos % 2),
    );

    return Column(
      children: [
        _LevelHeader(
          xp: _game.xp,
          attempts: _game.intentos,
          vidas: _game.vidas,
          training: _nivelYaCompletado,
          onExit: _salirDelNivel,
        ),
        SizedBox(
          height: sidebarHeight,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _NarrativeColumn(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: center),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJuegoDesktop() {
    final center = _buildTerminalPanel();
    final right = _buildMetricsPanel();

    return Column(
      children: [
        _LevelHeader(
          xp: _game.xp,
          attempts: _game.intentos,
          vidas: _game.vidas,
          training: _nivelYaCompletado,
          onExit: _salirDelNivel,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 3, child: _NarrativeColumn()),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: center),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalPanel() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _TerminalWordleCard(
        controller: _guessController,
        guesses: _game.guesses,
        feedback: _feedback,
        saving: _guardando,
        onSubmit: _submitGuess,
      ),
    );
  }

  Widget _buildMetricsPanel() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _MetricsColumn(
        attempts: _game.intentos,
        correctPositions: _game.posicionesCorrectas,
        bestPattern: _game.mejorPatron,
        hints: _game.pistasVisibles,
        nextHintIn: _game.intentos >= DatosNivel07.pistasDesbloqueables.length * 2
            ? 0
            : 2 - (_game.intentos % 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarFractura) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Container(
          color: Colors.black.withValues(alpha: 0.80),
          child: FracturaDialogo(
            dialogos: DatosNivel07.dialogosIntro,
            subtitulo: 'NIVEL 7 // FUERZA BRUTA',
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
              await _setupNivel();
            },
          ),
        ),
      );
    }
    if (_mostrarFracturaFinal) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Container(
          color: Colors.black.withValues(alpha: 0.80),
          child: FracturaDialogo(
            dialogos: DatosNivel07.dialogosFinales,
            subtitulo: 'COMO LO HARÍA UN ORDENADOR',
            textoBotonFinal: 'CONTINUAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () {
              setState(() => _mostrarFracturaFinal = false);
              _completarReto();
              _salirDelNivel();
            },
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _gameOver ? _buildGameOverView() : _buildMainLevelView(),
        ),
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final int xp;
  final int attempts;
  final int vidas;
  final bool training;
  final Future<void> Function() onExit;

  const _LevelHeader({
    required this.xp,
    required this.attempts,
    required this.vidas,
    required this.training,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.fromLTRB(isSmall ? 10 : 16, 12, isSmall ? 10 : 16, 8),
      child: Row(
        children: [
          Tooltip(
            message: 'Volver al mapa',
            child: _IconButtonFrame(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () async => onExit(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'NIVEL 7 - FUERZA BRUTA',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                if (!isSmall)
                  Text(
                    training
                        ? 'ENTRENAMIENTO // FUERZA BRUTA DE CLAVE'
                        : 'INTRUSION // FUERZA BRUTA DE CLAVE',
                    style: TextStyle(
                      color: AppColors.cyan.withValues(alpha: 0.75),
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),
          _HeaderStat(
            label: 'INTENTOS',
            value: '$attempts',
            color: AppColors.pink,
          ),
          const SizedBox(width: 8),
          _LivesStat(vidas: vidas),
          const SizedBox(width: 6),
          _HeaderStat(label: 'XP', value: '$xp', color: AppColors.cyan),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 8,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivesStat extends StatelessWidget {
  final int vidas;

  const _LivesStat({required this.vidas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            'VIDAS',
            style: TextStyle(
              color: AppColors.pink.withValues(alpha: 0.75),
              fontSize: 8,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
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
        ],
      ),
    );
  }
}

class _NarrativeColumn extends StatelessWidget {
  const _NarrativeColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _NarratorSideCard(),
        SizedBox(height: 12),
        Expanded(child: SingleChildScrollView(child: _LessonCard())),
      ],
    );
  }
}

class _NarratorSideCard extends StatelessWidget {
  const _NarratorSideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const _NarratorImage(size: 108),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FRACTURA',
                  style: TextStyle(
                    color: AppColors.cyan.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ENTIDAD NO CLASIFICADA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Prueba. Observa.\nReduce el universo.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
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

class _LessonCard extends StatelessWidget {
  const _LessonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
      ),
      child: const Text(
        'TRANSMISION // NIVEL 7\n\n'
        'El terminal compara tu intento con una clave ficticia.\n\n'
        'Verde significa carácter correcto en posición correcta. Amarillo significa que el carácter existe, pero está en otra posición.\n\n'
        'Haz lo que haría una máquina, pero despacio: conserva los aciertos, cambia lo dudoso y repite hasta encontrar la clave.',
        style: TextStyle(color: Colors.white, fontSize: 14, height: 1.7),
      ),
    );
  }
}

class _TerminalWordleCard extends StatelessWidget {
  final TextEditingController controller;
  final List<String> guesses;
  final String feedback;
  final bool saving;
  final VoidCallback onSubmit;

  const _TerminalWordleCard({
    required this.controller,
    required this.guesses,
    required this.feedback,
    required this.saving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TERMINAL // FUERZA BRUTA ',
            style: TextStyle(
              color: AppColors.cyan.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          const _PolicyBox(),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.18)),
              ),
              child: guesses.isEmpty
                  ? Text(
                      '> esperando primer candidato...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    )
                  : ListView.separated(
                      itemCount: guesses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _GuessRow(guess: guesses[index]);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            maxLength: DatosNivel07.password.length,
            onSubmitted: (_) => onSubmit(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixText: '> ',
              prefixStyle: const TextStyle(
                color: AppColors.cyan,
                fontFamily: 'monospace',
              ),
              hintText: 'prueba una clave...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: AppColors.bgMain.withValues(alpha: 0.6),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.cyan.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feedback,
            style: TextStyle(
              color: AppColors.purple.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSubmit,
              icon: Icon(
                saving ? Icons.sync_rounded : Icons.keyboard_return_rounded,
              ),
              label: Text(saving ? 'VALIDANDO' : 'PROBAR CANDIDATO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.25),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuessRow extends StatelessWidget {
  final String guess;

  const _GuessRow({required this.guess});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final target = DatosNivel07.password;
        final length = target.length;
        final cellSize = ((constraints.maxWidth - ((length - 1) * 6)) / length)
            .clamp(30.0, 48.0);
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(length, (index) {
            final char = guess[index];
            final exact = char == target[index];
            final present = !exact && target.contains(char);
            final color = exact
                ? const Color(0xFF22C55E)
                : present
                ? const Color(0xFFEAB308)
                : AppColors.bgMain;
            return Container(
              width: cellSize,
              height: cellSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: exact || present ? 0.85 : 0.65),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: exact
                      ? const Color(0xFF86EFAC)
                      : present
                      ? const Color(0xFFFDE047)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                char.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PolicyBox extends StatelessWidget {
  const _PolicyBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Política filtrada:\n'
        '- Longitud exacta: ${DatosNivel07.password.length} caracteres\n'
        '- Caracteres permitidos: a-z y 0-9\n'
        '- Verde: posición correcta\n'
        '- Amarillo: existe, posición incorrecta',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _MetricsColumn extends StatelessWidget {
  final int attempts;
  final int correctPositions;
  final String bestPattern;
  final List<String> hints;
  final int nextHintIn;
  const _MetricsColumn({
    required this.attempts,
    required this.correctPositions,
    required this.bestPattern,
    required this.hints,
    required this.nextHintIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _InfoCard(
            title: 'ESTADO',
            child: Column(
              children: [
                _MetricRow(label: 'Intentos manuales', value: '$attempts'),
                _MetricRow(
                  label: 'Posiciones verdes',
                  value: '$correctPositions / ${DatosNivel07.password.length}',
                ),
                _MetricRow(label: 'Patrón conocido', value: bestPattern),
                _MetricRow(
                  label: 'Espacio base',
                  value: '36^${DatosNivel07.password.length}',
                ),
                _MetricRow(label: 'Con pista de formato', value: 'mucho menor'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _InfoCard(
            title: 'PISTAS',
            child: hints.isEmpty
                ? Text(
                    'Aún no hay pistas desbloqueadas.\n',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  )
                : ListView(
                    children: [
                      for (final hint in hints) _HintText(hint),
                      if (nextHintIn > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Siguiente pista en $nextHintIn intento${nextHintIn == 1 ? '' : 's'} más.',
                          style: TextStyle(
                            color: AppColors.purple.withValues(alpha: 0.85),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _HintText extends StatelessWidget {
  final String text;

  const _HintText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '- $text',
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
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
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarratorImage extends StatelessWidget {
  final double size;

  const _NarratorImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.45), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.cyan.withValues(alpha: 0.18), blurRadius: 18),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/narrador_fractura.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _IconButtonFrame extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonFrame({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: AppColors.cyan, size: 16),
      ),
    );
  }
}
