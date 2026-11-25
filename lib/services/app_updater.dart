import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/extra_strings.dart';
import '../state/fit_state.dart';
import 'auto_backup.dart';
import 'backup_zip.dart';
import 'sha256.dart';

const String kDefaultUpdateRepo = 'yuanxinxu190645/FitMane';
const String kCurrentAppVersion = '2.4.10';
const int kCurrentAppBuild = 25;

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  final String name;
  final String downloadUrl;
  final int size;

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
        name: (json['name'] as String?) ?? '',
        downloadUrl: (json['browser_download_url'] as String?) ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

class ReleaseInfo {
  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.publishedAt,
    required this.assets,
  });

  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final DateTime? publishedAt;
  final List<ReleaseAsset> assets;

  String get displayVersion =>
      tagName.trim().replaceFirst(RegExp(r'^[vV]'), '');

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final rawAssets = (json['assets'] as List?) ?? const [];
    return ReleaseInfo(
      tagName: (json['tag_name'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      htmlUrl: (json['html_url'] as String?) ?? '',
      publishedAt: DateTime.tryParse((json['published_at'] as String?) ?? ''),
      assets: [
        for (final a in rawAssets)
          if (a is Map) ReleaseAsset.fromJson(a.cast<String, dynamic>()),
      ],
    );
  }
}

enum UpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  needsPermission,
  error,
}

class AppUpdater extends ChangeNotifier {
  AppUpdater._();
  static final AppUpdater instance = AppUpdater._();

  static const _channel = MethodChannel('gymmane/updater');
  static const _kRepo = 'fitmane_upd_repo';
  static const _kProxy = 'fitmane_upd_proxy';
  static const _kToken = 'fitmane_upd_token';
  static const _kAuto = 'fitmane_upd_auto';
  static const _kLastCheck = 'fitmane_upd_last_check';
  static const _kDismissed = 'fitmane_upd_dismissed_tag';
  static const Duration _autoCooldown = Duration(minutes: 15);
  static const Duration _coldStartCooldown = Duration(minutes: 2);

  bool _initialized = false;
  bool _promptedThisLaunch = false;
  String repo = kDefaultUpdateRepo;
  String proxy = '';
  String token = '';
  bool autoCheck = true;
  String currentVersion = kCurrentAppVersion;
  int currentBuild = kCurrentAppBuild;
  List<String> deviceAbis = const ['arm64-v8a', 'armeabi-v7a', 'x86_64'];

  UpdateStatus status = UpdateStatus.idle;
  ReleaseInfo? latest;
  String? downloadedApkPath;
  double? progress;
  int receivedBytes = 0;
  int totalBytes = 0;
  String? errorMessage;
  DateTime? lastCheckedAt;
  String dismissedTag = '';
  bool sha256Verified = false;
  bool preUpdateBackedUp = false;

  bool get supported => !kIsWeb && Platform.isAndroid;

  bool get hasUpdate =>
      latest != null &&
      compareVersions(latest!.tagName, currentVersion) > 0;

  bool get hasUpdateBanner =>
      hasUpdate && dismissedTag != latest!.tagName;

  /// True when an un-skipped newer release is ready to prompt automatically
  /// and this launch has not yet been prompted or deferred.
  bool get shouldAutoPrompt =>
      autoCheck &&
      hasUpdateBanner &&
      !_promptedThisLaunch &&
      status != UpdateStatus.downloading;

  void markPromptedThisLaunch() {
    if (_promptedThisLaunch) return;
    _promptedThisLaunch = true;
    notifyListeners();
  }

  Future<void> skipCurrentUpdate() async {
    _promptedThisLaunch = true;
    await dismissBanner();
  }

  @visibleForTesting
  void resetPromptStateForTest() {
    _promptedThisLaunch = false;
    dismissedTag = '';
    autoCheck = true;
    status = UpdateStatus.idle;
  }

