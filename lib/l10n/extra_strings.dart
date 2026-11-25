import 'l10n.dart';

class ExtraStrings {
  ExtraStrings._();

  static bool get _zh => appLanguage.startsWith('zh');

  static const String appName = 'FitMane';
  static const String repoSlug = 'yuanxinxu190645/FitMane';
  static const String repoUrl = 'https://github.com/$repoSlug';
  static const String upstreamSlug = 'InlitX/GymMane';
  static const String upstreamUrl = 'https://github.com/$upstreamSlug';

  static String get attribution =>
      _zh ? '基于 InlitX 的 GymMane 构建' : 'Based on GymMane by InlitX';
  static String get projectRepoLabel => _zh ? '定制仓库' : 'FitMane Repo';
  static String get upstreamRepoLabel => _zh ? '上游开源项目' : 'Upstream Project';

  // Theme quick toggle
  static String themeSwitchToast(String pref) => switch (pref) {
        'system' => _zh ? '主题已切换：跟随系统' : 'Theme: Follow system',
        'light' => _zh ? '主题已切换：浅色模式' : 'Theme: Light',
        'amoled' => _zh ? '主题已切换：纯黑模式' : 'Theme: AMOLED black',
        _ => _zh ? '主题已切换：深色模式' : 'Theme: Dark',
      };

  static String themeLabel(String pref) => switch (pref) {
        'system' => _zh ? '跟随系统' : 'System',
        'light' => _zh ? '浅色' : 'Light',
        'amoled' => _zh ? '纯黑' : 'AMOLED',
        _ => _zh ? '深色' : 'Dark',
      };

  // App updater
  static String get appUpdatesTitle => _zh ? '应用更新' : 'App Updates';
  static String get appUpdatesHint =>
      _zh ? '直连 GitHub Releases 检查并安装新版本' : 'Check and install releases directly from GitHub';
  static String get checkUpdatesNow => _zh ? '检查更新' : 'Check for updates';
  static String get checkingUpdates => _zh ? '正在连接 GitHub 检查版本…' : 'Checking GitHub Releases…';
  static String get currentVersionLabel => _zh ? '当前版本' : 'Installed';
  static String get latestVersionLabel => _zh ? '最新版本' : 'Latest';
  static String get upToDateTitle => _zh ? '已是最新版本' : 'Up to date';
  static String upToDateHint(String ver) =>
      _zh ? '当前 $ver 已是 GitHub 上的最新版本' : 'Version $ver is the latest available release';
  static String newVersionBanner(String ver) =>
      _zh ? '发现新版本 $ver，点此下载更新' : 'Update $ver available · Tap to install';
  static String get newVersionBadge => _zh ? '有新版本' : 'Update ready';
  static String get releaseNotesTitle => _zh ? '更新日志' : 'Release notes';
  static String get noReleaseNotes => _zh ? '本次发布未附带更新说明。' : 'No release notes provided.';
  static String get downloadAndInstall => _zh ? '下载并安装' : 'Download & install';
  static String get installDownloadedApk => _zh ? '立即安装更新包' : 'Install downloaded APK';
  static String downloadingProgress(String receivedMb, String totalMb) =>
      totalMb.isEmpty
          ? (_zh ? '正在下载安装包… $receivedMb MB' : 'Downloading APK… $receivedMb MB')
          : (_zh ? '正在下载安装包… $receivedMb / $totalMb MB' : 'Downloading APK… $receivedMb / $totalMb MB');
  static String get installPermTitle =>
      _zh ? '需要授予安装权限' : 'Install permission needed';
  static String get installPermBody => _zh
      ? '请在小米澎湃系统设置中开启“允许来自此来源的应用”，授权后返回即可直接安装并保留所有记录。'
      : 'Allow installing unknown apps from FitMane in Android settings, then return to continue.';
  static String get openInstallSettings => _zh ? '去授权并继续' : 'Grant permission';
  static String get installerLaunched =>
      _zh ? '已唤起系统安装器，请确认覆盖安装' : 'System installer opened. Confirm to update.';
  static String get noCompatibleApk =>
      _zh ? '此 Release 中未找到适配的 APK 文件' : 'No compatible APK asset found in this release.';
  static String get openInBrowser => _zh ? '在浏览器中打开发布页' : 'Open release in browser';
  static String get retry => _zh ? '重试' : 'Retry';
  static String get updateSourceSettings => _zh ? '更新源与网络设置' : 'Source & network settings';
  static String get repoFieldLabel => _zh ? 'GitHub 仓库 (owner/repo)' : 'GitHub repository (owner/repo)';
  static String get proxyFieldLabel => _zh ? '国内加速代理前缀（可选）' : 'Mirror / proxy URL prefix (optional)';
  static String get proxyFieldHint => _zh ? '例如 https://ghfast.top/，留空则直连 GitHub' : 'e.g. https://ghfast.top/ (leave empty for direct)';
  static String get tokenFieldLabel => _zh ? 'GitHub Token（私有仓库可选）' : 'GitHub token (optional for private repos)';
  static String get tokenFieldHint => _zh ? '公开仓库无需填写' : 'Not needed for public repositories';
  static String get autoCheckLabel => _zh ? '启动时自动检查更新' : 'Auto-check on launch';
  static String get saveSourceSettings => _zh ? '保存更新源配置' : 'Save settings';
  static String get sourceSettingsSaved => _zh ? '更新源配置已保存' : 'Update settings saved';
  static String get lastCheckedNever => _zh ? '尚未检查' : 'Never checked';
  static String lastCheckedAt(String stamp) => _zh ? '上次检查：$stamp' : 'Last checked: $stamp';
  static String get androidOnlyHint =>
      _zh ? '应用内安装仅支持 Android 设备' : 'In-app APK installation is only available on Android.';
  static String get updateCheckFailed => _zh ? '检查更新失败' : 'Update check failed';
  static String get downloadFailed => _zh ? '下载安装包失败' : 'Download failed';

