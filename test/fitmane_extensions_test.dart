import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/catalog/gym_pack.dart';
import 'package:gymmane/catalog/pro_packs.dart';
import 'package:gymmane/l10n/extra_strings.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/models/measure.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/app_updater.dart';
import 'package:gymmane/services/body_comp_math.dart';
import 'package:gymmane/services/chinese_aliases.dart';
import 'package:gymmane/services/exercise_match.dart';
import 'package:gymmane/services/exercise_smart.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/sha256.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/dialogs.dart';
import 'package:gymmane/widgets/exercise_media.dart';
import 'package:gymmane/widgets/weekly_muscle_card.dart';
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

    test('quickLogDefaultSets defaults to 5, clamps 1..12, and persists', () {
      expect(fit.quickLogDefaultSets, 5);
      fit.setQuickLogDefaultSets(0);
      expect(fit.quickLogDefaultSets, 1);
      fit.setQuickLogDefaultSets(99);
      expect(fit.quickLogDefaultSets, 12);
      fit.setQuickLogDefaultSets(3);
      fit.toggleQuickLog();
      expect(fit.showQuickLog, isFalse);

      fit.persistNow();
      fit.loadFromStore();
      expect(fit.quickLogDefaultSets, 3);
      expect(fit.showQuickLog, isFalse);

      fit.resetAllData();
      expect(fit.quickLogDefaultSets, 5);
      expect(fit.showQuickLog, isTrue);
    });

    test('kHomeBlocks puts bodycomp and quicklog before focus', () {
      expect(kHomeBlocks.indexOf('bodycomp'), lessThan(kHomeBlocks.indexOf('focus')));
      expect(kHomeBlocks.indexOf('quicklog'), lessThan(kHomeBlocks.indexOf('focus')));
    });

    test('quickLogAddExercise creates sets, pre-fills history, avoids duplicates, and edits kind/note', () {
      final bench = kExercises.firstWhere((e) => e.id == 'EIeI8Vf');
      final prevDay = DateTime(2026, 11, 10, 12);
      final targetDay = DateTime(2026, 11, 12, 12);

      fit.sessions.add(LoggedSession(prevDay, 1800, [
        LoggedExercise(bench.id, bench.name, bench.primary, [
          LoggedSet(8, 80),
          LoggedSet(6, 85),
        ]),
      ]));

      final res1 = fit.quickLogAddExercise(bench, day: targetDay);
      expect(res1.created, isTrue);
      expect(res1.exercise.sets, hasLength(5));
      expect(res1.exercise.sets[0].weight, 80);
      expect(res1.exercise.sets[0].reps, 8);
      expect(res1.exercise.sets[4].weight, 85);
      expect(res1.exercise.sets[4].reps, 6);
      expect(fit.isLoggedOnDay(bench.id, targetDay), isTrue);
      expect(fit.isLoggedOnDay(bench.id, DateTime(2026, 11, 11)), isFalse);

      final resDup = fit.quickLogAddExercise(bench, day: targetDay);
      expect(resDup.created, isFalse);
      expect(fit.sessionsOn(targetDay).single.exercises, hasLength(1));

      fit.setLoggedKind(res1.exercise, 0, SetKind.warmup);
      fit.setLoggedNote(res1.exercise, 1, '顶峰收缩');
      fit.persistNow();
      fit.loadFromStore();

      final reloaded = fit.sessionsOn(targetDay).single.exercises.single;
      expect(reloaded.sets[0].kind, SetKind.warmup);
      expect(reloaded.sets[1].note, '顶峰收缩');

      final row = kExercises.firstWhere((e) => e.id != bench.id && fit.modeOf(e.id).isEmpty);
      fit.setQuickLogDefaultSets(3);
      final resCustom = fit.quickLogAddExercise(row, day: targetDay);
      expect(resCustom.created, isTrue);
      expect(resCustom.exercise.sets, hasLength(3));
    });

    test('setNutritionBeta exits nutrition route, persists off state, and restores cleanly', () {
      fit.onboarded = true;
      fit.pushRoute('nutrition');
      expect(fit.route, 'nutrition');

      fit.setNutritionBeta(false);
      expect(fit.nutritionBeta, isFalse);
      expect(fit.route, 'home');

      fit.persistNow();
      fit.loadFromStore();
      expect(fit.nutritionBeta, isFalse);

      fit.setNutritionBeta(true);
      expect(fit.nutritionBeta, isTrue);
    });

    test('kGymPackExercises integrates into allExercises cleanly with full Chinese coverage', () {
      expect(kGymPackExercises.length, greaterThanOrEqualTo(75));
      final baseIds = {for (final e in kExercises) e.id};
      final baseNames = {for (final e in kExercises) e.name.trim().toLowerCase()};
      final validMuscles = {for (final m in kMuscles) m.id};

      for (final ex in kGymPackExercises) {
        expect(baseIds.contains(ex.id), isFalse, reason: 'duplicate id ${ex.id}');
        expect(baseNames.contains(ex.name.trim().toLowerCase()), isFalse, reason: 'duplicate name ${ex.name}');
        expect(validMuscles.contains(ex.primary), isTrue, reason: 'primary ${ex.primary}');
        expect(kEquipment.contains(ex.equipment), isTrue, reason: 'equip ${ex.equipment}');
        expect(kGymPackNameZh[ex.id], isNotNull, reason: 'missing zh name ${ex.id}');
        expect(kGymPackStepsZh[ex.id]?.length, 3, reason: 'missing zh steps ${ex.id}');
      }

      expect(fit.allExercises.length, greaterThanOrEqualTo(kExercises.length + kGymPackExercises.length));
      setAppLanguage('zh');
      expect(t.catalogName('gp-hammer-incline-press', 'fallback'), '悍马机上斜推胸');
      setAppLanguage('en');
      expect(t.catalogName('gp-hammer-incline-press', 'Hammer Strength Incline Chest Press'),
          'Hammer Strength Incline Chest Press');
    });

    test('upgraded Chinese fuzzy and pinyin search finds segmented and slang queries', () {
      setAppLanguage('zh');
      expect(fit.allExercises.where(exerciseSearch('坐姿划船')).length, greaterThanOrEqualTo(3));
      expect(fit.allExercises.where(exerciseSearch('单臂划船')).length, greaterThanOrEqualTo(3));
      expect(fit.allExercises.where(exerciseSearch('悍马推胸')).length, greaterThanOrEqualTo(3));
      expect(fit.allExercises.where(exerciseSearch('倒蹬')).any((e) => e.id == 'gp-leg-press-45'), isTrue);
      expect(fit.allExercises.where(exerciseSearch('wt')).length, greaterThanOrEqualTo(5));
      expect(fit.allExercises.where(exerciseSearch('hmj')).length, greaterThanOrEqualTo(5));
      setAppLanguage('en');
      // Pinyin shortcut must stay inactive outside zh locale.
      expect(fit.allExercises.where(exerciseSearch('wt')).any((e) => e.id == 'EIeI8Vf'), isFalse);
    });

    test('inferExerciseMeta and bulk import identify muscles/gear and persist', () {
      final mChest = inferExerciseMeta('悍马机上斜推胸');
      expect(mChest.primary, 'chest');
      expect(mChest.equipment, 'Machine');
      expect(mChest.mode, isEmpty);

      final mRear = inferExerciseMeta('蝴蝶机反向飞鸟');
      expect(mRear.primary, 'shoulders');
      expect(mRear.equipment, 'Machine');

      final mLat = inferExerciseMeta('单臂绳索侧平举');
      expect(mLat.primary, 'shoulders');
      expect(mLat.equipment, 'Cable');

      final mLeg = inferExerciseMeta('45度倒蹬机');
      expect(mLeg.primary, 'quads');
      expect(mLeg.equipment, 'Machine');

      final mCore = inferExerciseMeta('下斜板卷腹');
      expect(mCore.primary, 'abdomen');

      final mCardio = inferExerciseMeta('动感单车间歇');
      expect(mCardio.mode, 'cardio');

      final parsed = parseBulkExerciseLines('''
        1. 定制龙门架单臂侧平举
        - 定制上斜哑铃挤压推胸
        • 定制龙门架单臂侧平举
      ''');
      expect(parsed, hasLength(2));

      final created = fit.addCustomExercisesBulk([
        for (final p in parsed)
          (
            name: p.name,
            primary: p.meta.primary,
            secondary: p.meta.secondary,
            equipment: p.meta.equipment,
            mode: p.meta.mode,
            art: p.meta.art,
          ),
      ]);
      expect(created, hasLength(2));

      // Re-importing same names skips duplicates
      final dup = fit.addCustomExercisesBulk([
        for (final p in parsed)
          (
            name: p.name,
            primary: p.meta.primary,
            secondary: p.meta.secondary,
            equipment: p.meta.equipment,
            mode: p.meta.mode,
            art: p.meta.art,
          ),
      ]);
      expect(dup, isEmpty);

      fit.persistNow();
      fit.loadFromStore();
      expect(fit.customExercises.map((e) => e.name), containsAll(['定制龙门架单臂侧平举', '定制上斜哑铃挤压推胸']));
    });

    test('pro_packs expands catalog to 654, toggles cleanly, and preserves history lookup', () {
      expect(kExercisePacks, hasLength(6));
      expect(kAllExpansionExercises, hasLength(185));

      final baseIds = kExercises.map((e) => e.id).toSet();
      final baseNames = kExercises.map((e) => e.name.toLowerCase()).toSet();
      expect(
        kAllExpansionExercises.where((e) => baseIds.contains(e.id)),
        isEmpty,
      );
      expect(
        kAllExpansionExercises.where((e) => baseNames.contains(e.name.toLowerCase())),
        isEmpty,
      );

      expect(fit.enabledPackCount, 6);
      expect(fit.enabledPackExerciseCount, 185);
      expect(fit.allExercises, hasLength(kExercises.length + 185));

      fit.toggleExercisePack('weak-points');
      expect(fit.isPackEnabled('weak-points'), isFalse);
      expect(fit.enabledPackCount, 5);
      expect(fit.enabledPackExerciseCount, 185 - kWeakPointsPackExercises.length);
      expect(
        fit.allExercises,
        hasLength(kExercises.length + 185 - kWeakPointsPackExercises.length),
      );
      expect(fit.exerciseById('pp-back-ext-weighted'), isNotNull);

      fit.persistNow();
      fit.loadFromStore();
      expect(fit.isPackEnabled('weak-points'), isFalse);
      expect(fit.exerciseById('pp-back-ext-weighted')?.primary, 'lowerback');

      fit.toggleExercisePack('weak-points');
      expect(fit.isPackEnabled('weak-points'), isTrue);
      expect(fit.allExercises, hasLength(kExercises.length + 185));
    });

    test('matchesChineseExerciseQuery finds pro_packs by Chinese term and Pinyin initials', () {
      setAppLanguage('zh');
      addTearDown(() => setAppLanguage('en'));

      final skiErg =
          kAllExpansionExercises.firstWhere((e) => e.id == 'pp-skierg-sprint');
      expect(matchesChineseExerciseQuery('滑雪机', skiErg), isTrue);
      expect(matchesChineseExerciseQuery('hxj', skiErg), isTrue);

      final filterSki = exerciseSearch('滑雪机');
      expect(kAllExpansionExercises.where(filterSki).contains(skiErg), isTrue);

      final filterPinBayesian = exerciseSearch('bys');
      expect(
        kAllExpansionExercises.where(filterPinBayesian).any((e) => e.id == 'pp-cable-bayesian-curl'),
        isTrue,
      );
    });

    test('AppUpdater auto-prompt defers on later, skips current tag, and wakes on newer tag', () async {
      SharedPreferences.setMockInitialValues({});
      final upd = AppUpdater.instance;
      upd.resetPromptStateForTest();
      addTearDown(() {
        upd.latest = null;
        upd.resetPromptStateForTest();
      });

      const rel9 = ReleaseInfo(
        tagName: 'v9.9.9',
        name: 'v9.9.9',
        body: 'test notes',
        htmlUrl: 'https://example.com',
        publishedAt: null,
        assets: [],
      );
      upd.latest = rel9;
      expect(upd.shouldAutoPrompt, isTrue);

      upd.markPromptedThisLaunch();
      expect(upd.shouldAutoPrompt, isFalse);

      upd.resetPromptStateForTest();
      expect(upd.shouldAutoPrompt, isTrue);

      await upd.skipCurrentUpdate();
      expect(upd.dismissedTag, 'v9.9.9');
      expect(upd.hasUpdateBanner, isFalse);
      expect(upd.shouldAutoPrompt, isFalse);

      upd.latest = const ReleaseInfo(
        tagName: 'v9.9.10',
        name: 'v9.9.10',
        body: 'newer',
        htmlUrl: 'https://example.com',
        publishedAt: null,
        assets: [],
      );
      expect(upd.hasUpdateBanner, isTrue);
      upd.autoCheck = false;
      expect(upd.shouldAutoPrompt, isFalse);
    });

    testWidgets('ExerciseMedia shows reference art badge only for expansion packs', (tester) async {
      setAppLanguage('zh');
      addTearDown(() => setAppLanguage('en'));

      final baseEx = kExercises.firstWhere((e) => e.id == 'EIeI8Vf');
      final gymEx = kGymPackExercises.first;
      final proEx = kWeakPointsPackExercises.first;

      expect(isExpansionArtExercise(baseEx.id), isFalse);
      expect(isExpansionArtExercise(gymEx.id), isTrue);
      expect(isExpansionArtExercise(proEx.id), isTrue);
      expect(isExpansionArtExercise('c999'), isFalse);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ExerciseMedia(ex: baseEx, height: 220),
                ExerciseMedia(ex: proEx, height: 220),
                ExerciseMedia(ex: gymEx, height: 52),
                ExerciseMedia(ex: proEx, height: 32),
              ],
            ),
          ),
        ),
      ));

      expect(find.text(ExtraStrings.referenceArtLabel), findsOneWidget);
      expect(find.text(ExtraStrings.referenceArtShort), findsOneWidget);
    });

    test('sha256Hex and SHA256SUMS parser match standard vectors', () {
      expect(
        sha256Hex(const []),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      final sink = Sha256Sink()
        ..add(utf8.encode('abcdbcdecdefdefgefghfghighij'))
        ..add(utf8.encode('hijkijkljklmklmnlmnomnopnopq'));
      expect(
        sink.digestHex(),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );

      const sums = '''
ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad  FitMane-arm64-v8a.apk
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 *FitMane-x86_64.apk
''';
      expect(
        AppUpdater.parseSha256ForFile(sums, 'FitMane-arm64-v8a.apk'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        AppUpdater.parseSha256ForFile(sums, 'FitMane-x86_64.apk'),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(AppUpdater.parseSha256ForFile(sums, 'missing.apk'), isNull);
    });

    test('quickLogAddExercise applies autoProgress weight & reps rules and detects PR sets', () {
      final bench = kExercises.firstWhere((e) => e.id == 'EIeI8Vf');
      final day1 = DateTime(2026, 11, 10, 12);
      final day2 = DateTime(2026, 11, 12, 12);
      final day3 = DateTime(2026, 11, 14, 12);

      fit.sessions.add(LoggedSession(day1, 1800, [
        LoggedExercise(bench.id, bench.name, bench.primary, [
          LoggedSet(8, 80),
          LoggedSet(8, 80),
        ]),
      ]));

      // Weight auto-progress: +2.5 kg step
      fit.setAutoProgress('weight');
      final resW = fit.quickLogAddExercise(bench, day: day2, setsCount: 3);
      expect(resW.exercise.sets.first.weight, 82.5);
      expect(resW.exercise.sets.first.reps, 8);
      expect(fit.isQuickLogSetPr(resW.exercise, 0, day2), isTrue);

      // Warmup set never counts as PR
      fit.setLoggedKind(resW.exercise, 0, SetKind.warmup);
      expect(fit.isQuickLogSetPr(resW.exercise, 0, day2), isFalse);

      // Reps auto-progress: +1 rep until 12, then weight up & reset to 8
      fit.setAutoProgress('reps');
      final resR = fit.quickLogAddExercise(bench, day: day3, setsCount: 2);
      expect(resR.exercise.sets.first.weight, 82.5);
      expect(resR.exercise.sets.first.reps, 9);
    });

    test('smartQuickRecommendation favors under-trained recovered split and weeklyMuscleTarget persists', () {
      expect(fit.showMuscleVol, isTrue);
      expect(fit.weeklyMuscleTarget, 10);
      expect(fit.weeklyMuscleTargetMax, 20);
      fit.setWeeklyMuscleTarget(12);
      fit.toggleMuscleVol();
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.weeklyMuscleTarget, 12);
      expect(fit.showMuscleVol, isFalse);

      fit.resetAllData();
      final bench = kExercises.firstWhere((e) => e.id == 'EIeI8Vf');
      final squat = kExercises.firstWhere((e) => e.primary == 'quads' && fit.modeOf(e.id).isEmpty);
      final now = DateTime.now();
      fit.sessions.add(LoggedSession(now.subtract(const Duration(hours: 6)), 1800, [
        LoggedExercise(bench.id, bench.name, bench.primary, List.generate(12, (_) => LoggedSet(8, 80))),
        LoggedExercise(squat.id, squat.name, squat.primary, List.generate(12, (_) => LoggedSet(8, 100))),
      ]));

      final rec = fit.smartQuickRecommendation;
      expect(rec.hasReason, isTrue);
      expect(rec.highlightMuscle, 'back');
      expect(rec.weeklySets, 0);
      expect(rec.recovery, greaterThanOrEqualTo(0.9));
    });

    testWidgets('WeeklyMuscleCard displays target range and expands extra muscles', (tester) async {
      setAppLanguage('zh');
      addTearDown(() => setAppLanguage('en'));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: WeeklyMuscleCard(),
          ),
        ),
      ));

      expect(find.text(ExtraStrings.weeklyMuscleTitle.toUpperCase()), findsOneWidget);
      expect(find.text(ExtraStrings.weeklyMuscleRange(10, 20)), findsOneWidget);
      expect(find.text(ExtraStrings.weeklyMuscleShowMore), findsOneWidget);

      await tester.tap(find.text(ExtraStrings.weeklyMuscleShowMore));
      await tester.pumpAndSettle();
      expect(find.text(ExtraStrings.weeklyMuscleShowLess), findsOneWidget);
    });

    test('barbellTotalFromPerSide calculates bar + per-side plates accurately', () {
      expect(barbellTotalFromPerSide(20, 20), 60);
      expect(barbellTotalFromPerSide(20, 12.5), 45);
      expect(barbellTotalFromPerSide(10, 5), 20);
      expect(barbellTotalFromPerSide(20, -5), 20);
    });

    testWidgets('askNumber shows dumbbell single-hand reminder and askBarbellWeight converts per-side', (tester) async {
      setAppLanguage('zh');
      addTearDown(() => setAppLanguage('en'));

      double? dbResult;
      double? bbResult;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    dbResult = await askNumber(
                      ctx,
                      title: ExtraStrings.dumbbellInputTitle('KG'),
                      subtitle: ExtraStrings.dumbbellInputHint(paired: false),
                      initial: '15',
                      decimal: true,
                    );
                  },
                  child: const Text('DB'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    bbResult = await askBarbellWeight(
                      ctx,
                      unit: 'kg',
                      initialTotal: 60,
                      barWeight: 20,
                    );
                  },
                  child: const Text('BB'),
                ),
              ],
            ),
          ),
        ),
      ));

      await tester.tap(find.text('DB'));
      await tester.pumpAndSettle();
      expect(find.text(ExtraStrings.dumbbellInputHint(paired: false)), findsOneWidget);
      await tester.tap(find.text(t.set));
      await tester.pumpAndSettle();
      expect(dbResult, 15);

      await tester.tap(find.text('BB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ExtraStrings.barbellModePerSide));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '25');
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.set));
      await tester.pumpAndSettle();
      expect(bbResult, 70);
      await tester.pump(const Duration(milliseconds: 700));
    });

    test('effectiveMuscleSets weights compound heavy lifts by lean mass and recalculates history', () {
      expect(fit.useEffectiveVolume, isTrue);
      expect(fit.effectiveLeanMassBaseline.source, 'weight');

      fit.addBodyComposition(displayWeight: 75, bodyFatPct: 16);
      final base = fit.effectiveLeanMassBaseline;
      expect(base.source, 'lbm');
      expect(base.kg, closeTo(63.0, 0.2));

      final squat = kExercises.firstWhere((e) => e.equipment == 'Barbell' && e.primary == 'quads' && e.secondary.length >= 2);
      final dbPress = kExercises.firstWhere((e) => e.equipment == 'Dumbbell' && e.primary == 'shoulders' && e.secondary.isNotEmpty);

      // Historical session 10 days ago + recent session 1 day ago
      final oldDay = DateTime.now().subtract(const Duration(days: 10));
      final recentDay = DateTime.now().subtract(const Duration(days: 1));
      fit.sessions.add(LoggedSession(oldDay, 1800, [
        LoggedExercise(squat.id, squat.name, squat.primary, List.generate(3, (_) => LoggedSet(6, 100))),
      ]));
      fit.sessions.add(LoggedSession(recentDay, 1800, [
        LoggedExercise(squat.id, squat.name, squat.primary, List.generate(3, (_) => LoggedSet(6, 100))),
        LoggedExercise(dbPress.id, dbPress.name, dbPress.primary, List.generate(5, (_) => LoggedSet(10, 12.5))),
      ]));

      final eff7 = fit.effectiveMuscleSetsOver(7);
      final raw7 = fit.muscleSetsOver(7);
      expect(raw7['quads'], 3);
      expect(raw7['shoulders'], 5);
      // 3 heavy barbell squat sets beat 5 moderate dumbbell shoulder press sets in effective stimulus
      expect(eff7['quads']!, greaterThan(eff7['shoulders']!));
      expect(eff7['quads']!, greaterThan(4.5));

      // Historical 30-day window recalculates automatically
      final eff30 = fit.effectiveMuscleSetsOver(30);
      expect(eff30['quads']!, greaterThan(eff7['quads']!));

      // Toggle persists and switches activeMuscleSetsOver
      fit.setUseEffectiveVolume(false);
      expect(fit.activeMuscleSetsOver(7)['quads'], 3);
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.useEffectiveVolume, isFalse);
      fit.setUseEffectiveVolume(true);
      expect(fit.activeMuscleSetsOver(7)['quads']!, greaterThan(4.5));
    });
  });
}
