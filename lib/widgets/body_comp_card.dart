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
import 'body_comp_trend.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'ui_kit.dart';

class BodyCompCard extends StatelessWidget {
  const BodyCompCard({super.key});

  String _fmt(double v) => decimalText(v.toStringAsFixed(1));

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final summary = BodyCompMath.summarize(
      fit.bodyweight,
      fit.measures,
      heightCm: fit.profile.heightCm,
    );
    final wSeries = BodyCompMath.dailyWeightSeries(
      fit.bodyweight,
      convert: fit.toDisplayWeight,
    );
    final bfSeries = BodyCompMath.dailyBodyFatSeries(fit.measures);

    return Pressable(
      scale: 0.985,
      onTap: () {
        HapticFeedback.selectionClick();
        showBodyCompTrendSheet(context);
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
                  ExtraStrings.bodyCompTitle.toUpperCase(),
                  style: kickerStyle(gc),
                ),
                const SizedBox(width: 6),
                Icon(
                  PhosphorIconsRegular.chartLineUp,
                  size: 13,
                  color: gc.textTertiary,
                ),
                const Spacer(),
                Pressable(
                  scale: 0.94,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showQuickBodyCompSheet(context);
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
                          ExtraStrings.logNow,
                          style: AppTheme.f(12, weight: FontWeight.w700, color: gc.onEmber),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (summary.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: gc.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        PhosphorIconsRegular.scales,
                        size: 18,
                        color: gc.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ExtraStrings.bodyCompEmptyHint,
                        style: AppTheme.f(
                          13,
                          weight: FontWeight.w500,
                          color: gc.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _metricBlock(
                      gc,
                      label: ExtraStrings.weightLabel,
                      value: summary.latestWeightKg != null
                          ? _fmt(fit.toDisplayWeight(summary.latestWeightKg!))
                          : '—',
                      unit: summary.latestWeightKg != null ? fit.units : '',
                      delta: summary.weightDeltaKg != null
                          ? fit.toDisplayWeight(summary.weightDeltaKg!)
                          : null,
                      deltaUnit: fit.units,
                      color: gc.accent,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: gc.border.withValues(alpha: 0.5),
                  ),
                  Expanded(
                    child: _metricBlock(
                      gc,
                      label: ExtraStrings.bodyFatLabel,
                      value: summary.latestBodyFatPct != null
                          ? _fmt(summary.latestBodyFatPct!)
                          : '—',
                      unit: summary.latestBodyFatPct != null ? '%' : '',
                      delta: summary.bodyFatDeltaPct,
                      deltaUnit: '%',
                      color: gc.sage,
                    ),
                  ),
                ],
              ),
              if (summary.leanMassKg != null || summary.bmi != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (summary.leanMassKg != null)
                      _pillStat(
                        gc,
                        ExtraStrings.leanMassLabel,
                        '${_fmt(fit.toDisplayWeight(summary.leanMassKg!))} ${fit.units}',
                      ),
                    if (summary.fatMassKg != null)
                      _pillStat(
                        gc,
                        ExtraStrings.fatMassLabel,
                        '${_fmt(fit.toDisplayWeight(summary.fatMassKg!))} ${fit.units}',
                      ),
                    if (summary.bmi != null)
                      _pillStat(gc, ExtraStrings.bmiLabel, _fmt(summary.bmi!)),
                  ],
                ),
              ],
              if (wSeries.length >= 2 || bfSeries.length >= 2) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: CustomPaint(
                    size: const Size(double.infinity, 36),
                    painter: _MiniDualSparkPainter(
                      primary: [for (final p in wSeries) p.value],
                      secondary: [for (final p in bfSeries) p.value],
                      primaryColor: gc.accent,
                      secondaryColor: gc.sage,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricBlock(
    GymColors gc, {
    required String label,
    required String value,
    required String unit,
    required double? delta,
    required String deltaUnit,
    required Color color,
  }) {
    final d = delta;
    final dText = d == null
        ? null
        : '${d > 0 ? '+' : ''}${_fmt(d)} $deltaUnit'.trim();
    final dColor = d == null || d == 0
        ? gc.textTertiary
        : (d < 0 ? gc.sage : gc.accent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.textSecondary),
            ),
            const Spacer(),
            if (dText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: dColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  dText,
                  style: AppTheme.d(10, weight: FontWeight.w700, color: dColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Ltr(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.d(26, weight: FontWeight.w800, color: gc.text, height: 1.05),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTheme.f(12.5, weight: FontWeight.w600, color: gc.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _pillStat(GymColors gc, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$label · $value',
        style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.textSecondary),
      ),
    );
  }
}

class _MiniDualSparkPainter extends CustomPainter {
  _MiniDualSparkPainter({
    required this.primary,
    required this.secondary,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<double> primary;
  final List<double> secondary;
  final Color primaryColor;
  final Color secondaryColor;

  void _paintLine(Canvas canvas, Size size, List<double> pts, Color color, {bool fill = false}) {
    if (pts.length < 2) return;
    final tail = pts.length > 20 ? pts.sublist(pts.length - 20) : pts;
    var lo = tail.reduce(math.min);
    var hi = tail.reduce(math.max);
    if ((hi - lo).abs() < 0.05) {
      lo -= 1;
      hi += 1;
    }
    final padY = 4.0;
    final h = math.max(1.0, size.height - padY * 2);
    final offsets = [
      for (var i = 0; i < tail.length; i++)
        Offset(
          size.width * i / (tail.length - 1),
          padY + h - ((tail[i] - lo) / (hi - lo)) * h,
        ),
    ];
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final midX = (offsets[i].dx + offsets[i + 1].dx) / 2;
      path.cubicTo(midX, offsets[i].dy, midX, offsets[i + 1].dy, offsets[i + 1].dx, offsets[i + 1].dy);
    }
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(offsets.last.dx, size.height)
        ..lineTo(offsets.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(offsets.last, 3.0, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintLine(canvas, size, secondary, secondaryColor.withValues(alpha: 0.8));
    _paintLine(canvas, size, primary, primaryColor, fill: true);
  }

  @override
  bool shouldRepaint(_MiniDualSparkPainter o) =>
      o.primary != primary || o.secondary != secondary;
}

void showQuickBodyCompSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QuickBodyCompSheet(),
  );
}

class _QuickBodyCompSheet extends StatefulWidget {
  const _QuickBodyCompSheet();

  @override
  State<_QuickBodyCompSheet> createState() => _QuickBodyCompSheetState();
}

class _QuickBodyCompSheetState extends State<_QuickBodyCompSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final latestW = fit.latestBodyweight?.kg ?? fit.profile.weightKg;
    final shownW = latestW > 0 ? fit.toDisplayWeight(latestW) : null;
    final latestBf = fit.latestMeasure('bodyfat')?.value;
    _weight = TextEditingController(
      text: shownW != null ? shownW.toStringAsFixed(1) : '',
    );
    _bodyFat = TextEditingController(
      text: latestBf != null ? latestBf.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _note.dispose();
    super.dispose();
  }

  double? _parseNum(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  void _nudge(
    TextEditingController ctrl,
    double delta, {
    required double min,
    required double max,
    required double fallback,
  }) {
    HapticFeedback.selectionClick();
    final cur = _parseNum(ctrl.text) ?? fallback;
    final next = (cur + delta).clamp(min, max);
    ctrl.text = next.toStringAsFixed(1);
    setState(() {});
  }

  void _save() {
    final w = _parseNum(_weight.text);
    final bf = _parseNum(_bodyFat.text);
    final validW = w != null && w > 0;
    final validBf = bf != null && bf > 0 && bf < 80;
    if (!validW && !validBf) {
      showNotchToast(
        context,
        ExtraStrings.enterAtLeastOne,
        icon: PhosphorIconsFill.warningCircle,
        accent: context.gc.warn,
      );
      return;
    }
    fit.addBodyComposition(
      displayWeight: validW ? w : null,
      bodyFatPct: validBf ? bf : null,
      note: _note.text,
    );
    Navigator.of(context).pop();
    showNotchToast(
      context,
      ExtraStrings.savedBodyComp,
      icon: PhosphorIconsFill.checkCircle,
      accent: context.gc.sage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final wShown = _parseNum(_weight.text);
    final bfShown = _parseNum(_bodyFat.text);
    final wKg = wShown != null && wShown > 0 ? fit.fromDisplayWeight(wShown) : null;
    final lbmKg = BodyCompMath.leanMass(wKg, bfShown);
    final fmKg = BodyCompMath.fatMass(wKg, bfShown);
    final bmi = BodyCompMath.computeBmi(wKg, fit.profile.heightCm);

    return AppSheet(
      children: [
        SheetTitle(
          ExtraStrings.quickLogTitle,
          subtitle: ExtraStrings.quickLogSubtitle,
        ),
        const SizedBox(height: 18),
        _metricInputCard(
          gc,
          title: ExtraStrings.weightLabel,
          unit: fit.units,
          hint: ExtraStrings.weightInputHint,
          controller: _weight,
          accent: gc.accent,
          steps: const [-0.5, -0.1, 0.1, 0.5],
          onStep: (d) => _nudge(
            _weight,
            d,
            min: fit.isLb ? 50 : 25,
            max: fit.isLb ? 660 : 300,
            fallback: fit.isLb ? 150 : 70,
          ),
        ),
        const SizedBox(height: 12),
        _metricInputCard(
          gc,
          title: ExtraStrings.bodyFatLabel,
          unit: '%',
          hint: ExtraStrings.bodyFatInputHint,
          controller: _bodyFat,
          accent: gc.sage,
          steps: const [-0.5, -0.1, 0.1, 0.5],
          onStep: (d) => _nudge(
            _bodyFat,
            d,
            min: 3,
            max: 65,
            fallback: 18,
          ),
        ),
        if (lbmKg != null || bmi != null) ...[
          const SizedBox(height: 12),
          SoftCard(
            radius: 18,
            color: gc.bgRaised2,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ExtraStrings.livePreviewTitle.toUpperCase(),
                  style: kickerStyle(gc),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (lbmKg != null)
                      Expanded(
                        child: _previewStat(
                          gc,
                          ExtraStrings.leanMassLabel,
                          '${decimalText(fit.toDisplayWeight(lbmKg).toStringAsFixed(1))} ${fit.units}',
                        ),
                      ),
                    if (fmKg != null)
                      Expanded(
                        child: _previewStat(
                          gc,
                          ExtraStrings.fatMassLabel,
                          '${decimalText(fit.toDisplayWeight(fmKg).toStringAsFixed(1))} ${fit.units}',
                        ),
                      ),
                    if (bmi != null)
                      Expanded(
                        child: _previewStat(
                          gc,
                          ExtraStrings.bmiLabel,
                          decimalText(bmi.toStringAsFixed(1)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: gc.bgRaised2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.notePencil, size: 16, color: gc.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _note,
                  maxLines: 2,
                  minLines: 1,
                  maxLength: 200,
                  cursorColor: gc.accent,
                  style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: ExtraStrings.noteInputHint,
                    hintStyle: AppTheme.f(13, weight: FontWeight.w500, color: gc.textTertiary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: ExtraStrings.saveRecord,
          onTap: _save,
        ),
      ],
    );
  }

  Widget _metricInputCard(
    GymColors gc, {
    required String title,
    required String unit,
    required String hint,
    required TextEditingController controller,
    required Color accent,
    required List<double> steps,
    required ValueChanged<double> onStep,
  }) {
    return SoftCard(
      radius: 20,
      color: gc.bgRaised2,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.f(13, weight: FontWeight.w700, color: gc.textSecondary),
              ),
              const Spacer(),
              Text(
                unit,
                style: AppTheme.f(12.5, weight: FontWeight.w700, color: gc.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            cursorColor: accent,
            onChanged: (_) => setState(() {}),
            style: AppTheme.d(30, weight: FontWeight.w800, color: gc.text, height: 1.1),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: AppTheme.f(18, weight: FontWeight.w500, color: gc.textTertiary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, step) in steps.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Pressable(
                    scale: 0.94,
                    onTap: () => onStep(step),
                    child: Container(
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: gc.bgRaised,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${step > 0 ? '+' : ''}${step.toStringAsFixed(1)}',
                        style: AppTheme.d(12, weight: FontWeight.w700, color: gc.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewStat(GymColors gc, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textTertiary)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.d(14.5, weight: FontWeight.w800, color: gc.text)),
      ],
    );
  }
}
