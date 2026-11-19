import '../catalog/gym_pack.dart';
import '../l10n/catalog_zh.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';

const Map<String, List<String>> _kCnEquip = {
  '哑铃': ['dumbbell'],
  '杠铃': ['barbell'],
  '曲杆': ['barbell', 'ez'],
  'ez杆': ['barbell', 'ez'],
  'w杆': ['barbell', 'ez'],
  '绳索': ['cable'],
  '龙门架': ['cable'],
  '滑轮': ['cable'],
  '器械': ['machine', 'lever', 'sled'],
  '固定': ['machine', 'lever'],
  '挂片': ['machine', 'plate-loaded', 'hammer'],
  '插片': ['machine'],
  '史密斯': ['smith'],
  '悍马机': ['hammer', 'machine'],
  '悍马': ['hammer', 'machine'],
  '蝴蝶机': ['pec deck', 'machine', 'fly'],
  '壶铃': ['kettlebell'],
  '弹力带': ['band'],
  '阻力带': ['band'],
  '徒手': ['bodyweight'],
  '自重': ['bodyweight'],
  '吊环': ['rings'],
  '地雷管': ['landmine'],
  '罗马椅': ['roman chair', 'hyperextension'],
};

const Map<String, List<String>> _kCnModifiers = {
  '坐姿': ['seated'],
  '站姿': ['standing'],
  '仰卧': ['lying', 'bench'],
  '俯卧': ['lying', 'prone', 'chest-supported'],
  '俯身': ['bent-over', 'bent over'],
  '上斜': ['incline'],
  '下斜': ['decline'],
  '斜板': ['decline', 'incline', 'bench'],
  '平板': ['flat', 'bench'],
  '单臂': ['single-arm', 'one-arm', 'single arm', 'one arm', '单手', '单臂'],
  '单手': ['single-arm', 'one-arm', 'single arm', '单臂', '单手'],
  '单腿': ['single-leg', 'one-leg', 'single leg', '单脚', '单腿'],
  '单脚': ['single-leg', 'one-leg', '单腿', '单脚'],
  '双臂': ['double', 'both'],
  '宽握': ['wide-grip', 'wide grip', 'wide'],
  '宽距': ['wide'],
  '窄握': ['close-grip', 'close grip', 'narrow'],
  '窄距': ['close-grip', 'narrow'],
  '反握': ['reverse-grip', 'underhand'],
  '反手': ['underhand', 'reverse-grip', 'chin'],
  '对握': ['neutral-grip', 'neutral grip', 'hammer', 'v-bar'],
  '胸托': ['chest-supported', 'supported'],
  '高位': ['high'],
  '低位': ['low'],
  '中位': ['mid'],
  '背后': ['behind-the-back', 'behind the back'],
  '颈后': ['behind', 'overhead'],
  '过顶': ['overhead'],
  '跪姿': ['kneeling'],
  '负重': ['weighted'],
  '助力': ['assisted'],
  '辅助': ['assisted'],
  '垫脚跟': ['heel-elevated'],
};

const Map<String, List<String>> _kCnMuscles = {
  '上胸': ['upper chest', 'incline'],
  '下胸': ['lower chest', 'decline'],
  '胸部': ['chest', 'pec'],
  '胸肌': ['chest', 'pec'],
  '胸': ['chest', 'pec'],
  '背阔': ['lat', 'back'],
  '上背': ['upper back', 'back', 'trapezius'],
  '背部': ['back'],
  '背': ['back'],
  '后束': ['rear delt', 'reverse', 'face pull', 'shoulders'],
  '中束': ['lateral raise', 'shoulders'],
  '前束': ['front raise', 'overhead press', 'shoulders'],
  '肩部': ['shoulders', 'shoulder'],
  '三角肌': ['shoulders', 'delt'],
  '肩': ['shoulders', 'shoulder'],
  '二头肌': ['biceps', 'curl'],
  '二头': ['biceps', 'curl'],
  '三头肌': ['triceps'],
  '三头': ['triceps'],
  '前臂': ['forearm', 'wrist'],
  '小臂': ['forearm', 'wrist'],
  '斜方肌': ['trapezius', 'shrug'],
  '斜方': ['trapezius', 'shrug'],
  '腹斜': ['obliques', 'twist'],
  '侧腹': ['obliques', 'side bend'],
  '人鱼线': ['obliques'],
  '腹肌': ['abdomen', 'ab', 'crunch'],
  '腹部': ['abdomen'],
  '核心': ['abdomen', 'plank'],
  '臀部': ['glutes', 'glute'],
  '臀': ['glutes', 'glute', 'hip'],
  '股四': ['quads'],
  '腘绳': ['hamstrings'],
  '小腿': ['calves', 'calf'],
  '下背': ['lowerback', 'lower back', 'hyperextension'],
  '大腿': ['quads', 'hamstrings', 'leg'],
};

