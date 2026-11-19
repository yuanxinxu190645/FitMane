import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog/pro_packs.dart';
import '../l10n/extra_strings.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'ui_kit.dart';

void showExercisePacksSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ExercisePacksSheet(),
  );
}

class _ExercisePacksSheet extends StatelessWidget {
  const _ExercisePacksSheet();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fit,
      builder: (context, _) {
        final gc = context.gc;
        final zh = ExtraStrings.isZh;
        return AppSheet(
          children: [
            SheetTitle(
              ExtraStrings.exercisePacksTitle,
              subtitle: ExtraStrings.exercisePacksSummary(
                fit.enabledPackCount,
                fit.enabledPackExerciseCount,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ExtraStrings.exercisePacksHint,
              style: AppTheme.f(
                12.5,
                weight: FontWeight.w500,
                color: gc.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < kExercisePacks.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _PackTile(
                pack: kExercisePacks[i],
                enabled: fit.isPackEnabled(kExercisePacks[i].id),
                zh: zh,
                onToggle: () {
                  HapticFeedback.selectionClick();
                  fit.toggleExercisePack(kExercisePacks[i].id);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.pack,
    required this.enabled,
    required this.zh,
    required this.onToggle,
  });

  final ExercisePackMeta pack;
  final bool enabled;
  final bool zh;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Pressable(
      onTap: onToggle,
      scale: 0.985,
      child: SoftCard(
        radius: 20,
        color: enabled ? gc.bgRaised2 : gc.bgRaised,
        borderColor:
            enabled ? gc.accent.withValues(alpha: 0.25) : Colors.transparent,
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pack.title(zh),
                          style: AppTheme.f(
                            14.5,
                            weight: FontWeight.w700,
                            color: gc.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: enabled ? gc.accentSoft : gc.bgRaised2,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          ExtraStrings.exercisePackCount(pack.exercises.length),
                          style: AppTheme.d(
                            11,
                            weight: FontWeight.w700,
                            color: enabled ? gc.accent : gc.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pack.subtitle(zh),
                    style: AppTheme.f(
                      12,
                      weight: FontWeight.w500,
                      color: gc.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TinySwitch(on: enabled),
          ],
        ),
      ),
    );
  }
}
