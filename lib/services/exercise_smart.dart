import '../catalog/exercise_catalog.dart' show kEquipment;
import 'exercise_match.dart' show guessMuscle;

class InferredExerciseMeta {
  const InferredExerciseMeta({
    required this.primary,
    required this.secondary,
    required this.equipment,
    required this.mode,
    required this.art,
  });

  final String primary;
  final List<String> secondary;
  final String equipment;
  final String mode;
  final String art;
}

class BulkParsedExercise {
  const BulkParsedExercise({
    required this.name,
    required this.meta,
  });

  final String name;
  final InferredExerciseMeta meta;
}

const List<({List<String> keys, String equip})> _kEquipRules = [
  (keys: ['史密斯', 'smith'], equip: 'Machine'),
  (keys: ['悍马', 'hammer strength', 'hammer ', '器械', '坐姿机', '倒蹬机', '倒蹬', '哈克机', '钟摆', 'v蹲', '腰带深蹲', '蝴蝶机', '推胸机', '推肩机', 'leg press', 'hack squat', 'pendulum', 'machine', 'pec deck', 'lever', 'sled', 'plate-loaded', '楼梯机', '动感单车', '划船机', '椭圆机', '跑步机'], equip: 'Machine'),
  (keys: ['绳索', '龙门架', '滑轮', 'pullover', 'cable', 'pulldown', 'pushdown', 'crossover', 'face pull', '面拉', '脸拉'], equip: 'Cable'),
  (keys: ['哑铃', 'dumbbell', ' db ', 'db '], equip: 'Dumbbell'),
  (keys: ['杠铃', '曲杆', 'ez杆', 'ez-bar', 'ez bar', 'w杆', '地雷管', 'landmine', 't杠', 't-bar', 'barbell', ' bb '], equip: 'Barbell'),
  (keys: ['壶铃', 'kettlebell', ' kb '], equip: 'Kettlebell'),
  (keys: ['弹力带', '阻力带', 'band', 'mini band'], equip: 'Band'),
  (keys: ['吊环', 'rings'], equip: 'Rings'),
  (keys: ['负重', '杠铃片', '配重', 'weighted', 'dip belt'], equip: 'Weighted'),
  (keys: ['俯卧撑', '引体', '仰卧起坐', '卷腹', '平板支撑', '徒手', '自重', '悬垂', '双杠', '罗马椅', '山羊挺身', '开合跳', '波比', '深蹲跳', 'bodyweight', 'push-up', 'push up', 'pull-up', 'pull up', 'chin-up', 'plank', 'crunch', 'burpee', 'sit-up'], equip: 'Bodyweight'),
];

