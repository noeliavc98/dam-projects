import 'package:cyber_ops/games/nivel_17/nivel17_game.dart';
import 'package:cyber_ops/services/firestore_service.dart';
import 'package:cyber_ops/services/music_service.dart';
import 'package:cyber_ops/widgets/fractura/fractura_dialogo.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:cyber_ops/config/app_colors.dart';

class Nivel17Screen extends StatefulWidget {
  final bool soloEntrenamiento;
  const Nivel17Screen({super.key, this.soloEntrenamiento = false});

  @override
  State<Nivel17Screen> createState() => _Nivel17ScreenState();
}

class _Nivel17ScreenState extends State<Nivel17Screen> {
  late final Nivel17Game _game;
  bool _resultadoMostrado = false;
  bool _hudUpdatePending = false;
  bool _mostrarIntroFractura = true;
  bool _nivelYaCompletado = false;

  @override
  void initState() {
    super.initState();
    _nivelYaCompletado = widget.soloEntrenamiento;
    MusicService().stopMusic();

    _game = Nivel17Game(
      onStateChanged: _actualizarHud,
      onCompleted: _mostrarVictoria,
      onGameOver: _mostrarGameOver,
    );
  }
 
  void _actualizarHud() {
    if (!mounted || _hudUpdatePending) return;

    _hudUpdatePending = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hudUpdatePending = false;

      if (!mounted) return;
      setState(() {});
    });
  }

  void _volverAlMapa() {
    Navigator.of(context).pop();
  }

  void _mostrarVictoria() async {
    if (!mounted) return;
  
    // Guardar solo si no es modo entrenamiento
    if (!_nivelYaCompletado) {
      await FirestoreService.guardarPuntuacion(
        puntos: _game.score,
        nivelCompletado: 17,
      );
      await FirestoreService.guardarMision(
        nivel: 17,
        mision: 1,
        puntos: _game.score,
      );
    }
    if (_resultadoMostrado || !mounted) return;
    _resultadoMostrado = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultadoNivel17Dialog(
        titulo: 'MISIÓN COMPLETADA',
        subtitulo: 'Has mantenido la sesión VPN protegida.',
        exito: true,
        puntos: _game.score,
        nivelYaCompletado: _nivelYaCompletado,
        onReintentar: _reiniciarNivel,
        onSalir: () => _salirDelNivel(desdeDialog: true),
      ),
    );
  }

  void _mostrarGameOver() {
    if (_resultadoMostrado || !mounted) return;
    _resultadoMostrado = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultadoNivel17Dialog(
        titulo: 'SESIÓN COMPROMETIDA',
        subtitulo: 'Te has quedado sin vidas.',
        exito: false,
        puntos: _game.score,
        nivelYaCompletado: _nivelYaCompletado,
        onReintentar: _reiniciarNivel,
        onSalir: () => _salirDelNivel(desdeDialog: true),
      ),
    );
  }

  void _reiniciarNivel() {
    if (!mounted) return;
    MusicService().stopMusic();
    Navigator.pop(context);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Nivel17Screen()),
    );
  }

  bool _saliendo = false;

  void _salirDelNivel({bool desdeDialog = false}) {
    if (!mounted) return;
    Navigator.pop(context);
    if (!mounted) return;
    Navigator.pop(context);
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarIntroFractura) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: FracturaDialogo(
            subtitulo: 'NIVEL 17 // VPN TUNNEL',
            textoBotonFinal: 'JUGAR',
            usarVoz: true,
            permitirSaltarIntro: true,
            permitirCambiarVoz: true,
            velocidadVoz: 0.66,
            milisegundosPorCaracter: 18,
            dialogos: const [
              '¡Bienvenido al nivel 17!',
              'Este nivel es tipo minijuego. Te explico',
              'Entramos en un túnel VPN en el que tú serás los datos que navegan a través de él.',
              'Posees 4 datos/vidas: DNI, tarjeta, email y ubicación. Además de un nivel de privacidad.',
              'El objetivo es que aguantes un minuto sin que los atacantes te roben todos los datos y te quiten la privacidad.',
              'A lo largo de ese minuto tendrás que recaudar la mayor cantidad de XP, que irá apareciendo.', 
              'Existen dos atacantes: el hacker, que si sales fuera del túnel te roba un dato; y spyware, un ojo que te quita privacidad si estás fuera del túnel.',
              'Cuidado con chocarte con los muros, que te quitan privacidad.'
              'Si se te agota toda la privacidad, también pierdes una vida.',
              'Datos y privacidad = vidas. ¡Suerte!'
            ],
            onFinalizado: () {
              MusicService().playNivel17Music();
              setState(() {
                _mostrarIntroFractura = false;
              });
            },
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: Stack(
          children: [
            GameWidget(game: _game),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _volverAlMapa(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.purple.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.cyan,
                              size: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.cyan, AppColors.purple],
                            ).createShader(bounds),
                            child: const Text(
                              'NIVEL 17 · VPN TUNNEL',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Center(
                              child: _Nivel17Hud(game: _game),
                            ),
                          ),
                          const SizedBox(width: 10),
                        
                          if (_nivelYaCompletado) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fitness_center_rounded,
                                      color: AppColors.purple, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    'MODO ENTRENAMIENTO',
                                    style: TextStyle(
                                      color: AppColors.purple.withOpacity(0.9),
                                      fontSize: 9,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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

class _Nivel17Hud extends StatelessWidget {
  final Nivel17Game game;

  const _Nivel17Hud({required this.game});

  @override
  Widget build(BuildContext context) {
    final privacy = game.privacy.clamp(0, 100).round();
    final remainingTime = (game.missionDuration - game.gameTime)
        .clamp(0, game.missionDuration)
        .ceil();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HudChip(
                label: 'PRIVACIDAD',
                value: '$privacy%',
                color: AppColors.cyan,
              ),
              _LivesDisplay(lives: game.lives),
              _HudChip(
                label: 'TIEMPO',
                value: '${remainingTime}s',
                color: AppColors.purple,
              ),
              _HudChip(
                label: 'XP',
                value: '${game.score}',
                color: Colors.amberAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PrivacyBar(value: privacy / 100),
          const SizedBox(height: 10),
          _DataStatusStrip(game: game),
        ],
      ),
    );
  }
}

class _PrivacyBar extends StatelessWidget {
  final double value;

  const _PrivacyBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);

    final color = safeValue > 0.55
        ? Colors.cyanAccent
        : safeValue > 0.25
            ? Colors.orangeAccent
            : Colors.redAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: constraints.maxWidth * safeValue,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 8,
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
}