  // Body composition card & quick logger
  static String get bodyCompTitle => _zh ? '今日体态' : 'Body Composition';
  static String get bodyCompEmptyHint =>
      _zh ? '3 秒记录体重与体脂率，自动计算瘦体重与变化趋势' : 'Log weight & body fat in seconds to track lean mass & trends';
  static String get logNow => _zh ? '记录' : 'Log';
  static String get weightLabel => _zh ? '体重' : 'Weight';
  static String get bodyFatLabel => _zh ? '体脂率' : 'Body fat';
  static String get leanMassLabel => _zh ? '瘦体重' : 'Lean mass';
  static String get fatMassLabel => _zh ? '脂肪重' : 'Fat mass';
  static String get bmiLabel => 'BMI';
  static String get quickLogTitle => _zh ? '记录体重与体脂率' : 'Log Weight & Body Fat';
  static String get quickLogSubtitle =>
      _zh ? '同一弹窗快速录入，保存后同步更新趋势与瘦体重' : 'Record both metrics together to update trends and lean mass';
  static String get weightInputHint => _zh ? '例如 72.5' : 'e.g. 72.5';
  static String get bodyFatInputHint => _zh ? '例如 16.5（可选）' : 'e.g. 16.5 (optional)';
  static String get noteInputHint => _zh ? '备注（如晨起空腹 / 晚间训练后）' : 'Note (e.g. morning fasted)';
  static String get saveRecord => _zh ? '保存记录' : 'Save record';
  static String get savedBodyComp => _zh ? '已保存今日体态记录' : 'Body composition saved';
  static String get enterAtLeastOne =>
      _zh ? '请至少填写有效的体重或体脂率' : 'Enter a valid weight or body fat percentage';
  static String get livePreviewTitle => _zh ? '实时体成分估算' : 'Estimated composition';
  static String get viewTrend => _zh ? '趋势分析' : 'Trends';