const List<({List<String> keys, String primary, List<String> secondary, String art})> _kMuscleRules = [
  // Specific multi-word disambiguation FIRST
  (keys: ['反向飞鸟', '后束', '蝴蝶机后束', 'face pull', '面拉', '脸拉', 'rear delt', 'reverse fly', 'reverse pec'], primary: 'shoulders', secondary: ['back', 'trapezius'], art: 'cable-rear-delt-fly'),
  (keys: ['腿弯举', '勾腿', 'leg curl', 'nordic', '北欧', '罗马尼亚硬拉', '直腿硬拉', 'romanian deadlift', 'rdl', 'good morning', '早安式', '早安'], primary: 'hamstrings', secondary: ['glutes', 'lowerback'], art: 'leg-curl'),
  (keys: ['腿屈伸', 'leg extension', '倒蹬', '腿举', '哈克深蹲', '钟摆深蹲', 'v蹲', '腰带深蹲', '前蹲', '颈前深蹲', '西斯深蹲', '保加利亚', '弓步蹲', '箭步蹲', '夹腿', '内收', 'deep squat', 'squat', 'leg press', 'hack squat', 'pendulum', 'lunge', 'adduction'], primary: 'quads', secondary: ['glutes'], art: 'leg-press'),
  (keys: ['提踵', '小腿', 'calf', 'calves', 'soleus'], primary: 'calves', secondary: [], art: 'calf-raise'),
  (keys: ['臀推', '臀桥', '后踢臀', '后踢', '髋外展', '分腿机', '蛙泳踢', '相扑深蹲', 'sumo', 'hip thrust', 'glute bridge', 'kickback', 'abduction', 'glute'], primary: 'glutes', secondary: ['hamstrings'], art: 'dumbbell-hip-thrust'),
  (keys: ['直臂下压', 'straight arm pulldown', 'straight-arm pulldown', '仰卧上拉', 'pullover'], primary: 'back', secondary: ['triceps', 'chest'], art: 'straight-arm-pulldown'),
  (keys: ['高位下拉', '下拉胸', '引体向上', '引体', '划船', 't杠', '梅多斯', '背阔', '背部', 'lat pulldown', 'pulldown', 'pull-up', 'pull up', 'chin-up', 'chin up', 'row'], primary: 'back', secondary: ['biceps'], art: 'chest-supported-row'),
  (keys: ['耸肩', '斜方', 'shrug', 'trap'], primary: 'trapezius', secondary: ['forearm'], art: 'shrug'),
  (keys: ['农夫行走', '小臂', '前臂', '腕弯举', '握力', 'farmer', 'wrist', 'forearm'], primary: 'forearm', secondary: ['trapezius'], art: 'wrist-curl'),
  (keys: ['山羊挺身', '罗马椅腰背', '下背', '竖脊', '超人', 'hyperextension', 'back extension', 'lower back', 'erector'], primary: 'lowerback', secondary: ['glutes', 'hamstrings'], art: 'back-extension'),
  (keys: ['俄罗斯转体', '侧腹', '人鱼线', '斜腹', '伐木', 'russian twist', 'side bend', 'wood chop', 'oblique'], primary: 'obliques', secondary: ['abdomen'], art: 'weighted-russian-twist'),
  (keys: ['卷腹', '仰卧起坐', '平板支撑', '悬垂举腿', '举腿', '提膝', '腹肌轮', '死虫', '腹肌', '腹部', '核心', 'crunch', 'sit-up', 'sit up', 'plank', 'leg raise', 'knee raise', 'ab wheel', 'rollout', 'dead bug'], primary: 'abdomen', secondary: ['obliques'], art: 'cable-crunch'),
  (keys: ['碎颅', '三头下压', '绳索下压', '下压', '臂屈伸', '过顶臂屈伸', '颈后臂屈伸', '窄距卧推', '窄握卧推', '三头', 'tricep', 'pushdown', 'skullcrusher', 'skull crusher', 'close-grip', 'close grip', 'dip'], primary: 'triceps', secondary: ['shoulders'], art: 'rope-tricep-pushdown'),
  (keys: ['牧师凳', '集中弯举', '锤式弯举', '曲杆弯举', '反握弯举', '弯举', '二头', 'bicep', 'curl', 'preacher', 'hammer'], primary: 'biceps', secondary: ['forearm'], art: 'bicep-curl'),
  (keys: ['侧平举', '前平举', '推肩', '阿诺德', '推举', '直立划船', '三角肌', '前束', '中束', 'shoulder', 'lateral raise', 'front raise', 'overhead press', 'military press', 'arnold', 'upright row'], primary: 'shoulders', secondary: ['triceps'], art: 'lateral-raise'),
  (keys: ['上斜卧推', '上斜推胸', '下斜卧推', '下斜推胸', '平板卧推', '卧推', '推胸', '夹胸', '蝴蝶机', '飞鸟', '俯卧撑', '胸肌', 'chest', 'bench press', 'fly', 'pec', 'push-up', 'push up'], primary: 'chest', secondary: ['shoulders', 'triceps'], art: 'machine-chest-press'),
  (keys: ['硬拉', '传统硬拉', '相扑硬拉', 'deadlift'], primary: 'lowerback', secondary: ['hamstrings', 'glutes'], art: 'deadlift'),
  // Cardio / Conditioning fallbacks
  (keys: ['爬楼', '楼梯机', '登山机', 'stair'], primary: 'glutes', secondary: ['quads', 'calves'], art: 'stair-climber'),
  (keys: ['动感单车', '单车', '自行车', 'bike', 'cycling', 'spin'], primary: 'quads', secondary: ['calves', 'hamstrings'], art: 'assault-bike'),
  (keys: ['跳绳', 'jump rope', 'skipping'], primary: 'calves', secondary: ['shoulders', 'quads'], art: 'jump-rope'),
  (keys: ['战绳', 'battle rope'], primary: 'shoulders', secondary: ['abdomen', 'back'], art: 'battle-ropes'),
  (keys: ['跑步', '慢跑', '爬坡', '健走', '椭圆机', '开合跳', '波比', 'run', 'jog', 'treadmill', 'walk', 'elliptical', 'burpee'], primary: 'quads', secondary: ['calves', 'glutes'], art: 'running'),
];