class _LivesDisplay extends StatelessWidget {
  final int lives;

  const _LivesDisplay({required this.lives});

  @override
  Widget build(BuildContext context) {
    final safeLives = lives.clamp(0, 4);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VIDAS',
              maxLines: 1,
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.75),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  final active = index < safeLives;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Icon(
                      active
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 17,
                      color: active
                          ? Colors.redAccent
                          : Colors.redAccent.withOpacity(0.35),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataStatusStrip extends StatelessWidget {
  final Nivel17Game game;

  const _DataStatusStrip({required this.game});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: game.sensitiveData.map((data) {
        final stolen = game.stolenData.contains(data);
        final color = stolen ? AppColors.pink : AppColors.cyan;

        return Container(
          constraints: const BoxConstraints(minWidth: 76, maxWidth: 128),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: stolen
                ? AppColors.pink.withOpacity(0.12)
                : AppColors.cyan.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stolen ? 'ROBADO' : data,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                decoration: stolen ? TextDecoration.lineThrough : null,
                decorationColor: color,
                decorationThickness: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HudChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HudChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92, maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.75),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoNivel17Dialog extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int puntos;
  final bool exito;
  final bool nivelYaCompletado;
  final VoidCallback onReintentar;
  final VoidCallback onSalir;

  const _ResultadoNivel17Dialog({
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
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.bgMain,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$puntos XP',
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            if (nivelYaCompletado && exito) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        color: AppColors.purple.withOpacity(0.7), size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'Modo entrenamiento — puntos no guardados',
                      style: TextStyle(
                        color: AppColors.purple.withOpacity(0.7),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
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
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
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
                    letterSpacing: 3,
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
