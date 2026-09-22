import 'package:cyber_ops/config/app_colors.dart';
import 'package:cyber_ops/games/nivel_10/data/phishing_data.dart';
import 'package:cyber_ops/games/nivel_10/components/email_component.dart';
import 'package:cyber_ops/games/nivel_10/nivel10_game.dart';
import 'package:cyber_ops/games/nivel_10/widgets/nivel10_responsive.dart';
import 'package:flutter/material.dart';

class Acto1Widget extends StatelessWidget {
  final Nivel10Game game;
  final GlobalKey? hudKey;
  final GlobalKey? objetivoKey;
  final GlobalKey? editorKey;
  final GlobalKey? credibilidadKey;

  const Acto1Widget({
    super.key,
    required this.game,
    this.hudKey,
    this.objetivoKey,
    this.editorKey,
    this.credibilidadKey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = nivel10LayoutFor(constraints.maxWidth);

        return switch (layout) {
          Nivel10Layout.mobile => _buildMobile(),
          Nivel10Layout.tablet => _buildTablet(),
          Nivel10Layout.desktop => _buildDesktop(),
        };
      },
    );
  }

  Widget _buildDesktop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Columna izquierda ─────────────────────────────────────────────
          SizedBox(
            key: objetivoKey,
            width: 250,
            child: Column(
              children: [
                _ObjetivoCard(),
                const SizedBox(height: 10),
                _TransmisionCard(),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Columna central — Editor ──────────────────────────────────────
          Expanded(
            child: KeyedSubtree(
              key: editorKey,
              child: _EditorAtaque(game: game),
            ),
          ),
          const SizedBox(width: 10),

          // ── Columna derecha ───────────────────────────────────────────────
          SizedBox(
            key: credibilidadKey,
            width: 250,
            child: Column(
              children: [
                _CredibilidadCard(game: game),
                const SizedBox(height: 10),
                _LibretaCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KeyedSubtree(key: objetivoKey, child: _ObjetivoCard()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KeyedSubtree(
                key: credibilidadKey,
                child: _CredibilidadCard(game: game),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: editorKey,
          child: _EditorAtaque(game: game),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _TransmisionCard()),
            const SizedBox(width: 10),
            Expanded(child: _LibretaCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      children: [
        KeyedSubtree(key: objetivoKey, child: _ObjetivoCard()),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: editorKey,
          child: _EditorAtaque(game: game),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: credibilidadKey,
          child: _CredibilidadCard(game: game),
        ),
        const SizedBox(height: 10),
        _LibretaCard(),
        const SizedBox(height: 10),
        _TransmisionCard(),
      ],
    );
  }
}

// ── OBJETIVO ──────────────────────────────────────────────────────────────────

class _ObjetivoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('OBJETIVO'),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.bgMain,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textMuted,
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carlos Mendoza',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Técnico — Ayto. Madrid',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Accede a su certificado digital. Necesita renovarlo esta semana.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Es metódico. Revisa el asunto antes de abrir.',
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

// ── TRANSMISIÓN ───────────────────────────────────────────────────────────────

class _TransmisionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('TRANSMISIÓN'),
          const SizedBox(height: 10),
          const Text(
            'Construye el email perfecto.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cada pieza importa. Una mala elección y lo perderás.',
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

// ── EDITOR DE ATAQUE ──────────────────────────────────────────────────────────

class _EditorAtaque extends StatelessWidget {
  final Nivel10Game game;

  const _EditorAtaque({required this.game});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelLabel('EDITOR DE ATAQUE'),
            const SizedBox(height: 14),
            ...ComponentType.values.map(
              (type) => _StepSection(
                type: type,
                stepNumber: type.index + 1,
                game: game,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSection extends StatelessWidget {
  final ComponentType type;
  final int stepNumber;
  final Nivel10Game game;

  const _StepSection({
    required this.type,
    required this.stepNumber,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final opciones = PhishingData.optionsForType(type);
    final seleccionado = game.componentesSeleccionados[type];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header del paso
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              PhishingData.labelForType(type),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Opciones
        ...opciones.map(
          (op) => _OpcionItem(
            componente: op,
            isSelected: seleccionado?.id == op.id,
            onTap: () => game.seleccionarComponente(op),
          ),
        ),

        // Comentario del hacker si hay selección
        if (seleccionado != null && seleccionado.hackerComment.isNotEmpty) ...[
          const SizedBox(height: 8),
          _HackerComment(text: seleccionado.hackerComment),
        ],

        const SizedBox(height: 6),
        const Divider(color: AppColors.border, height: 24),
      ],
    );
  }
}

class _OpcionItem extends StatelessWidget {
  final EmailComponent componente;
  final bool isSelected;
  final VoidCallback onTap;

  const _OpcionItem({
    required this.componente,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.08)
              : AppColors.bgMain,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.cyan : AppColors.border,
          ),
        ),
        child: Text(
          componente.value,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: isSelected ? AppColors.cyan : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HackerComment extends StatelessWidget {
  final String text;

  const _HackerComment({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.bgMain,
        border: const Border(
          left: BorderSide(color: AppColors.purple, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '// HACKER',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.purple,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CREDIBILIDAD ──────────────────────────────────────────────────────────────

class _CredibilidadCard extends StatelessWidget {
  final Nivel10Game game;

  const _CredibilidadCard({required this.game});

  @override
  Widget build(BuildContext context) {
    const maxCredibilidad = 12;
    final progreso = game.credibilidadTotal / maxCredibilidad;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('CREDIBILIDAD'),
          const SizedBox(height: 12),
          const Text(
            'PUNTUACIÓN DE ENGAÑO',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${game.credibilidadTotal}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cyan,
                  ),
                ),
                TextSpan(
                  text: ' / $maxCredibilidad',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Botón lanzar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: game.acto1Completo ? game.confirmarActo1 : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'LANZAR ATAQUE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: game.acto1Completo
                      ? AppColors.bgMain
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
          if (!game.acto1Completo) ...[
            const SizedBox(height: 8),
            const Text(
              'Selecciona una opción en cada paso para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ── LIBRETA ───────────────────────────────────────────────────────────────────

class _LibretaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelLabel('LIBRETA'),
          SizedBox(height: 10),
          _LibretaItem(
            'Carlos usa Firefox y revisa el remitente antes de abrir.',
          ),
          SizedBox(height: 6),
          _LibretaItem('Su certificado vence el viernes.'),
          SizedBox(height: 6),
          _LibretaItem('Trabaja bajo presión de plazos.'),
        ],
      ),
    );
  }
}

class _LibretaItem extends StatelessWidget {
  final String text;
  const _LibretaItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
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
