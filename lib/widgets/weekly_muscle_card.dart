import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/extra_strings.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ui_kit.dart';

class WeeklyMuscleCard extends StatefulWidget {
  const WeeklyMuscleCard({super.key});

  static const List<String> primaryMuscles = [
    'chest',
    'back',
    'shoulders',
    'quads',
    'hamstrings',
    'glutes',
  ];

  static const List<String> extraMuscles = [
    'biceps',
    'triceps',
    'abdomen',
    'calves',
  ];

  @override
  State<WeeklyMuscleCard> createState() => _WeeklyMuscleCardState();
}

class _WeeklyMuscleCardState extends State<WeeklyMuscleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final setsMap = fit.muscleSetsOver(7);
    final minTarget = fit.weeklyMuscleTarget;
    final maxTarget = fit.weeklyMuscleTargetMax;
    final shown = [
      ...WeeklyMuscleCard.primaryMuscles,
      if (_expanded) ...WeeklyMuscleCard.extraMuscles,
    ];

    return SoftCard(
      radius: 24,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                ExtraStrings.weeklyMuscleTitle.toUpperCase(),
                style: kickerStyle(gc),
              ),
              const SizedBox(width: 6),
              Icon(
                PhosphorIconsRegular.chartBar,
                size: 13,
                color: gc.textTertiary,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  ExtraStrings.weeklyMuscleRange(minTarget, maxTarget),
                  style: AppTheme.d(11, weight: FontWeight.w600, color: gc.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < shown.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MuscleBarTile(
                    muscle: shown[i],
                    sets: setsMap[shown[i]] ?? 0,
                    minTarget: minTarget,
                    maxTarget: maxTarget,
                  ),
                ),
                const SizedBox(width: 12),
                if (i + 1 < shown.length)
                  Expanded(
                    child: _MuscleBarTile(
                      muscle: shown[i + 1],
                      sets: setsMap[shown[i + 1]] ?? 0,
                      minTarget: minTarget,
                      maxTarget: maxTarget,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded
                        ? ExtraStrings.weeklyMuscleShowLess
                        : ExtraStrings.weeklyMuscleShowMore,
                    style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.textTertiary),
                  ),
                  const SizedBox(width: 4),
                  RotatedBox(
                    quarterTurns: _expanded ? 2 : 0,
                    child: Icon(
                      PhosphorIconsBold.caretDown,
                      size: 11,
                      color: gc.textTertiary,
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

class _MuscleBarTile extends StatelessWidget {
  const _MuscleBarTile({
    required this.muscle,
    required this.sets,
    required this.minTarget,
    required this.maxTarget,
  });

  final String muscle;
  final double sets;
  final int minTarget;
  final int maxTarget;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final rounded = sets.round();
    final ratio = maxTarget > 0 ? (sets / maxTarget).clamp(0.0, 1.0) : 0.0;
    final minMark = maxTarget > 0 ? (minTarget / maxTarget).clamp(0.1, 0.9) : 0.5;
    final Color barColor;
    if (sets <= 0) {
      barColor = gc.textTertiary.withValues(alpha: 0.25);
    } else if (sets >= minTarget && sets <= maxTarget) {
      barColor = gc.sage;
    } else {
      barColor = gc.accent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                muscleLabel(muscle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.f(12.5, weight: FontWeight.w600, color: gc.text),
              ),
            ),
            Text(
              '$rounded/$minTarget',
              style: AppTheme.d(
                11.5,
                weight: FontWeight.w700,
                color: sets >= minTarget ? gc.sage : gc.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: gc.bgRaised2,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  if (ratio > 0)
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  Positioned(
                    left: (w * minMark).clamp(2.0, w - 2.0),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: gc.bg.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
