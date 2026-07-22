import '../../models/player.dart';
import '../church_pathway.dart';
import 'jupas_models.dart';

/// 對照玩家分科成績檢查課程要求 + 計收生分
///
/// 兩層：
/// 1. **GER（一般入學資格）**：22222＝Asso／HD；33222＝UGC 學士底線
///    （科目門檻；**唔**用 Best5 當 GER——Best5／Best6 只係收生計分）
/// 2. **課程科目要求（PER）**：各 JS／AD 自己嘅 chinMin／選修等（[meets]）
/// 3. **收生競爭分**：[admissionScore] 按課程 formula（best5／best6／加重）對 [expectedScore]
class JupasRequirements {
  static int levelOf(Map<String, int> grades, String id) => grades[id] ?? 0;

  /// 科目有冇計入「達標科」：Category A ≥ min；CSD Attained 當一科
  static bool _countsAsSubject(String id, int level, int minLevel) {
    if (id == DseSubjectIds.csd) return level >= 1 && minLevel <= 2;
    return level >= minLevel;
  }

  /// 有幾多科達 [minLevel]（CSD Attained 計 1 科）
  static int subjectCountAt(Map<String, int> grades, int minLevel) {
    var n = 0;
    for (final e in grades.entries) {
      if (_countsAsSubject(e.key, e.value, minLevel)) n++;
    }
    return n;
  }

  /// Asso／HD 一般入學：**22222**（五科二級，必須包中、英）
  static bool meetsAssoGer(Map<String, int> grades) {
    if (levelOf(grades, DseSubjectIds.chin) < 2) return false;
    if (levelOf(grades, DseSubjectIds.eng) < 2) return false;
    return subjectCountAt(grades, 2) >= 5;
  }

  /// UGC 學士一般入學：**33222**（中 3、英 3、數 2、另兩科 2；公民 Attained 可當其中一科）
  static bool meetsDegreeGer(Map<String, int> grades) {
    if (levelOf(grades, DseSubjectIds.chin) < 3) return false;
    if (levelOf(grades, DseSubjectIds.eng) < 3) return false;
    if (levelOf(grades, DseSubjectIds.math) < 2) return false;
    // 中英數已佔 3 科；再要 ≥2 科達 2（可含 CSD／選修）→ 合共五科概念
    var extra = 0;
    for (final e in grades.entries) {
      if (e.key == DseSubjectIds.chin ||
          e.key == DseSubjectIds.eng ||
          e.key == DseSubjectIds.math) {
        continue;
      }
      if (_countsAsSubject(e.key, e.value, 2)) extra++;
    }
    return extra >= 2;
  }

  /// 有 Asso 入場資格：DSE 22222／Foundation Pass／IB Diploma
  static bool hasAssoEntrance(Player p, Map<String, int> grades) {
    if (p.unlockedFlags.contains('foundation_pass')) return true;
    if (p.unlockedFlags.contains('ib_diploma')) return true;
    return meetsAssoGer(grades);
  }

  /// 有學士 GER：DSE 33222（JUPAS／本地學士底線；課程 PER 另計）
  static bool hasDegreeEntrance(Player p, Map<String, int> grades) {
    return meetsDegreeGer(grades);
  }

  static String gerSummary(Player p) {
    if (p.unlockedFlags.contains('foundation_pass')) {
      return 'Foundation Pass（視同 22222）'
          '${p.unlockedFlags.contains('ib_diploma') ? ' · IB Diploma' : ''}';
    }
    if (p.dseGrades.isEmpty && p.dseSittingCount <= 0) {
      return '未應考 DSE';
    }
    final g = p.dseGrades.isNotEmpty
        ? p.dseGrades
        : const <String, int>{};
    if (g.isEmpty) return '未有放榜成績';
    final asso = hasAssoEntrance(p, g);
    final deg = hasDegreeEntrance(p, g);
    return '22222（Asso／HD）${asso ? "✓" : "✗"}'
        ' · 33222（學士）${deg ? "✓" : "✗"}'
        '${!asso ? " — ${assoGerFailReason(g)}" : ""}';
  }

  static String assoGerFailReason(Map<String, int> grades) {
    if (levelOf(grades, DseSubjectIds.chin) < 2) return '中文未達 2（需 22222）';
    if (levelOf(grades, DseSubjectIds.eng) < 2) return '英文未達 2（需 22222）';
    if (subjectCountAt(grades, 2) < 5) {
      return '未達五科二級 22222（而家 ${subjectCountAt(grades, 2)} 科）';
    }
    return '未達 Asso／HD 一般入學（22222）';
  }

  static String degreeGerFailReason(Map<String, int> grades) {
    if (levelOf(grades, DseSubjectIds.chin) < 3) return '中文未達 3（需 33222）';
    if (levelOf(grades, DseSubjectIds.eng) < 3) return '英文未達 3（需 33222）';
    if (levelOf(grades, DseSubjectIds.math) < 2) return '數學未達 2（需 33222）';
    return '未達大學一般入學 33222（中英數外再要兩科 ≥2／公民 Attained）';
  }

  /// 課程科目要求（PER）；唔代替 GER
  static bool meets(JupasProgramme prog, Map<String, int> grades) {
    if (levelOf(grades, DseSubjectIds.chin) < prog.chinMin) return false;
    if (levelOf(grades, DseSubjectIds.eng) < prog.engMin) return false;
    if (levelOf(grades, DseSubjectIds.math) < prog.mathMin) return false;
    if (prog.requireCsdAttained &&
        levelOf(grades, DseSubjectIds.csd) < 1) {
      return false;
    }

    final electiveIds = grades.keys
        .where((k) => !DseSubjectIds.cores.contains(k))
        .toList();

    // 每個 ElectiveRequirement 要獨立滿足（唔重複用同一科）
    final used = <String>{};
    for (final req in prog.electiveRequirements) {
      final pool = electiveIds.where((id) {
        if (used.contains(id)) return false;
        if (req.oneOf.isNotEmpty && !req.oneOf.contains(id)) return false;
        return levelOf(grades, id) >= req.minLevel;
      }).toList()
        ..sort((a, b) => levelOf(grades, b).compareTo(levelOf(grades, a)));

      if (pool.length < req.count) return false;
      for (var i = 0; i < req.count; i++) {
        used.add(pool[i]);
      }
    }
    return true;
  }

