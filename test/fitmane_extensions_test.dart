import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/measure.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/app_updater.dart';
import 'package:gymmane/services/body_comp_math.dart';
import 'package:gymmane/services/exercise_match.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdater helpers', () {
    test('compareVersions handles prefixes, patch bumps and build suffixes', () {
      expect(AppUpdater.compareVersions('v2.4.1', '2.4.1'), 0);
      expect(AppUpdater.compareVersions('v2.4.2', '2.4.1'), greaterThan(0));
      expect(AppUpdater.compareVersions('v2.5.0', '2.4.9'), greaterThan(0));
      expect(AppUpdater.compareVersions('3.0.0', '2.9.9'), greaterThan(0));
      expect(AppUpdater.compareVersions('v2.4.0', '2.4.1'), lessThan(0));
      expect(AppUpdater.compareVersions('v2.4.1-beta.1', '2.4.1'), lessThan(0));
      expect(AppUpdater.compareVersions('v2.4.1+17', '2.4.1+16'), greaterThan(0));
      expect(AppUpdater.compareVersions('v2.4.1', '2.4.1+16'), 0);
    });

    test('pickApkAsset prefers arm64-v8a then falls back cleanly', () {
      const assets = [
        ReleaseAsset(name: 'FitMane-x86_64.apk', downloadUrl: 'https://example.com/x86.apk', size: 100),
        ReleaseAsset(name: 'FitMane-armeabi-v7a.apk', downloadUrl: 'https://example.com/v7a.apk', size: 100),
        ReleaseAsset(name: 'FitMane-arm64-v8a.apk', downloadUrl: 'https://example.com/arm64.apk', size: 100),
        ReleaseAsset(name: 'checksums.txt', downloadUrl: 'https://example.com/sum.txt', size: 10),
      ];
      expect(
        AppUpdater.pickApkAsset(assets, ['arm64-v8a', 'armeabi-v7a'])?.name,
        'FitMane-arm64-v8a.apk',
      );
      expect(
        AppUpdater.pickApkAsset(assets, ['armeabi-v7a'])?.name,
        'FitMane-armeabi-v7a.apk',
      );
      const universal = [
        ReleaseAsset(name: 'FitMane-release.apk', downloadUrl: 'https://example.com/u.apk', size: 100),
      ];
      expect(
        AppUpdater.pickApkAsset(universal, ['arm64-v8a'])?.name,
        'FitMane-release.apk',
      );
      expect(
        AppUpdater.pickApkAsset(const [ReleaseAsset(name: 'notes.txt', downloadUrl: 'https://x/n', size: 1)], ['arm64-v8a']),
        isNull,
      );
    });

    test('applyProxy and normalizeRepo work for empty, prefix and template proxies', () {
      const url = 'https://github.com/yuanxinxu190645/FitMane/releases/download/v2.4.1/FitMane-arm64-v8a.apk';
      expect(AppUpdater.applyProxy(url, ''), url);
      expect(AppUpdater.applyProxy(url, 'https://ghfast.top'), 'https://ghfast.top/$url');
      expect(AppUpdater.applyProxy(url, 'https://ghfast.top/'), 'https://ghfast.top/$url');
      expect(AppUpdater.applyProxy(url, 'https://mirror.example/?target={url}'), 'https://mirror.example/?target=$url');
      expect(AppUpdater.normalizeRepo('https://github.com/yuanxinxu190645/FitMane.git/'), 'yuanxinxu190645/FitMane');
      expect(AppUpdater.normalizeRepo(''), kDefaultUpdateRepo);
    });
  });

  group('BodyCompMath', () {
    test('calculates lean mass, fat mass, BMI and summary deltas', () {
      expect(BodyCompMath.leanMass(80, 20), 64.0);
      expect(BodyCompMath.fatMass(80, 20), 16.0);
      expect(BodyCompMath.computeBmi(75, 175), 24.5);

      final d1 = DateTime(2026, 11, 10, 8);
      final d2 = DateTime(2026, 11, 15, 8);
      final summary = BodyCompMath.summarize(
        [BodyweightEntry(d1, 76.0), BodyweightEntry(d2, 74.5)],
        [BodyMeasure(d1, 'bodyfat', 18.0), BodyMeasure(d2, 'bodyfat', 17.2)],
        heightCm: 175,
      );
      expect(summary.latestWeightKg, 74.5);
      expect(summary.weightDeltaKg, -1.5);
      expect(summary.latestBodyFatPct, 17.2);
      expect(summary.bodyFatDeltaPct, -0.8);
      expect(summary.leanMassKg, closeTo(61.7, 0.1));
      expect(summary.fatMassKg, closeTo(12.8, 0.1));
      expect(summary.bmi, 24.3);
    });

    test('movingAverage7d uses a 7-day calendar window', () {
      final pts = [
        BodyCompPoint(DateTime(2026, 11, 1), 80),
        BodyCompPoint(DateTime(2026, 11, 4), 78),
        BodyCompPoint(DateTime(2026, 11, 7), 76),
        BodyCompPoint(DateTime(2026, 11, 10), 74), // Nov 1 drops out (> 6 days)
      ];
      final ma = BodyCompMath.movingAverage7d(pts);
      expect(ma, hasLength(4));
      expect(ma[0].value, 80);
      expect(ma[1].value, 79);
      expect(ma[2].value, 78);
      expect(ma[3].value, closeTo((78 + 76 + 74) / 3, 0.02));
    });

    test('periodStats and mergeDailyLogs summarize history cleanly', () {
      final d1 = DateTime(2026, 11, 1);
      final d2 = DateTime(2026, 11, 5);
      final stats = BodyCompMath.periodStats([BodyCompPoint(d1, 75), BodyCompPoint(d2, 73.5)]);
      expect(stats, isNotNull);
      expect(stats!.change, -1.5);
      expect(stats.avg, 74.25);

      final merged = BodyCompMath.mergeDailyLogs(
        [BodyweightEntry(d1, 75), BodyweightEntry(d2, 73.5)],
        [BodyMeasure(d2, 'bodyfat', 16.5)],
      );
      expect(merged, hasLength(2));
      expect(merged.first.day, d2);
      expect(merged.first.weight?.kg, 73.5);
      expect(merged.first.bodyFat?.value, 16.5);
    });
  });

  group('FitState extensions & Chinese search', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.setUnits('kg');
    });

    test('theme defaults to system and showBodyComp persists', () {
      expect(fit.themePref, 'system');
      expect(fit.showBodyComp, isTrue);
      fit.toggleBodyComp();
      expect(fit.showBodyComp, isFalse);
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.showBodyComp, isFalse);
      expect(fit.themePref, 'system');
    });

    test('addBodyComposition records weight and body fat together', () {
      fit.addBodyComposition(displayWeight: 72.4, bodyFatPct: 16.8, note: '晨起');
      expect(fit.latestBodyweight?.kg, closeTo(72.4, 0.001));
      expect(fit.latestBodyweight?.note, '晨起');
      expect(fit.latestMeasure('bodyfat')?.value, closeTo(16.8, 0.001));
    });

    test('Chinese gym slang search finds matching exercises', () {
      setAppLanguage('zh');
      final filterFly = exerciseSearch('夹胸');
      expect(kExercises.where(filterFly), isNotEmpty);

      final filterHip = exerciseSearch('臀推');
      expect(kExercises.where(filterHip), isNotEmpty);

      final filterBench = exerciseSearch('哑铃卧推');
      expect(kExercises.where(filterBench).any((e) => e.id == 'SpYC0Kp'), isTrue);
      setAppLanguage('en');
    });
  });
}
