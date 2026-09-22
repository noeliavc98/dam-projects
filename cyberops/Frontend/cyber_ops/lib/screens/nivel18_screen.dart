import 'package:cyber_ops/games/nivel_18/components/linea_terminal.dart';
import 'package:cyber_ops/games/nivel_18/components/resultado_terminal.dart';
import 'package:cyber_ops/games/nivel_18/nivel18_game.dart';
import 'package:flutter/material.dart';

import '../services/music_service.dart';

import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';

class Nivel18Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel18Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel18Screen> createState() => _Nivel18ScreenState();
}

class _Nivel18ScreenState extends State<Nivel18Screen> {
  final Nivel18Game _game = Nivel18Game();
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _mostrarIntro = true;
  bool _nivelYaCompletado = false;
  bool _progresoGuardado = false;

  String _ultimoMensaje = 'Terminal preparada. Escribe help para comenzar.';

  @override
  void initState() {
    super.initState();
    MusicService().stopMusic();
    _setupLevel();
  }

  Future<void> _setupLevel() async {
    _nivelYaCompletado = widget.soloEntrenamiento;

    if (!widget.soloEntrenamiento) {
      try {
        final data = await FirestoreService.obtenerUsuario();
        final level = (data['nivel'] as num?)?.toInt() ?? 1;
        _nivelYaCompletado = level > 18;
      } catch (e) {
        debugPrint('No se pudo comprobar progreso del nivel 18: $e');
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
        nivelCompletado: 18,
        soloEntrenamiento: widget.soloEntrenamiento,
      );

      await FirestoreService.guardarMision(
        nivel: 18,
        mision: 18,
        puntos: _game.xp,
      );
    } catch (e) {
      _progresoGuardado = false;
      debugPrint('No se pudo guardar progreso del nivel 18: $e');
    }
  }

  void _volverAlMapa() {
    Navigator.of(context).pop();
  }

  void _ejecutarComando([String? comandoManual]) {
    final comando = comandoManual ?? _commandController.text;
    final ResultadoTerminal resultado = _game.ejecutarComando(comando);

    setState(() {
      _ultimoMensaje = resultado.salida;
      _commandController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    if (_game.fallido) {
      _mostrarDerrota();
      return;
    }

    if (resultado.nivelCompletado) {
      _mostrarVictoria();
    }
  }

  void _mostrarVictoria() async {
    await _guardarProgreso();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _ResultadoNivel18Dialog(
          titulo: 'VAULT DESCIFRADO',
          subtitulo: widget.soloEntrenamiento
              ? 'Completado en modo entrenamiento'
              : 'Has completado el nivel de cifrado',
          xp: _game.xp,
          exito: true,
          onReintentar: () {
            Navigator.of(dialogContext).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    Nivel18Screen(soloEntrenamiento: widget.soloEntrenamiento),
              ),
            );
          },
          onSalir: () {
            Navigator.of(dialogContext).pop();
            _volverAlMapa();
          },
        );
      },
    );
  }

  void _mostrarDerrota() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _ResultadoNivel18Dialog(
          titulo: 'CIFRADO BLOQUEADO',
          subtitulo: 'Has agotado las vidas intentando operaciones inválidas',
          xp: _game.xp,
          exito: false,
          onReintentar: () {
            Navigator.of(dialogContext).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    Nivel18Screen(soloEntrenamiento: widget.soloEntrenamiento),
              ),
            );
          },
          onSalir: () {
            Navigator.of(dialogContext).pop();
            _volverAlMapa();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    if (_mostrarIntro) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: FracturaDialogo(
            subtitulo: 'CIFRADO // CÁMARA DE CLAVES',
            textoBotonFinal: 'ABRIR TERMINAL',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            dialogos: _game.dialogosIntro,
            onFinalizado: () {
              MusicService().playNivel17Music();
              setState(() {
                _mostrarIntro = false;
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
            _buildTopBar(),
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

  Widget _buildTopBar() {
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
              'NIVEL 18 - CIFRADO',
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
          _MetricPill(label: 'FASE', value: _game.faseActual.label),
          const SizedBox(width: 8),
          _MetricPill(label: 'VIDAS', value: '${_game.vidas}'),
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
          Expanded(flex: 6, child: _buildTerminalPanel()),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: _buildSidePanel()),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(height: 520, child: _buildTerminalPanel()),
        const SizedBox(height: 12),
        _buildSidePanel(),
      ],
    );
  }

  Widget _buildTerminalPanel() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('TERMINAL DE CIFRADO'),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.25),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _game.historial.length,
                itemBuilder: (context, index) {
                  final linea = _game.historial[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      linea.texto,
                      style: TextStyle(
                        color: _getColorLinea(linea.tipo),
                        fontSize: 13,
                        height: 1.45,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commandController,
                  onSubmitted: (_) => _ejecutarComando(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe un comando...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: AppColors.bgMain,
                    prefixText: '> ',
                    prefixStyle: const TextStyle(
                      color: AppColors.cyan,
                      fontFamily: 'monospace',
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.cyan),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _ejecutarComando,
                child: const Text('EJECUTAR'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('COMANDOS SUGERIDOS'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _game.comandosSugeridos.map((comando) {
              return ActionChip(
                label: Text(comando.texto),
                onPressed: () => _ejecutarComando(comando.texto),
                backgroundColor: AppColors.bgMain,
                labelStyle: const TextStyle(color: AppColors.cyan),
                side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.35)),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('ESTADO'),
          const SizedBox(height: 10),
          _StatusLine(label: 'Clave AES', active: _game.claveCargada),
          _StatusLine(label: 'IV', active: _game.ivCargado),
          _StatusLine(label: 'Vault descifrado', active: _game.vaultDescifrado),
          _StatusLine(label: 'Jackpot', active: _game.jackpotDesbloqueado),
          const SizedBox(height: 18),
          const _SectionLabel('ÚLTIMO EVENTO'),
          const SizedBox(height: 10),
          Text(
            _ultimoMensaje,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

Color _getColorLinea(TipoLineaTerminal tipo) {
  switch (tipo) {
    case TipoLineaTerminal.comando:
      return Colors.white;

    case TipoLineaTerminal.correcto:
      return AppColors.cyan;

    case TipoLineaTerminal.error:
      return AppColors.pink;

    case TipoLineaTerminal.sistema:
      return Colors.orangeAccent;

    case TipoLineaTerminal.easterEgg:
      return Colors.purpleAccent;

    case TipoLineaTerminal.jackpot:
      return Colors.amber;

    case TipoLineaTerminal.normal:
      return Colors.white70;
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

class _StatusLine extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusLine({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: active ? AppColors.cyan : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoNivel18Dialog extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int xp;
  final bool exito;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _ResultadoNivel18Dialog({
    required this.titulo,
    required this.subtitulo,
    required this.xp,
    required this.exito,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: exito ? AppColors.cyan : AppColors.pink,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (exito ? AppColors.cyan : AppColors.pink).withValues(
                alpha: 0.18,
              ),
              blurRadius: 22,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.lock_open_rounded : Icons.warning_amber_rounded,
              color: exito ? AppColors.cyan : AppColors.pink,
              size: 52,
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: exito ? AppColors.cyan : AppColors.pink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgMain,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '+$xp XP',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSalir,
                    child: const Text('SALIR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReintentar,
                    child: const Text('REINTENTAR'),
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