const Map<String, List<String>> _kCnMovements = {
  '推胸': ['chest press', 'bench press'],
  '卧推': ['bench press'],
  '夹胸': ['fly', 'pec deck', 'crossover', 'chest fly'],
  '反向飞鸟': ['reverse fly', 'rear delt fly', 'pec deck'],
  '飞鸟': ['fly'],
  '俯卧撑': ['push-up', 'push up', 'pushup'],
  '双杠臂屈伸': ['dip', 'chest dip'],
  '臂屈伸': ['dip', 'triceps extension', 'skullcrusher', 'skull crusher'],
  '直臂下压': ['straight arm pulldown', 'straight-arm pulldown', 'pullover'],
  '高位下拉': ['lat pulldown', 'pulldown'],
  '下拉': ['pulldown', 'pushdown'],
  '引体向上': ['pull-up', 'pull up', 'chin-up', 'chin up'],
  '引体': ['pull-up', 'pull up', 'chin-up', 'chin up'],
  't杠划船': ['t-bar row', 't bar row'],
  '梅多斯': ['meadows row'],
  '划船': ['row'],
  '面拉': ['face pull'],
  '脸拉': ['face pull'],
  '耸肩': ['shrug'],
  '山羊挺身': ['hyperextension', 'back extension'],
  '罗马尼亚硬拉': ['romanian deadlift', 'rdl'],
  '相扑硬拉': ['sumo deadlift'],
  '直腿硬拉': ['stiff-leg deadlift', 'stiff leg deadlift', 'romanian deadlift'],
  '早安': ['good morning'],
  '硬拉': ['deadlift'],
  '保加利亚': ['bulgarian split squat'],
  '高脚杯': ['goblet squat'],
  '哈克深蹲': ['hack squat'],
  '哈克': ['hack squat'],
  '钟摆深蹲': ['pendulum squat'],
  '钟摆': ['pendulum'],
  'v蹲': ['v-squat', 'v squat'],
  '腰带深蹲': ['belt squat'],
  '西斯深蹲': ['sissy squat'],
  '相扑深蹲': ['sumo squat'],
  '前蹲': ['front squat'],
  '深蹲': ['squat'],
  '分腿蹲': ['split squat', 'bulgarian'],
  '箭步蹲': ['lunge'],
  '弓步': ['lunge'],
  '倒蹬': ['leg press'],
  '蹬腿': ['leg press'],
  '腿举': ['leg press'],
  '腿屈伸': ['leg extension'],
  '腿弯举': ['leg curl'],
  '夹腿': ['hip adduction', 'adduction'],
  '内收': ['adduction'],
  '分腿机': ['hip abduction', 'abduction'],
  '髋外展': ['hip abduction', 'abduction'],
  '后踢': ['kickback'],
  '臀推': ['hip thrust', 'glute bridge'],
  '臀桥': ['glute bridge', 'hip thrust'],
  '提踵': ['calf raise', 'calf press'],
  '阿诺德': ['arnold press'],
  '推肩': ['shoulder press', 'overhead press', 'military press', 'arnold press'],
  '推举': ['overhead press', 'shoulder press', 'military press', 'arnold press'],
  '侧平举': ['lateral raise'],
  '前平举': ['front raise'],
  '直立划船': ['upright row'],
  '牧师凳': ['preacher curl'],
  '集中弯举': ['concentration curl'],
  '锤式': ['hammer curl'],
  '弯举': ['curl'],
  '碎颅': ['lying triceps extension', 'skullcrusher', 'skull crusher'],
  '下压': ['pushdown'],
  '卷腹': ['crunch'],
  '仰卧起坐': ['sit-up', 'sit up'],
  '抬腿': ['leg raise'],
  '提膝': ['knee raise'],
  '举腿': ['leg raise'],
  '平板支撑': ['plank'],
  '俄罗斯转体': ['russian twist'],
  '腹肌轮': ['ab wheel', 'rollout'],
  '农夫行走': ['farmer'],
  '战绳': ['battle rope'],
  '动感单车': ['spin', 'bike'],
  '单车': ['cycling', 'bike'],
  '跑步': ['run', 'jog', 'treadmill'],
  '爬坡': ['incline', 'treadmill', 'walk'],
  '爬楼': ['stair'],
  '楼梯机': ['stair'],
  '跳绳': ['jump rope', 'skipping'],
  '开合跳': ['jumping jack'],
  '波比': ['burpee'],
  '划船机': ['rowing'],
  '椭圆机': ['elliptical'],
  '拉伸': ['stretch'],
};

