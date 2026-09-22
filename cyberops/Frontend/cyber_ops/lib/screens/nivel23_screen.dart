import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../games/nivel_23/components/ddos_packet.dart';
import '../games/nivel_23/nivel23_game.dart';
import '../services/firestore_service.dart';
import '../services/music_service.dart';
import '../widgets/fractura/fractura_dialogo.dart';
import 'level_map_screen.dart';

class Nivel23Screen extends StatefulWidget {
  final bool soloEntrenamiento;

  const Nivel23Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel23Screen> createState() => _Nivel23ScreenState();
}

class _Nivel23ScreenState extends State<Nivel23Screen>
    with SingleTickerProviderStateMixin {
  final Nivel23Game game = Nivel23Game();
  bool progresoGuardado = false;
  bool dialogoFinalMostrado = false;
  late final AnimationController _anim;

  bool _mostrarFractura = true;
  final List<String> _dialogosFractura = [
    'Miles de máquinas atacando al mismo tiempo. Ninguna sabe que está siendo usada.',
    'Un ataque DDoS no busca robar datos. Busca silenciar. Tumbar. Hacer desaparecer.',
    'Cuando el servidor cae, nadie puede acceder. Hospitales, bancos, infraestructura crítica.',
    'Tu misión: identificar el tipo de ataque y cortar el flujo antes de que colapse todo.',
  ];

  @override
  void initState() {
    super.initState();
    game.iniciarRonda1();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void responderTipo(DdosType tipo) {
    if (game.fase == Nivel23Phase.completado ||
        game.fase == Nivel23Phase.fallado) {
      return;
    }

    final correcto = game.responderTipo(tipo);
    setState(() {});
    mostrarResultadoRespuesta(correcto);
  }

  void responderMitigacion(String opcion) {
    if (game.fase == Nivel23Phase.completado ||
        game.fase == Nivel23Phase.fallado) {
      return;
    }

    final correcto = game.responderMitigacion(opcion);
    setState(() {});
    mostrarResultadoRespuesta(correcto);
  }

  void mostrarResultadoRespuesta(bool correcto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: correcto ? AppColors.cyan : AppColors.pink,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (correcto ? AppColors.cyan : AppColors.pink).withValues(
                  alpha: 0.28,
                ),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                correcto ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: correcto ? AppColors.cyan : AppColors.pink,
                size: 58,
              ),
              const SizedBox(height: 14),
              Text(
                correcto ? 'Respuesta correcta' : 'Respuesta incorrecta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: correcto ? AppColors.cyan : AppColors.pink,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                game.ultimaExplicacion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (!mounted) return;
                    revisarEstado();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: correcto ? AppColors.cyan : AppColors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Future<void> revisarEstado() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (game.fase == Nivel23Phase.completado) {
      await guardarProgreso();
      if (!mounted || dialogoFinalMostrado) return;
      dialogoFinalMostrado = true;
      mostrarDialogoFinal(true);
    } else if (game.fase == Nivel23Phase.fallado) {
      mostrarDialogoFinal(false);
    } else if (game.labActualTerminado) {
      mostrarResultadoLab();
    } else {
      setState(() {});
    }
  }

  Future<void> guardarProgreso() async {
    if (progresoGuardado || widget.soloEntrenamiento) return;
    progresoGuardado = true;

    await FirestoreService.guardarPuntuacion(
      puntos: game.xp,
      nivelCompletado: 23,
      soloEntrenamiento: widget.soloEntrenamiento,
    );
  }

  void mostrarResultadoLab() {
    final esLab1 = game.fase == Nivel23Phase.ronda1;
    final labActual = esLab1 ? 1 : 2;
    final labSiguiente = esLab1 ? 2 : 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cyan, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.28),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_outlined,
                color: AppColors.cyan,
                size: 62,
              ),
              const SizedBox(height: 14),
              Text(
                'LAB $labActual COMPLETADO',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Acceso concedido al Lab $labSiguiente.',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      game.siguienteLab();
                    });
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: Text(
                    'CONTINUAR AL LAB $labSiguiente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void mostrarDialogoFinal(bool victoria) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogoResultadoNivel23(
        titulo: victoria ? 'SERVIDOR PROTEGIDO' : 'LAB NO SUPERADO',
        subtitulo: victoria
            ? 'Has mitigado el ataque DDoS con éxito'
            : 'No has conseguido defender la infraestructura',
        puntos: game.xp,
        exito: victoria,
        nivelYaCompletado: widget.soloEntrenamiento,
        onReintentar: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Nivel23Screen(soloEntrenamiento: widget.soloEntrenamiento),
            ),
          );
        },
        onSalir: () {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LevelMapScreen()),
            (route) => route.settings.name == 'menu',
          );
        },
      ),
    );
  }

  String get tituloFase {
    switch (game.fase) {
      case Nivel23Phase.intro:
      case Nivel23Phase.ronda1:
        return 'Nivel 23: Ataque DDoS - Lab 1';
      case Nivel23Phase.ronda2:
        return 'Nivel 23: Ataque DDoS - Lab 2';
      case Nivel23Phase.ronda3:
        return 'Nivel 23: Ataque DDoS - Lab 3';
      case Nivel23Phase.completado:
        return 'Nivel 23: Ataque DDoS';
      case Nivel23Phase.fallado:
        return 'Nivel 23';
    }
  }

  String get subtituloFase {
    switch (game.fase) {
      case Nivel23Phase.ronda1:
        return 'Detectar tráfico';
      case Nivel23Phase.ronda2:
        return 'Identificar ataque';
      case Nivel23Phase.ronda3:
        return 'Aplicar defensa';
      default:
        return '';
    }
  }

  String get objetivoFase {
    if (game.fase == Nivel23Phase.ronda3) {
      return 'Lee el incidente y elige la defensa correcta.';
    }
    return 'Lee los datos del recuadro y selecciona la opción correcta.';
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
            subtitulo: 'NIVEL 23 // ATAQUE DDoS',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            onFinalizado: () {
              setState(() => _mostrarFractura = false);
              MusicService().playNiveles21to25Music();
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              buildHeader(),
              const SizedBox(height: 18),
              buildObjetivoLab(),
              const SizedBox(height: 60),
              Expanded(child: buildJuego()),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Volver al mapa',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.cyan,
          style: IconButton.styleFrom(
            side: const BorderSide(color: AppColors.cyan),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tituloFase,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtituloFase.isNotEmpty)
              Text(
                subtituloFase,
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const Spacer(),
        ...List.generate(
          Nivel23Game.vidasIniciales,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              index < game.vidas ? Icons.favorite : Icons.favorite_border,
              color: AppColors.pink,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 22),
        Text(
          'XP: ${game.xp}',
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildObjetivoLab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              final scale = 1 + math.sin(_anim.value * math.pi * 2) * 0.05;
              return Transform.scale(
                scale: scale,
                child: const Icon(Icons.gps_fixed, color: AppColors.pink),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$objetivoFase Consigue 3 respuestas para pasar al siguiente lab.',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildJuego() {
    return Card(
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: buildEscenarioUnificado(),
      ),
    );
  }

  Widget buildEscenarioUnificado() {
    if (game.fase == Nivel23Phase.ronda3) {
      final mitigacion = game.mitigacionActual;
      if (mitigacion == null) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mitigacion.titulo,
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'MITIGACIÓN',
            style: TextStyle(color: AppColors.pink, fontSize: 15),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            height: 155,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.bgMain,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cyan, width: 1.5),
            ),
            child: Text(
              mitigacion.descripcion,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgMain,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) {
                    final dx = math.sin(_anim.value * math.pi * 2) * 0.8;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: const Icon(Icons.bar_chart, color: AppColors.pink),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Selecciona la contramedida más adecuada para proteger el servidor.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          buildBotonesMitigacion(mitigacion),
        ],
      );
    }

    final escenario = game.escenarioActual;
    if (escenario == null) return const SizedBox();
    return buildEscenario(escenario);
  }

  Widget buildEscenario(DdosScenario escenario) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          escenario.titulo,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          escenario.protocolo,
          style: const TextStyle(color: AppColors.pink, fontSize: 15),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          height: 155,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.bgMain,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cyan, width: 1.5),
          ),
          child: Text(
            escenario.captura,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgMain,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                  final dx = math.sin(_anim.value * math.pi * 2) * 0.8;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: const Icon(Icons.bar_chart, color: AppColors.pink),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  escenario.nota,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        buildBotonesTipo(),
      ],
    );
  }

  Widget buildBotonesTipo() {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: DdosType.values.map((tipo) {
        final legitimo = tipo == DdosType.legitimo;
        final color = legitimo ? AppColors.cyan : AppColors.purple;

        return AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            final glow =
                0.18 + (math.sin(_anim.value * math.pi * 2) + 1) * 0.08;

            return Container(
              width: 120,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: glow),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => responderTipo(tipo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: color,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: color, width: 2),
                  ),
                ),
                child: Text(
                  tipo == DdosType.dnsAmplification ? 'DNS AMP' : tipo.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget buildBotonesMitigacion(DdosMitigationScenario escenario) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: (() {
        final opciones = List<String>.from(escenario.opciones)..shuffle();
        return opciones.map((opcion) {
          return AnimatedBuilder(
            animation: _anim,
            builder: (context, child) {
              final glow =
                  0.18 + (math.sin(_anim.value * math.pi * 2) + 1) * 0.08;

              return Container(
                width: 170,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: glow),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => responderMitigacion(opcion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: AppColors.purple,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.purple, width: 2),
                    ),
                  ),
                  child: Text(
                    opcion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        }).toList();
      }()),
    );
  }

  Widget buildMitigacion(DdosMitigationScenario escenario) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          escenario.titulo,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          escenario.descripcion,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        const Spacer(),
        ...escenario.opciones.map(
          (opcion) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => responderMitigacion(opcion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: AppColors.purple,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.purple, width: 2),
                  ),
                ),
                child: Text(
                  opcion,
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogoResultadoNivel23 extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int puntos;
  final bool exito;
  final bool nivelYaCompletado;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _DialogoResultadoNivel23({
    required this.titulo,
    required this.subtitulo,
    required this.puntos,
    required this.exito,
    required this.nivelYaCompletado,
    required this.onReintentar,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final color = exito ? AppColors.cyan : AppColors.pink;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.emoji_events : Icons.close_rounded,
              color: color,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              nivelYaCompletado ? 'Modo entrenamiento' : subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 18),
            Text(
              'Puntuación: $puntos XP',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (!exito)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReintentar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'REINTENTAR',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            if (!exito) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSalir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  exito ? 'CONTINUAR' : 'VOLVER AL MAPA',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