  // Dual trend sheet
  static String get bodyCompTrendTitle => _zh ? '体态趋势分析' : 'Body Composition Trends';
  static String get range7d => _zh ? '7天' : '7D';
  static String get range30d => _zh ? '30天' : '30D';
  static String get range90d => _zh ? '90天' : '90D';
  static String get rangeAll => _zh ? '全部' : 'All';
  static String get modeDual => _zh ? '双曲线' : 'Dual';
  static String get modeWeight => _zh ? '体重' : 'Weight';
  static String get modeBodyFat => _zh ? '体脂率' : 'Body fat';
  static String get modeLean => _zh ? '瘦体重' : 'Lean mass';
  static String get ma7Legend => _zh ? '7日均线' : '7-day avg';
  static String get rawLegend => _zh ? '每日记录' : 'Daily';
  static String get statStart => _zh ? '起始' : 'Start';
  static String get statLatest => _zh ? '最新' : 'Latest';
  static String get statChange => _zh ? '变化' : 'Change';
  static String get statAvg => _zh ? '均值' : 'Average';
  static String get recentLogsTitle => _zh ? '历史记录' : 'Recent entries';
  static String get noTrendDataHint =>
      _zh ? '还没有足够的体重或体脂记录，先记录一笔吧。' : 'No weight or body fat entries in this range yet.';
  static String get openAllMeasures => _zh ? '管理全部 10 项身体围度' : 'Open all 10 body measurements';
  static String get logTodayEntry => _zh ? '记一笔体态' : 'Log entry';
  static String get deleteEntryLabel => _zh ? '删除记录' : 'Delete';
  static String get tapChartHint => _zh ? '点击或滑动图表查看具体日期数值' : 'Tap chart points to inspect values';

  // Quick daily log mode
  static String get quickWorkoutTitle => _zh ? '今日训练记录' : 'Quick Training Log';
  static String get quickLogEmptyHint =>
      _zh ? '无需先开计划，随时搜动作加入今天并记录组数与重量' : 'Search any exercise to log sets & weights directly';
  static String get quickLogAddExercise => _zh ? '添加动作' : 'Add exercise';
  static String get quickLogOpenToday => _zh ? '去记录' : 'Edit sets';
  static String quickLogAddedToast(String name, int sets) =>
      _zh ? '已加入今日：$name（$sets 组）' : 'Added $name ($sets sets)';
  static String get quickLogAlreadyAdded => _zh ? '已在今日记录中' : 'Already logged today';
  static String get quickLogToday => _zh ? '今天' : 'Today';
  static String get quickLogYesterday => _zh ? '昨天' : 'Yesterday';
  static String get quickLogNoEntriesDay => _zh ? '这一天还没有记录任何训练动作' : 'No exercises logged for this day yet';
  static String get quickLogAddSet => _zh ? '加一组' : 'Add set';
  static String get quickLogSetNoteTitle => _zh ? '单组备注' : 'Set note';
  static String get quickLogSetNoteHint =>
      _zh ? '记录本组感受，如：力竭 / 稳 / 借力' : 'How it felt (e.g. clean, RPE 9, drop)';
  static String quickLogLastSession(String summary) =>
      _zh ? '上次：$summary' : 'Last: $summary';
  static String quickLogSummary(int exCount, int setCount) =>
      _zh ? '$exCount 个动作 · $setCount 组' : '$exCount exercises · $setCount sets';
  static String get quickLogDeleteExercise => _zh ? '移除该动作' : 'Remove exercise';
  static String get quickLogSearchHint =>
      _zh ? '搜索动作（支持中文俗称，如 卧推 / 夹胸 / 臀推）' : 'Search exercises…';
  static String quickLogRecommendedTitle(String focusTitle) =>
      _zh ? '今日推荐 · $focusTitle' : 'Suggested today · $focusTitle';
  static String get quickLogRecentTitle => _zh ? '最近练过' : 'Recently logged';
  static String get quickLogAllExercises => _zh ? '全部动作' : 'All exercises';
  static String quickLogAddToToday(int defaultSets) =>
      _zh ? '加入今日训练（默认 $defaultSets 组）' : 'Add to today ($defaultSets sets)';
  static String get quickLogInToday => _zh ? '今日已记 · 编辑组数' : 'Logged today · Edit sets';
  static String get quickLogDefaultSetsLabel => _zh ? '即时记录默认组数' : 'Quick-log default sets';
  static String get quickLogDefaultSetsHint =>
      _zh ? '点击搜索结果加入今日训练时自动生成的组数' : 'Number of sets created when quick-adding an exercise';
  static String quickLogSetsUnit(int n) => _zh ? '$n 组' : '$n sets';