const Map<String, String> _kPinyinInitials = {
  'wt': '卧推',
  'glwt': '杠铃卧推',
  'ylwt': '哑铃卧推',
  'sxwt': '上斜卧推',
  'xxwt': '下斜卧推',
  'tx': '推胸',
  'hmj': '悍马机',
  'sms': '史密斯',
  'hdj': '蝴蝶机',
  'jx': '夹胸',
  'lmj': '龙门架',
  'fn': '飞鸟',
  'fxfn': '反向飞鸟',
  'fwc': '俯卧撑',
  'bqs': '臂屈伸',
  'gwxl': '高位下拉',
  'xl': '下拉',
  'zby': '直臂下压',
  'ytxs': '引体向上',
  'yt': '引体',
  'hc': '划船',
  'zzhc': '坐姿划船',
  'fshc': '俯身划船',
  'dbhc': '单臂划船',
  'ylhc': '哑铃划船',
  'ml': '面拉',
  'sj': '耸肩',
  'syts': '山羊挺身',
  'sd': '深蹲',
  'glsd': '杠铃深蹲',
  'ylsd': '哑铃深蹲',
  'qd': '前蹲',
  'hksd': '哈克深蹲',
  'zbsd': '钟摆深蹲',
  'bjly': '保加利亚',
  'dd': '倒蹬',
  'tj': '腿举',
  'tqs': '腿屈伸',
  'twj': '腿弯举',
  'ht': '臀推',
  'hq': '臀桥',
  'jt': '夹腿',
  'ftj': '分腿机',
  'yl': '硬拉',
  'gryl': '罗马尼亚硬拉',
  'lmny': '罗马尼亚硬拉',
  'tz': '提踵',
  'tjian': '推肩',
  'yltj': '哑铃推肩',
  'cpj': '侧平举',
  'qpj': '前平举',
  'wj': '弯举',
  'ylwj': '哑铃弯举',
  'glwj': '杠铃弯举',
  'msd': '牧师凳',
  'xy': '下压',
  'jf': '卷腹',
  'pbzc': '平板支撑',
  'ywqz': '仰卧起坐',
  'elzt': '俄罗斯转体',
  'nf': '农夫行走',
  'pb': '跑步',
  'ltj': '楼梯机',
  'dc': '单车',
  'ts': '跳绳',
};

final RegExp _kCjkPattern = RegExp(r'[\u4e00-\u9fff]');
final RegExp _kPinyinPattern = RegExp(r'^[a-z]{2,6}$');

bool hasCjk(String s) => _kCjkPattern.hasMatch(s);

