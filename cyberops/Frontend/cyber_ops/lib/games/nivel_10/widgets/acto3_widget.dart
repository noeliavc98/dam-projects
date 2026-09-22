import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/games/nivel_10/data/phishing_data.dart';
import 'package:cyber_ops/games/nivel_10/components/inspection_element.dart';
import 'package:cyber_ops/games/nivel_10/nivel10_game.dart';
import 'package:cyber_ops/games/nivel_10/widgets/nivel10_responsive.dart';
import 'package:flutter/material.dart';

class Acto3Widget extends StatefulWidget {
  final Nivel10Game game;
  final GlobalKey? contextoKey;
  final GlobalKey? emailKey;
  final GlobalKey? revelacionKey;
  final GlobalKey? decisionKey;

  const Acto3Widget({
    super.key,
    required this.game,
    this.contextoKey,
    this.emailKey,
    this.revelacionKey,
    this.decisionKey,
  });

  @override
  State<Acto3Widget> createState() => _Acto3WidgetState();
}

class _Acto3WidgetState extends State<Acto3Widget> {
  ElementType? _elementoActivo; // El que está mostrando su revelación
  bool _mostrandoFeedback = false;
  bool _ultimaDecisionCorrecta = false;
  String _feedbackTexto = '';
  bool? _decisionPendiente;

  void _tocarElemento(InspectionElement elemento) {
    setState(() => _elementoActivo = elemento.type);
    widget.game.revelarElemento(elemento.type);
  }

  void _tomarDecision(bool bloquear) {
    final caso = widget.game.acto3EmailActual;
    final correcto = bloquear == caso.email.isPhishing;

    setState(() {
      _elementoActivo = null;
      _ultimaDecisionCorrecta = correcto;
      _feedbackTexto = caso.email.educationalTip;
      _decisionPendiente = bloquear;
      _mostrandoFeedback = true;
    });
  }

  bool get _puedeDecidir =>
      widget.game.elementosRevelados.length >=
      widget.game.acto3EmailActual.inspectionElements.length;

