import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/extra_strings.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../screens/exercises_screen.dart' show showCreateExerciseSheet;
import '../services/exercise_match.dart';
import '../services/exercise_smart.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dialogs.dart';
import 'exercise_media.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'set_kind.dart';
import 'ui_kit.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _formatSetSummary(LoggedExercise e, LoggedSet s) {
  if (fit.loggedDistance(e)) {
    final dist = '${fit.distanceValueFor(e.id, s.km ?? 0)} ${fit.distanceUnitFor(e.id)}';
    return (s.sec ?? 0) > 0 ? '$dist · ${durationLabel(s.sec!)}' : dist;
  }
  if (fit.loggedTimed(e)) {
    final dur = durationLabel(s.sec ?? 0);
    if (!fit.isRepsOnly(e.id) && s.weight > 0) {
      return '${fit.weightLabel(s.weight)} × $dur';
    }
    return dur;
  }
  final repsText = s.sided ? t.sidesReps(s.left ?? 0, s.right ?? 0) : '${s.reps}';
  if (!fit.isRepsOnly(e.id) && s.weight > 0) {
    return '${fit.weightLabel(s.weight)} × $repsText';
  }
  return s.sided ? repsText : t.repCount(s.reps);
}

String _formatTopSummary(LoggedExercise e) {
  final working = e.workingSets;
  final pool = working.isNotEmpty ? working : e.sets;
  if (pool.isEmpty) return '';
  if (fit.loggedDistance(e) || fit.loggedTimed(e)) {
    return _formatSetSummary(e, pool.first);
  }
  var best = pool.first;
  for (final st in pool.skip(1)) {
    if (st.weight > best.weight || (st.weight == best.weight && st.reps > best.reps)) {
      best = st;
    }
  }
  return _formatSetSummary(e, best);
}

Future<void> showQuickLogSheet(
  BuildContext context, {
  DateTime? initialDay,
  String? expandExerciseId,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickLogSheet(
      initialDay: initialDay,
      expandExerciseId: expandExerciseId,
    ),
  );
}

Future<String?> showQuickAddExerciseSheet(
  BuildContext context, {
  DateTime? day,
}) {
  return showAppSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickAddExerciseSheet(day: day ?? DateTime.now()),
  );
}

class _QuickLogSheet extends StatefulWidget {
  const _QuickLogSheet({this.initialDay, this.expandExerciseId});

  final DateTime? initialDay;
  final String? expandExerciseId;

  @override
  State<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<_QuickLogSheet> {
  late DateTime _day = _dayOnly(widget.initialDay ?? DateTime.now());
  String? _expandedId;
  final Map<String, double> _announcedPrScore = {};

  void _checkPrToast(BuildContext context, GymColors gc, LoggedExercise e, int i) {
    if (!fit.isQuickLogSetPr(e, i, _day)) return;
    final st = e.sets[i];
    final score = fit.isRepsOnly(e.id) ? st.reps.toDouble() : fit.liftScore(e.id, st);
    final announced = _announcedPrScore[e.id] ?? 0;
    if (score <= announced + 0.001) return;
    _announcedPrScore[e.id] = score;
    HapticFeedback.mediumImpact();
    showNotchToast(
      context,
      ExtraStrings.quickLogNewPrToast(t.catalogName(e.id, e.name)),
      icon: PhosphorIconsFill.trophy,
      accent: gc.accent,
    );
  }

  @override
  void initState() {
    super.initState();
    _expandedId = widget.expandExerciseId;
  }

  DateTime get _today => _dayOnly(DateTime.now());

  bool get _isToday => _day == _today;

  String get _dayLabel {
    if (_day == _today) return ExtraStrings.quickLogToday;
    if (_day == _today.subtract(const Duration(days: 1))) return ExtraStrings.quickLogYesterday;
    return t.shortDate(_day);
  }

  void _shiftDay(int delta) {
    final next = _dayOnly(DateTime(_day.year, _day.month, _day.day + delta));
    if (next.isAfter(_today)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _day = next;
      _expandedId = null;
    });
  }

