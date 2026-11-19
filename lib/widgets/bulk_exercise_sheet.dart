import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../catalog/exercise_catalog.dart' show kEquipment;
import '../l10n/extra_strings.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../services/exercise_smart.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'ui_kit.dart';

Future<List<String>> showBulkImportExercisesSheet(
  BuildContext context, {
  DateTime? addToDay,
}) async {
  final res = await showAppSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BulkExerciseSheet(addToDay: addToDay),
  );
  return res ?? const [];
}

class _BulkExerciseSheet extends StatefulWidget {
  const _BulkExerciseSheet({this.addToDay});

  final DateTime? addToDay;

  @override
  State<_BulkExerciseSheet> createState() => _BulkExerciseSheetState();
}

class _BulkExerciseSheetState extends State<_BulkExerciseSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final Map<String, ({String? primary, String? equipment, String? mode})> _overrides = {};
  List<BulkParsedExercise> _parsed = const [];
  late bool _alsoLogToday = widget.addToDay != null;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String v) {
    setState(() {
      _parsed = parseBulkExerciseLines(v);
    });
  }

  void _fillSample() {
    HapticFeedback.selectionClick();
    _ctrl.text = ExtraStrings.bulkImportSampleText;
    _parsed = parseBulkExerciseLines(_ctrl.text);
    setState(() {});
  }

  ({String primary, List<String> secondary, String equipment, String mode, String art}) _resolvedOf(
      BulkParsedExercise item) {
    final ov = _overrides[item.name.toLowerCase()];
    final primary = ov?.primary ?? item.meta.primary;
    final equipment = ov?.equipment ?? item.meta.equipment;
    final mode = ov?.mode ?? item.meta.mode;
    return (
      primary: primary,
      secondary: [for (final s in item.meta.secondary) if (s != primary) s],
      equipment: equipment,
      mode: mode,
      art: item.meta.art,
    );
  }

  Set<String> _existingKeys() => {
        for (final e in fit.allExercises) ...[
          e.name.trim().toLowerCase(),
          t.catalogName(e.id, e.name).trim().toLowerCase(),
        ],
      };

  Future<void> _pickMuscle(String key, String current) async {
    final gc = context.gc;
    final picked = await showAppSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        padding: sheetPad(sheet),
        decoration: sheetDecoration(gc),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              SheetTitle(t.muscleFilter),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in kMuscles)
                    Pill(
                      label: muscleLabel(m.id),
                      bg: m.id == current ? gc.ember : gc.bgRaised2,
                      fg: m.id == current ? gc.onEmber : gc.textSecondary,
                      onTap: () => Navigator.of(sheet).pop(m.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final cur = _overrides[key];
    setState(() {
      _overrides[key] = (primary: picked, equipment: cur?.equipment, mode: cur?.mode);
    });
  }

  Future<void> _pickEquipment(String key, String current) async {
    final gc = context.gc;
    final list = [...kEquipment, ...fit.customGear];
    final picked = await showAppSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        padding: sheetPad(sheet),
        decoration: sheetDecoration(gc),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              SheetTitle(t.equipmentLabel),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final eq in list)
                    Pill(
                      label: t.equipment(eq),
                      bg: eq == current ? gc.ember : gc.bgRaised2,
                      fg: eq == current ? gc.onEmber : gc.textSecondary,
                      onTap: () => Navigator.of(sheet).pop(eq),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final cur = _overrides[key];
    setState(() {
      _overrides[key] = (primary: cur?.primary, equipment: picked, mode: cur?.mode);
    });
  }

  void _cycleMode(String key, String current) {
    HapticFeedback.selectionClick();
    final next = switch (current) {
      '' => 'time',
      'time' => 'cardio',
      _ => '',
    };
    final cur = _overrides[key];
    setState(() {
      _overrides[key] = (primary: cur?.primary, equipment: cur?.equipment, mode: next);
    });
  }

  void _submit(List<BulkParsedExercise> ready) {
    final gc = context.gc;
    if (ready.isEmpty) {
      showNotchToast(
        context,
        ExtraStrings.bulkImportEmptyAction,
        icon: PhosphorIconsFill.warningCircle,
        accent: gc.warn,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final payload = <({
      String name,
      String primary,
      List<String> secondary,
      String equipment,
      String mode,
      String art,
    })>[];
    for (final item in ready) {
      final r = _resolvedOf(item);
      payload.add((
        name: item.name,
        primary: r.primary,
        secondary: r.secondary,
        equipment: r.equipment,
        mode: r.mode,
        art: r.art,
      ));
    }
    final createdIds = fit.addCustomExercisesBulk(payload);
    if (_alsoLogToday) {
      final targetDay = widget.addToDay ?? DateTime.now();
      for (final id in createdIds) {
        final ex = fit.exerciseById(id);
        if (ex != null) fit.quickLogAddExercise(ex, day: targetDay);
      }
    }
    showNotchToast(
      context,
      _alsoLogToday
          ? ExtraStrings.bulkImportDoneAndLoggedToast(createdIds.length)
          : ExtraStrings.bulkImportDoneToast(createdIds.length),
      icon: PhosphorIconsFill.checkCircle,
      accent: gc.sage,
    );
    Navigator.of(context).pop(createdIds);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final media = MediaQuery.of(context);
    final existing = _existingKeys();
    final ready = [
      for (final p in _parsed)
        if (!existing.contains(p.name.trim().toLowerCase())) p,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        padding: sheetPad(context, bottom: 20),
        decoration: sheetDecoration(gc),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            SheetTitle(
              ExtraStrings.bulkImportTitle,
              subtitle: ExtraStrings.bulkImportSubtitle,
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: gc.bgRaised2,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _ctrl,
                            minLines: 4,
                            maxLines: 7,
                            keyboardType: TextInputType.multiline,
                            onChanged: _onTextChanged,
                            style: AppTheme.f(14, weight: FontWeight.w500, color: gc.text, height: 1.45),
                            cursorColor: gc.accent,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: ExtraStrings.bulkImportHint,
                              hintStyle: AppTheme.f(13, weight: FontWeight.w500, color: gc.textTertiary, height: 1.45),
                            ),
                          ),
                          if (_ctrl.text.trim().isEmpty) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Pill(
                                label: ExtraStrings.bulkImportFillSample,
                                bg: gc.accentSoft,
                                fg: gc.accent,
                                onTap: _fillSample,
                                hPad: 12,
                                vPad: 6,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Pressable(
                      scale: 0.985,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _alsoLogToday = !_alsoLogToday);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: gc.bgRaised2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.lightning, size: 17, color: gc.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ExtraStrings.bulkImportAlsoLogToday,
                                style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text),
                              ),
                            ),
                            TinySwitch(on: _alsoLogToday),
                          ],
                        ),
                      ),
                    ),
                    if (_parsed.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            ExtraStrings.bulkImportPreviewTitle(ready.length),
                            style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text),
                          ),
                          const Spacer(),
                          Text(
                            ExtraStrings.bulkImportTapToAdjust,
                            style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final (i, item) in _parsed.indexed) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _previewTile(gc, item, existing.contains(item.name.trim().toLowerCase())),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: ready.isNotEmpty ? ExtraStrings.bulkImportSubmit(ready.length) : ExtraStrings.bulkImportTitle,
              onTap: () => _submit(ready),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewTile(GymColors gc, BulkParsedExercise item, bool isDup) {
    final key = item.name.toLowerCase();
    final res = _resolvedOf(item);
    final modeLabel = switch (res.mode) {
      'time' => t.typeTime,
      'cardio' => t.typeCardio,
      _ => t.typeReps,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDup ? gc.border : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(
                    14,
                    weight: FontWeight.w700,
                    color: isDup ? gc.textTertiary : gc.text,
                  ),
                ),
              ),
              if (isDup)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gc.bgRaised,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    ExtraStrings.bulkImportDuplicateBadge,
                    style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textTertiary),
                  ),
                ),
            ],
          ),
          if (!isDup) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Pill(
                  label: muscleLabel(res.primary),
                  bg: gc.accentSoft,
                  fg: gc.accent,
                  onTap: () => _pickMuscle(key, res.primary),
                  hPad: 10,
                  vPad: 5,
                  fontSize: 11.5,
                ),
                Pill(
                  label: t.equipment(res.equipment),
                  bg: gc.bgRaised,
                  fg: gc.textSecondary,
                  onTap: () => _pickEquipment(key, res.equipment),
                  hPad: 10,
                  vPad: 5,
                  fontSize: 11.5,
                ),
                Pill(
                  label: modeLabel,
                  bg: res.mode.isNotEmpty ? gc.sage.withValues(alpha: 0.16) : gc.bgRaised,
                  fg: res.mode.isNotEmpty ? gc.sage : gc.textTertiary,
                  onTap: () => _cycleMode(key, res.mode),
                  hPad: 10,
                  vPad: 5,
                  fontSize: 11.5,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
