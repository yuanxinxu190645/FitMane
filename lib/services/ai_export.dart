import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import 'body_comp_math.dart';
import 'local_store.dart';

const String kAiSummaryFileName = 'FitMane-AI-Summary.md';

/// Builds a clean, AI-readable Markdown training & body-composition archive
/// designed for Gemini (`@Google Drive`) and ChatGPT analysis.
String buildAiTrainingReport({DateTime? now}) {
  final ts = now ?? DateTime.now();
  String pad2(int n) => n.toString().padLeft(2, '0');
  final dateIso =
      '${ts.year}-${pad2(ts.month)}-${pad2(ts.day)} ${pad2(ts.hour)}:${pad2(ts.minute)}';
  final sb = StringBuffer();

  sb.writeln('# FitMane 训练与体成分档案（AI 专用）');
  sb.writeln();
  sb.writeln('- **更新时间**: $dateIso');
  sb.writeln('- **单位制**: ${fit.units.toUpperCase()}');
  sb.writeln('- **总训练次数**: ${fit.sessions.length}');
  final modeText = fit.useEffectiveVolume ? '等效有效组（按瘦体重与重量加权）' : '原始组数';
  sb.writeln('- **当前肌群统计口径**: $modeText');
  sb.writeln();

  // 1. Body composition
  sb.writeln('## 1. 身体成分与趋势');
  final summary = BodyCompMath.summarize(
    fit.bodyweight,
    fit.measures,
    heightCm: fit.profile.heightCm,
  );
  final base = fit.effectiveLeanMassBaseline;
  if (summary.latestWeightKg != null) {
    sb.writeln('- **最新体重**: ${fit.weightLabel(summary.latestWeightKg!)}');
  } else if (fit.profile.weightKg > 0) {
    sb.writeln('- **资料体重**: ${fit.weightLabel(fit.profile.weightKg)}');
  }
  if (summary.latestBodyFatPct != null) {
    sb.writeln('- **最新体脂率**: ${summary.latestBodyFatPct!.toStringAsFixed(1)}%');
  }
  if (summary.leanMassKg != null) {
    sb.writeln('- **估算瘦体重 (LBM)**: ${fit.weightLabel(summary.leanMassKg!)}');
  } else {
    sb.writeln('- **强度归一化基准**: ${fit.weightLabel(base.kg)} (${base.source})');
  }
  if (summary.bmi != null) {
    sb.writeln('- **BMI**: ${summary.bmi!.toStringAsFixed(1)}');
  }
  if (fit.profile.heightCm > 0) {
    sb.writeln('- **身高**: ${fit.profile.heightCm.round()} cm');
  }
  sb.writeln();

  // 2. Muscle volume & recovery
  sb.writeln('## 2. 肌群训练量与恢复状态（目标区间 ${fit.weeklyMuscleTarget}–${fit.weeklyMuscleTargetMax}）');
  final eff7 = fit.effectiveMuscleSetsOver(7);
  final raw7 = fit.muscleSetsOver(7);
  final eff30 = fit.effectiveMuscleSetsOver(30);
  final rec = fit.muscleRecovery(now: ts);
  sb.writeln('| 肌群 | 近7天等效组 | 近7天原始组 | 近30天等效组 | 当前恢复度 |');
  sb.writeln('|---|---:|---:|---:|---:|');
  for (final m in kMuscles) {
    final id = m.id;
    final e7 = eff7[id] ?? 0;
    final r7 = raw7[id] ?? 0;
    final e30 = eff30[id] ?? 0;
    final rv = ((rec[id] ?? 1.0) * 100).round();
    if (e7 == 0 && r7 == 0 && e30 == 0 && rv == 100) continue;
    sb.writeln(
      '| ${muscleLabel(id)} ($id) | ${e7.toStringAsFixed(1)} | ${r7.toStringAsFixed(1)} | ${e30.toStringAsFixed(1)} | $rv% |',
    );
  }
  sb.writeln();

  // 3. Personal records
  final prs = fit.personalRecords.take(25).toList();
  sb.writeln('## 3. 个人最佳纪录 (Top PR)');
  if (prs.isEmpty) {
    sb.writeln('暂无纪录。');
  } else {
    sb.writeln('| 动作 | 最佳表现 | 估算 1RM |');
    sb.writeln('|---|---|---|');
    for (final r in prs) {
      final name = t.catalogName(r.id, r.name);
      final best = fit.recordLabel(r);
      final orm = r.kind == PrKind.weight && r.oneRm > 0
          ? fit.weightLabel(r.oneRm)
          : '-';
      sb.writeln('| $name | $best | $orm |');
    }
  }
  sb.writeln();

  // 4. Last 30 days workouts
  sb.writeln('## 4. 近 30 天逐日训练明细');
  final cutoff = DateTime(ts.year, ts.month, ts.day - 29);
  final recent = fit.sessions
      .where((s) => !DateTime(s.day.year, s.day.month, s.day.day).isBefore(cutoff))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  if (recent.isEmpty) {
    sb.writeln('近 30 天暂无训练记录。');
  } else {
    for (final s in recent) {
      final dStr = '${s.day.year}-${pad2(s.day.month)}-${pad2(s.day.day)}';
      final durMin = (s.durationSec / 60).round();
      final durPart = durMin > 0 ? ' · $durMin 分钟' : '';
      sb.writeln('### $dStr$durPart');
      for (final e in s.exercises) {
        final ex = fit.exerciseById(e.id);
        final name = t.catalogName(e.id, e.name);
        final eq = ex?.equipment ?? '';
        final paired = fit.isPaired(e.id);
        final eqTag = eq.isEmpty
            ? ''
            : (eq == 'Dumbbell' ? ' [$eq${paired ? " 单只×2" : " 单只"}]' : ' [$eq]');
        final parts = <String>[];
        for (final st in e.sets) {
          final kindMark = switch (st.kind) {
            SetKind.warmup => '(热身)',
            SetKind.drop => '(递减)',
            SetKind.failure => '(力竭)',
            SetKind.restPause => '(休息暂停)',
            SetKind.normal => '',
          };
          final rpeMark = st.rpe != null ? ' @RPE${st.rpe!.toStringAsFixed(1)}' : '';
          final noteMark = st.note.trim().isNotEmpty ? '「${st.note.trim()}」' : '';
          if (fit.loggedDistance(e)) {
            parts.add('${fit.distanceValueFor(e.id, st.km ?? 0)}${fit.distanceUnitFor(e.id)}$kindMark$noteMark');
          } else if (fit.loggedTimed(e)) {
            parts.add('${st.sec ?? 0}s$kindMark$noteMark');
          } else if (st.weight > 0) {
            final repsText = st.sided ? '${st.left ?? 0}/${st.right ?? 0}' : '${st.reps}';
            parts.add('${fit.weightLabel(st.weight)}×$repsText$kindMark$rpeMark$noteMark');
          } else {
            parts.add('${st.reps}次$kindMark$rpeMark$noteMark');
          }
        }
        sb.writeln('- **$name**$eqTag: ${parts.join(', ')}');
      }
      sb.writeln();
    }
  }

  return sb.toString();
}

