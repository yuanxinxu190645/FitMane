import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/extra_strings.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'quick_log_sheet.dart';
import 'ui_kit.dart';

class QuickLogCard extends StatelessWidget {
  const QuickLogCard({super.key});

  String _previewSet(LoggedExercise e) {
    final pool = e.workingSets.isNotEmpty ? e.workingSets : e.sets;
    if (pool.isEmpty) return ExtraStrings.quickLogSetsUnit(0);
    final s = pool.first;
    if (fit.loggedDistance(e)) {
      return '${fit.distanceValueFor(e.id, s.km ?? 0)} ${fit.distanceUnitFor(e.id)}';
    }
    if (fit.loggedTimed(e)) {
      return durationLabel(s.sec ?? 0);
    }
    var best = pool.first;
    for (final st in pool.skip(1)) {
      if (st.weight > best.weight || (st.weight == best.weight && st.reps > best.reps)) {
        best = st;
      }
    }
    final repsStr = best.sided ? '${best.left ?? 0}/${best.right ?? 0}' : '${best.reps}';
    if (!fit.isRepsOnly(e.id) && best.weight > 0) {
      final pairedSuffix = (!best.sided && fit.isPaired(e.id)) ? '×2' : '';
      return '${fit.weightLabel(best.weight)}$pairedSuffix × $repsStr';
    }
    return t.repCount(best.reps);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final todaySessions = fit.sessionsOn(DateTime.now());
    final items = <LoggedExercise>[
      for (final s in todaySessions) ...s.exercises,
    ];
    final totalSets = items.fold<int>(0, (acc, e) => acc + e.sets.length);
    final shown = items.take(4).toList();
    final rec = fit.smartQuickRecommendation;
    final recReason = rec.hasReason
        ? ExtraStrings.smartRecReason(
            muscleLabel(rec.highlightMuscle),
            rec.weeklySets,
            recovered: rec.recovery >= 0.75,
            effective: fit.useEffectiveVolume,
          )
        : '';

    return Pressable(
      scale: 0.985,
      onTap: () {
        HapticFeedback.selectionClick();
        showQuickLogSheet(context);
      },
      child: SoftCard(
        radius: 24,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  ExtraStrings.quickWorkoutTitle.toUpperCase(),
                  style: kickerStyle(gc),
                ),
                const SizedBox(width: 6),
                Icon(
                  PhosphorIconsRegular.lightning,
                  size: 13,
                  color: gc.textTertiary,
                ),
                const Spacer(),
                Pressable(
                  scale: 0.94,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final id = await showQuickAddExerciseSheet(context);
                    if (id != null && context.mounted) {
                      showQuickLogSheet(context, expandExerciseId: id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: gc.ember,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsBold.plus, size: 12, color: gc.onEmber),
                        const SizedBox(width: 5),
                        Text(
                          ExtraStrings.quickLogAddExercise,
                          style: AppTheme.f(12, weight: FontWeight.w700, color: gc.onEmber),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: gc.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.notePencil,
                      size: 18,
                      color: gc.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ExtraStrings.quickLogEmptyHint,
                      style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsBold.sparkle, size: 13, color: gc.sage),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ExtraStrings.quickLogRecommendedTitle(rec.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.f(12, weight: FontWeight.w700, color: gc.text),
                          ),
                          if (recReason.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              recReason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.f(11, weight: FontWeight.w500, color: gc.sage),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                ExtraStrings.quickLogSummary(items.length, totalSets),
                style: AppTheme.f(12.5, weight: FontWeight.w700, color: gc.accent),
              ),
              const SizedBox(height: 10),
              for (final (idx, e) in shown.indexed) ...[
                if (idx > 0) const SizedBox(height: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showQuickLogSheet(context, expandExerciseId: e.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: gc.bgRaised2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.catalogName(e.id, e.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${ExtraStrings.quickLogSetsUnit(e.sets.length)} · ${_previewSet(e)}',
                          style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Icon(PhosphorIconsBold.caretRight, size: 12, color: gc.textTertiary),
                      ],
                    ),
                  ),
                ),
              ],
              if (items.length > 4) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+${items.length - 4} · ${ExtraStrings.quickLogOpenToday}',
                      style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
