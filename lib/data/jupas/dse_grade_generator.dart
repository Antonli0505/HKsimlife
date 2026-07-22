import 'dart:math';

import '../../models/enums.dart';
import '../../models/player.dart';
import '../elective_subjects.dart';
import 'jupas_models.dart';

/// 由智慧／Band／選修／傾向生成分科等級
///
/// 儲存：1–5 ＝ DSE 1–5；**6＝5\***；**7＝5\*\***；CSD：1=Attained
///
/// 出分對齊 HKEAA 全港大概分布（2025 全體考生累積約）：
/// 5\*\* ~1%、5\*+ ~4%、5+ ~10%、4+ ~28%、3+ ~55%、2+ ~80%、1+ ~92%
/// 用「全港百分位 + 能力偏移」抽級；智慧 50 ≈ 平均。
///
/// GER（22222／33222）同收生 Best5／Best6 分開：呢度只負責出分。
class DseGradeGenerator {
  /// 由高至低：達到該級或以上嘅累積比例（全港）
  static const _cum5starStar = 0.010;
  static const _cum5star = 0.041;
  static const _cum5 = 0.101;
  static const _cum4 = 0.284;
  static const _cum3 = 0.551;
  static const _cum2 = 0.797;
  static const _cum1 = 0.915;

  static Map<String, int> generate(
    Player p, {
    bool missed = false,
    Random? random,
  }) {
    final rng = random ??
        Random(p.year * 97 + p.smarts * 13 + p.dseSittingCount * 17);
    final grades = <String, int>{};
    final ability = _abilityOf(p, missed: missed);

    // 中英獨立難啲（現實硬門檻科）
    grades[DseSubjectIds.chin] = _rollLevel(
      rng,
      ability +
          (p.streamAffinity == StreamAffinity.arts ? 0.12 : 0) -
          0.35,
    );
    grades[DseSubjectIds.eng] = _rollLevel(rng, ability - 0.40);
    grades[DseSubjectIds.math] = _rollLevel(
      rng,
      ability +
          (p.streamAffinity == StreamAffinity.science ? 0.15 : 0) -
          0.08,
    );
    grades[DseSubjectIds.csd] =
        (!missed && (p.smarts >= 32 || rng.nextDouble() < 0.85)) ? 1 : 0;

    final electives = p.electiveIds.isNotEmpty
        ? List<String>.from(p.electiveIds)
        : _defaultElectives(p);
    for (final id in electives) {
      final sub = ElectiveData.byId(id);
      var bias = 0.0;
      if (sub != null && sub.category.matchesAffinity(p.streamAffinity)) {
        bias += 0.20;
      }
      if (sub != null && sub.difficulty >= 70) bias -= 0.28;
      grades[id] = _rollLevel(rng, ability + bias);
    }

    return grades;
  }

  /// 智慧 50 ≈ 0；高智慧軟封頂，避免 5** 氾濫
  static double _abilityOf(Player p, {required bool missed}) {
    final raw = (p.smarts - 50) / 35.0;
    var a = raw.clamp(-1.3, 1.15);
    switch (p.schoolBand) {
      case SchoolBand.band1:
        a += 0.22;
      case SchoolBand.band2:
        break;
      case SchoolBand.band3:
        a -= 0.30;
      case SchoolBand.none:
        break;
    }
    switch (p.dseRetakeMode) {
      case DseRetakeMode.originalSchool:
        a += 0.15;
      case DseRetakeMode.selfStudy:
      case DseRetakeMode.transferSchool:
        a += 0.04;
      case DseRetakeMode.none:
        break;
    }
    if (p.unlockedFlags.contains('jupas_elite_track')) a += 0.12;
    if (missed) a -= 1.00;
    return a.clamp(-1.8, 1.35);
  }

  /// ability 愈高 → 愈易抽中頂百分位（對齊全港累積表）
  static int _rollLevel(Random rng, double ability) {
    final u = rng.nextDouble().clamp(1e-12, 1.0);
    // ability>0：指數>1 → 有效百分位更細（更好成績）
    final topShare = pow(u, exp(ability * 0.70)).toDouble();
    if (topShare < _cum5starStar) return 7;
    if (topShare < _cum5star) return 6;
    if (topShare < _cum5) return 5;
    if (topShare < _cum4) return 4;
    if (topShare < _cum3) return 3;
    if (topShare < _cum2) return 2;
    if (topShare < _cum1) return 1;
    return 1;
  }

  static List<String> _defaultElectives(Player p) {
    if (p.streamAffinity == StreamAffinity.arts) {
      return ['econ', 'hist', 'geog'];
    }
    return ['phy', 'chem', 'bio'];
  }

  /// 顯示用：6→5*、7→5**
  static String levelLabel(int level) {
    if (level >= 7) return '5**';
    if (level == 6) return '5*';
    if (level <= 0) return 'U';
    return '$level';
  }

  /// 合計「最佳 N 科」原始分（CSD 唔計入；5*=6、5**=7）
  static int bestNScore(Map<String, int> grades, int n) {
    final scored = grades.entries
        .where((e) => e.key != DseSubjectIds.csd && e.value > 0)
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (scored.isEmpty) return 0;
    return scored.take(n).fold(0, (a, b) => a + b);
  }

  static String summaryLabel(Map<String, int> grades) {
    if (grades.isEmpty) return '未有分科成績';
    final core = [
      '${DseSubjectIds.label(DseSubjectIds.chin)} ${levelLabel(grades[DseSubjectIds.chin] ?? 0)}',
      '${DseSubjectIds.label(DseSubjectIds.eng)} ${levelLabel(grades[DseSubjectIds.eng] ?? 0)}',
      '${DseSubjectIds.label(DseSubjectIds.math)} ${levelLabel(grades[DseSubjectIds.math] ?? 0)}',
      'CSD ${(grades[DseSubjectIds.csd] ?? 0) >= 1 ? "Attained" : "未達"}',
    ].join(' · ');
    final electives = grades.entries
        .where((e) => !DseSubjectIds.cores.contains(e.key))
        .map((e) => '${DseSubjectIds.label(e.key)} ${levelLabel(e.value)}')
        .join(' · ');
    return electives.isEmpty ? core : '$core\n選修：$electives';
  }

  static Map<String, int> mergeBest(
    Map<String, int> a,
    Map<String, int> b,
  ) {
    final out = Map<String, int>.from(a);
    for (final e in b.entries) {
      final prev = out[e.key] ?? 0;
      if (e.value > prev) out[e.key] = e.value;
    }
    return out;
  }
}