  // Nutrition module master switch
  static String get nutritionModuleTitle => _zh ? '饮食记录与营养' : 'Nutrition & diet module';
  static String get nutritionModuleHint => _zh
      ? '关闭后不展示饮食标签页、首页卡片、饮食工具与统计，也不启用相关提醒'
      : 'Hide nutrition tab, home card, diet tools & reports, and disable reminders';

  // Smart quick-create & bulk exercise import
  static String quickCreateAction(String name) =>
      _zh ? '快捷新建「$name」并加入' : 'Quick-create "$name" & add';
  static String quickCreateOnly(String name) =>
      _zh ? '快捷新建「$name」' : 'Quick-create "$name"';
  static String quickCreateAutoHint(String muscle, String equip) =>
      _zh ? '已自动识别：$muscle · $equip（点右侧可微调）' : 'Auto-detected: $muscle · $equip';
  static String quickCreateAutoTag(String muscle, String equip) =>
      _zh ? '自动识别：$muscle · $equip' : 'Auto: $muscle · $equip';
  static String get quickCreateCustomize => _zh ? '微调属性' : 'Customize';
  static String quickCreateCreatedToast(String name) =>
      _zh ? '已新建并加入：$name' : 'Created & added: $name';
  static String quickCreateSavedToast(String name) =>
      _zh ? '已新建动作：$name' : 'Created exercise: $name';
  static String get bulkImportTitle => _zh ? '批量添加动作' : 'Bulk add exercises';
  static String get bulkImportChip => _zh ? '批量添加' : 'Bulk add';
  static String get bulkImportSubtitle =>
      _zh ? '每行输入或粘贴一个动作名，自动识别部位与器械' : 'One exercise per line — muscles & equipment auto-detected';
  static String get bulkImportHint => _zh
      ? '每行一个动作，例如：\n悍马机上斜推胸\n蝴蝶机反向飞鸟\n单臂绳索侧平举\n下斜板卷腹'
      : 'One per line, e.g.:\nHammer Incline Press\nReverse Pec Deck\nCable Lateral Raise';
  static String get bulkImportFillSample => _zh ? '填入示例' : 'Fill sample';
  static String get bulkImportSampleText => _zh
      ? '悍马机窄距推胸\n单臂绳索高位下拉\n坐姿器械反向飞鸟\n斜板负重卷腹'
      : 'Hammer Close-Grip Press\nSingle-Arm Cable Pulldown\nSeated Reverse Fly\nDecline Weighted Crunch';
  static String bulkImportPreviewTitle(int n) =>
      _zh ? '识别预览（$n 个可导入）' : 'Preview ($n ready to import)';
  static String get bulkImportTapToAdjust =>
      _zh ? '点击部位或器械标签可快速切换' : 'Tap muscle or gear chip to adjust';
  static String get bulkImportDuplicateBadge => _zh ? '库中已有' : 'Exists';
  static String get bulkImportAlsoLogToday =>
      _zh ? '导入后同时加入今日训练' : 'Also add to today’s log';
  static String bulkImportSubmit(int n) =>
      _zh ? '一键导入 $n 个动作' : 'Import $n exercises';
  static String get bulkImportEmptyAction =>
      _zh ? '请先输入至少一个新动作名称' : 'Enter at least one new exercise';
  static String bulkImportDoneToast(int n) =>
      _zh ? '已成功导入 $n 个自定义动作' : 'Imported $n custom exercises';
  static String bulkImportDoneAndLoggedToast(int n) =>
      _zh ? '已导入 $n 个动作并加入今日训练' : 'Imported $n exercises & logged today';

  static bool get isZh => _zh;

  static String get updatePromptTitle =>
      _zh ? '发现新版本' : 'New version available';
  static String get updatePromptSubtitle => _zh
      ? '检测到 GitHub 有新的安装包发布，可立即更新或跳过。'
      : 'A newer GitHub release APK is ready to install or skip.';
  static String get updateLater => _zh ? '稍后再说' : 'Later';
  static String get skipThisVersion => _zh ? '跳过此版本' : 'Skip version';
  static String skippedVersionToast(String tag) =>
      _zh ? '已跳过版本 $tag' : 'Skipped $tag';

