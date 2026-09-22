import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/games/nivel_10/data/phishing_data.dart';
import 'package:cyber_ops/games/nivel_10/nivel10_game.dart';
import 'package:cyber_ops/games/nivel_10/widgets/nivel10_responsive.dart';
import 'package:flutter/material.dart';

class ResultadosWidget extends StatefulWidget {
  final Nivel10Game game;
  final bool modoEntrenamiento;
  final VoidCallback onSalir;

  const ResultadosWidget({
    super.key,
    required this.game,
    this.modoEntrenamiento = false,
    required this.onSalir,
  });

  @override
  State<ResultadosWidget> createState() => _ResultadosWidgetState();
}

class _ResultadosWidgetState extends State<ResultadosWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: ScaleTransition(
        scale: _scaleIn,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (nivel10IsCompact(constraints.maxWidth)) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    _PuntuacionCentral(game: widget.game),
                    const SizedBox(height: 10),
                    _ResumenActo1Card(game: widget.game),
                    const SizedBox(height: 10),
                    _ResumenActo2Card(game: widget.game),
                    const SizedBox(height: 10),
                    _ResumenActo3Card(game: widget.game),
                    const SizedBox(height: 10),
                    _TecnicasCard(game: widget.game),
                    const SizedBox(height: 10),
                    _BotonSalir(
                      modoEntrenamiento: widget.modoEntrenamiento,
                      onSalir: widget.onSalir,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Columna izquierda — Resumen actos ───────────────────────
                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        _ResumenActo1Card(game: widget.game),
                        const SizedBox(height: 10),
                        _ResumenActo2Card(game: widget.game),
                        const SizedBox(height: 10),
                        _ResumenActo3Card(game: widget.game),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ── Columna central — Puntuación principal ───────────────────
                  Expanded(child: _PuntuacionCentral(game: widget.game)),
                  const SizedBox(width: 10),

                  // ── Columna derecha — Técnicas aprendidas + botón ────────────
                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        _TecnicasCard(game: widget.game),
                        const SizedBox(height: 10),
                        _BotonSalir(
                          modoEntrenamiento: widget.modoEntrenamiento,
                          onSalir: widget.onSalir,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── PUNTUACIÓN CENTRAL ────────────────────────────────────────────────────────

class _PuntuacionCentral extends StatelessWidget {
  final Nivel10Game game;

  const _PuntuacionCentral({required this.game});

  String get _icono {
    if (game.puntos >= 800) return '🛡️';
    if (game.puntos >= 500) return '🔍';
    return '📚';
  }

  Color get _colorRango {
    if (game.puntos >= 800) return AppColors.cyan;
    if (game.puntos >= 500) return const Color(0xFFF5A623);
    return AppColors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = (game.puntos / Nivel10Game.puntuacionMaxima).clamp(
      0.0,
      1.0,
    );

    return _Panel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PanelLabel('OPERACIÓN COMPLETADA'),
          const SizedBox(height: 20),

          // Icono de rango
          Text(_icono, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),

          // Rango
          Text(
            game.rangFinal.toUpperCase(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _colorRango,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Puntuación
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${game.puntos}',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' XP',
                  style: const TextStyle(
                    fontSize: 22,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'de ${Nivel10Game.puntuacionMaxima} XP posibles',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Barra de puntuación total
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_colorRango),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 20),

          // Estadísticas rápidas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                valor: '${game.emailsAcertados}/${game.bandeja.length}',
                label: 'EMAILS\nCORRECTOS',
                color: AppColors.cyan,
              ),
              _StatItem(
                valor: '${game.pistasActo3Reveladas}/${game.totalPistasActo3}',
                label: 'PISTAS\nINSPECCIONADAS',
                color: AppColors.purple,
              ),
              _StatItem(
                valor: game.decisionFinal == true ? '✓' : '✗',
                label: 'DECISIÓN\nFINAL',
                color: game.decisionFinal == true
                    ? AppColors.cyan
                    : const Color(0xFFFF4D7D),
              ),
              _StatItem(
                valor: '${game.vidas}',
                label: 'VIDAS\nRESTANTES',
                color: const Color(0xFFFF4D7D),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;

  const _StatItem({
    required this.valor,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textMuted,
            letterSpacing: 1,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ── RESUMEN ACTO 1 ────────────────────────────────────────────────────────────

class _ResumenActo1Card extends StatelessWidget {
  final Nivel10Game game;

  const _ResumenActo1Card({required this.game});

  @override
  Widget build(BuildContext context) {
    final componentes = game.componentesSeleccionados;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PanelLabel('ACTO 1'),
              const Spacer(),
              Text(
                'Credibilidad: ${game.credibilidadTotal}/12',
                style: const TextStyle(fontSize: 10, color: AppColors.cyan),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Email construido',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...componentes.entries.map((entry) {
            final comp = entry.value;
            if (comp == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: AppColors.purple, fontSize: 11),
                  ),
                  Expanded(
                    child: Text(
                      comp.value,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── RESUMEN ACTO 2 ────────────────────────────────────────────────────────────

class _ResumenActo2Card extends StatelessWidget {
  final Nivel10Game game;

  const _ResumenActo2Card({required this.game});

  @override
  Widget build(BuildContext context) {
    final acertados = game.emailsAcertados;
    final total = game.bandeja.length;
    final porcentaje = total > 0 ? acertados / total : 0.0;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('ACTO 2'),
          const SizedBox(height: 8),
          const Text(
            'Bandeja de entrada',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$acertados de $total emails clasificados correctamente',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          // Detalle por email
          ...game.bandeja.map((email) {
            final respuesta = game.respuestasJugador[email.id];
            final correcto = respuesta == email.isPhishing;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Icon(
                    correcto ? Icons.check : Icons.close,
                    size: 12,
                    color: correcto ? AppColors.cyan : const Color(0xFFFF4D7D),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      email.subject,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── RESUMEN ACTO 3 ────────────────────────────────────────────────────────────

class _ResumenActo3Card extends StatelessWidget {
  final Nivel10Game game;

  const _ResumenActo3Card({required this.game});

  @override
  Widget build(BuildContext context) {
    final correcto = game.decisionFinal == true;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('ACTO 3'),
          const SizedBox(height: 8),
          const Text(
            'Decisión final',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                correcto ? Icons.shield_outlined : Icons.warning_amber_rounded,
                color: correcto ? AppColors.cyan : const Color(0xFFFF4D7D),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  correcto
                      ? 'Bloqueaste el email. ¡Correcto!'
                      : 'Dejaste pasar el phishing.',
                  style: TextStyle(
                    fontSize: 11,
                    color: correcto ? AppColors.cyan : const Color(0xFFFF4D7D),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...PhishingData.acto3Emails.map(
            (caso) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                caso.email.educationalTip,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TÉCNICAS APRENDIDAS ───────────────────────────────────────────────────────

class _TecnicasCard extends StatelessWidget {
  final Nivel10Game game;

  const _TecnicasCard({required this.game});

  static const List<Map<String, String>> _tecnicas = [
    {'icono': '🔗', 'texto': 'Dominios falsos con guiones o typos'},
    {'icono': '⚠️', 'texto': 'Urgencia artificial como técnica de presión'},
    {'icono': '📎', 'texto': 'Adjuntos ejecutables .exe en emails oficiales'},
    {'icono': '👤', 'texto': 'CEO Fraud: peticiones urgentes y confidenciales'},
    {'icono': '🔒', 'texto': 'HTTPS no garantiza que un sitio sea seguro'},
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('TÉCNICAS APRENDIDAS'),
          const SizedBox(height: 10),
          ..._tecnicas.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['icono']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t['texto']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOTÓN SALIR ───────────────────────────────────────────────────────────────

class _BotonSalir extends StatelessWidget {
  final bool modoEntrenamiento;
  final VoidCallback onSalir;

  const _BotonSalir({required this.modoEntrenamiento, required this.onSalir});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSalir,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.bgMain,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'FINALIZAR NIVEL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            modoEntrenamiento
                ? 'Modo entrenamiento: progreso no guardado'
                : 'El progreso se guardará automáticamente',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── WIDGETS COMUNES ───────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _PanelLabel extends StatelessWidget {
  final String text;

  const _PanelLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 2,
        color: AppColors.purple,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