  /// Compares two version strings (`remote` vs `current`).
  /// Returns > 0 when [remote] is newer, 0 when equal, < 0 when older.
  static int compareVersions(String remote, String current) {
    final a = _parseVersion(remote);
    final b = _parseVersion(current);
    final maxLen = a.nums.length > b.nums.length ? a.nums.length : b.nums.length;
    for (var i = 0; i < maxLen; i++) {
      final av = i < a.nums.length ? a.nums[i] : 0;
      final bv = i < b.nums.length ? b.nums[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    if (a.preRelease != b.preRelease) {
      return a.preRelease ? -1 : 1;
    }
    if (a.build != null && b.build != null && a.build != b.build) {
      return a.build!.compareTo(b.build!);
    }
    return 0;
  }

  static ({List<int> nums, bool preRelease, int? build}) _parseVersion(String raw) {
    var clean = raw.trim().replaceFirst(RegExp(r'^[vV]'), '');
    int? build;
    final plus = clean.indexOf('+');
    if (plus >= 0) {
      build = int.tryParse(clean.substring(plus + 1).trim());
      clean = clean.substring(0, plus);
    }
    final dash = clean.indexOf('-');
    final preRelease = dash >= 0;
    if (dash >= 0) {
      clean = clean.substring(0, dash);
    }
    final nums = <int>[
      for (final part in clean.split('.'))
        int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
    ];
    return (nums: nums, preRelease: preRelease, build: build);
  }

  /// Selects the best APK asset matching [abis] in priority order.
  static ReleaseAsset? pickApkAsset(
    List<ReleaseAsset> assets,
    List<String> abis,
  ) {
    final apks = assets
        .where((a) =>
            a.name.toLowerCase().endsWith('.apk') && a.downloadUrl.isNotEmpty)
        .toList();
    if (apks.isEmpty) return null;

    for (final abi in abis) {
      final target = abi.toLowerCase();
      for (final asset in apks) {
        if (asset.name.toLowerCase().contains(target)) {
          return asset;
        }
      }
    }

    const archTokens = ['arm64-v8a', 'armeabi-v7a', 'armeabi', 'x86_64', 'x86'];
    for (final asset in apks) {
      final lower = asset.name.toLowerCase();
      if (!archTokens.any(lower.contains)) return asset;
    }
    return apks.first;
  }

  /// Prepends [proxyPrefix] (or fills `{url}` template) when non-empty.
  static String applyProxy(String url, String proxyPrefix) {
    final p = proxyPrefix.trim();
    if (p.isEmpty) return url;
    if (p.contains('{url}')) return p.replaceAll('{url}', url);
    final normalized = p.endsWith('/') ? p : '$p/';
    return '$normalized$url';
  }

  static String normalizeRepo(String raw) {
    var v = raw.trim();
    v = v.replaceFirst(RegExp(r'^https?://github\.com/'), '');
    v = v.replaceAll(RegExp(r'^/+|/+$'), '');
    v = v.replaceAll(RegExp(r'\.git$'), '');
    v = v.replaceAll(RegExp(r'^/+|/+$'), '');
    return v.isEmpty ? kDefaultUpdateRepo : v;
  }

  static ReleaseAsset? findSha256Asset(List<ReleaseAsset> assets) {
    for (final a in assets) {
      final lower = a.name.toLowerCase();
      if (lower == 'sha256sums.txt' || lower.endsWith('.sha256')) {
        return a;
      }
    }
    return null;
  }

  static String? parseSha256ForFile(String sumsText, String fileName) {
    final target = fileName.trim().toLowerCase();
    for (final rawLine in sumsText.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+)$').firstMatch(line);
      if (m == null) continue;
      final hash = m.group(1)!.toLowerCase();
      final name = m.group(2)!.trim().split('/').last.toLowerCase();
      if (name == target) return hash;
    }
    return null;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      repo = normalizeRepo(prefs.getString(_kRepo) ?? kDefaultUpdateRepo);
      proxy = prefs.getString(_kProxy) ?? '';
      token = prefs.getString(_kToken) ?? '';
      autoCheck = prefs.getBool(_kAuto) ?? true;
      dismissedTag = prefs.getString(_kDismissed) ?? '';
      final lastMs = prefs.getInt(_kLastCheck);
      if (lastMs != null && lastMs > 0) {
        lastCheckedAt = DateTime.fromMillisecondsSinceEpoch(lastMs);
      }
    } catch (_) {}

    if (supported) {
      try {
        final info = await _channel.invokeMapMethod<String, dynamic>('info');
        if (info != null) {
          final v = info['versionName'] as String?;
          if (v != null && v.trim().isNotEmpty) {
            currentVersion = v.trim();
          }
          final c = info['versionCode'];
          if (c is num) currentBuild = c.toInt();
          final abis = (info['abis'] as List?)?.whereType<String>().toList();
          if (abis != null && abis.isNotEmpty) {
            deviceAbis = abis;
          }
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<bool> initAndMaybeCheck({bool coldStart = true}) async {
    await init();
    if (!supported || !autoCheck) return false;
    await checkForUpdate(silent: true, coldStart: coldStart);
    return shouldAutoPrompt;
  }

  Future<void> saveSettings({
    required String repo,
    required String proxy,
    required String token,
    required bool autoCheck,
  }) async {
    await init();
    final nextRepo = normalizeRepo(repo);
    final repoChanged = nextRepo != this.repo;
    this.repo = nextRepo;
    this.proxy = proxy.trim();
    this.token = token.trim();
    this.autoCheck = autoCheck;
    if (repoChanged) {
      latest = null;
      downloadedApkPath = null;
      status = UpdateStatus.idle;
      errorMessage = null;
      _promptedThisLaunch = false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRepo, this.repo);
      await prefs.setString(_kProxy, this.proxy);
      await prefs.setString(_kToken, this.token);
      await prefs.setBool(_kAuto, this.autoCheck);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> dismissBanner() async {
    final tag = latest?.tagName;
    if (tag == null || tag.isEmpty) return;
    dismissedTag = tag;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDismissed, tag);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> checkForUpdate({
    bool silent = false,
    bool coldStart = false,
  }) async {
    await init();
    if (silent && (!supported || !autoCheck)) return;
    if (status == UpdateStatus.checking || status == UpdateStatus.downloading) {
      return;
    }
    if (silent && lastCheckedAt != null) {
      final cooldown = coldStart ? _coldStartCooldown : _autoCooldown;
      if (DateTime.now().difference(lastCheckedAt!) < cooldown) {
        return;
      }
    }
    if (!silent) {
      status = UpdateStatus.checking;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final info = await _fetchLatestRelease();
      latest = info;
      lastCheckedAt = DateTime.now();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kLastCheck, lastCheckedAt!.millisecondsSinceEpoch);
      } catch (_) {}

      if (compareVersions(info.tagName, currentVersion) > 0) {
        status = UpdateStatus.available;
      } else {
        status = silent ? UpdateStatus.idle : UpdateStatus.upToDate;
      }
      errorMessage = null;
    } catch (e) {
      if (silent) {
        status = UpdateStatus.idle;
      } else {
        status = UpdateStatus.error;
        errorMessage = e.toString();
      }
    }
    notifyListeners();
  }

  Future<ReleaseInfo> _fetchLatestRelease() async {
    final directApi = 'https://api.github.com/repos/$repo/releases/latest';
    try {
      return await _requestReleaseJson(directApi);
    } catch (firstErr) {
      if (proxy.trim().isNotEmpty) {
        try {
          return await _requestReleaseJson(applyProxy(directApi, proxy));
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<ReleaseInfo> _requestReleaseJson(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      req.headers.set(HttpHeaders.userAgentHeader, 'FitMane/$currentVersion');
      if (token.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final resp = await req.close().timeout(const Duration(seconds: 15));
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${resp.statusCode}', uri: Uri.parse(url));
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid GitHub release payload');
      }
      return ReleaseInfo.fromJson(decoded);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> downloadAndInstall() async {
    final rel = latest;
    if (rel == null) return;
    if (!supported) {
      status = UpdateStatus.error;
      errorMessage = 'Android only';
      notifyListeners();
      return;
    }
    final asset = pickApkAsset(rel.assets, deviceAbis);
    if (asset == null) {
      status = UpdateStatus.error;
      errorMessage = 'No APK asset';
      notifyListeners();
      return;
    }

    status = UpdateStatus.downloading;
    progress = 0;
    receivedBytes = 0;
    totalBytes = asset.size;
    errorMessage = null;
    sha256Verified = false;
    preUpdateBackedUp = false;
    notifyListeners();

    preUpdateBackedUp = await _backupBeforeUpdate();
    notifyListeners();

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    IOSink? sink;
    try {
      final tempDir = await getTemporaryDirectory();
      final updatesDir = Directory('${tempDir.path}/updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }
      // Clean stale APKs before downloading
      await for (final entity in updatesDir.list()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }

      final safeName = asset.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final partFile = File('${updatesDir.path}/$safeName.part');
      final finalFile = File('${updatesDir.path}/$safeName');

      final targetUrl = applyProxy(asset.downloadUrl, proxy);
      final req = await client.getUrl(Uri.parse(targetUrl));
      req.headers.set(HttpHeaders.userAgentHeader, 'FitMane/$currentVersion');
      if (token.isNotEmpty && proxy.trim().isEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final resp = await req.close().timeout(const Duration(seconds: 25));
      if (resp.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${resp.statusCode}', uri: Uri.parse(targetUrl));
      }

      if (resp.contentLength > 0) {
        totalBytes = resp.contentLength;
      }

      sink = partFile.openWrite();
      final hasher = Sha256Sink();
      var lastNotify = DateTime.now();
      await for (final chunk in resp) {
        sink.add(chunk);
        hasher.add(chunk);
        receivedBytes += chunk.length;
        final now = DateTime.now();
        if (now.difference(lastNotify).inMilliseconds >= 80) {
          lastNotify = now;
          progress = totalBytes > 0
              ? (receivedBytes / totalBytes).clamp(0.0, 1.0)
              : null;
          notifyListeners();
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;

      final sumsAsset = findSha256Asset(rel.assets);
      if (sumsAsset != null) {
        final actualHash = hasher.digestHex();
        final sumsText = await _fetchTextAsset(sumsAsset.downloadUrl);
        final expectedHash = parseSha256ForFile(sumsText, asset.name);
        if (expectedHash != null) {
          if (expectedHash != actualHash) {
            try {
              await partFile.delete();
            } catch (_) {}
            throw Exception(ExtraStrings.sha256MismatchError);
          }
          sha256Verified = true;
        }
      }

      if (await finalFile.exists()) await finalFile.delete();
      await partFile.rename(finalFile.path);
      downloadedApkPath = finalFile.path;
      progress = 1.0;

      await installDownloaded();
    } catch (e) {
      await sink?.close();
      status = UpdateStatus.error;
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> _backupBeforeUpdate() async {
    var ok = false;
    try {
      fit.persistNow();
      if (AutoBackup.instance.hasFolder) {
        if (await AutoBackup.instance.run(force: true)) {
          ok = true;
        }
      }
      final zip = await buildBackupZip();
      if (isValidBackupZip(zip)) {
        final docs = await getApplicationDocumentsDirectory();
        final dir = Directory('${docs.path}/pre_update_backups');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/pre-update-v$currentVersion-$stamp.zip');
        await file.writeAsBytes(zip, flush: true);
        ok = true;
        final existing = await dir
            .list()
            .where((e) => e is File && e.path.endsWith('.zip'))
            .cast<File>()
            .toList();
        existing.sort((a, b) => b.path.compareTo(a.path));
        for (final stale in existing.skip(2)) {
          try {
            await stale.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return ok;
  }

  Future<String> _fetchTextAsset(String rawUrl) async {
    Future<String> get(String url) async {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      try {
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set(HttpHeaders.userAgentHeader, 'FitMane/$currentVersion');
        if (token.isNotEmpty && proxy.trim().isEmpty) {
          req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }
        final resp = await req.close().timeout(const Duration(seconds: 15));
        if (resp.statusCode != HttpStatus.ok) {
          throw HttpException('HTTP ${resp.statusCode}', uri: Uri.parse(url));
        }
        return await resp.transform(utf8.decoder).join();
      } finally {
        client.close(force: true);
      }
    }

    final primary = applyProxy(rawUrl, proxy);
    try {
      return await get(primary);
    } catch (_) {
      if (primary != rawUrl) {
        return await get(rawUrl);
      }
      rethrow;
    }
  }

  Future<bool> canInstallPackages() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('canInstall') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openInstallSettings() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('openInstallSettings');
    } catch (_) {}
  }

  Future<bool> installDownloaded() async {
    final path = downloadedApkPath;
    if (!supported || path == null || !File(path).existsSync()) return false;
    final allowed = await canInstallPackages();
    if (!allowed) {
      status = UpdateStatus.needsPermission;
      notifyListeners();
      return false;
    }
    try {
      status = UpdateStatus.readyToInstall;
      notifyListeners();
      final ok = await _channel.invokeMethod<bool>('installApk', {'path': path}) ?? false;
      return ok;
    } catch (e) {
      status = UpdateStatus.error;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