  @override
  void didUpdateWidget(covariant Acto3Widget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.game.acto3EmailIndex != widget.game.acto3EmailIndex) {
      _elementoActivo = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = nivel10IsCompact(constraints.maxWidth);

        return Stack(
          children: [
            compact ? _buildCompactLayout() : _buildDesktopLayout(),
            if (_mostrandoFeedback) _buildFeedbackOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Columna izquierda — Contexto ─────────────────────────────────
              SizedBox(
                key: widget.contextoKey,
                width: 220,
                child: Column(
                  children: [
                    _ContextoCard(),
                    const SizedBox(height: 10),
                    _PistasCard(
                      revelados: widget.game.elementosRevelados.length,
                      total: widget
                          .game
                          .acto3EmailActual
                          .inspectionElements
                          .length,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Columna central — Email inspeccionable ────────────────────────
              Expanded(
                child: KeyedSubtree(
                  key: widget.emailKey,
                  child: _EmailInspeccionable(
                    caso: widget.game.acto3EmailActual,
                    elementoActivo: _elementoActivo,
                    elementosRevelados: widget.game.elementosRevelados,
                    onTocar: _tocarElemento,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Columna derecha — Revelación + Decisión ───────────────────────
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    KeyedSubtree(
                      key: widget.revelacionKey,
                      child: _RevelacionCard(
                        caso: widget.game.acto3EmailActual,
                        elementoActivo: _elementoActivo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    KeyedSubtree(
                      key: widget.decisionKey,
                      child: _DecisionCard(
                        puedeDecidir: _puedeDecidir,
                        onDecidir: _tomarDecision,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      children: [
        KeyedSubtree(key: widget.contextoKey, child: _ContextoCard()),
        const SizedBox(height: 10),
        _PistasCard(
          revelados: widget.game.elementosRevelados.length,
          total: widget.game.acto3EmailActual.inspectionElements.length,
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: widget.emailKey,
          child: _EmailInspeccionable(
            caso: widget.game.acto3EmailActual,
            elementoActivo: _elementoActivo,
            elementosRevelados: widget.game.elementosRevelados,
            onTocar: _tocarElemento,
          ),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: widget.revelacionKey,
          child: _RevelacionCard(
            caso: widget.game.acto3EmailActual,
            elementoActivo: _elementoActivo,
          ),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: widget.decisionKey,
          child: _DecisionCard(
            puedeDecidir: _puedeDecidir,
            onDecidir: _tomarDecision,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _FeedbackDecisionActo3(
              correcto: _ultimaDecisionCorrecta,
              texto: _feedbackTexto,
              onContinuar: () {
                final decision = _decisionPendiente;

                setState(() {
                  _mostrandoFeedback = false;
                  _elementoActivo = null;
                  _decisionPendiente = null;
                });

                if (decision != null) {
                  widget.game.tomarDecisionFinal(decision);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── CONTEXTO ──────────────────────────────────────────────────────────────────

class _ContextoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelLabel('ALERTA'),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF5A623),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Email sospechoso detectado',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Inspecciona cada elemento antes de tomar una decisión. Un error aquí puede comprometer toda la red.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          SizedBox(height: 10),
          _PanelLabel('TRANSMISIÓN'),
          SizedBox(height: 6),
          Text(
            'Toca cada elemento del email para analizarlo. Cuando hayas revisado todo, decide.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── PISTAS REVELADAS ──────────────────────────────────────────────────────────

class _PistasCard extends StatelessWidget {
  final int revelados;
  final int total;

  const _PistasCard({required this.revelados, required this.total});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('ANÁLISIS'),
          const SizedBox(height: 10),
          Text(
            'PISTAS REVISADAS',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? revelados / total : 0,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$revelados / $total elementos inspeccionados',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          if (revelados < total) ...[
            const SizedBox(height: 10),
            const Text(
              'Toca los elementos resaltados del email para revelar las pistas.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.cyan,
                  size: 14,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Análisis completo. Toma tu decisión.',
                    style: TextStyle(fontSize: 11, color: AppColors.cyan),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── EMAIL INSPECCIONABLE ──────────────────────────────────────────────────────

class _EmailInspeccionable extends StatelessWidget {
  final Acto3Email caso;
  final ElementType? elementoActivo;
  final List<ElementType> elementosRevelados;
  final void Function(InspectionElement) onTocar;

  const _EmailInspeccionable({
    required this.caso,
    required this.elementoActivo,
    required this.elementosRevelados,
    required this.onTocar,
  });

  @override
  Widget build(BuildContext context) {
    final email = caso.email;
    final elementos = caso.inspectionElements;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('ESCRITORIO INVESTIGABLE'),
          const SizedBox(height: 14),

          // Remitente inspeccionable
          _ElementoInspeccionable(
            elemento: elementos.firstWhere((e) => e.type == ElementType.sender),
            isActivo: elementoActivo == ElementType.sender,
            isRevelado: elementosRevelados.contains(ElementType.sender),
            prefijo: 'DE: ',
            onTocar: onTocar,
          ),
          const SizedBox(height: 10),

          // Asunto
          Text(
            email.subject,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Divider(color: AppColors.border, height: 24),

          // Cuerpo con URL inspeccionable
          _CuerpoConUrl(
            body: email.body,
            elementoUrl: elementos.firstWhere((e) => e.type == ElementType.url),
            isActivo: elementoActivo == ElementType.url,
            isRevelado: elementosRevelados.contains(ElementType.url),
            onTocar: onTocar,
          ),
          const SizedBox(height: 16),

          // Cuerpo inspeccionable
          _ElementoInspeccionable(
            elemento: elementos.firstWhere((e) => e.type == ElementType.body),
            isActivo: elementoActivo == ElementType.body,
            isRevelado: elementosRevelados.contains(ElementType.body),
            prefijo: '📋 ',
            onTocar: onTocar,
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),

          // Hint
          const Row(
            children: [
              Icon(Icons.touch_app_outlined, size: 14, color: AppColors.purple),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Toca los elementos resaltados para inspeccionarlos',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElementoInspeccionable extends StatelessWidget {
  final InspectionElement elemento;
  final bool isActivo;
  final bool isRevelado;
  final String prefijo;
  final void Function(InspectionElement) onTocar;

  const _ElementoInspeccionable({
    required this.elemento,
    required this.isActivo,
    required this.isRevelado,
    required this.prefijo,
    required this.onTocar,
  });

  Color get _borderColor {
    if (isActivo) return const Color(0xFFFF4D7D);
    if (isRevelado) return AppColors.purple.withValues(alpha: 0.5);
    return AppColors.cyan.withValues(alpha: 0.5);
  }

  Color get _bgColor {
    if (isActivo) return const Color(0xFFFF4D7D).withValues(alpha: 0.08);
    if (isRevelado) return AppColors.purple.withValues(alpha: 0.05);
    return AppColors.cyan.withValues(alpha: 0.05);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTocar(elemento),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            if (prefijo.isNotEmpty)
              Text(
                prefijo,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            Expanded(
              child: Text(
                elemento.value,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isActivo
                      ? const Color(0xFFFF4D7D)
                      : isRevelado
                      ? AppColors.purple
                      : AppColors.cyan,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isRevelado ? Icons.search_off : Icons.search,
              size: 14,
              color: isActivo ? const Color(0xFFFF4D7D) : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CuerpoConUrl extends StatelessWidget {
  final String body;
  final InspectionElement elementoUrl;
  final bool isActivo;
  final bool isRevelado;
  final void Function(InspectionElement) onTocar;

  const _CuerpoConUrl({
    required this.body,
    required this.elementoUrl,
    required this.isActivo,
    required this.isRevelado,
    required this.onTocar,
  });

  @override
  Widget build(BuildContext context) {
    // Divide el body antes y después de la URL
    final urlValue = elementoUrl.value;
    final partes = body.split(urlValue);
    final antes = partes.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          antes,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        _ElementoInspeccionable(
          elemento: elementoUrl,
          isActivo: isActivo,
          isRevelado: isRevelado,
          prefijo: '🔗 ',
          onTocar: onTocar,
        ),
      ],
    );
  }
}

// ── REVELACIÓN ────────────────────────────────────────────────────────────────

class _RevelacionCard extends StatelessWidget {
  final Acto3Email caso;
  final ElementType? elementoActivo;

  const _RevelacionCard({required this.caso, required this.elementoActivo});

  InspectionElement? get _elemento {
    if (elementoActivo == null) return null;

    return caso.inspectionElements.firstWhere((e) => e.type == elementoActivo);
  }

  @override
  Widget build(BuildContext context) {
    final el = _elemento;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('LIBRETA'),
          const SizedBox(height: 10),
          if (el == null)
            const Text(
              'Toca un elemento del email para ver el análisis aquí.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            )
          else ...[
            Row(
              children: [
                Icon(
                  el.isSuspicious
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: el.isSuspicious
                      ? const Color(0xFFFF4D7D)
                      : AppColors.cyan,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  el.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: el.isSuspicious
                        ? const Color(0xFFFF4D7D)
                        : AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgMain,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: el.isSuspicious
                      ? const Color(0xFFFF4D7D).withValues(alpha: 0.3)
                      : AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                el.revelation,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            if (el.isSuspicious) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.flag_outlined, color: Color(0xFFFF4D7D), size: 13),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Señal de alerta detectada',
                      style: TextStyle(fontSize: 11, color: Color(0xFFFF4D7D)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── DECISIÓN FINAL ────────────────────────────────────────────────────────────

class _DecisionCard extends StatelessWidget {
  final bool puedeDecidir;
  final void Function(bool bloquear) onDecidir;

  const _DecisionCard({required this.puedeDecidir, required this.onDecidir});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('ACCESO'),
          const SizedBox(height: 10),
          Text(
            puedeDecidir
                ? '¿Qué haces con este email?'
                : 'Inspecciona todos los elementos primero.',
            style: TextStyle(
              fontSize: 12,
              color: puedeDecidir ? Colors.white : AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Botón bloquear
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: puedeDecidir ? () => onDecidir(true) : null,
              icon: const Icon(Icons.block, size: 15),
              label: const Text('BLOQUEAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D7D),
                disabledBackgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Botón dejar pasar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: puedeDecidir ? () => onDecidir(false) : null,
              icon: const Icon(Icons.check_outlined, size: 15),
              label: const Text('DEJAR PASAR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: puedeDecidir
                    ? AppColors.cyan
                    : AppColors.textMuted,
                side: BorderSide(
                  color: puedeDecidir ? AppColors.cyan : AppColors.border,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
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

class _FeedbackDecisionActo3 extends StatelessWidget {
  final bool correcto;
  final String texto;
  final VoidCallback onContinuar;

  const _FeedbackDecisionActo3({
    required this.correcto,
    required this.texto,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final color = correcto ? AppColors.cyan : const Color(0xFFFF4D7D);
    final titulo = correcto ? '¡CORRECTO!' : 'INCORRECTO';
    final icono = correcto
        ? Icons.shield_outlined
        : Icons.warning_amber_rounded;

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
          Text(
            texto,
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
              onPressed: onContinuar,
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
