import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/services/music_service.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import 'nivel20_game.dart';
import '../../config/app_styles.dart';
import '../../services/firestore_service.dart';

class Nivel20Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel20Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel20Screen> createState() => _Nivel20ScreenState();
}

class _Nivel20ScreenState extends State<Nivel20Screen> {
  final game = Nivel20Game();

  // ── FRACTURA ──────────────────────────────────────────────────────────────
  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Un zero-day no se busca. Se descubre.',
    'Una vulnerabilidad que nadie conoce. Ni el fabricante. Ni el sistema. Solo tú.',
    'Tienes exactamente cero días para reaccionar.',
    'Úsalo antes de que lo parcheen. El tiempo es el arma.',
  ];

  bool _nivelYaCompletado = false;
  bool _resultadoMostrado = false;

  @override
  void initState() {
    super.initState();
    MusicService().stopMusic();
    MusicService().playNivel17Music();
    game.addListener(() {
      if (mounted) setState(() {});
    });
    _setupNivel();
  }

  Future<void> _setupNivel() async {
    if (widget.soloEntrenamiento) {
      _nivelYaCompletado = true;
      return;
    }

    try {
      final datos = await FirestoreService.obtenerUsuario();
      final nivelUsuario = (datos['nivel'] as num?)?.toInt() ?? 1;
      _nivelYaCompletado = nivelUsuario > 20;
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _salirDelNivel() async {
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    MusicService().stopMusic();
    game.dispose();
    super.dispose();
  }

  Future<void> _guardarProgreso() async {
    if (_nivelYaCompletado || widget.soloEntrenamiento) return;

    try {
      await FirestoreService.guardarPuntuacion(
        puntos: game.xp,
        nivelCompletado: 20,
        soloEntrenamiento: widget.soloEntrenamiento,
      );
      await FirestoreService.guardarMision(
        nivel: 20,
        mision: 20,
        puntos: game.xp,
      );
      _nivelYaCompletado = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarFractura) {
      return Scaffold(
        body: Container(
          color: Colors.black.withValues(alpha: 0.80),
          child: FracturaDialogo(
            dialogos: _dialogosFractura,
            subtitulo: 'NIVEL 20 // ZERO DAY',
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
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.purple.withValues(alpha: 0.30),
              AppColors.bgMain,
              AppColors.bgMain,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 14),
                _panelObjetivo(),
                const SizedBox(height: 14),
                _modulos(),
                const SizedBox(height: 14),
                _terminal(),
                const SizedBox(height: 14),
                _vectores(),
                const SizedBox(height: 14),
                _acciones(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.92),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.purple),
            ),
            child: const Icon(
              Icons.security_outlined,
              color: AppColors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZERO DAY',
                  style: AppStyles.screenTitle.copyWith(
                    color: AppColors.pink,
                    fontSize: 20,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIVEL 20 · CASO ${game.casoActual + 1}/3',
                  style: AppStyles.small.copyWith(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _chip('${game.xp} pts', AppColors.cyan),
          const SizedBox(width: 10),
          _vidasChip(),
        ],
      ),
    );
  }

  Widget _panelObjetivo() {
    return _panel(
      color: AppColors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('OPERACIÓN ZERO DAY', AppColors.purple),
          const SizedBox(height: 6),
          const Text(
            'Un sistema crítico ejecuta código anómalo sin archivo visible en disco. '
            'Analiza los módulos del entorno y determina el vector real del ataque.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: game.progreso / 3,
            backgroundColor: Colors.white10,
            color: AppColors.cyan,
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Text(
            'Caso ${game.casoActual + 1}/3 · Módulos analizados: ${game.progreso}/3',
            style: const TextStyle(color: AppColors.cyan, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _modulos() {
    final datos = [
      (
        ModuloZeroDay.red,
        Icons.wifi_tethering,
        'RED',
        'Tráfico TLS válido. No hay MITM ni red abierta activa.',
        AppColors.cyan,
      ),
      (
        ModuloZeroDay.logs,
        Icons.article_outlined,
        'LOGS',
        'Eventos incompletos. El ataque evita dejar trazas persistentes.',
        AppColors.purple,
      ),
      (
        ModuloZeroDay.procesos,
        Icons.memory,
        'PROCESOS',
        'Payload ejecutándose en RAM. No existe binario asociado.',
        AppColors.pink,
      ),
      (
        ModuloZeroDay.archivos,
        Icons.folder_outlined,
        'ARCHIVOS',
        'No se detectan instaladores, USB ni documentos infectados.',
        AppColors.blue,
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final d in datos)
          SizedBox(
            width: 280,
            child: _moduloCard(
              modulo: d.$1,
              icono: d.$2,
              titulo: d.$3,
              descripcion: d.$4,
              color: d.$5,
            ),
          ),
      ],
    );
  }

  Widget _moduloCard({
    required ModuloZeroDay modulo,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Color color,
  }) {
    final activo = game.modulosAnalizados.contains(modulo);

    return GestureDetector(
      onTap: () => game.analizarModulo(modulo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.92),
          border: Border.all(
            color: activo ? color : color.withValues(alpha: 0.35),
          ),
          boxShadow: [
            if (activo)
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activo
                  ? game.caso.hallazgos[modulo]!
                  : 'Toca para analizar módulo...',
              style: TextStyle(
                color: activo ? Colors.white70 : Colors.white38,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _terminal() {
    final lineas = <String>[
      '> scan --zero-day',
      game.modulosAnalizados.contains(ModuloZeroDay.red)
          ? '[RED] ${game.caso.hallazgos[ModuloZeroDay.red]}'
          : '[RED] pendiente',
      game.modulosAnalizados.contains(ModuloZeroDay.logs)
          ? '[LOGS] ${game.caso.hallazgos[ModuloZeroDay.logs]}'
          : '[LOGS] pendiente',
      game.modulosAnalizados.contains(ModuloZeroDay.procesos)
          ? '[PROC] ${game.caso.hallazgos[ModuloZeroDay.procesos]}'
          : '[PROC] pendiente',
      game.modulosAnalizados.contains(ModuloZeroDay.archivos)
          ? '[FILES] ${game.caso.hallazgos[ModuloZeroDay.archivos]}'
          : '[FILES] pendiente',
    ];

    return _panel(
      color: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('CONSOLA FORENSE', AppColors.cyan),
          const SizedBox(height: 6),
          for (final l in lineas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                l,
                style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vectores() {
    final opciones = game.caso.opciones;

    return _panel(
      color: AppColors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('VEREDICTO TÉCNICO', AppColors.pink),
          const SizedBox(height: 10),
          Text(
            game.caso.pregunta,
            style: AppStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final o in opciones)
                _opcionVector(
                  id: o.id,
                  titulo: o.titulo,
                  descripcion: o.descripcion,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcionVector({
    required String id,
    required String titulo,
    required String descripcion,
  }) {
    final seleccionado = game.vectorSeleccionado == id;

    return SizedBox(
      width: 280,
      height: 92,
      child: GestureDetector(
        onTap: () => game.seleccionarVector(id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: seleccionado
                ? AppColors.pink.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: seleccionado ? AppColors.pink : Colors.white24,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: seleccionado ? AppColors.pink : Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  descripcion,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acciones() {
    final puede = game.puedeEmitirVeredicto && game.vectorSeleccionado != null;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _salirDelNivel(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.cyan,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'ZERO DAY',
          style: TextStyle(color: AppColors.pink, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.purple, width: 1.5),
            color: AppColors.purple.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              const Text(
                'NIVEL 20',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 1,
                height: 18,
                color: AppColors.purple.withValues(alpha: 0.4),
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              const Text(
                'IDENTIFICA LA VULNERABILIDAD',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ), 
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            game.puedeEmitirVeredicto
                ? 'Evidencia suficiente para emitir veredicto.'
                : 'Analiza al menos 3 módulos antes del veredicto.',
            style: TextStyle( 
              color: game.puedeEmitirVeredicto ? AppColors.cyan : Colors.white54,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: puede ? _confirmar : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // 👈 padding añadido
            decoration: BoxDecoration(
              color: puede
                  ? AppColors.pink.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: puede ? AppColors.pink : Colors.white24,
              ),
            ),
            child: Text(
              'EJECUTAR VEREDICTO',
              style: TextStyle(
                color: puede ? AppColors.pink : Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    final correcto = game.confirmar();

    if (game.misionCumplida) {
      await _guardarProgreso();

      if (_resultadoMostrado) return;
      _resultadoMostrado = true;

      _dialogoFinal(
        titulo: 'NIVEL COMPLETADO',
        mensaje: 'Has superado el Nivel 20. Puntos obtenidos: ${game.xp}.',
        color: AppColors.cyan,
        esVictoria: true,
      );
      return;
    }

    if (game.misionFallida) {
      _dialogoFinal(
        titulo: 'NIVEL FALLIDO',
        mensaje: 'No has superado el Nivel 20. Puedes volver a intentarlo.',
        color: AppColors.pink,
        esVictoria: false,
      );
      return;
    }

    if (correcto) {
      _dialogoCaso(
        titulo: 'CASO RESUELTO',
        mensaje: 'Vector correcto. Nuevo sistema cargado para análisis.',
        color: AppColors.cyan,
      );
      return;
    }

    _dialogoCaso(
      titulo: 'VEREDICTO INCORRECTO',
      mensaje:
          'Respuesta incorrecta. Revisa las evidencias antes de continuar.',
      color: AppColors.pink,
    );
  }

  void _dialogoCaso({
    required String titulo,
    required String mensaje,
    required Color color,
  }) {
    final esCorrecto = color == AppColors.cyan;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.92),
            border: Border.all(color: color, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esCorrecto ? Icons.check_circle_outline : Icons.error_outline,
                color: color,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              _dialogButton(
                texto: esCorrecto ? 'SIGUIENTE CASO' : 'CONTINUAR',
                color: color,
                onTap: () => Navigator.pop(c),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dialogoFinal({
    required String titulo,
    required String mensaje,
    required Color color,
    required bool esVictoria,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.92),
            border: Border.all(color: color, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esVictoria
                    ? Icons.emoji_events_outlined
                    : Icons.dangerous_outlined,
                color: color,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgMain.withValues(alpha: 0.65),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('${game.xp} pts', AppColors.cyan),
                    const SizedBox(width: 10),
                    _vidasChip(),
                  ],
                ),
              ),
              if (widget.soloEntrenamiento) ...[
                const SizedBox(height: 10),
                const Text(
                  'MODO ENTRENAMIENTO · No se guardará progreso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton(
                      texto: 'REINTENTAR',
                      color: AppColors.purple,
                      onTap: () {
                        Navigator.pop(c);
                        game.reiniciar();
                        _resultadoMostrado = false;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogButton(
                      texto: esVictoria ? 'CONTINUAR' : 'CERRAR',
                      color: color,
                      onTap: () {
                        Navigator.pop(c);
                        if (esVictoria && Navigator.canPop(context)) {
                          MusicService().playMenuMusic();
                          Navigator.pop(context);
                        }
                      },
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

  Widget _dialogButton({
    required String texto,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }

  Widget _panel({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.92),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _titulo(String texto, Color color) {
    return Text(
      texto,
      style: AppStyles.subtitle.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _vidasChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.pink),
        color: AppColors.pink.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.favorite,
                color: i < game.vidas
                    ? AppColors.pink
                    : AppColors.pink.withValues(alpha: 0.25),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(
        texto,
        style: AppStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
