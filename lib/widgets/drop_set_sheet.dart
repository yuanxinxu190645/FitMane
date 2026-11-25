import 'dart:math' as math;

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
import 'dialogs.dart';
import 'glass.dart';
import 'ui_kit.dart';

/// Opens a bottom sheet for creating or editing a multi-stage drop-set chain
/// (e.g. 6kg×12 -> 4kg×12 -> 2kg×12 counted as 1 big set / 36 reps).
Future<({List<DropStage> stages, int count})?> showDropSetBuilderSheet(
  BuildContext context, {
  required String exerciseId,
  Exercise? exercise,
  List<DropStage>? initialStages,
  bool allowBatchCount = true,
  int initialCount = 3,
}) {
  return showAppSheet<({List<DropStage> stages, int count})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DropSetBuilderSheet(
      exerciseId: exerciseId,
      exercise: exercise,
      initialStages: initialStages,
      allowBatchCount: allowBatchCount,
      initialCount: initialCount,
    ),
  );
}

class _MutableStage {
  _MutableStage({required this.displayWeight, required this.reps});

  double displayWeight;
  int reps;
}

class _DropSetBuilderSheet extends StatefulWidget {
  const _DropSetBuilderSheet({
    required this.exerciseId,
    required this.exercise,
    required this.initialStages,
    required this.allowBatchCount,
    required this.initialCount,
  });

  final String exerciseId;
  final Exercise? exercise;
  final List<DropStage>? initialStages;
  final bool allowBatchCount;
  final int initialCount;

  @override
  State<_DropSetBuilderSheet> createState() => _DropSetBuilderSheetState();
}

class _DropSetBuilderSheetState extends State<_DropSetBuilderSheet> {
  late final List<_MutableStage> _stages;
  late int _count;