  Future<void> _openPicker() async {
    final addedId = await showQuickAddExerciseSheet(context, day: _day);
    if (addedId != null && mounted) {
      setState(() => _expandedId = addedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final media = MediaQuery.of(context);
    return AnimatedBuilder(
      animation: fit,
      builder: (context, _) {
        final entries = <(LoggedSession session, LoggedExercise ex)>[
          for (final s in fit.sessionsOn(_day))
            for (final e in s.exercises) (s, e),
        ];
        final totalSets = entries.fold<int>(0, (acc, item) => acc + item.$2.sets.length);
        final effectiveExpanded = _expandedId ?? (entries.length == 1 ? entries.single.$2.id : null);

        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
            padding: sheetPad(context, bottom: 20),
            decoration: sheetDecoration(gc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHandle(),
                const SizedBox(height: 14),
                SheetTitle(
                  ExtraStrings.quickWorkoutTitle,
                  subtitle: entries.isNotEmpty
                      ? ExtraStrings.quickLogSummary(entries.length, totalSets)
                      : ExtraStrings.quickLogEmptyHint,
                ),
                const SizedBox(height: 14),
                _daySwitcher(gc),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (entries.isEmpty)
                          _emptyDayCard(gc)
                        else
                          for (final (idx, item) in entries.indexed) ...[
                            if (idx > 0) const SizedBox(height: 10),
                            _exerciseCard(
                              context,
                              gc,
                              item.$1,
                              item.$2,
                              expanded: effectiveExpanded == item.$2.id,
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: '+ ${ExtraStrings.quickLogAddExercise}',
                  onTap: _openPicker,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _daySwitcher(GymColors gc) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _navArrow(gc, PhosphorIconsBold.caretLeft, true, () => _shiftDay(-1)),
          Expanded(
            child: Text(
              '$_dayLabel · ${t.shortDate(_day)}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.f(13.5, weight: FontWeight.w700, color: gc.text),
            ),
          ),
          _navArrow(gc, PhosphorIconsBold.caretRight, !_isToday, () => _shiftDay(1)),
        ],
      ),
    );
  }

  Widget _navArrow(GymColors gc, IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 40,
        height: 36,
        child: Icon(
          icon,
          size: 15,
          color: enabled ? gc.text : gc.textTertiary.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _emptyDayCard(GymColors gc) {
    final rec = fit.smartQuickRecommendation;
    final reason = rec.hasReason
        ? ExtraStrings.smartRecReason(
            muscleLabel(rec.highlightMuscle),
            rec.weeklySets,
            recovered: rec.recovery >= 0.75,
          )
        : '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: gc.accentSoft, shape: BoxShape.circle),
                child: Icon(PhosphorIconsRegular.barbell, size: 19, color: gc.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ExtraStrings.quickLogNoEntriesDay,
                  style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: gc.bgRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsBold.sparkle, size: 14, color: gc.sage),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ExtraStrings.quickLogRecommendedTitle(rec.title),
                        style: AppTheme.f(12.5, weight: FontWeight.w700, color: gc.sage),
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          reason,
                          style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary),
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

  Widget _exerciseCard(
    BuildContext context,
    GymColors gc,
    LoggedSession s,
    LoggedExercise e, {
    required bool expanded,
  }) {
    final catalogEx = fit.exerciseById(e.id);
    final repsOnly = fit.isRepsOnly(e.id);
    final prev = fit.previousExerciseBefore(e.id, _day);
    final topSummary = _formatTopSummary(e);
    final prevSummary = prev == null ? '' : _formatTopSummary(prev);

    return Container(
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expanded ? gc.accent.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expandedId = expanded ? '' : e.id);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  if (catalogEx != null)
                    SizedBox(
                      width: 44,
                      child: ExerciseMedia(ex: catalogEx, height: 44, radius: 12, bordered: false),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: gc.bgRaised,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(PhosphorIconsRegular.barbell, size: 18, color: gc.textSecondary),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.catalogName(e.id, e.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          topSummary.isEmpty
                              ? ExtraStrings.quickLogSetsUnit(e.sets.length)
                              : '${ExtraStrings.quickLogSetsUnit(e.sets.length)} · $topSummary',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final ok = await askConfirm(
                        context,
                        title: ExtraStrings.quickLogDeleteExercise,
                        body: t.catalogName(e.id, e.name),
                        confirmLabel: t.delete,
                        danger: true,
                      );
                      if (ok) fit.deleteLoggedExercise(s, e);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textTertiary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: RotatedBox(
                      quarterTurns: expanded ? 2 : 0,
                      child: Icon(
                        PhosphorIconsBold.caretDown,
                        size: 14,
                        color: gc.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Container(height: 1, color: gc.border.withValues(alpha: 0.45)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (prev != null && prevSummary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 2),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.clockCounterClockwise, size: 13, color: gc.accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ExtraStrings.quickLogLastSession(
                                '$prevSummary · ${ExtraStrings.quickLogSetsUnit(prev.sets.length)}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.f(12, weight: FontWeight.w600, color: gc.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (var i = 0; i < e.sets.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _setEditorRow(context, gc, s, e, i, repsOnly),
                  ],
                  const SizedBox(height: 10),
                  Pressable(
                    scale: 0.97,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      fit.addLoggedSet(e);
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: gc.bgRaised,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsBold.plus, size: 13, color: gc.accent),
                          const SizedBox(width: 6),
                          Text(
                            ExtraStrings.quickLogAddSet,
                            style: AppTheme.f(13.5, weight: FontWeight.w700, color: gc.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _setEditorRow(
    BuildContext context,
    GymColors gc,
    LoggedSession s,
    LoggedExercise e,
    int i,
    bool repsOnly,
  ) {
    final set = e.sets[i];
    final distance = fit.loggedDistance(e);
    final timed = !distance && fit.loggedTimed(e);
    final kindTag = setKindTag(set.kind);
    final badgeText = kindTag.isEmpty ? '${i + 1}' : kindTag;
    final badgeColor = set.kind == SetKind.normal ? gc.text : setKindColor(gc, set.kind);

    Widget cell(
      String label,
      String value,
      VoidCallback onDec,
      VoidCallback onInc, {
      double minWidth = 28,
      Future<void> Function(BuildContext)? edit,
    }) {
      return Expanded(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTheme.s(9.5, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 2),
            Builder(
              builder: (ctx) => StepperControl(
                value: value,
                onDec: onDec,
                onInc: onInc,
                onEdit: edit == null ? null : () => edit(ctx),
                minWidth: minWidth,
                btnSize: 26,
                gap: 6,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      );
    }

    final timeCell = cell(
      t.timeCol,
      durationLabel(set.sec ?? 0),
      () => fit.bumpLoggedSec(e, i, -1),
      () => fit.bumpLoggedSec(e, i, 1),
      minWidth: 38,
    );

    final shownWeight = (fit.toDisplayWeight(set.weight) * 100).round() / 100;
    final isPr = fit.isQuickLogSetPr(e, i, _day);
    final weightCell = cell(
      t.weightCol(fit.units.toUpperCase()),
      fmt(shownWeight),
      () {
        fit.bumpLoggedWeight(e, i, -1);
        _checkPrToast(context, gc, e, i);
      },
      () {
        fit.bumpLoggedWeight(e, i, 1);
        _checkPrToast(context, gc, e, i);
      },
      minWidth: 32,
      edit: (ctx) async {
        final v = await askNumber(
          ctx,
          title: t.weightCol(fit.units.toUpperCase()),
          initial: fmt(shownWeight),
          decimal: true,
        );
        if (v != null) {
          fit.setLoggedWeightShown(e, i, v);
          if (context.mounted) _checkPrToast(context, gc, e, i);
        }
      },
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(14),
        border: isPr
            ? Border.all(color: gc.accent.withValues(alpha: 0.45), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final picked = await askSetKind(context, set.kind);
                  if (picked != null) fit.setLoggedKind(e, i, picked);
                },
                child: Container(
                  width: 28,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: set.kind == SetKind.normal
                        ? gc.bgRaised2
                        : setKindColor(gc, set.kind).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTheme.d(13, weight: FontWeight.w800, color: badgeColor),
                  ),
                ),
              ),
              if (isPr) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: gc.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsFill.star, size: 10, color: gc.accent),
                      const SizedBox(width: 2),
                      Text(
                        ExtraStrings.prBadge,
                        style: AppTheme.d(9.5, weight: FontWeight.w800, color: gc.accent),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 6),
              if (distance) ...[
                cell(
                  t.distanceCol(fit.distanceUnitFor(e.id)).replaceAll(RegExp(r'\s*\(.*\)'), ''),
                  fit.distanceValueFor(e.id, set.km ?? 0),
                  () => fit.bumpLoggedKm(e, i, -1),
                  () => fit.bumpLoggedKm(e, i, 1),
                  minWidth: 34,
                  edit: (ctx) async {
                    final v = await askNumber(
                      ctx,
                      title: t.distanceCol(fit.distanceUnitFor(e.id)).replaceAll(RegExp(r'\s*\(.*\)'), ''),
                      initial: fit.distanceValueFor(e.id, set.km ?? 0),
                      decimal: true,
                    );
                    if (v != null) fit.setLoggedKmShown(e, i, v);
                  },
                ),
                timeCell,
              ] else ...[
                if (!repsOnly && (!timed || set.weight > 0)) weightCell,
                if (timed)
                  timeCell
                else if (set.sided) ...[
                  cell(
                    t.repsLeftCol,
                    '${set.left ?? 0}',
                    () => fit.bumpLoggedSide(e, i, true, -1),
                    () => fit.bumpLoggedSide(e, i, true, 1),
                    minWidth: 22,
                    edit: (ctx) async {
                      final v = await askNumber(ctx, title: t.repsLeftCol, initial: '${set.left ?? 0}', decimal: false);
                      if (v != null) fit.setLoggedSide(e, i, true, v.round());
                    },
                  ),
                  cell(
                    t.repsRightCol,
                    '${set.right ?? 0}',
                    () => fit.bumpLoggedSide(e, i, false, -1),
                    () => fit.bumpLoggedSide(e, i, false, 1),
                    minWidth: 22,
                    edit: (ctx) async {
                      final v = await askNumber(ctx, title: t.repsRightCol, initial: '${set.right ?? 0}', decimal: false);
                      if (v != null) fit.setLoggedSide(e, i, false, v.round());
                    },
                  ),
                ] else
                  cell(
                    t.repsCol,
                    '${set.reps}',
                    () {
                      fit.bumpLoggedReps(e, i, -1);
                      _checkPrToast(context, gc, e, i);
                    },
                    () {
                      fit.bumpLoggedReps(e, i, 1);
                      _checkPrToast(context, gc, e, i);
                    },
                    edit: (ctx) async {
                      final v = await askNumber(ctx, title: t.repsCol, initial: '${set.reps}', decimal: false);
                      if (v != null) {
                        fit.setLoggedReps(e, i, v.round());
                        if (context.mounted) _checkPrToast(context, gc, e, i);
                      }
                    },
                  ),
              ],
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final text = await askText(
                    context,
                    title: ExtraStrings.quickLogSetNoteTitle,
                    initial: set.note,
                    hint: ExtraStrings.quickLogSetNoteHint,
                    allowEmpty: true,
                  );
                  if (text != null) fit.setLoggedNote(e, i, text);
                },
                child: SizedBox(
                  width: 30,
                  height: 36,
                  child: Icon(
                    set.note.isNotEmpty ? PhosphorIconsFill.notePencil : PhosphorIconsRegular.notePencil,
                    size: 14,
                    color: set.note.isNotEmpty ? gc.accent : gc.textTertiary,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: t.removeSet,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => fit.removeLoggedSet(s, e, i),
                  child: SizedBox(
                    width: 30,
                    height: 36,
                    child: Icon(PhosphorIconsRegular.x, size: 14, color: gc.textTertiary),
                  ),
                ),
              ),
            ],
          ),
          if (set.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 6, 8, 2),
              child: Text(
                set.note,
                style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAddExerciseSheet extends StatefulWidget {
  const _QuickAddExerciseSheet({required this.day});

  final DateTime day;

  @override
  State<_QuickAddExerciseSheet> createState() => _QuickAddExerciseSheetState();
}

class _QuickAddExerciseSheetState extends State<_QuickAddExerciseSheet> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Exercise> _recentExercises(Set<String> excludeIds) {
    final seen = <String>{...excludeIds};
    final out = <Exercise>[];
    final sorted = [...fit.sessions]..sort((a, b) => b.day.compareTo(a.day));
    for (final s in sorted) {
      for (final e in s.exercises) {
        if (!seen.add(e.id) || fit.isArchived(e.id)) continue;
        final ex = fit.exerciseById(e.id);
        if (ex != null) out.add(ex);
        if (out.length >= 6) return out;
      }
    }
    return out;
  }

  void _pick(Exercise ex) {
    HapticFeedback.mediumImpact();
    fit.quickLogAddExercise(ex, day: widget.day);
    Navigator.of(context).pop(ex.id);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final media = MediaQuery.of(context);
    final filter = exerciseSearch(_query);
    final activeAll = [
      for (final ex in fit.allExercises)
        if (!fit.isArchived(ex.id)) ex,
    ];
    final trimmed = _query.trim();
    final smartRec = fit.smartQuickRecommendation;
    final smartRecHeader = smartRec.hasReason
        ? '${ExtraStrings.quickLogRecommendedTitle(smartRec.title)} · ${ExtraStrings.smartRecReason(muscleLabel(smartRec.highlightMuscle), smartRec.weeklySets, recovered: smartRec.recovery >= 0.75)}'
        : ExtraStrings.quickLogRecommendedTitle(smartRec.title);
    final rec = trimmed.isEmpty
        ? [for (final ex in fit.recommendedExercises(6)) if (!fit.isArchived(ex.id)) ex]
        : const <Exercise>[];
    final recIds = {for (final ex in rec) ex.id};
    final recent = trimmed.isEmpty ? _recentExercises(recIds) : const <Exercise>[];
    final shownIds = {...recIds, for (final ex in recent) ex.id};
    final rest = trimmed.isEmpty
        ? [for (final ex in activeAll) if (!shownIds.contains(ex.id)) ex]
        : [for (final ex in activeAll) if (filter(ex)) ex];
    final hasExact = trimmed.isNotEmpty &&
        rest.any((e) =>
            exerciseName(e).trim().toLowerCase() == trimmed.toLowerCase() ||
            e.name.trim().toLowerCase() == trimmed.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.84,
        padding: sheetPad(context, bottom: 16),
        decoration: sheetDecoration(gc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            SheetTitle(
              ExtraStrings.quickLogAddExercise,
              subtitle: ExtraStrings.quickLogAddToToday(fit.quickLogDefaultSets),
            ),
            const SizedBox(height: 14),
            SearchField(
              controller: _ctrl,
              hint: ExtraStrings.quickLogSearchHint,
              color: gc.bgRaised2,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (trimmed.isNotEmpty && rest.isEmpty) ...[
                    _quickCreateCard(gc, trimmed),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        t.noMatches,
                        textAlign: TextAlign.center,
                        style: AppTheme.f(13.5, weight: FontWeight.w500, color: gc.textSecondary),
                      ),
                    ),
                  ],
                  if (rec.isNotEmpty) ...[
                    _sectionHeader(gc, smartRecHeader, accent: gc.sage),
                    for (final ex in rec) _exerciseRow(gc, ex),
                    const SizedBox(height: 10),
                  ],
                  if (recent.isNotEmpty) ...[
                    _sectionHeader(gc, ExtraStrings.quickLogRecentTitle),
                    for (final ex in recent) _exerciseRow(gc, ex),
                    const SizedBox(height: 10),
                  ],
                  if (rest.isNotEmpty) ...[
                    if (trimmed.isEmpty) _sectionHeader(gc, ExtraStrings.quickLogAllExercises),
                    for (final ex in rest) _exerciseRow(gc, ex),
                    if (trimmed.isNotEmpty && !hasExact) ...[
                      const SizedBox(height: 4),
                      _quickCreateCard(gc, trimmed),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCreateCard(GymColors gc, String rawName) {
    final name = rawName.trim();
    final meta = inferExerciseMeta(name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: gc.accentSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gc.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            scale: 0.985,
            onTap: () {
              HapticFeedback.mediumImpact();
              final id = fit.addCustomExercise(
                name: name,
                primary: meta.primary,
                secondary: meta.secondary,
                equipment: meta.equipment,
                mode: meta.mode,
                art: meta.art,
              );
              final created = fit.exerciseById(id);
              if (created != null) {
                fit.quickLogAddExercise(created, day: widget.day);
                showNotchToast(
                  context,
                  ExtraStrings.quickCreateCreatedToast(name),
                  icon: PhosphorIconsFill.checkCircle,
                  accent: gc.sage,
                );
              }
              Navigator.of(context).pop(id);
            },
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: gc.ember, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsBold.plus, size: 17, color: gc.onEmber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ExtraStrings.quickCreateAction(name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.f(14.5, weight: FontWeight.w700, color: gc.text),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ExtraStrings.quickCreateAutoHint(
                          muscleLabel(meta.primary),
                          t.equipment(meta.equipment),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.f(12, weight: FontWeight.w600, color: gc.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Pill(
              label: ExtraStrings.quickCreateCustomize,
              bg: gc.bgRaised,
              fg: gc.textSecondary,
              onTap: () {
                showCreateExerciseSheet(
                  context,
                  initialName: name,
                  onCreated: (id) {
                    final ex = fit.exerciseById(id);
                    if (ex != null) fit.quickLogAddExercise(ex, day: widget.day);
                    if (mounted) Navigator.of(context).pop(id);
                  },
                );
              },
              hPad: 12,
              vPad: 6,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(GymColors gc, String title, {Color? accent}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: kickerStyle(gc, color: accent),
      ),
    );
  }

  Widget _exerciseRow(GymColors gc, Exercise ex) {
    final logged = fit.isLoggedOnDay(ex.id, widget.day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        scale: 0.985,
        onTap: () => _pick(ex),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: ExerciseMedia(ex: ex, height: 44, radius: 12, bordered: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName(ex),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${muscleLabel(ex.primary)} · ${t.equipment(ex.equipment)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: logged ? gc.sage.withValues(alpha: 0.16) : gc.emberSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  logged ? PhosphorIconsBold.check : PhosphorIconsBold.plus,
                  size: 14,
                  color: logged ? gc.sage : gc.ember,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
