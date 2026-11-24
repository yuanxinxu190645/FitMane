import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/extra_strings.dart';
import '../services/ai_export.dart';
import '../services/file_share.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'liquid_notch.dart';
import 'ui_kit.dart';

void showAiExportSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AiExportSheet(),
  );
}

class _AiExportSheet extends StatelessWidget {
  const _AiExportSheet();

  String _formatTime(DateTime? dt) {
    if (dt == null) return ExtraStrings.aiCloudNeverSynced;
    String p2(int n) => n.toString().padLeft(2, '0');
    return ExtraStrings.aiCloudLastSynced(
      '${dt.month}/${dt.day} ${p2(dt.hour)}:${p2(dt.minute)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AiExportService.instance,
      builder: (context, _) {
        final gc = context.gc;
        final svc = AiExportService.instance;
        final bound = svc.hasTarget;

        return AppSheet(
          children: [
            SheetTitle(
              ExtraStrings.aiCloudExportTitle,
              subtitle: ExtraStrings.aiCloudExportSubtitle,
            ),
            const SizedBox(height: 14),
            SoftCard(
              radius: 20,
              color: gc.bgRaised2,
              borderColor: bound
                  ? gc.sage.withValues(alpha: 0.35)
                  : Colors.transparent,
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        bound
                            ? PhosphorIconsFill.checkCircle
                            : PhosphorIconsRegular.sparkle,
                        size: 18,
                        color: bound ? gc.sage : gc.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bound ? svc.fileName : ExtraStrings.aiCloudNotBound,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.f(
                            14.5,
                            weight: FontWeight.w700,
                            color: gc.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bound ? _formatTime(svc.lastExportAt) : ExtraStrings.aiCloudExportGuide,
                    style: AppTheme.f(
                      12.5,
                      weight: FontWeight.w500,
                      color: gc.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (svc.supported) ...[
              PrimaryButton(
                label: bound
                    ? ExtraStrings.aiCloudOverwriteNow
                    : ExtraStrings.aiCloudPickAndExport,
                onTap: svc.exporting
                    ? null
                    : () async {
                        HapticFeedback.selectionClick();
                        final ok = bound
                            ? await svc.exportOverwrite()
                            : await svc.pickAndExport();
                        if (!context.mounted) return;
                        showNotchToast(
                          context,
                          ok
                              ? ExtraStrings.aiCloudExportSuccess
                              : ExtraStrings.aiCloudExportFailed,
                          icon: ok
                              ? PhosphorIconsFill.checkCircle
                              : PhosphorIconsFill.warningCircle,
                          accent: ok ? gc.sage : gc.danger,
                        );
                      },
              ),
              const SizedBox(height: 10),
              if (bound) ...[
                SoftCard(
                  radius: 18,
                  color: gc.bgRaised2,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      svc.setAutoSync(!svc.autoSync);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ExtraStrings.aiCloudAutoSync,
                                style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ExtraStrings.aiCloudAutoSyncHint,
                                style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        TinySwitch(on: svc.autoSync),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GhostButton(
                  label: ExtraStrings.aiCloudChangeFile,
                  icon: PhosphorIconsRegular.folders,
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final ok = await svc.pickAndExport();
                    if (!context.mounted) return;
                    if (ok) {
                      showNotchToast(
                        context,
                        ExtraStrings.aiCloudExportSuccess,
                        icon: PhosphorIconsFill.checkCircle,
                        accent: gc.sage,
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
            GhostButton(
              label: ExtraStrings.aiCloudShareFile,
              icon: PhosphorIconsRegular.export,
              onTap: () async {
                HapticFeedback.selectionClick();
                final md = buildAiTrainingReport();
                await shareFile(
                  kAiSummaryFileName,
                  utf8Bytes(md),
                  mime: 'text/markdown',
                  subject: kAiSummaryFileName,
                );
              },
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: ExtraStrings.aiCloudCopyMarkdown,
              icon: PhosphorIconsRegular.fileText,
              onTap: () async {
                HapticFeedback.selectionClick();
                await Clipboard.setData(ClipboardData(text: buildAiTrainingReport()));
                if (!context.mounted) return;
                showNotchToast(
                  context,
                  ExtraStrings.aiCloudCopiedToast,
                  icon: PhosphorIconsFill.checkCircle,
                  accent: gc.sage,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