class AiExportService extends ChangeNotifier {
  AiExportService._();
  static final AiExportService instance = AiExportService._();

  static const _channel = MethodChannel('gymmane/backup');
  static const _noteKey = 'aiExport';

  bool get supported => !kIsWeb && Platform.isAndroid;

  String fileUri = '';
  String fileName = '';
  bool autoSync = true;
  DateTime? lastExportAt;
  bool exporting = false;
  bool lastFailed = false;
  int _lastDigest = 0;
  Timer? _debounce;

  bool get hasTarget => fileUri.isNotEmpty;

  void init() {
    _load();
    if (!supported) return;
    fit.addListener(_onFitChanged);
  }

  void _load() {
    final raw = Store.instance.note(_noteKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      fileUri = j['uri'] as String? ?? '';
      fileName = j['name'] as String? ?? '';
      autoSync = j['auto'] as bool? ?? true;
      final at = (j['at'] as num?)?.toInt();
      lastExportAt = at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
      _lastDigest = (j['digest'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  void _save() {
    Store.instance.setNote(
      _noteKey,
      jsonEncode({
        'uri': fileUri,
        'name': fileName,
        'auto': autoSync,
        if (lastExportAt != null) 'at': lastExportAt!.millisecondsSinceEpoch,
        'digest': _lastDigest,
      }),
    );
    notifyListeners();
  }

  void setAutoSync(bool on) {
    if (autoSync == on) return;
    autoSync = on;
    _save();
  }

  void _onFitChanged() {
    if (!supported || !hasTarget || !autoSync) return;
    final digest = Object.hash(
      fit.sessions.length,
      fit.sessions.isEmpty ? 0 : fit.sessions.last.exercises.length,
      fit.bodyweight.length,
      fit.useEffectiveVolume,
    );
    if (digest == _lastDigest) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 6), () {
      unawaited(exportOverwrite(silent: true));
    });
  }

  Future<bool> pickAndExport() async {
    if (!supported || exporting) return false;
    try {
      final picked = await _channel.invokeMapMethod<String, dynamic>('pickFile', {
        'name': kAiSummaryFileName,
        'mime': 'text/markdown',
      });
      if (picked == null) return false;
      final uri = picked['uri'] as String? ?? '';
      if (uri.isEmpty) return false;
      fileUri = uri;
      fileName = (picked['name'] as String? ?? '').isNotEmpty
          ? picked['name'] as String
          : kAiSummaryFileName;
      _save();
      return await exportOverwrite();
    } catch (_) {
      return false;
    }
  }

  Future<bool> exportOverwrite({bool silent = false}) async {
    if (!supported || !hasTarget || exporting) return false;
    exporting = true;
    lastFailed = false;
    if (!silent) notifyListeners();
    var ok = false;
    try {
      final report = buildAiTrainingReport();
      ok = await _channel.invokeMethod<bool>('writeFile', {
            'uri': fileUri,
            'content': report,
          }) ??
          false;
      if (ok) {
        lastExportAt = DateTime.now();
        _lastDigest = Object.hash(
          fit.sessions.length,
          fit.sessions.isEmpty ? 0 : fit.sessions.last.exercises.length,
          fit.bodyweight.length,
          fit.useEffectiveVolume,
        );
      } else {
        lastFailed = true;
      }
    } catch (_) {
      lastFailed = true;
      ok = false;
    }
    exporting = false;
    _save();
    return ok;
  }
}