const List<String> _kCardioKeywords = [
  '跑步', '慢跑', '爬坡', '健走', '椭圆机', '划船机', '楼梯机', '登山机', '动感单车', '单车', '骑行', '跳绳',
  'running', 'treadmill', 'elliptical', 'stair', 'cycling', 'spin', 'jump rope', 'cardio', '有氧',
];

const List<String> _kTimedKeywords = [
  '平板支撑', '支撑保持', '静态', '悬垂保持', '战绳', '靠墙静蹲', 'L坐',
  'plank', 'hold', 'static', 'wall sit', 'battle rope', 'hang', 'carry', '行走', '拉伸', 'stretch',
];

String _refineArt(String primary, String equip, String rawLower, String defaultArt) {
  if (primary == 'chest') {
    if (rawLower.contains('飞鸟') || rawLower.contains('夹胸') || rawLower.contains('fly') || rawLower.contains('pec')) {
      return equip == 'Cable' ? 'cable-fly' : 'dumbbell-fly';
    }
    if (rawLower.contains('上斜') || rawLower.contains('incline')) {
      return equip == 'Machine' ? 'incline-chest-press-machine' : 'bench-press';
    }
    if (rawLower.contains('下斜') || rawLower.contains('decline')) {
      return equip == 'Machine' ? 'decline-chest-press-machine' : 'decline-bench-press';
    }
    if (equip == 'Machine') return 'machine-chest-press';
    if (equip == 'Dumbbell') return 'dumbbell-bench-press';
    return 'bench-press';
  }
  if (primary == 'back') {
    if (rawLower.contains('下拉') || rawLower.contains('pulldown')) return 'lat-pulldown';
    if (rawLower.contains('引体') || rawLower.contains('pull-up') || rawLower.contains('pull up')) return 'pull-up';
    if (rawLower.contains('t杠') || rawLower.contains('t-bar')) return 't-bar-row';
    if (equip == 'Machine') return 'machine-row';
    if (equip == 'Dumbbell') return 'dumbbell-bent-over-row';
    return 'barbell-row';
  }
  if (primary == 'shoulders') {
    if (rawLower.contains('后束') || rawLower.contains('反向飞鸟') || rawLower.contains('rear')) return 'cable-rear-delt-fly';
    if (rawLower.contains('侧平举') || rawLower.contains('lateral')) {
      if (equip == 'Cable') return 'cable-lateral-raise';
      if (equip == 'Machine') return 'machine-lateral-raise';
      return 'lateral-raise';
    }
    if (rawLower.contains('面拉') || rawLower.contains('脸拉') || rawLower.contains('face pull')) return 'banded-face-pull';
    if (equip == 'Machine') return 'machine-shoulder-press';
    return 'arnold-press';
  }
  if (primary == 'quads') {
    if (rawLower.contains('腿屈伸') || rawLower.contains('extension')) return 'leg-extension';
    if (rawLower.contains('夹腿') || rawLower.contains('内收') || rawLower.contains('adduct')) return 'hip-adduction-machine';
    if (rawLower.contains('倒蹬') || rawLower.contains('腿举') || rawLower.contains('leg press')) return 'leg-press';
    if (rawLower.contains('保加利亚') || rawLower.contains('分腿') || rawLower.contains('split')) {
      return 'smith-machine-bulgarian-split-squat';
    }
    if (rawLower.contains('哈克') || rawLower.contains('hack')) return 'barbell-hack-squat';
    return defaultArt;
  }
  if (primary == 'biceps') {
    if (rawLower.contains('牧师') || rawLower.contains('preacher')) return 'preacher-curl';
    if (equip == 'Cable') return 'cable-curl';
    return 'bicep-curl';
  }
  if (primary == 'triceps') {
    if (rawLower.contains('碎颅') || rawLower.contains('skull')) return 'skull-crusher';
    if (equip == 'Cable') return 'rope-tricep-pushdown';
    if (equip == 'Machine') return 'machine-triceps-extension';
    return defaultArt;
  }
  return defaultArt;
}

