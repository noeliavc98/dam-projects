import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class ResponsiveGameHud extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final List<Widget> stats;
  final double verticalOffset;
  final double? compactVerticalOffset;

  const ResponsiveGameHud({
    super.key,
    required this.title,
    required this.onBack,
    required this.stats,
    this.verticalOffset = 10,
    this.compactVerticalOffset,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 620;
    final horizontalPadding = compact ? 10.0 : 16.0;
    final topPadding = compact ? compactVerticalOffset ?? 10 : verticalOffset;
    final contentWidth = screenWidth - (horizontalPadding * 2);

    final titleRow = Row(
      children: [
        _HudBackButton(onTap: onBack),
        const SizedBox(width: 12),
        Expanded(child: _HudTitle(title: title)),
      ],
    );
    final statsWrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: stats,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: topPadding,
          ),
          child: compact
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleRow),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (contentWidth * 0.45).clamp(120.0, 260.0),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: statsWrap,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HudBackButton(onTap: onBack),
                    const SizedBox(width: 12),
                    Expanded(child: _HudTitle(title: title)),
                    Flexible(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: statsWrap,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class GameTrainingBanner extends StatelessWidget {
  const GameTrainingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.purple,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'MODO ENTRENAMIENTO - Puntuacion no se guardara',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.purple.withValues(alpha: 0.9),
                    fontSize: 10,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameHintOverlay extends StatelessWidget {
  final String text;

  const GameHintOverlay({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: SafeArea(
        top: false,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.cyan.withValues(alpha: 0.4),
                fontSize: 9,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameHudHearts extends StatelessWidget {
  final int lives;

  const GameHudHearts({super.key, required this.lives});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
          child: Icon(
            Icons.favorite_rounded,
            color: i < lives
                ? AppColors.pink
                : AppColors.pink.withValues(alpha: 0.2),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class GameHudChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const GameHudChip({
    super.key,
    required this.label,
    this.color = AppColors.cyan,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameHudStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const GameHudStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.75),
                      fontSize: 8,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HudBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.cyan,
          size: 16,
        ),
      ),
    );
  }
}

class _HudTitle extends StatelessWidget {
  final String title;

  const _HudTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.cyan, AppColors.purple],
      ).createShader(bounds),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
