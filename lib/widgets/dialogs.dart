import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/extra_strings.dart';
import '../l10n/l10n.dart';
import '../models/note.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'ui_kit.dart';

AlertDialog appDialog(
  GymColors gc, {
  required Widget title,
  required Widget content,
  required List<Widget> actions,
}) =>
    AlertDialog(
      backgroundColor: gc.bgRaised,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: title,
      content: content,
      actions: actions,
    );

Widget dialogAction(String label, Color color, VoidCallback onPressed, {bool strong = true}) =>
    TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      child: Text(titleCase(label),
          style: AppTheme.f(14,
              weight: strong ? FontWeight.w700 : FontWeight.w600, color: color)),
    );

Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? cancelLabel,
  bool danger = false,
}) async {
  final gc = context.gc;
  final ok = await showAppDialog<bool>(
    context: context,
    builder: (dctx) => appDialog(
      gc,
      title: Text(title, style: AppTheme.f(19, weight: FontWeight.w800, color: gc.text)),
      content: Text(body,
          style: AppTheme.f(13.5,
              weight: FontWeight.w500, color: gc.textSecondary, height: 1.45)),
      actions: [
        dialogAction(cancelLabel ?? t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(false),
            strong: false),
        dialogAction(confirmLabel, danger ? gc.danger : gc.accent, () => Navigator.of(dctx).pop(true)),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  bool allowEmpty = false,
  int maxLines = 1,
}) async {
  final gc = context.gc;
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  final raw = await showAppDialog<String>(
    context: context,
    builder: (dctx) => appDialog(
      gc,
      title: Text(title, style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        style: AppTheme.s(15, color: gc.text),
        cursorColor: gc.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.s(15, color: gc.textTertiary),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.border)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.accent)),
        ),
        onSubmitted: (v) => Navigator.of(dctx).pop(v),
      ),
      actions: [
        dialogAction(t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(), strong: false),
        dialogAction(t.save, gc.accent, () => Navigator.of(dctx).pop(controller.text)),
      ],
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
  final text = raw?.trim();
  return text == '' && !allowEmpty ? null : text;
}

Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String initial,
  required bool decimal,
  String? subtitle,
}) async {
  final gc = context.gc;
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);

  final raw = await showAppDialog<String>(
    context: context,
    builder: (dctx) => appDialog(
      gc,
      title: Text(titleCase(title), style: AppTheme.f(19, weight: FontWeight.w800, color: gc.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (subtitle != null && subtitle.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: gc.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.f(12, weight: FontWeight.w600, color: gc.accent, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textAlign: TextAlign.center,
            style: AppTheme.f(34, weight: FontWeight.w800, color: gc.text, height: 1.1),
            cursorColor: gc.accent,
            onSubmitted: (v) => Navigator.of(dctx).pop(v),
            decoration: InputDecoration(
              filled: true,
              fillColor: gc.bgRaised2,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        dialogAction(t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(), strong: false),
        dialogAction(t.set, gc.accent, () => Navigator.of(dctx).pop(controller.text)),
      ],
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);

  return double.tryParse((raw ?? '').trim().replaceAll(',', '.'));
}

String _fmtNum(double v) {
  final r = (v * 100).round() / 100;
  if (r == r.roundToDouble()) return '${r.round()}';
  final s = r.toStringAsFixed(2);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

double barbellTotalFromPerSide(double barWeight, double perSideWeight) {
  final side = perSideWeight < 0 ? 0.0 : perSideWeight;
  final total = barWeight + side * 2;
  return (total * 100).round() / 100;
}

Future<double?> askBarbellWeight(
  BuildContext context, {
  required String unit,
  required double initialTotal,
  required double barWeight,
}) async {
  final gc = context.gc;
  var perSideMode = false;
  final initText = _fmtNum(initialTotal);
  final controller = TextEditingController(text: initText)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initText.length);

  double? parseInput() => double.tryParse(controller.text.trim().replaceAll(',', '.'));

  double? resolveResult() {
    final v = parseInput();
    if (v == null) return null;
    return perSideMode ? barbellTotalFromPerSide(barWeight, v) : v;
  }

  final result = await showAppDialog<double>(
    context: context,
    builder: (dctx) => StatefulBuilder(
      builder: (dctx, setState) {
        final v = parseInput();
        final barText = '${_fmtNum(barWeight)} $unit';
        final previewTotal = v != null ? barbellTotalFromPerSide(barWeight, v) : barWeight;
        return appDialog(
          gc,
          title: Text(
            ExtraStrings.barbellInputTitle(unit.toUpperCase()),
            style: AppTheme.f(19, weight: FontWeight.w800, color: gc.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      scale: 0.96,
                      onTap: () {
                        if (!perSideMode) return;
                        final cur = parseInput();
                        final total = cur != null ? barbellTotalFromPerSide(barWeight, cur) : initialTotal;
                        final txt = _fmtNum(total);
                        controller.value = TextEditingValue(
                          text: txt,
                          selection: TextSelection(baseOffset: 0, extentOffset: txt.length),
                        );
                        setState(() => perSideMode = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !perSideMode ? gc.ember : gc.bgRaised2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ExtraStrings.barbellModeTotal,
                          style: AppTheme.f(
                            12.5,
                            weight: FontWeight.w700,
                            color: !perSideMode ? gc.onEmber : gc.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Pressable(
                      scale: 0.96,
                      onTap: () {
                        if (perSideMode) return;
                        final cur = parseInput() ?? initialTotal;
                        final side = ((cur - barWeight) / 2).clamp(0.0, 500.0);
                        final txt = _fmtNum(side);
                        controller.value = TextEditingValue(
                          text: txt,
                          selection: TextSelection(baseOffset: 0, extentOffset: txt.length),
                        );
                        setState(() => perSideMode = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: perSideMode ? gc.ember : gc.bgRaised2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ExtraStrings.barbellModePerSide,
                          style: AppTheme.f(
                            12.5,
                            weight: FontWeight.w700,
                            color: perSideMode ? gc.onEmber : gc.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                perSideMode
                    ? ExtraStrings.barbellPerSidePreview(
                        '${_fmtNum(previewTotal)} $unit',
                        barText,
                        '${_fmtNum(v ?? 0)} $unit',
                      )
                    : ExtraStrings.barbellInputHint(barText),
                textAlign: TextAlign.center,
                style: AppTheme.f(
                  11.5,
                  weight: FontWeight.w600,
                  color: perSideMode ? gc.accent : gc.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: AppTheme.f(34, weight: FontWeight.w800, color: gc.text, height: 1.1),
                cursorColor: gc.accent,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => Navigator.of(dctx).pop(resolveResult()),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: gc.bgRaised2,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            dialogAction(t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(), strong: false),
            dialogAction(t.set, gc.accent, () => Navigator.of(dctx).pop(resolveResult())),
          ],
        );
      },
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
  return result;
}

Future<NoteLink?> askLink(BuildContext context, {NoteLink? initial}) async {
  final gc = context.gc;
  final name = TextEditingController(text: initial?.name ?? '');
  final url = TextEditingController(text: initial?.url ?? '');
  bool bad = false;
  InputDecoration deco(String hint, {String? error}) => InputDecoration(
        hintText: hint,
        errorText: error,
        hintStyle: AppTheme.s(15, color: gc.textTertiary),
        errorStyle: AppTheme.s(12, color: gc.danger),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.border)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.accent)),
        errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.danger)),
        focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.danger)),
      );
  final result = await showAppDialog<NoteLink>(
    context: context,
    builder: (dctx) => StatefulBuilder(
      builder: (dctx, setState) {
        void submit() {
          final uri = NoteLink.parse(url.text);
          if (uri == null) {
            setState(() => bad = true);
            return;
          }
          final label = name.text.trim();
          Navigator.of(dctx).pop(NoteLink(
            name: label.isEmpty ? uri.host.replaceFirst('www.', '') : label,
            url: uri.toString(),
          ));
        }

        return appDialog(
          gc,
          title: Text(initial == null ? t.noteLinkAdd : t.noteLinkEdit,
              style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                style: AppTheme.s(15, color: gc.text),
                cursorColor: gc.accent,
                decoration: deco(t.noteLinkNameHint).copyWith(counterText: ''),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: AppTheme.s(15, color: gc.text),
                cursorColor: gc.accent,
                decoration: deco(t.noteLinkUrlHint, error: bad ? t.noteLinkInvalid : null),
                onChanged: (_) {
                  if (bad) setState(() => bad = false);
                },
                onSubmitted: (_) => submit(),
              ),
            ],
          ),
          actions: [
            dialogAction(t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(), strong: false),
            dialogAction(t.save, gc.accent, submit),
          ],
        );
      },
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 600), () {
    name.dispose();
    url.dispose();
  });
  return result;
}

Future<void> openNoteLink(BuildContext context, NoteLink link) async {
  final uri = NoteLink.parse(link.url);
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context.mounted) {
    showNotchToast(context, t.cantOpenLink, icon: PhosphorIconsFill.warningCircle, accent: context.gc.danger);
  }
}