  static String get exercisePacksChip => _zh ? '动作包' : 'Packs';
  static String get exercisePacksTitle => _zh ? '扩展动作包' : 'Exercise Packs';
  static String get exercisePacksHint => _zh
      ? '按需开启或关闭专项动作包；关闭后已记录的历史训练仍会保留。'
      : 'Toggle specialty exercise packs on or off. Existing workout history is always preserved.';
  static String exercisePacksSummary(int enabledCount, int totalExercises) =>
      _zh
          ? '已启用 $enabledCount 个包 · 共 $totalExercises 个扩展动作'
          : '$enabledCount packs active · $totalExercises pack exercises';
  static String exercisePackCount(int n) =>
      _zh ? '$n 个动作' : '$n exercises';

  static String get referenceArtLabel => _zh ? '参考示意图' : 'Reference';
  static String get referenceArtShort => _zh ? '示意' : 'Ref';

  // Quick log PR & smart recommendations (v2.4.6)
  static String get prBadge => 'PR';
  static String quickLogNewPrToast(String name) =>
      _zh ? '新纪录！$name 刷新个人最佳' : 'New PR! $name personal best';
  static String smartRecReason(
    String muscle,
    double weeklySets, {
    required bool recovered,
    bool effective = false,
  }) {
    final numStr = effective && weeklySets != weeklySets.roundToDouble()
        ? weeklySets.toStringAsFixed(1)
        : '${weeklySets.round()}';
    if (_zh) {
      final unit = effective ? '等效组' : '组';
      final status = recovered ? '已恢复' : '可安排';
      return '$muscle本周 $numStr $unit · $status';
    }
    final unit = effective ? 'eff. sets' : 'sets';
    final status = recovered ? 'Recovered' : 'Ready';
    return '$muscle $numStr $unit this wk · $status';
  }
  static String get autoProgressAppliedHint =>
      _zh ? '已按自动加重规则预填目标' : 'Pre-filled with auto-progression';

  // Weekly muscle volume card (v2.4.6)
  static String get weeklyMuscleTitle => _zh ? '本周肌群进度' : 'Weekly Muscle Volume';
  static String weeklyMuscleRange(int minSets, int maxSets) =>
      _zh ? '目标 $minSets–$maxSets 组' : 'Target $minSets–$maxSets sets';
  static String get weeklyMuscleTargetLabel =>
      _zh ? '每周肌群目标下限' : 'Weekly muscle set target';
  static String get weeklyMuscleTargetHint => _zh
      ? '首页「本周肌群进度」与智能推荐使用的每周目标组数下限（默认 10 组，达标区间 10–20 组）。'
      : 'Lower bound of weekly sets per muscle for progress bars & recommendations (default 10, range 10–20).';
  static String get weeklyMuscleShowMore => _zh ? '展开全部' : 'Show all';
  static String get weeklyMuscleShowLess => _zh ? '收起' : 'Less';

  // Safer updates: SHA-256 + pre-update backup (v2.4.6)
  static String get sha256Verifying =>
      _zh ? '正在校验安装包完整性 (SHA-256)…' : 'Verifying APK checksum (SHA-256)…';
  static String get sha256MismatchError => _zh
      ? '安装包 SHA-256 校验未通过，文件可能损坏或被篡改，已自动删除，请重新下载。'
      : 'APK SHA-256 checksum mismatch. File was deleted for safety; please retry.';
  static String get preUpdateBackupHint =>
      _zh ? '更新前已自动备份训练数据' : 'Training data backed up before update';
  static String get sha256VerifiedHint =>
      _zh ? '已通过 SHA-256 完整性校验' : 'SHA-256 integrity verified';

