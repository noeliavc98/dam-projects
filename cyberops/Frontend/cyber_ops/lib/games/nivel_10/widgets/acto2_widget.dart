import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/games/nivel_10/components/email_model.dart';
import 'package:cyber_ops/games/nivel_10/nivel10_game.dart';
import 'package:flutter/material.dart';

class Acto2Widget extends StatefulWidget {
  final Nivel10Game game;

  const Acto2Widget({super.key, required this.game});

  @override
  State<Acto2Widget> createState() => _Acto2WidgetState();
}

class _Acto2WidgetState extends State<Acto2Widget>
    with SingleTickerProviderStateMixin {
  // ── Swipe ──────────────────────────────────────────────────────────────────
  double _dragOffset = 0;
  bool _animating = false;
  late AnimationController _animController;
  late Animation<double> _snapAnimation;

  // ── Feedback visual al clasificar ─────────────────────────────────────────
  bool? _ultimaRespuesta; // true=phishing, false=legítimo
  bool _mostrandoFeedback = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_animating || _mostrandoFeedback) return;
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_animating || _mostrandoFeedback) return;
    const umbral = 100.0;
    if (_dragOffset.abs() >= umbral) {
      _clasificar(_dragOffset < 0); // izquierda = phishing, derecha = legítimo
    } else {
      _snapDeVuelta();
    }
  }

  void _clasificar(bool esPhishing) {
    final email = widget.game.emailActual;
    if (email == null) return;

    setState(() {
      _animating = true;
      _ultimaRespuesta = esPhishing;
    });

    // Animar la tarjeta fuera de pantalla
    final destino = esPhishing ? -500.0 : 500.0;
    _snapAnimation = Tween<double>(
      begin: _dragOffset,
      end: destino,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward(from: 0).then((_) {
      // Feedback fijo — el jugador avanza manualmente
      widget.game.clasificarEmail(email.id, esPhishing);
      setState(() {
        _mostrandoFeedback = true;
        _dragOffset = 0;
        _animating = false;
      });
    });
  }

  void _siguienteEmail() {
    setState(() => _mostrandoFeedback = false);
  }

  void _snapDeVuelta() {
    _snapAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    setState(() => _animating = true);
    _animController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
          _animating = false;
        });
      }
    });
  }

  double get _offsetActual => _animating ? _snapAnimation.value : _dragOffset;

  @override
  Widget build(BuildContext context) {
    final email = widget.game.emailActual;
    final total = widget.game.bandeja.length;
    final actual = widget.game.emailActualIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 12,
            compact ? 6 : 10,
            compact ? 8 : 12,
            12,
          ),
          child: Column(
            children: [
              // ── Barra de progreso y timer ──────────────────────────────────────
              _BarraProgreso(
                actual: actual,
                total: total,
                segundos: widget.game.segundosRestantes,
              ),
              SizedBox(height: compact ? 10 : 16),

              // ── Instrucciones ─────────────────────────────────────────────────
              const _Instrucciones(),
              SizedBox(height: compact ? 10 : 16),

              // ── Tarjeta de email con swipe ─────────────────────────────────────
              Expanded(
                child: email == null
                    ? const SizedBox()
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Tarjeta siguiente (fondo, ligeramente escalada)
                          if (actual + 1 < total)
                            Transform.scale(
                              scale: 0.95,
                              child: _EmailCard(
                                email: widget.game.bandeja[actual + 1],
                                dragOffset: 0,
                                opacity: 0.5,
                              ),
                            ),

                          // Overlay de feedback
                          if (_mostrandoFeedback)
                            _FeedbackOverlay(
                              esPhishing: _ultimaRespuesta!,
                              emailAnterior: widget
                                  .game
                                  .bandeja[(actual - 1).clamp(0, total - 1)],
                              onSiguiente: _siguienteEmail,
                            ),

                          // Tarjeta actual con swipe
                          if (!_mostrandoFeedback)
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (_, _) => GestureDetector(
                                onHorizontalDragUpdate: _onDragUpdate,
                                onHorizontalDragEnd: _onDragEnd,
                                child: _EmailCard(
                                  email: email,
                                  dragOffset: _offsetActual,
                                  opacity: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              SizedBox(height: compact ? 8 : 12),

              // ── Botones de clasificación manual ───────────────────────────────
              if (email != null && !_mostrandoFeedback)
                _BotonesClasificacion(
                  onPhishing: () => _clasificar(true),
                  onLegitimo: () => _clasificar(false),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── BARRA DE PROGRESO Y TIMER ─────────────────────────────────────────────────

class _BarraProgreso extends StatelessWidget {
  final int actual;
  final int total;
  final int segundos;

  const _BarraProgreso({
    required this.actual,
    required this.total,
    required this.segundos,
  });

  String get _timerLabel {
    final m = segundos ~/ 60;
    final s = segundos % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (segundos > 60) return AppColors.cyan;
    if (segundos > 30) return const Color(0xFFF5A623);
    return const Color(0xFFFF4D7D);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Progreso emails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMAIL $actual DE $total',
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total > 0 ? actual / total : 0,
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Timer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'TIEMPO',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _timerLabel,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _timerColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── INSTRUCCIONES ─────────────────────────────────────────────────────────────

class _Instrucciones extends StatelessWidget {
  const _Instrucciones();

  @override
  Widget build(BuildContext context) {
    const phishing = _InstruccionItem(
      icono: Icons.arrow_back,
      color: Color(0xFFFF4D7D),
      label: 'PHISHING',
    );
    const indicacion = Text(
      'Desliza para clasificar',
      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
    );
    const legitimo = _InstruccionItem(
      icono: Icons.arrow_forward,
      color: AppColors.cyan,
      label: 'LEGITIMO',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [phishing, indicacion, legitimo],
          );
        }

        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            phishing,
            SizedBox(width: 32),
            indicacion,
            SizedBox(width: 32),
            legitimo,
          ],
        );
      },
    );
  }
}

class _InstruccionItem extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String label;

  const _InstruccionItem({
    required this.icono,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── TARJETA DE EMAIL ──────────────────────────────────────────────────────────

class _EmailCard extends StatelessWidget {
  final EmailModel email;
  final double dragOffset;
  final double opacity;

  const _EmailCard({
    required this.email,
    required this.dragOffset,
    required this.opacity,
  });

  double get _rotacion => dragOffset * 0.0015;

  Color get _overlayColor {
    if (dragOffset.abs() < 20) return Colors.transparent;
    return dragOffset < 0
        ? const Color(
            0xFFFF4D7D,
          ).withValues(alpha: (dragOffset.abs() / 200).clamp(0, 0.3))
        : AppColors.cyan.withValues(alpha: (dragOffset / 200).clamp(0, 0.3));
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(dragOffset, 0),
      child: Transform.rotate(
        angle: _rotacion,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                // Contenido del email
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cabecera
                      _EmailHeader(email: email),
                      const Divider(color: AppColors.border, height: 24),
                      // Cuerpo
                      Text(
                        email.body,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.6,
                        ),
                      ),
                      // Adjunto si existe
                      if (email.attachment != null) ...[
                        const SizedBox(height: 16),
                        _AdjuntoChip(nombre: email.attachment!),
                      ],
                    ],
                  ),
                ),
                // Overlay de color al deslizar
                if (_overlayColor != Colors.transparent)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _overlayColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                // Label izquierda/derecha al deslizar
                if (dragOffset < -30)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _SwipeLabel(
                      texto: '⚠ PHISHING',
                      color: const Color(0xFFFF4D7D),
                    ),
                  ),
                if (dragOffset > 30)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _SwipeLabel(
                      texto: '✓ LEGÍTIMO',
                      color: AppColors.cyan,
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

class _EmailHeader extends StatelessWidget {
  final EmailModel email;

  const _EmailHeader({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DE: ',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
            Expanded(
              child: Text(
                email.sender,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.cyan,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          email.subject,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AdjuntoChip extends StatelessWidget {
  final String nombre;

  const _AdjuntoChip({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D7D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFF4D7D).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, size: 14, color: Color(0xFFFF4D7D)),
          const SizedBox(width: 6),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF4D7D),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  final String texto;
  final Color color;

  const _SwipeLabel({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── OVERLAY DE FEEDBACK ───────────────────────────────────────────────────────

class _FeedbackOverlay extends StatelessWidget {
  final bool esPhishing;
  final EmailModel emailAnterior;
  final VoidCallback onSiguiente;

  const _FeedbackOverlay({
    required this.esPhishing,
    required this.emailAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    final correcto = esPhishing == emailAnterior.isPhishing;
    final color = correcto ? AppColors.cyan : const Color(0xFFFF4D7D);
    final icono = correcto
        ? Icons.shield_outlined
        : Icons.warning_amber_rounded;
    final titulo = correcto ? '¡CORRECTO!' : 'INCORRECTO';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          const Text(
            '¿POR QUÉ?',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            emailAnterior.educationalTip,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSiguiente,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.bgMain,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'SIGUIENTE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOTONES DE CLASIFICACIÓN MANUAL ──────────────────────────────────────────

class _BotonesClasificacion extends StatelessWidget {
  final VoidCallback onPhishing;
  final VoidCallback onLegitimo;

  const _BotonesClasificacion({
    required this.onPhishing,
    required this.onLegitimo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPhishing,
            icon: const Icon(Icons.dangerous_outlined, size: 16),
            label: const Text('PHISHING'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D7D),
              side: const BorderSide(color: Color(0xFFFF4D7D)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onLegitimo,
            icon: const Icon(Icons.verified_outlined, size: 16),
            label: const Text('LEGÍTIMO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cyan,
              side: const BorderSide(color: AppColors.cyan),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
