import '../models/measure.dart';
import '../models/workout.dart';

class BodyCompPoint {
  const BodyCompPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

class BodyCompSummary {
  const BodyCompSummary({
    this.latestWeightKg,
    this.weightDeltaKg,
    this.latestBodyFatPct,
    this.bodyFatDeltaPct,
    this.leanMassKg,
    this.fatMassKg,
    this.bmi,
    this.latestDate,
  });

  final double? latestWeightKg;
  final double? weightDeltaKg;
  final double? latestBodyFatPct;
  final double? bodyFatDeltaPct;
  final double? leanMassKg;
  final double? fatMassKg;
  final double? bmi;
  final DateTime? latestDate;

  bool get isEmpty => latestWeightKg == null && latestBodyFatPct == null;
}

class PeriodStats {
  const PeriodStats({
    required this.start,
    required this.latest,
    required this.change,
    required this.min,
    required this.max,
    required this.avg,
  });

  final double start;
  final double latest;
  final double change;
  final double min;
  final double max;
  final double avg;
}

class MergedBodyCompDay {
  const MergedBodyCompDay({
    required this.day,
    this.weight,
    this.bodyFat,
  });

  final DateTime day;
  final BodyweightEntry? weight;
  final BodyMeasure? bodyFat;
}

class BodyCompMath {
  BodyCompMath._();

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  static double _round1(double v) => (v * 10).round() / 10;

  static double _round2(double v) => (v * 100).round() / 100;

  static double? leanMass(double? weightKg, double? bodyFatPct) {
    if (weightKg == null || bodyFatPct == null) return null;
    if (weightKg <= 0 || bodyFatPct <= 0 || bodyFatPct >= 80) return null;
    return _round1(weightKg * (1 - bodyFatPct / 100));
  }

  static double? fatMass(double? weightKg, double? bodyFatPct) {
    if (weightKg == null || bodyFatPct == null) return null;
    if (weightKg <= 0 || bodyFatPct <= 0 || bodyFatPct >= 80) return null;
    return _round1(weightKg * (bodyFatPct / 100));
  }

  static double? computeBmi(double? weightKg, double heightCm) {
    if (weightKg == null || weightKg <= 0 || heightCm <= 0) return null;
    final m = heightCm / 100;
    return _round1(weightKg / (m * m));
  }