String _cjkOnly(String s) {
  final sb = StringBuffer();
  for (final code in s.runes) {
    if (code >= 0x4e00 && code <= 0x9fff) sb.writeCharCode(code);
  }
  return sb.toString();
}

bool _isSubsequence(String needle, String haystack) {
  if (needle.isEmpty || haystack.isEmpty) return false;
  var ni = 0;
  for (var hi = 0; hi < haystack.length && ni < needle.length; hi++) {
    if (haystack[hi] == needle[ni]) ni++;
  }
  return ni == needle.length;
}

final List<(String key, List<String> terms)> _kAllCnChunks = () {
  final entries = <String, List<String>>{};
  for (final map in [_kCnEquip, _kCnModifiers, _kCnMuscles, _kCnMovements]) {
    for (final e in map.entries) {
      entries[e.key] = [e.key, ...e.value];
    }
  }
  final list = [for (final e in entries.entries) (e.key, e.value)];
  list.sort((a, b) => b.$1.length.compareTo(a.$1.length));
  return list;
}();

/// Matches Chinese queries (including segmented tokens, ordered CJK subsequences,
/// and common Chinese fitness pinyin initials when in Chinese locale).
bool matchesChineseExerciseQuery(String rawQuery, Exercise e) {
  final plain = rawQuery.trim().toLowerCase();
  if (plain.isEmpty) return false;

  if (!hasCjk(plain)) {
    if (appLanguage.startsWith('zh') && _kPinyinPattern.hasMatch(plain)) {
      final mapped = _kPinyinInitials[plain];
      if (mapped != null) return matchesChineseExerciseQuery(mapped, e);
    }
    return false;
  }

  final zhTitle = (kExerciseNameZh[e.id] ?? kGymPackNameZh[e.id] ?? e.name).toLowerCase();
  final zhHaystack = '$zhTitle ${e.aliases.join(' ')}'.toLowerCase();

  // Path A: Direct / whitespace-split token match on Chinese title & aliases.
  final tokens = plain.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (tokens.isNotEmpty && tokens.every(zhHaystack.contains)) {
    return true;
  }

  final enHaystack = '${e.name} ${e.equipment} ${e.primary} ${e.aliases.join(' ')}'.toLowerCase();
  final combinedHaystack = '$zhHaystack $enHaystack';

  // Path B: Ordered Chinese character subsequence (3+ CJK chars), e.g. "坐姿划船" -> "坐姿器械划船".
  final cjkChars = _cjkOnly(plain);
  if (cjkChars.length >= 3 && _isSubsequence(cjkChars, zhHaystack)) {
    return true;
  }

  // Path C: Longest-first Chinese semantic chunk segmentation (equip + modifier + muscle + movement).
  final requiredGroups = <List<String>>[];
  var remaining = plain.replaceAll(RegExp(r'\s+'), '');

  while (remaining.isNotEmpty) {
    var matched = false;
    for (final (chunk, terms) in _kAllCnChunks) {
      if (remaining.startsWith(chunk)) {
        requiredGroups.add(terms);
        remaining = remaining.substring(chunk.length);
        matched = true;
        break;
      }
    }
    if (!matched) {
      // Skip non-matched bridge words/digits if we still find known chunks further ahead.
      var foundAhead = false;
      for (var idx = 1; idx < remaining.length; idx++) {
        final sub = remaining.substring(idx);
        for (final (chunk, _) in _kAllCnChunks) {
          if (sub.startsWith(chunk)) {
            final skipped = remaining.substring(0, idx);
            if (hasCjk(skipped)) requiredGroups.add([skipped]);
            remaining = sub;
            foundAhead = true;
            break;
          }
        }
        if (foundAhead) break;
      }
      if (!foundAhead) {
        if (hasCjk(remaining)) requiredGroups.add([remaining]);
        remaining = '';
      }
    }
  }

  if (requiredGroups.isEmpty) return false;
  return requiredGroups.every((group) => group.any(combinedHaystack.contains));
}