  // Dumbbell & barbell weight clarity (v2.4.7)
  static String dumbbellWeightCol(String unit) =>
      _zh ? '单只 ($unit)' : 'PER DB ($unit)';
  static String barbellWeightCol(String unit) =>
      _zh ? '含杠 ($unit)' : 'TOTAL ($unit)';
  static String dumbbellInputTitle(String unit) =>
      _zh ? '单只哑铃重量 ($unit)' : 'Single Dumbbell ($unit)';
  static String dumbbellInputHint({required bool paired}) {
    if (_zh) {
      return paired
          ? '请输入单只哑铃重量（容量自动按一对 ×2 计算）'
          : '请输入单只哑铃重量（照哑铃上刻的数字填）';
    }
    return paired
        ? 'Enter weight of ONE dumbbell (volume counts ×2)'
        : 'Enter weight of ONE dumbbell';
  }
  static String get dumbbellBannerPaired =>
      _zh ? '哑铃 · 填单只（容量自动 ×2）' : 'Dumbbell · per hand (×2 volume)';
  static String get dumbbellBannerSingle =>
      _zh ? '哑铃 · 填单只（点此开启一对 ×2）' : 'Dumbbell · per hand (tap for ×2)';
  static String barbellInputTitle(String unit) =>
      _zh ? '杠铃含杠总重 ($unit)' : 'Barbell Total ($unit)';
  static String barbellInputHint(String barText) => _zh
      ? '当前杆重 $barText · 可直接输总重或切换按单边片重换算'
      : 'Bar $barText · enter total or switch to per-side plates';
  static String get barbellModeTotal => _zh ? '含杠总重' : 'Total';
  static String get barbellModePerSide => _zh ? '单边片重' : 'Per side';
  static String barbellPerSidePreview(String total, String bar, String side) =>
      _zh ? '= $total（杆 $bar + 单边 $side × 2）' : '= $total (bar $bar + $side × 2)';
  static String barbellBanner(String barText, String sideText) =>
      _zh ? '含杠总重 · 杆 $barText + 单边 $sideText' : 'Total · Bar $barText + $sideText/side';
  static String barbellBannerBarOnly(String barText) =>
      _zh ? '含杠总重 · 当前杆重 $barText（点此修改）' : 'Total · Bar $barText (tap to edit)';

  // Effective stimulus volume algorithm (v2.4.8)
  static String get volumeModeEffective => _zh ? '等效组' : 'Effective';
  static String get volumeModeRaw => _zh ? '原始组' : 'Raw sets';
  static String effectiveVolumeCaptionLbm(String lbmText) =>
      _zh ? '按瘦体重 $lbmText 与动作/重量加权' : 'Weighted by $lbmText lean mass & load';
  static String effectiveVolumeCaptionWeight(String weightText) =>
      _zh ? '按体重 $weightText 与动作/重量加权' : 'Weighted by $weightText body weight & load';
  static String get effectiveVolumeCaptionDefault =>
      _zh ? '按动作复合度与重量强度加权（记录体重/体脂更精准）' : 'Weighted by movement & load (log weight/BF for accuracy)';
  static String get effectiveVolumeTitle =>
      _zh ? '按体重/重量计算等效有效组' : 'Effective volume weighting';
  static String get effectiveVolumeHint => _zh
      ? '结合体重/体脂（瘦体重）、动作复合系数、实际重量与努力度折算等效组数；历史记录自动重算，可在首页随时切换回原始组数。'
      : 'Weights sets by lean mass, compound factor, load, and effort. Applies to past logs automatically.';

