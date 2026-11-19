import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/extra_strings.dart';
import '../l10n/l10n.dart';
import '../services/body_comp_math.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'body_comp_card.dart';
import 'dialogs.dart';
import 'glass.dart';
import 'ui_kit.dart';

void showBodyCompTrendSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _BodyCompTrendSheet(),
  );
}

enum _TrendMode { dual, weight, bodyFat, leanMass }

class _BodyCompTrendSheet extends StatefulWidget {
  const _BodyCompTrendSheet();

  @override
  State<_BodyCompTrendSheet> createState() => _BodyCompTrendSheetState();
}

class _BodyCompTrendSheetState extends State<_BodyCompTrendSheet> {
  int? _rangeDays = 30;
  _TrendMode _mode = _TrendMode.dual;
  DateTime? _inspectDay;

  @override
  void initState() {
    super.initState();
    final w = BodyCompMath.dailyWeightSeries(fit.bodyweight);
    final bf = BodyCompMath.dailyBodyFatSeries(fit.measures);
    if (w.isEmpty && bf.isNotEmpty) {
      _mode = _TrendMode.bodyFat;
    } else if (bf.isEmpty) {
      _mode = _TrendMode.weight;
    }
    final recent30 = BodyCompMath.filterRange(w.isNotEmpty ? w : bf, 30);
    if (recent30.isEmpty && (w.isNotEmpty || bf.isNotEmpty)) {
      _rangeDays = null;
    }
  }

  String _fmtNum(double v, {int decimals = 1}) {
    final s = v.toStringAsFixed(decimals);
    return decimalText(s);
  }