  static BodyCompSummary summarize(
    List<BodyweightEntry> weights,
    List<BodyMeasure> measures, {
    double heightCm = 0,
  }) {
    final wSorted = [...weights]..sort((a, b) => a.date.compareTo(b.date));
    final bfSorted = measures
        .where((m) => m.key == 'bodyfat' && m.value > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final latestW = wSorted.isEmpty ? null : wSorted.last;
    final prevW = wSorted.length < 2 ? null : wSorted[wSorted.length - 2];
    final latestBf = bfSorted.isEmpty ? null : bfSorted.last;
    final prevBf = bfSorted.length < 2 ? null : bfSorted[bfSorted.length - 2];

    final wKg = latestW?.kg;
    final bfPct = latestBf?.value;
    DateTime? latestDate;
    if (latestW != null && latestBf != null) {
      latestDate = latestW.date.isAfter(latestBf.date) ? latestW.date : latestBf.date;
    } else {
      latestDate = latestW?.date ?? latestBf?.date;
    }

    return BodyCompSummary(
      latestWeightKg: wKg,
      weightDeltaKg: wKg != null && prevW != null ? _round2(wKg - prevW.kg) : null,
      latestBodyFatPct: bfPct,
      bodyFatDeltaPct: bfPct != null && prevBf != null ? _round1(bfPct - prevBf.value) : null,
      leanMassKg: leanMass(wKg, bfPct),
      fatMassKg: fatMass(wKg, bfPct),
      bmi: computeBmi(wKg, heightCm),
      latestDate: latestDate,
    );
  }

  static List<BodyCompPoint> dailyWeightSeries(
    List<BodyweightEntry> weights, {
    double Function(double kg)? convert,
  }) {
    final byDay = <DateTime, BodyweightEntry>{};
    final sorted = [...weights]..sort((a, b) => a.date.compareTo(b.date));
    for (final w in sorted) {
      if (w.kg <= 0) continue;
      byDay[_dayKey(w.date)] = w;
    }
    return [
      for (final entry in byDay.entries)
        BodyCompPoint(
          entry.key,
          convert != null ? convert(entry.value.kg) : entry.value.kg,
        ),
    ];
  }

  static List<BodyCompPoint> dailyBodyFatSeries(List<BodyMeasure> measures) {
    final byDay = <DateTime, BodyMeasure>{};
    final sorted = measures
        .where((m) => m.key == 'bodyfat' && m.value > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final m in sorted) {
      byDay[_dayKey(m.date)] = m;
    }
    return [
      for (final entry in byDay.entries)
        BodyCompPoint(entry.key, entry.value.value),
    ];
  }

  static List<BodyCompPoint> dailyLeanMassSeries(
    List<BodyweightEntry> weights,
    List<BodyMeasure> measures, {
    double Function(double kg)? convert,
  }) {
    final wPoints = dailyWeightSeries(weights);
    final bfPoints = dailyBodyFatSeries(measures);
    if (wPoints.isEmpty || bfPoints.isEmpty) return const [];

    final bfByDay = {for (final p in bfPoints) p.date: p.value};
    final out = <BodyCompPoint>[];
    for (final wp in wPoints) {
      var bf = bfByDay[wp.date];
      if (bf == null) {
        // Use nearest body fat entry within 14 days before or on this weight date
        BodyCompPoint? best;
        for (final bp in bfPoints) {
          final diff = wp.date.difference(bp.date).inDays;
          if (diff >= 0 && diff <= 14) {
            best = bp;
          }
        }
        bf = best?.value;
      }
      final lbmKg = leanMass(wp.value, bf);
      if (lbmKg != null) {
        out.add(BodyCompPoint(wp.date, convert != null ? convert(lbmKg) : lbmKg));
      }
    }
    return out;
  }

  /// Computes a 7-day time-windowed moving average over chronologically sorted [points].
  static List<BodyCompPoint> movingAverage7d(List<BodyCompPoint> points) {
    if (points.isEmpty) return const [];
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final out = <BodyCompPoint>[];
    var left = 0;
    var sum = 0.0;
    for (var right = 0; right < sorted.length; right++) {
      final cur = sorted[right];
      sum += cur.value;
      while (left < right &&
          _dayKey(cur.date).difference(_dayKey(sorted[left].date)).inDays > 6) {
        sum -= sorted[left].value;
        left++;
      }
      final count = right - left + 1;
      out.add(BodyCompPoint(cur.date, _round2(sum / count)));
    }
    return out;
  }

  static List<BodyCompPoint> filterRange(
    List<BodyCompPoint> points,
    int? days, {
    DateTime? now,
  }) {
    if (days == null || points.isEmpty) return points;
    final ref = _dayKey(now ?? DateTime.now());
    final cutoff = ref.subtract(Duration(days: days - 1));
    return points.where((p) => !_dayKey(p.date).isBefore(cutoff)).toList();
  }

  static PeriodStats? periodStats(List<BodyCompPoint> points) {
    if (points.isEmpty) return null;
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    var minV = sorted.first.value;
    var maxV = sorted.first.value;
    var sum = 0.0;
    for (final p in sorted) {
      if (p.value < minV) minV = p.value;
      if (p.value > maxV) maxV = p.value;
      sum += p.value;
    }
    final start = sorted.first.value;
    final latest = sorted.last.value;
    return PeriodStats(
      start: _round2(start),
      latest: _round2(latest),
      change: _round2(latest - start),
      min: _round2(minV),
      max: _round2(maxV),
      avg: _round2(sum / sorted.length),
    );
  }

  static List<MergedBodyCompDay> mergeDailyLogs(
    List<BodyweightEntry> weights,
    List<BodyMeasure> measures,
  ) {
    final wSorted = [...weights]..sort((a, b) => a.date.compareTo(b.date));
    final bfSorted = measures
        .where((m) => m.key == 'bodyfat' && m.value > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final map = <DateTime, ({BodyweightEntry? w, BodyMeasure? bf})>{};
    for (final w in wSorted) {
      final key = _dayKey(w.date);
      final prev = map[key];
      map[key] = (w: w, bf: prev?.bf);
    }
    for (final bf in bfSorted) {
      final key = _dayKey(bf.date);
      final prev = map[key];
      map[key] = (w: prev?.w, bf: bf);
    }

    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final d in days)
        MergedBodyCompDay(day: d, weight: map[d]!.w, bodyFat: map[d]!.bf),
    ];
  }
}