  // AI Cloud Drive overwrite export (v2.4.9)
  static String get aiCloudExportTitle =>
      _zh ? '导出 AI 训练档案（谷歌云盘）' : 'AI Cloud Export (Google Drive)';
  static String get aiCloudExportSubtitle => _zh
      ? '导出为可读 Markdown 并默认覆盖旧文件，供 Gemini / ChatGPT 直接读取分析'
      : 'Overwrite one Markdown archive on Google Drive for Gemini & ChatGPT';
  static String get aiCloudExportGuide => _zh
      ? '首次点击下方按钮，在系统文件选择器左侧选「Google 云端硬盘」并保存 FitMane-AI-Summary.md。之后每次导出都会直接覆盖同一份旧文件，在 Gemini 中 @Google Drive 即可直接读取最新训练与体成分数据。'
      : 'Pick Google Drive in the system file picker to save FitMane-AI-Summary.md once. Future exports overwrite the exact same file so Gemini and ChatGPT always read your latest logs.';
  static String get aiCloudPickAndExport =>
      _zh ? '选择谷歌云盘位置并导出' : 'Choose Google Drive File & Export';
  static String get aiCloudOverwriteNow =>
      _zh ? '立即覆盖更新到云盘' : 'Overwrite Cloud File Now';
  static String get aiCloudChangeFile =>
      _zh ? '重新选择云盘位置' : 'Change Cloud File';
  static String get aiCloudAutoSync =>
      _zh ? '训练记录变动后自动覆盖更新' : 'Auto-overwrite after workouts';
  static String get aiCloudAutoSyncHint => _zh
      ? '新增或修改训练记录后，自动将最新档案覆盖写入已绑定的云盘文件。'
      : 'Automatically overwrite the bound cloud file shortly after logging workouts.';
  static String get aiCloudCopyMarkdown =>
      _zh ? '复制 Markdown 文本' : 'Copy Markdown';
  static String get aiCloudShareFile =>
      _zh ? '通过系统分享 .md 文件' : 'Share .md File';
  static String get aiCloudExportSuccess =>
      _zh ? '已成功覆盖更新云盘 AI 训练档案' : 'Updated AI training archive in cloud';
  static String get aiCloudExportFailed => _zh
      ? '写入云盘失败，请重新选择云盘位置或改用「分享 .md 文件」'
      : 'Could not overwrite file. Please re-pick the file or share .md directly.';
  static String get aiCloudCopiedToast =>
      _zh ? '已复制完整 AI 训练档案到剪贴板' : 'Copied AI training archive to clipboard';
  static String get aiCloudNotBound =>
      _zh ? '尚未绑定云盘文件' : 'No cloud file bound yet';
  static String aiCloudLastSynced(String time) =>
      _zh ? '上次覆盖更新：$time' : 'Last updated: $time';
  static String get aiCloudNeverSynced =>
      _zh ? '尚未同步' : 'Not synced yet';

  // Multi-stage drop-set chains (v2.4.10)
  static String get dropSetAddButton => _zh ? '递减大组' : 'Drop set';
  static String get dropSetBuilderTitle => _zh ? '添加递减大组' : 'Add Drop-Set Chain';
  static String get dropSetEditTitle => _zh ? '编辑递减大组' : 'Edit Drop-Set Chain';
  static String get dropSetBuilderSubtitle => _zh
      ? '配置每大组内的连续递减阶段（如 6→4→2kg 各 12 次），自动合并算 1 大组'
      : 'Configure consecutive drop stages per set (e.g. 6→4→2kg × 12) counted as 1 set';
  static String dropSetStageLabel(int n) => _zh ? '第 $n 阶' : 'Stage $n';
  static String get dropSetAddStage => _zh ? '添加一阶' : 'Add stage';
  static String get dropSetBatchCount => _zh ? '一次添加大组数' : 'Number of sets to add';
  static String dropSetCountChip(int n) => _zh ? '$n 组' : '$n sets';
  static String dropSetSummary(int totalReps, String volText, {bool paired = false}) => _zh
      ? '每大组共 $totalReps 次 · 单组容量 $volText${paired ? "（双持×2）" : ""}'
      : '$totalReps reps/set · $volText vol${paired ? " (×2)" : ""}';
  static String dropSetConfirmAdd(int count) =>
      _zh ? '添加 $count 个递减大组' : 'Add $count Drop ${count == 1 ? "Set" : "Sets"}';
  static String get dropSetConfirmSave => _zh ? '保存递减大组' : 'Save Drop Set';
  static String dropSetRowSummary(int totalReps) =>
      _zh ? '共 $totalReps 次 · 点击编辑各阶' : '$totalReps total reps · tap to edit';
  static String dropSetDumbbellHint(bool paired) => _zh
      ? (paired ? '哑铃请填单只重量（容量自动×2）' : '哑铃请填单只重量')
      : (paired ? 'Enter per-dumbbell weight (volume ×2)' : 'Enter per-dumbbell weight');
}