  double _round2(double v) => (v * 100).round() / 100;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount.clamp(1, 10);
    if (widget.initialStages != null && widget.initialStages!.length >= 2) {
      _stages = [
        for (final d in widget.initialStages!)
          _MutableStage(
            displayWeight: _round2(fit.toDisplayWeight(d.weight)),
            reps: d.reps,
          ),
      ];
    } else {
      final isDb = widget.exercise?.equipment == 'Dumbbell';
      final step = isDb ? 2.0 : fit.weightStep;
      final start = isDb ? 6.0 : math.max(step * 4, 20.0);
      _stages = [
        _MutableStage(displayWeight: _round2(start), reps: 12),
        _MutableStage(displayWeight: _round2(math.max(0, start - step)), reps: 12),
        _MutableStage(displayWeight: _round2(math.max(0, start - step * 2)), reps: 12),
      ];
    }
  }

  void _addStage() {
    if (_stages.length >= 6) return;
    HapticFeedback.selectionClick();
    final last = _stages.last;
    final step = widget.exercise?.equipment == 'Dumbbell' ? 2.0 : fit.weightStep;
    setState(() {
      _stages.add(
        _MutableStage(
          displayWeight: _round2(math.max(0, last.displayWeight - step)),
          reps: last.reps,
        ),
      );
    });
  }

  void _removeStage(int idx) {
    if (_stages.length <= 2) return;
    HapticFeedback.selectionClick();
    setState(() => _stages.removeAt(idx));
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    final stages = [
      for (final s in _stages)
        DropStage(
          weight: fit.fromDisplayWeight(math.max(0, s.displayWeight)),
          reps: s.reps.clamp(1, 999),
        ),
    ];
    Navigator.of(context).pop((stages: stages, count: _count));
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final isDb = widget.exercise?.equipment == 'Dumbbell';
    final paired = isDb && fit.isPaired(widget.exerciseId);
    final step = isDb ? 1.0 : fit.weightStep;
    final unitUpper = fit.units.toUpperCase();
    final totalReps = _stages.fold<int>(0, (sum, s) => sum + s.reps);
    final rawDisplayVol = _stages.fold<double>(0, (sum, s) => sum + s.displayWeight * s.reps);
    final shownVol = rawDisplayVol * (paired ? 2 : 1);
    final volText = '${fmt(_round2(shownVol))} ${fit.units}';

    return AppSheet(
      children: [
        SheetTitle(
          widget.allowBatchCount ? ExtraStrings.dropSetBuilderTitle : ExtraStrings.dropSetEditTitle,
          subtitle: ExtraStrings.dropSetBuilderSubtitle,
        ),
        const SizedBox(height: 12),
        if (isDb) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: gc.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.barbell, size: 13, color: gc.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ExtraStrings.dropSetDumbbellHint(paired),
                    style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < _stages.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
            decoration: BoxDecoration(
              color: gc.bgRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: gc.info.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ExtraStrings.dropSetStageLabel(i + 1),
                    style: AppTheme.f(11, weight: FontWeight.w800, color: gc.info),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isDb ? ExtraStrings.dumbbellWeightCol(unitUpper) : t.weightCol(unitUpper),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.s(9.5, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      StepperControl(
                        value: fmt(_stages[i].displayWeight),
                        onDec: () => setState(() {
                          _stages[i].displayWeight = _round2(math.max(0, _stages[i].displayWeight - step));
                        }),
                        onInc: () => setState(() {
                          _stages[i].displayWeight = _round2(_stages[i].displayWeight + step);
                        }),
                        onEdit: () async {
                          final v = await askNumber(
                            context,
                            title: isDb
                                ? ExtraStrings.dumbbellInputTitle(unitUpper)
                                : t.weightCol(unitUpper),
                            subtitle: isDb ? ExtraStrings.dumbbellInputHint(paired: paired) : null,
                            initial: fmt(_stages[i].displayWeight),
                            decimal: true,
                          );
                          if (v != null && mounted) {
                            setState(() => _stages[i].displayWeight = _round2(math.max(0, v)));
                          }
                        },
                        minWidth: 32,
                        btnSize: 26,
                        gap: 5,
                        fontSize: 13.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        t.repsCol,
                        maxLines: 1,
                        style: AppTheme.s(9.5, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      StepperControl(
                        value: '${_stages[i].reps}',
                        onDec: () => setState(() {
                          _stages[i].reps = math.max(1, _stages[i].reps - 1);
                        }),
                        onInc: () => setState(() {
                          _stages[i].reps = math.min(999, _stages[i].reps + 1);
                        }),
                        onEdit: () async {
                          final v = await askNumber(
                            context,
                            title: t.repsCol,
                            initial: '${_stages[i].reps}',
                            decimal: false,
                          );
                          if (v != null && mounted) {
                            setState(() => _stages[i].reps = v.round().clamp(1, 999));
                          }
                        },
                        minWidth: 26,
                        btnSize: 26,
                        gap: 5,
                        fontSize: 13.5,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _stages.length > 2 ? () => _removeStage(i) : null,
                  child: SizedBox(
                    width: 28,
                    height: 36,
                    child: Icon(
                      PhosphorIconsRegular.x,
                      size: 14,
                      color: _stages.length > 2 ? gc.textTertiary : gc.border,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_stages.length < 6) ...[
          const SizedBox(height: 8),
          Pressable(
            scale: 0.98,
            onTap: _addStage,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: gc.bgRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gc.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsBold.plus, size: 12, color: gc.info),
                  const SizedBox(width: 5),
                  Text(
                    ExtraStrings.dropSetAddStage,
                    style: AppTheme.f(12.5, weight: FontWeight.w700, color: gc.info),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SoftCard(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(PhosphorIconsBold.trendDown, size: 15, color: gc.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ExtraStrings.dropSetSummary(totalReps, volText, paired: paired),
                  style: AppTheme.f(12.5, weight: FontWeight.w700, color: gc.text),
                ),
              ),
            ],
          ),
        ),
        if (widget.allowBatchCount) ...[
          const SizedBox(height: 12),
          SoftCard(
            radius: 14,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ExtraStrings.dropSetBatchCount,
                        style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text),
                      ),
                    ),
                    StepperControl(
                      value: '$_count',
                      onDec: () => setState(() => _count = math.max(1, _count - 1)),
                      onInc: () => setState(() => _count = math.min(10, _count + 1)),
                      minWidth: 26,
                      btnSize: 28,
                      gap: 8,
                      fontSize: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final preset in const [3, 4, 5]) ...[
                      if (preset != 3) const SizedBox(width: 8),
                      Expanded(
                        child: Pressable(
                          scale: 0.96,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _count = preset);
                          },
                          child: Container(
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _count == preset ? gc.accentSoft : gc.bgRaised2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _count == preset
                                    ? gc.accent.withValues(alpha: 0.45)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              ExtraStrings.dropSetCountChip(preset),
                              style: AppTheme.f(
                                12,
                                weight: FontWeight.w700,
                                color: _count == preset ? gc.accent : gc.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Pressable(
          scale: 0.98,
          onTap: _submit,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gc.ember,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              widget.allowBatchCount
                  ? ExtraStrings.dropSetConfirmAdd(_count)
                  : ExtraStrings.dropSetConfirmSave,
              style: AppTheme.f(14.5, weight: FontWeight.w800, color: gc.onEmber),
            ),
          ),
        ),
      ],
    );
  }
}