  String _signed(double v, String unit) {
    final prefix = v > 0 ? '+' : '';
    return '$prefix${_fmtNum(v)} $unit'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fit,
      builder: (context, _) {
        final gc = context.gc;
        final rawWeight = BodyCompMath.dailyWeightSeries(
          fit.bodyweight,
          convert: fit.toDisplayWeight,
        );
        final rawBf = BodyCompMath.dailyBodyFatSeries(fit.measures);
        final rawLean = BodyCompMath.dailyLeanMassSeries(
          fit.bodyweight,
          fit.measures,
          convert: fit.toDisplayWeight,
        );

        final wFiltered = BodyCompMath.filterRange(rawWeight, _rangeDays);
        final bfFiltered = BodyCompMath.filterRange(rawBf, _rangeDays);
        final leanFiltered = BodyCompMath.filterRange(rawLean, _rangeDays);

        final (primary, secondary, pUnit, sUnit, pColor, sColor) = switch (_mode) {
          _TrendMode.dual => (
              wFiltered,
              bfFiltered,
              fit.units,
              '%',
              gc.accent,
              gc.sage,
            ),
          _TrendMode.weight => (
              wFiltered,
              const <BodyCompPoint>[],
              fit.units,
              '',
              gc.accent,
              gc.sage,
            ),
          _TrendMode.bodyFat => (
              bfFiltered,
              const <BodyCompPoint>[],
              '%',
              '',
              gc.sage,
              gc.accent,
            ),
          _TrendMode.leanMass => (
              leanFiltered,
              const <BodyCompPoint>[],
              fit.units,
              '',
              gc.info,
              gc.sage,
            ),
        };

        final maPrimary = BodyCompMath.movingAverage7d(primary);
        final maSecondary = BodyCompMath.movingAverage7d(secondary);
        final statsPrimary = BodyCompMath.periodStats(
          primary.isNotEmpty ? primary : secondary,
        );
        final statsUnit = primary.isNotEmpty ? pUnit : sUnit;
        final logs = BodyCompMath.mergeDailyLogs(fit.bodyweight, fit.measures);

        return AppSheet(
          maxHeight: 0.92,
          children: [
            SheetTitle(ExtraStrings.bodyCompTrendTitle),
            const SizedBox(height: 16),
            _rangeChips(gc),
            const SizedBox(height: 10),
            _modeChips(gc),
            const SizedBox(height: 14),
            _chartCard(
              gc,
              primary: primary,
              secondary: secondary,
              maPrimary: maPrimary,
              maSecondary: maSecondary,
              pUnit: pUnit,
              sUnit: sUnit,
              pColor: pColor,
              sColor: sColor,
            ),
            if (statsPrimary != null) ...[
              const SizedBox(height: 12),
              _statsRow(gc, statsPrimary, statsUnit),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: ExtraStrings.logTodayEntry,
                    height: 46,
                    onTap: () => showQuickBodyCompSheet(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GhostButton(
                    label: ExtraStrings.openAllMeasures,
                    icon: PhosphorIconsRegular.ruler,
                    onTap: () {
                      Navigator.of(context).pop();
                      fit.goMeasures();
                    },
                  ),
                ),
              ],
            ),
            if (logs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                ExtraStrings.recentLogsTitle.toUpperCase(),
                style: kickerStyle(gc),
              ),
              const SizedBox(height: 10),
              SoftCard(
                radius: 20,
                color: gc.bgRaised2,
                borderColor: Colors.transparent,
                padding: EdgeInsets.zero,
                clip: true,
                child: Column(
                  children: [
                    for (var i = 0; i < logs.length && i < 20; i++)
                      _logRow(context, gc, logs[i], last: i == logs.length - 1 || i == 19),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _rangeChips(GymColors gc) {
    final ranges = <(int?, String)>[
      (7, ExtraStrings.range7d),
      (30, ExtraStrings.range30d),
      (90, ExtraStrings.range90d),
      (null, ExtraStrings.rangeAll),
    ];
    return SegToggle([
      for (final (days, label) in ranges)
        SegOption(label, _rangeDays == days, () {
          setState(() {
            _rangeDays = days;
            _inspectDay = null;
          });
        }),
    ]);
  }

  Widget _modeChips(GymColors gc) {
    final modes = <(_TrendMode, String)>[
      (_TrendMode.dual, ExtraStrings.modeDual),
      (_TrendMode.weight, ExtraStrings.modeWeight),
      (_TrendMode.bodyFat, ExtraStrings.modeBodyFat),
      (_TrendMode.leanMass, ExtraStrings.modeLean),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, (m, label)) in modes.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Pressable(
              scale: 0.95,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _mode = m;
                  _inspectDay = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _mode == m ? gc.ember : gc.bgRaised2,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  label,
                  style: AppTheme.f(
                    12.5,
                    weight: FontWeight.w700,
                    color: _mode == m ? gc.onEmber : gc.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chartCard(
    GymColors gc, {
    required List<BodyCompPoint> primary,
    required List<BodyCompPoint> secondary,
    required List<BodyCompPoint> maPrimary,
    required List<BodyCompPoint> maSecondary,
    required String pUnit,
    required String sUnit,
    required Color pColor,
    required Color sColor,
  }) {
    final hasAny = primary.isNotEmpty || secondary.isNotEmpty;
    final dates = {
      for (final p in primary) p.date,
      for (final p in secondary) p.date,
    }.toList()
      ..sort();

    BodyCompPoint? findAt(List<BodyCompPoint> list, DateTime? day) {
      if (day == null) return null;
      for (final p in list) {
        if (p.date == day) return p;
      }
      return null;
    }

    final inspectDate = _inspectDay ?? (dates.isEmpty ? null : dates.last);
    final pAt = findAt(primary, inspectDate);
    final sAt = findAt(secondary, inspectDate);

    return SoftCard(
      radius: 22,
      color: gc.bgRaised2,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: !hasAny
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                ExtraStrings.noTrendDataHint,
                textAlign: TextAlign.center,
                style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (inspectDate != null)
                  Row(
                    children: [
                      Text(
                        t.shortDate(inspectDate),
                        style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary),
                      ),
                      const Spacer(),
                      if (pAt != null)
                        _legendChip(
                          pColor,
                          '${_fmtNum(pAt.value)} $pUnit'.trim(),
                          gc,
                        ),
                      if (pAt != null && sAt != null) const SizedBox(width: 8),
                      if (sAt != null)
                        _legendChip(
                          sColor,
                          '${_fmtNum(sAt.value)} $sUnit'.trim(),
                          gc,
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                DualBodyCompChart(
                  primary: primary,
                  secondary: secondary,
                  maPrimary: maPrimary,
                  maSecondary: maSecondary,
                  primaryColor: pColor,
                  secondaryColor: sColor,
                  primaryUnit: pUnit,
                  secondaryUnit: sUnit,
                  selectedDate: _inspectDay,
                  onSelectDate: (d) => setState(() => _inspectDay = d),
                  height: 184,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (primary.isNotEmpty) ...[
                      Container(
                        width: 12,
                        height: 3,
                        decoration: BoxDecoration(
                          color: pColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _mode == _TrendMode.bodyFat
                            ? ExtraStrings.modeBodyFat
                            : _mode == _TrendMode.leanMass
                                ? ExtraStrings.modeLean
                                : ExtraStrings.modeWeight,
                        style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textSecondary),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (secondary.isNotEmpty) ...[
                      Container(
                        width: 12,
                        height: 3,
                        decoration: BoxDecoration(
                          color: sColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        ExtraStrings.modeBodyFat,
                        style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textSecondary),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      '${ExtraStrings.rawLegend} · ${ExtraStrings.ma7Legend}',
                      style: AppTheme.f(11, weight: FontWeight.w500, color: gc.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _legendChip(Color color, String text, GymColors gc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: AppTheme.d(12, weight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _statsRow(GymColors gc, PeriodStats s, String unit) {
    Widget cell(String label, String val, {Color? valueColor}) => Expanded(
          child: SoftCard(
            radius: 16,
            color: gc.bgRaised2,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(10.5, weight: FontWeight.w600, color: gc.textTertiary),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    val,
                    maxLines: 1,
                    style: AppTheme.d(15, weight: FontWeight.w800, color: valueColor ?? gc.text),
                  ),
                ),
              ],
            ),
          ),
        );

    final deltaColor = s.change == 0 ? gc.textSecondary : (s.change < 0 ? gc.sage : gc.accent);
    return Row(
      children: [
        cell(ExtraStrings.statStart, _fmtNum(s.start)),
        const SizedBox(width: 8),
        cell(ExtraStrings.statLatest, '${_fmtNum(s.latest)} $unit'.trim()),
        const SizedBox(width: 8),
        cell(ExtraStrings.statChange, _signed(s.change, unit), valueColor: deltaColor),
        const SizedBox(width: 8),
        cell(ExtraStrings.statAvg, _fmtNum(s.avg)),
      ],
    );
  }

  Widget _logRow(
    BuildContext context,
    GymColors gc,
    MergedBodyCompDay entry, {
    required bool last,
  }) {
    final w = entry.weight;
    final bf = entry.bodyFat;
    final note = (w?.note.isNotEmpty == true ? w!.note : bf?.note) ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: gc.border.withValues(alpha: 0.45))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.shortDateYear(entry.day),
                  style: AppTheme.f(12, weight: FontWeight.w600, color: gc.textSecondary),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    if (w != null)
                      Text(
                        '${_fmtNum(fit.toDisplayWeight(w.kg))} ${fit.units}',
                        style: AppTheme.d(15.5, weight: FontWeight.w800, color: gc.text),
                      ),
                    if (bf != null)
                      Text(
                        '${_fmtNum(bf.value)}%',
                        style: AppTheme.d(15.5, weight: FontWeight.w800, color: gc.sage),
                      ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final ok = await askConfirm(
                context,
                title: ExtraStrings.deleteEntryLabel,
                body: t.shortDateYear(entry.day),
                confirmLabel: t.delete,
                danger: true,
              );
              if (!ok) return;
              if (w != null) fit.deleteBodyweight(w);
              if (bf != null) fit.deleteMeasure(bf);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(PhosphorIconsRegular.trash, size: 17, color: gc.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class DualBodyCompChart extends StatelessWidget {
  const DualBodyCompChart({
    super.key,
    required this.primary,
    required this.secondary,
    required this.maPrimary,
    required this.maSecondary,
    required this.primaryColor,
    required this.secondaryColor,
    required this.primaryUnit,
    required this.secondaryUnit,
    this.selectedDate,
    this.onSelectDate,
    this.height = 180,
  });

  final List<BodyCompPoint> primary;
  final List<BodyCompPoint> secondary;
  final List<BodyCompPoint> maPrimary;
  final List<BodyCompPoint> maSecondary;
  final Color primaryColor;
  final Color secondaryColor;
  final String primaryUnit;
  final String secondaryUnit;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onSelectDate;
  final double height;

  List<DateTime> get _allDates {
    final set = <DateTime>{
      for (final p in primary) p.date,
      for (final p in secondary) p.date,
    };
    return set.toList()..sort();
  }

  void _pickAt(double dx, double width) {
    if (onSelectDate == null) return;
    final dates = _allDates;
    if (dates.isEmpty) return;
    const leftPad = 38.0;
    final rightPad = secondary.isNotEmpty ? 38.0 : 12.0;
    final plotW = math.max(1.0, width - leftPad - rightPad);
    final tVal = ((dx - leftPad) / plotW).clamp(0.0, 1.0);
    final firstMs = dates.first.millisecondsSinceEpoch;
    final lastMs = dates.last.millisecondsSinceEpoch;
    if (lastMs <= firstMs) {
      onSelectDate!(dates.first);
      return;
    }
    final target = firstMs + (lastMs - firstMs) * tVal;
    var best = dates.first;
    var bestDiff = (best.millisecondsSinceEpoch - target).abs();
    for (final d in dates) {
      final diff = (d.millisecondsSinceEpoch - target).abs();
      if (diff < bestDiff) {
        best = d;
        bestDiff = diff;
      }
    }
    onSelectDate!(best);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final dates = _allDates;
    return Ltr(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _pickAt(d.localPosition.dx, box.maxWidth),
              onHorizontalDragUpdate: (d) => _pickAt(d.localPosition.dx, box.maxWidth),
              child: SizedBox(
                height: height,
                child: CustomPaint(
                  size: Size(box.maxWidth, height),
                  painter: _DualChartPainter(
                    primary: primary,
                    secondary: secondary,
                    maPrimary: maPrimary,
                    maSecondary: maSecondary,
                    dates: dates,
                    selectedDate: selectedDate,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    gridColor: gc.border.withValues(alpha: 0.45),
                    textColor: gc.textTertiary,
                    bgColor: gc.bgRaised2,
                  ),
                ),
              ),
            ),
          ),
          if (dates.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(
                left: 38,
                right: secondary.isNotEmpty ? 38 : 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.shortDate(dates.first),
                    style: AppTheme.d(10, weight: FontWeight.w600, color: gc.textTertiary),
                  ),
                  if (dates.length > 2)
                    Text(
                      t.shortDate(dates[dates.length ~/ 2]),
                      style: AppTheme.d(10, weight: FontWeight.w600, color: gc.textTertiary),
                    ),
                  if (dates.length > 1)
                    Text(
                      t.shortDate(dates.last),
                      style: AppTheme.d(10, weight: FontWeight.w600, color: gc.textTertiary),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DualChartPainter extends CustomPainter {
  _DualChartPainter({
    required this.primary,
    required this.secondary,
    required this.maPrimary,
    required this.maSecondary,
    required this.dates,
    required this.selectedDate,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.textColor,
    required this.bgColor,
  });

  final List<BodyCompPoint> primary;
  final List<BodyCompPoint> secondary;
  final List<BodyCompPoint> maPrimary;
  final List<BodyCompPoint> maSecondary;
  final List<DateTime> dates;
  final DateTime? selectedDate;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color textColor;
  final Color bgColor;

  static (double, double) _bounds(List<BodyCompPoint> a, List<BodyCompPoint> b) {
    final all = [...a, ...b];
    if (all.isEmpty) return (0, 100);
    var lo = all.first.value;
    var hi = all.first.value;
    for (final p in all) {
      if (p.value < lo) lo = p.value;
      if (p.value > hi) hi = p.value;
    }
    if ((hi - lo).abs() < 0.2) {
      return (lo - 1.0, hi + 1.0);
    }
    final pad = (hi - lo) * 0.15;
    return (lo - pad, hi + pad);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dates.isEmpty) return;
    const topPad = 10.0;
    const bottomPad = 10.0;
    const leftPad = 38.0;
    final rightPad = secondary.isNotEmpty ? 38.0 : 12.0;
    final chartW = math.max(1.0, size.width - leftPad - rightPad);
    final chartH = math.max(1.0, size.height - topPad - bottomPad);

    final firstMs = dates.first.millisecondsSinceEpoch;
    final lastMs = dates.last.millisecondsSinceEpoch;

    double xOf(DateTime d) {
      if (lastMs <= firstMs) return leftPad + chartW / 2;
      final f = (d.millisecondsSinceEpoch - firstMs) / (lastMs - firstMs);
      return leftPad + f.clamp(0.0, 1.0) * chartW;
    }

    final (pMin, pMax) = _bounds(primary, maPrimary);
    final (sMin, sMax) = _bounds(secondary, maSecondary);

    double yOf(double v, double lo, double hi) {
      final f = (v - lo) / math.max(0.001, hi - lo);
      return topPad + chartH - f.clamp(0.0, 1.0) * chartH;
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = topPad + chartH * i / 2;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
      if (primary.isNotEmpty) {
        final v = pMax - (pMax - pMin) * i / 2;
        _drawAxisText(
          canvas,
          v.toStringAsFixed(1),
          Offset(2, y - 6),
          width: leftPad - 6,
          align: TextAlign.right,
          color: secondary.isNotEmpty ? primaryColor.withValues(alpha: 0.85) : textColor,
        );
      }
      if (secondary.isNotEmpty) {
        final v = sMax - (sMax - sMin) * i / 2;
        _drawAxisText(
          canvas,
          '${v.toStringAsFixed(1)}%',
          Offset(leftPad + chartW + 4, y - 6),
          width: rightPad - 4,
          align: TextAlign.left,
          color: secondaryColor.withValues(alpha: 0.85),
        );
      }
    }

    // Selected guide line
    if (selectedDate != null) {
      final sx = xOf(selectedDate!);
      canvas.drawLine(
        Offset(sx, topPad),
        Offset(sx, topPad + chartH),
        Paint()
          ..color = textColor.withValues(alpha: 0.4)
          ..strokeWidth = 1.2,
      );
    }

    // Draw series
    void drawSeries(
      List<BodyCompPoint> raw,
      List<BodyCompPoint> ma,
      double lo,
      double hi,
      Color color, {
      required bool fillArea,
    }) {
      if (raw.isEmpty) return;
      final rawPts = [for (final p in raw) Offset(xOf(p.date), yOf(p.value, lo, hi))];
      final maPts = [for (final p in ma) Offset(xOf(p.date), yOf(p.value, lo, hi))];

      if (rawPts.length >= 2) {
        final rawPath = _smoothPath(rawPts);
        canvas.drawPath(
          rawPath,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }

      if (maPts.length >= 2) {
        final maPath = _smoothPath(maPts);
        if (fillArea) {
          final fill = Path.from(maPath)
            ..lineTo(maPts.last.dx, topPad + chartH)
            ..lineTo(maPts.first.dx, topPad + chartH)
            ..close();
          canvas.drawPath(
            fill,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.0),
                ],
              ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH)),
          );
        }
        canvas.drawPath(
          maPath,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round,
        );
      }

      for (var i = 0; i < rawPts.length; i++) {
        final selected = selectedDate != null && raw[i].date == selectedDate;
        final pt = rawPts[i];
        if (selected) {
          canvas.drawCircle(pt, 5.5, Paint()..color = color);
          canvas.drawCircle(pt, 2.5, Paint()..color = bgColor);
        } else {
          canvas.drawCircle(pt, 3.0, Paint()..color = color.withValues(alpha: 0.85));
        }
      }
    }

    drawSeries(secondary, maSecondary, sMin, sMax, secondaryColor, fillArea: primary.isEmpty);
    drawSeries(primary, maPrimary, pMin, pMax, primaryColor, fillArea: true);
  }

  static Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) {
      path.lineTo(pts.last.dx, pts.last.dy);
      return path;
    }
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  static void _drawAxisText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    required TextAlign align,
    required Color color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_DualChartPainter o) =>
      o.primary != primary ||
      o.secondary != secondary ||
      o.selectedDate != selectedDate ||
      o.primaryColor != primaryColor ||
      o.secondaryColor != secondaryColor;
}