/// Infers likely muscle group, secondary muscles, equipment, tracking mode,
/// and built-in vector art slug from a Chinese or English exercise name.
InferredExerciseMeta inferExerciseMeta(String rawName) {
  final clean = rawName.trim();
  final lower = clean.toLowerCase();
  final padded = ' $lower ';

  var mode = '';
  for (final k in _kCardioKeywords) {
    if (lower.contains(k)) {
      mode = 'cardio';
      break;
    }
  }
  if (mode.isEmpty) {
    for (final k in _kTimedKeywords) {
      if (lower.contains(k)) {
        mode = 'time';
        break;
      }
    }
  }

  var equipment = '';
  for (final rule in _kEquipRules) {
    if (rule.keys.any((k) => padded.contains(k) || lower.contains(k.trim()))) {
      equipment = rule.equip;
      break;
    }
  }

  String primary = '';
  List<String> secondary = const [];
  String art = '';
  for (final rule in _kMuscleRules) {
    if (rule.keys.any((k) => lower.contains(k.trim()))) {
      primary = rule.primary;
      secondary = rule.secondary;
      art = rule.art;
      break;
    }
  }

  if (primary.isEmpty) {
    final guessed = guessMuscle(clean);
    if (guessed != null) {
      primary = guessed;
    } else {
      primary = 'chest';
    }
  }

  if (equipment.isEmpty) {
    if (mode == 'cardio') {
      equipment = (lower.contains('跑') || lower.contains('run') || lower.contains('开合') || lower.contains('波比'))
          ? 'Bodyweight'
          : 'Machine';
    } else if (primary == 'abdomen' || primary == 'obliques') {
      equipment = 'Bodyweight';
    } else {
      equipment = 'Dumbbell';
    }
  }

  if (art.isEmpty) {
    art = switch (primary) {
      'chest' => equipment == 'Machine' ? 'machine-chest-press' : 'bench-press',
      'back' => equipment == 'Machine' ? 'machine-row' : 'barbell-row',
      'shoulders' => equipment == 'Machine' ? 'machine-shoulder-press' : 'lateral-raise',
      'biceps' => 'bicep-curl',
      'triceps' => 'rope-tricep-pushdown',
      'abdomen' => 'crunch',
      'obliques' => 'weighted-russian-twist',
      'quads' => equipment == 'Machine' ? 'leg-press' : 'barbell-bench-squat',
      'hamstrings' => 'romanian-deadlift',
      'glutes' => 'dumbbell-hip-thrust',
      'calves' => 'calf-raise',
      'trapezius' => 'shrug',
      'forearm' => 'wrist-curl',
      'lowerback' => 'back-extension',
      _ => 'bench-press',
    };
  } else {
    art = _refineArt(primary, equipment, lower, art);
  }

  final validEquip = kEquipment.contains(equipment) ? equipment : 'Other';
  return InferredExerciseMeta(
    primary: primary,
    secondary: [for (final s in secondary) if (s != primary) s],
    equipment: validEquip,
    mode: mode,
    art: art,
  );
}

final RegExp _leadingBullet = RegExp(r'^\s*(?:\d+\s*[.)、:：]|[-•*·])\s*');

/// Parses multi-line user input into deduplicated exercise names + inferred metadata.
List<BulkParsedExercise> parseBulkExerciseLines(String rawText) {
  final seen = <String>{};
  final out = <BulkParsedExercise>[];
  for (final line in rawText.split(RegExp(r'[\r\n]+'))) {
    final cleaned = line.replaceFirst(_leadingBullet, '').trim();
    if (cleaned.isEmpty) continue;
    final key = cleaned.toLowerCase();
    if (!seen.add(key)) continue;
    out.add(BulkParsedExercise(name: cleaned, meta: inferExerciseMeta(cleaned)));
  }
  return out;
}