  /// 課程額外條件（洗禮、教會推薦信等）
  static bool meetsSpecialConditions(Player p, JupasProgramme prog) {
    for (final flag in prog.requiredFlags) {
      if (!_hasRequiredFlag(p, flag)) return false;
    }
    return true;
  }

  static bool _hasRequiredFlag(Player p, String flag) => switch (flag) {
        'church_ref_letter' => ChurchPathway.hasReferenceForJupas(p),
        'church_baptized' => p.isBaptized,
        _ => p.unlockedFlags.contains(flag),
      };

  /// DSE 科目 + 非學術條件
  static bool meetsAll(
    Player p,
    JupasProgramme prog,
    Map<String, int> grades,
  ) =>
      meets(prog, grades) && meetsSpecialConditions(p, prog);

  static String specialFailReason(Player p, JupasProgramme prog) {
    for (final flag in prog.requiredFlags) {
      if (_hasRequiredFlag(p, flag)) continue;
      return switch (flag) {
        'church_ref_letter' => ChurchPathway.referenceFailReason(p),
        'church_baptized' => '需要受洗',
        _ => '未達額外要求：$flag',
      };
    }
    return '未達課程額外要求';
  }

  static String failReasonAll(
    Player p,
    JupasProgramme prog,
    Map<String, int> grades,
  ) {
    if (!meets(prog, grades)) return failReason(prog, grades);
    return specialFailReason(p, prog);
  }

  /// DSE 等級 → 收生計分點（官方 2025+；legacy＝舊 7/6/5）
  /// 遊戲內部仍存 1–5、6=5*、7=5**
  static double levelPoints(int level, {required bool legacyScale}) {
    if (level <= 0) return 0;
    if (legacyScale) {
      return switch (level) {
        >= 7 => 7.0,
        6 => 6.0,
        _ => level.toDouble().clamp(1, 5),
      };
    }
    return switch (level) {
      >= 7 => 8.5,
      6 => 7.0,
      5 => 5.5,
      4 => 4.0,
      3 => 3.0,
      2 => 2.0,
      1 => 1.0,
      _ => 0.0,
    };
  }

  static double _weightedPoint(
    JupasProgramme prog,
    String id,
    int level,
  ) {
    final base = levelPoints(level, legacyScale: prog.legacyScale);
    final w = prog.subjectWeights[id] ??
        (id == 'm2' ? (prog.subjectWeights['m1'] ?? 1.0) : 1.0);
    return base * w;
  }

  /// 收生分（對齊官方公式：Best5／Best6／英數加權＋科目 weight）
  static int admissionScore(JupasProgramme prog, Map<String, int> grades) {
    return admissionScoreExact(prog, grades).round();
  }

  static double admissionScoreExact(
    JupasProgramme prog,
    Map<String, int> grades,
  ) {
    final scored = grades.entries
        .where((e) => e.key != DseSubjectIds.csd && e.value > 0)
        .map((e) => (id: e.key, pts: _weightedPoint(prog, e.key, e.value)))
        .toList()
      ..sort((a, b) => b.pts.compareTo(a.pts));

    switch (prog.formula) {
      case JupasScoreFormula.best4:
        return scored.take(4).fold(0.0, (s, e) => s + e.pts);
      case JupasScoreFormula.best5:
        return scored.take(5).fold(0.0, (s, e) => s + e.pts);
      case JupasScoreFormula.best6:
        return scored.take(6).fold(0.0, (s, e) => s + e.pts);
      case JupasScoreFormula.engMathWeighted:
        final engW = prog.subjectWeights[DseSubjectIds.eng] ?? 1.5;
        final mathW = prog.subjectWeights[DseSubjectIds.math] ?? 1.5;
        final eng = levelPoints(
              levelOf(grades, DseSubjectIds.eng),
              legacyScale: prog.legacyScale,
            ) *
            engW;
        final math = levelPoints(
              levelOf(grades, DseSubjectIds.math),
              legacyScale: prog.legacyScale,
            ) *
            mathW;
        final rest = grades.entries
            .where((e) =>
                e.key != DseSubjectIds.csd &&
                e.key != DseSubjectIds.eng &&
                e.key != DseSubjectIds.math &&
                e.value > 0)
            .map((e) => _weightedPoint(prog, e.key, e.value))
            .toList()
          ..sort((a, b) => b.compareTo(a));
        final top3 = rest.take(3).fold(0.0, (s, v) => s + v);
        return eng + math + top3;
    }
  }

  static String failReason(JupasProgramme prog, Map<String, int> grades) {
    if (levelOf(grades, DseSubjectIds.chin) < prog.chinMin) {
      return '中文未達 ${prog.chinMin}';
    }
    if (levelOf(grades, DseSubjectIds.eng) < prog.engMin) {
      return '英文未達 ${prog.engMin}';
    }
    if (levelOf(grades, DseSubjectIds.math) < prog.mathMin) {
      return '數學未達 ${prog.mathMin}';
    }
    if (prog.requireCsdAttained && levelOf(grades, DseSubjectIds.csd) < 1) {
      return 'CSD 未 Attained';
    }
    return '選修未符課程要求';
  }
}
