import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/extra_strings.dart';
import '../l10n/l10n.dart';
import '../services/app_updater.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'ui_kit.dart';

void showUpdateSheet(BuildContext context, {bool autoCheckIfIdle = true}) {
  if (autoCheckIfIdle &&
      (AppUpdater.instance.status == UpdateStatus.idle ||
          AppUpdater.instance.status == UpdateStatus.error)) {
    AppUpdater.instance.checkForUpdate();
  }
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _UpdateSheet(),
  );
}

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet();

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> with WidgetsBindingObserver {
  final _upd = AppUpdater.instance;
  late final TextEditingController _repo = TextEditingController(text: _upd.repo);
  late final TextEditingController _proxy = TextEditingController(text: _upd.proxy);
  late final TextEditingController _token = TextEditingController(text: _upd.token);
  late bool _autoCheck = _upd.autoCheck;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _upd.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repo.dispose();
    _proxy.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _upd.status == UpdateStatus.needsPermission) {
      _upd.installDownloaded();
    }
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  String _formatCheckedAt(DateTime? dt) {
    if (dt == null) return ExtraStrings.lastCheckedNever;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return ExtraStrings.lastCheckedAt('${t.shortDate(dt)} $hh:$mm');
  }

  Future<void> _openReleaseUrl(String url) async {
    final target = url.trim().isEmpty ? '${ExtraStrings.repoUrl}/releases' : url;
    try {
      await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    HapticFeedback.selectionClick();
    await _upd.saveSettings(
      repo: _repo.text,
      proxy: _proxy.text,
      token: _token.text,
      autoCheck: _autoCheck,
    );
    _repo.text = _upd.repo;
    if (!mounted) return;
    setState(() => _showSettings = false);
    showNotchToast(
      context,
      ExtraStrings.sourceSettingsSaved,
      icon: PhosphorIconsFill.checkCircle,
      accent: context.gc.sage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _upd,
      builder: (context, _) {
        final gc = context.gc;
        final rel = _upd.latest;
        final hasNew = _upd.hasUpdate;

        return AppSheet(
          children: [
            SheetTitle(
              ExtraStrings.appUpdatesTitle,
              subtitle: _formatCheckedAt(_upd.lastCheckedAt),
            ),
            const SizedBox(height: 16),
            SoftCard(
              radius: 20,
              color: gc.bgRaised2,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ExtraStrings.currentVersionLabel.toUpperCase(),
                          style: kickerStyle(gc),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v${_upd.currentVersion}',
                          style: AppTheme.d(20, weight: FontWeight.w800, color: gc.text),
                        ),
                      ],
                    ),
                  ),
                  if (rel != null) ...[
                    Icon(PhosphorIconsRegular.arrowRight, size: 16, color: gc.textTertiary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ExtraStrings.latestVersionLabel.toUpperCase(),
                            style: kickerStyle(gc),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v${rel.displayVersion}',
                            style: AppTheme.d(
                              20,
                              weight: FontWeight.w800,
                              color: hasNew ? gc.accent : gc.sage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _statusBody(context, gc),
            const SizedBox(height: 14),
            _sourceSettingsCard(context, gc),
          ],
        );
      },
    );
  }

  Widget _statusBody(BuildContext context, GymColors gc) {
    final rel = _upd.latest;
    switch (_upd.status) {
      case UpdateStatus.checking:
        return SoftCard(
          radius: 20,
          color: gc.bgRaised2,
          borderColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: gc.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ExtraStrings.checkingUpdates,
                textAlign: TextAlign.center,
                style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.textSecondary),
              ),
            ],
          ),
        );

      case UpdateStatus.downloading:
        final p = _upd.progress;
        final totalStr = _upd.totalBytes > 0 ? _mb(_upd.totalBytes) : '';
        return SoftCard(
          radius: 20,
          color: gc.bgRaised2,
          borderColor: Colors.transparent,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ExtraStrings.downloadingProgress(_mb(_upd.receivedBytes), totalStr),
                style: AppTheme.f(13.5, weight: FontWeight.w700, color: gc.text),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: p,
                  minHeight: 7,
                  backgroundColor: gc.bgRaised,
                  valueColor: AlwaysStoppedAnimation(gc.accent),
                ),
              ),
            ],
          ),
        );

      case UpdateStatus.needsPermission:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoftCard(
              radius: 20,
              color: gc.bgRaised2,
              borderColor: gc.accent.withValues(alpha: 0.45),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(PhosphorIconsFill.shieldCheck, size: 18, color: gc.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ExtraStrings.installPermTitle,
                        style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    ExtraStrings.installPermBody,
                    style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: ExtraStrings.openInstallSettings,
              onTap: () {
                HapticFeedback.selectionClick();
                _upd.openInstallSettings();
              },
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: ExtraStrings.installDownloadedApk,
              icon: PhosphorIconsRegular.downloadSimple,
              onTap: () => _upd.installDownloaded(),
            ),
          ],
        );

      case UpdateStatus.readyToInstall:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoftCard(
              radius: 20,
              color: gc.sageSoft,
              borderColor: Colors.transparent,
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(PhosphorIconsFill.checkCircle, size: 18, color: gc.sage),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ExtraStrings.installerLaunched,
                    style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: ExtraStrings.installDownloadedApk,
              onTap: () => _upd.installDownloaded(),
            ),
          ],
        );

      case UpdateStatus.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SoftCard(
              radius: 20,
              color: gc.bgRaised2,
              borderColor: gc.danger.withValues(alpha: 0.45),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(PhosphorIconsFill.warningCircle, size: 18, color: gc.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ExtraStrings.updateCheckFailed,
                        style: AppTheme.f(14.5, weight: FontWeight.w700, color: gc.text),
                      ),
                    ),
                  ]),
                  if ((_upd.errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _upd.errorMessage!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: ExtraStrings.retry,
              onTap: () => _upd.checkForUpdate(),
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: ExtraStrings.openInBrowser,
              icon: PhosphorIconsRegular.arrowUpRight,
              onTap: () => _openReleaseUrl(rel?.htmlUrl ?? ''),
            ),
          ],
        );

      case UpdateStatus.available:
      case UpdateStatus.upToDate:
      case UpdateStatus.idle:
        if (rel != null && _upd.hasUpdate) {
          final asset = AppUpdater.pickApkAsset(rel.assets, _upd.deviceAbis);
          final notes = rel.body.trim().isEmpty
              ? ExtraStrings.noReleaseNotes
              : rel.body.trim();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SoftCard(
                radius: 20,
                color: gc.bgRaised2,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: gc.accentSoft,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          ExtraStrings.newVersionBadge,
                          style: AppTheme.f(11, weight: FontWeight.w700, color: gc.accent),
                        ),
                      ),
                      const Spacer(),
                      if (asset != null && asset.size > 0)
                        Text(
                          '${_mb(asset.size)} MB',
                          style: AppTheme.f(12, weight: FontWeight.w600, color: gc.textSecondary),
                        ),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      ExtraStrings.releaseNotesTitle.toUpperCase(),
                      style: kickerStyle(gc),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Text(
                          notes,
                          style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!_upd.supported)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    ExtraStrings.androidOnlyHint,
                    textAlign: TextAlign.center,
                    style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary),
                  ),
                )
              else if (asset == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    ExtraStrings.noCompatibleApk,
                    textAlign: TextAlign.center,
                    style: AppTheme.f(12, weight: FontWeight.w500, color: gc.warn),
                  ),
                ),
              if (_upd.supported && asset != null) ...[
                PrimaryButton(
                  label: ExtraStrings.downloadAndInstall,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _upd.downloadAndInstall();
                  },
                ),
                const SizedBox(height: 10),
              ],
              GhostButton(
                label: ExtraStrings.openInBrowser,
                icon: PhosphorIconsRegular.arrowUpRight,
                onTap: () => _openReleaseUrl(rel.htmlUrl),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_upd.status == UpdateStatus.upToDate) ...[
              SoftCard(
                radius: 20,
                color: gc.sageSoft,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(PhosphorIconsFill.checkCircle, size: 20, color: gc.sage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ExtraStrings.upToDateTitle,
                          style: AppTheme.f(14.5, weight: FontWeight.w700, color: gc.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ExtraStrings.upToDateHint(_upd.currentVersion),
                          style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: ExtraStrings.checkUpdatesNow,
              onTap: () {
                HapticFeedback.selectionClick();
                _upd.checkForUpdate();
              },
            ),
          ],
        );
    }
  }

  Widget _sourceSettingsCard(BuildContext context, GymColors gc) {
    return SoftCard(
      radius: 20,
      color: gc.bgRaised2,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            scale: 0.98,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showSettings = !_showSettings);
            },
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.slidersHorizontal, size: 17, color: gc.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ExtraStrings.updateSourceSettings,
                    style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text),
                  ),
                ),
                AnimatedRotation(
                  turns: _showSettings ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(PhosphorIconsRegular.caretDown, size: 15, color: gc.textTertiary),
                ),
              ],
            ),
          ),
          if (_showSettings) ...[
            const SizedBox(height: 14),
            _field(gc, ExtraStrings.repoFieldLabel, _repo, ExtraStrings.repoSlug),
            const SizedBox(height: 12),
            _field(gc, ExtraStrings.proxyFieldLabel, _proxy, ExtraStrings.proxyFieldHint),
            const SizedBox(height: 12),
            _field(gc, ExtraStrings.tokenFieldLabel, _token, ExtraStrings.tokenFieldHint, obscure: true),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _autoCheck = !_autoCheck),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ExtraStrings.autoCheckLabel,
                      style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text),
                    ),
                  ),
                  TinySwitch(on: _autoCheck),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: ExtraStrings.saveSourceSettings,
              height: 44,
              onTap: _saveSettings,
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(
    GymColors gc,
    String label,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gc.border.withValues(alpha: 0.6)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            autocorrect: false,
            style: AppTheme.f(13.5, weight: FontWeight.w500, color: gc.text),
            cursorColor: gc.accent,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintText: hint,
              hintStyle: AppTheme.f(12.5, weight: FontWeight.w400, color: gc.textTertiary),
            ),
          ),
        ),
      ],
    );
  }
}
