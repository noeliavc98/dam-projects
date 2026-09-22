import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../games/nivel_25/components/defensa_boss.dart';
import '../games/nivel_25/components/resultado_boss.dart';
import '../games/nivel_25/nivel25_game.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';

class Nivel25Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel25Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel25Screen> createState() => _Nivel25ScreenState();
}

class _Nivel25ScreenState extends State<Nivel25Screen> {
  final Nivel25Game _game = Nivel25Game();

  bool _loading = true;
  bool _introVisible = true;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;

  String _mensajeFractura =
      'El Núcleo Cero está cargando el primer ataque. Observa la cadena.';
  Color? _flashColor;
  @override
  void initState() {
    super.initState();
    _setupLevel();
  }

  Future<void> _setupLevel() async {
    try {
      await MusicService().playNiveles21to25Music();
    } catch (e) {
      debugPrint('Error iniciando música nivel 25: $e');
    }
    _nivelYaCompletado = widget.soloEntrenamiento;

    if (!widget.soloEntrenamiento) {
      try {
        final data = await FirestoreService.obtenerUsuario();
        final level = (data['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = level > 25;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 25: $e');
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _guardarProgreso() async {
    if (_progresoGuardado || _nivelYaCompletado) return;

    _progresoGuardado = true;

    try {
      await FirestoreService.guardarPuntuacion(
        puntos: _game.xp,
        nivelCompletado: 25,
        soloEntrenamiento: widget.soloEntrenamiento,
      );

      await FirestoreService.guardarMision(
        nivel: 25,
        mision: 25,
        puntos: _game.xp,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso del nivel 25: $e');
    }
  }

  void _volverAlMapa() {
    Navigator.pop(context);
  }

  void _toggleDefensa(DefensaBoss defensa) {
    setState(() {
      _game.toggleDefensa(defensa);
    });
  }

  void _mostrarFlash(Color color) {
    setState(() {
      _flashColor = color;
    });

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _flashColor = null;
      });
    });
  }

  Future<void> _resolverRonda() async {
    final ResultadoBoss resultado = _game.resolverRonda();
    final cambioFase = _game.comprobarCambioFase();
    _mostrarFlash(resultado.correcto ? AppColors.cyan : AppColors.pink);

    setState(() {
      _mensajeFractura = resultado.mensaje;
      if (cambioFase != null) {
        _mensajeFractura = cambioFase;
      } else {
        _mensajeFractura = resultado.mensaje;
      }
    });

    if (resultado.victoria) {
      await _guardarProgreso();
      if (!mounted) return;
      _mostrarVictoria();
      return;
    }

    if (resultado.derrota) {
      _mostrarDerrota();
    }
  }

  void _pedirPista() {
    setState(() {
      _mensajeFractura = _game.pedirPista();
    });
  }

  void _reiniciarNivel() {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Nivel25Screen(soloEntrenamiento: widget.soloEntrenamiento),
      ),
    );
  }

  void _mostrarVictoria() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultadoFinalBossDialog(
        titulo: _game.protocoloOrigen
            ? 'PROTOCOLO ORIGEN'
            : 'NÚCLEO CERO NEUTRALIZADO',
        subtitulo: _game.protocoloOrigen
            ? 'Has desbloqueado el cierre legendario de Cyber Ops.'
            : 'Has superado Hora Cero.',
        xp: _game.xp,
        exito: true,
        onReintentar: _reiniciarNivel,
        onSalir: () { Navigator.pop(context); _volverAlMapa(); },
      ),
    );
  }

  void _mostrarDerrota() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultadoFinalBossDialog(
        titulo: 'HORA CERO FALLIDA',
        subtitulo: 'El Núcleo Cero ha roto la defensa final.',
        xp: _game.xp,
        exito: false,
        onReintentar: _reiniciarNivel,
        onSalir: () { Navigator.pop(context); _volverAlMapa(); },
      ),
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

    if (_introVisible) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: FracturaDialogo(
            dialogos: _game.dialogosIntro,
            subtitulo: 'NIVEL 25 // HORA CERO',
            textoBotonFinal: 'ENTRAR AL NÚCLEO',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () {
              setState(() {
                _introVisible = false;
              });
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_nivelYaCompletado) _buildTrainingBanner(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 900;

                  if (compact) {
                    return _buildMobileBody();
                  }

                  return _buildDesktopBody();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'NIVEL 25 - HORA CERO',
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
          _MetricPill(label: 'FASE', value: _game.faseActual),
          const SizedBox(width: 8),
          _MetricPill(label: 'COMBO', value: 'x${_game.combo}'),
          const SizedBox(width: 8),
          _MetricPill(label: 'XP', value: '${_game.xp}'),
        ],
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
      child: const Text(
        'MODO ENTRENAMIENTO - Progreso no guardado',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.purple,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  Widget _buildDesktopBody() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(flex: 5, child: _buildBossPanel()),
          const SizedBox(width: 14),
          Expanded(flex: 5, child: _buildDefensesPanel()),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(height: 520, child: _buildBossPanel()),
        const SizedBox(height: 12),
        SizedBox(height: 720, child: _buildDefensesPanel()),
      ],
    );
  }

  Widget _buildBossPanel() {
    final ataque = _game.ataqueActual;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('NÚCLEO CERO'),
          const SizedBox(height: 12),
          _HealthBar(
            label: 'INTEGRIDAD DEL JUGADOR',
            value: _game.vidaJugador,
            color: AppColors.cyan,
          ),
          const SizedBox(height: 10),
          _HealthBar(
            label: 'VIDA DEL BOSS',
            value: _game.vidaBoss,
            color: AppColors.pink,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.pink.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.blur_on_rounded,
                    color: AppColors.pink.withValues(alpha: 0.9),
                    size: 82,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    ataque.titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.pink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ataque.descripcion,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Defensas clave: ${ataque.defensasCorrectas.length} · puedes seleccionar hasta 5',
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FracturaMessage(text: _mensajeFractura),
        ],
      ),
    );
  }

  Widget _buildDefensesPanel() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('ARSENAL DEFENSIVO'),
          const SizedBox(height: 10),
          Text(
            'Selecciona las defensas adecuadas para cortar el ataque actual.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              itemCount: _game.defensas.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisExtent: 112,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final defensa = _game.defensas[index];
                final selected = _game.defensasSeleccionadas.contains(
                  defensa.id,
                );

                return _DefenseCard(
                  defensa: defensa,
                  selected: selected,
                  bloqueada: defensa.id == _game.defensaBloqueada,
                  onTap: () => _toggleDefensa(defensa),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pedirPista,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('PISTA'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _game.puedeResolver ? _resolverRonda : null,
                  icon: const Icon(Icons.security_rounded),
                  label: Text(
                    _game.defensasSeleccionadas.isEmpty
                        ? 'ELIGE DEFENSAS'
                        : 'DEFENDER (${_game.defensasSeleccionadas.length})',
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

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
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
        color: AppColors.cyan,
        fontSize: 11,
        fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 2),
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

class _HealthBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _HealthBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label · $value%',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppColors.bgMain,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FracturaMessage extends StatelessWidget {
  final String text;

  const _FracturaMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgMain.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.purple,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefenseCard extends StatelessWidget {
  final DefensaBoss defensa;
  final bool selected;
  final VoidCallback onTap;
  final bool bloqueada;

  const _DefenseCard({
    required this.defensa,
    required this.selected,
    required this.onTap,
    required this.bloqueada,
  });

  @override
  Widget build(BuildContext context) {
    final color = bloqueada
        ? AppColors.pink
        : selected
        ? AppColors.cyan
        : AppColors.purple;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : AppColors.bgMain.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.shield_rounded : Icons.shield_outlined,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bloqueada ? '${defensa.nombre} 🔒' : defensa.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? color : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                defensa.descripcion,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoFinalBossDialog extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int xp;
  final bool exito;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _ResultadoFinalBossDialog({
    required this.titulo,
    required this.subtitulo,
    required this.xp,
    required this.exito,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final color = exito ? AppColors.cyan : AppColors.pink;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 28),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                exito ? Icons.emoji_events_rounded : Icons.gpp_bad_rounded,
                color: color,
                size: 54,
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgMain,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReintentar,
                      child: const Text('REINTENTAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSalir,
                      child: const Text('SALIR'),
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
