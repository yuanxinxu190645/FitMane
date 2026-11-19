import '../l10n/catalog_zh.dart';
import '../models/exercise.dart';

const Map<String, List<String>> _kCnEquip = {
  '哑铃': ['dumbbell'],
  '杠铃': ['barbell'],
  '绳索': ['cable'],
  '龙门架': ['cable'],
  '器械': ['machine', 'lever', 'sled'],
  '史密斯': ['smith'],
  '壶铃': ['kettlebell'],
  '弹力带': ['band'],
  '徒手': ['bodyweight'],
  '自重': ['bodyweight'],
  '固定': ['machine', 'lever'],
};

const Map<String, List<String>> _kCnMovements = {
  '上斜卧推': ['incline bench press', 'incline dumbbell press', 'incline press'],
  '下斜卧推': ['decline bench press', 'decline press'],
  '平板卧推': ['bench press'],
  '卧推': ['bench press'],
  '推胸': ['chest press', 'bench press'],
  '夹胸': ['fly', 'pec deck', 'crossover', 'chest fly'],
  '蝴蝶机': ['pec deck', 'machine fly', 'chest fly'],
  '飞鸟': ['fly'],
  '俯卧撑': ['push-up', 'push up', 'pushup'],
  '双杠臂屈伸': ['dip'],
  '臂屈伸': ['dip', 'triceps extension', 'skullcrusher'],
  '高位下拉': ['lat pulldown', 'pulldown'],
  '直臂下压': ['straight arm pulldown', 'pullover'],
  '下拉': ['pulldown', 'pushdown'],
  '引体向上': ['pull-up', 'pull up', 'chin-up', 'chin up'],
  '引体': ['pull-up', 'pull up', 'chin-up', 'chin up'],
  '俯身划船': ['bent over row', 'bent-over row', 'dumbbell row', 'barbell row'],
  '坐姿划船': ['seated row', 'cable row', 'machine row'],
  '划船': ['row'],
  '面拉': ['face pull'],
  '脸拉': ['face pull'],
  '耸肩': ['shrug'],
  '山羊挺身': ['hyperextension', 'back extension'],
  '罗马尼亚硬拉': ['romanian deadlift'],
  '相扑硬拉': ['sumo deadlift'],
  '直腿硬拉': ['stiff-leg deadlift', 'stiff leg deadlift'],
  '硬拉': ['deadlift'],
  '保加利亚': ['bulgarian split squat'],
  '高脚杯': ['goblet squat'],
  '哈克深蹲': ['hack squat'],
  '前蹲': ['front squat'],
  '深蹲': ['squat'],
  '箭步蹲': ['lunge'],
  '弓步': ['lunge'],
  '倒蹬': ['leg press'],
  '腿举': ['leg press'],
  '腿屈伸': ['leg extension'],
  '腿弯举': ['leg curl'],
  '臀推': ['hip thrust', 'glute bridge'],
  '臀桥': ['glute bridge', 'hip thrust'],
  '提踵': ['calf raise'],
  '阿诺德': ['arnold press'],
  '推肩': ['shoulder press', 'overhead press', 'military press', 'arnold press'],
  '推举': ['overhead press', 'shoulder press', 'military press', 'arnold press'],
  '侧平举': ['lateral raise'],
  '前平举': ['front raise'],
  '后束': ['rear delt', 'reverse fly', 'face pull'],
  '锤式': ['hammer curl'],
  '牧师凳': ['preacher curl'],
  '集中弯举': ['concentration curl'],
  '弯举': ['curl'],
  '碎颅': ['lying triceps extension', 'skullcrusher'],
  '绳索下压': ['triceps pushdown', 'pushdown'],
  '下压': ['pushdown'],
  '二头': ['biceps', 'curl'],
  '三头': ['triceps'],
  '卷腹': ['crunch'],
  '仰卧起坐': ['sit-up', 'sit up'],
  '悬垂举腿': ['hanging leg raise', 'leg raise'],
  '举腿': ['leg raise'],
  '平板支撑': ['plank'],
  '俄罗斯转体': ['russian twist'],
  '腹肌轮': ['ab wheel', 'rollout'],
  '农夫行走': ['farmer'],
  '跑步': ['run', 'jog', 'treadmill'],
  '跳绳': ['jump rope', 'skipping'],
  '开合跳': ['jumping jack'],
  '波比': ['burpee'],
  '划船机': ['rowing'],
  '椭圆机': ['elliptical'],
  '爬楼': ['stair'],
  '单车': ['cycling', 'bike'],
  '拉伸': ['stretch'],
};

final RegExp _kCjkPattern = RegExp(r'[\u4e00-\u9fff]');

bool hasCjk(String s) => _kCjkPattern.hasMatch(s);

/// Matches Chinese queries against localized catalog titles and common gym slang.
bool matchesChineseExerciseQuery(String rawQuery, Exercise e) {
  final plain = rawQuery.trim().toLowerCase();
  if (plain.isEmpty || !hasCjk(plain)) return false;

  final zhTitle = (kExerciseNameZh[e.id] ?? '').toLowerCase();
  final tokens = plain.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (tokens.isNotEmpty && zhTitle.isNotEmpty && tokens.every(zhTitle.contains)) {
    return true;
  }

  final requiredGroups = <List<String>>[];
  var remaining = plain.replaceAll(RegExp(r'\s+'), '');

  for (final entry in _kCnEquip.entries) {
    if (remaining.contains(entry.key)) {
      requiredGroups.add(entry.value);
      remaining = remaining.replaceAll(entry.key, '');
    }
  }

  final sortedMovements = _kCnMovements.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));
  for (final entry in sortedMovements) {
    if (remaining.contains(entry.key)) {
      requiredGroups.add(entry.value);
      remaining = remaining.replaceAll(entry.key, '');
      break;
    }
  }

  if (requiredGroups.isEmpty) return false;
  if (remaining.isNotEmpty && hasCjk(remaining)) {
    // Allow leftover general modifiers if at least movement matched, unless strict unmatched CJK
    var matchedAnother = false;
    for (final entry in sortedMovements) {
      if (remaining.contains(entry.key)) {
        requiredGroups.add(entry.value);
        matchedAnother = true;
        break;
      }
    }
    if (!matchedAnother && zhTitle.isNotEmpty && !zhTitle.contains(remaining)) {
      // Fall back to checking if zhTitle contains the original tokens directly above
      if (requiredGroups.length < 2) return false;
    }
  }

  final haystack = '${e.name} ${e.equipment} ${e.primary} ${e.aliases.join(' ')}'.toLowerCase();
  return requiredGroups.every((group) => group.any(haystack.contains));
}
