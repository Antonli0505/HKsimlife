/// JUPAS／DSE 共用模型（模組化，唔塞爆單一檔）
library;

/// DSE 核心科 id（同選修 id 對齊 elective_subjects）
abstract final class DseSubjectIds {
  static const chin = 'chin';
  static const eng = 'eng';
  static const math = 'math';
  static const csd = 'csd'; // Citizenship & Social Development：1 = Attained
  static const m1 = 'm1';
  static const m2 = 'm2';

  static const cores = [chin, eng, math, csd];

  static String label(String id) => switch (id) {
        chin => '中國語文',
        eng => '英國語文',
        math => '數學（必修）',
        csd => '公民與社會發展',
        m1 => '數學延伸 M1',
        m2 => '數學延伸 M2',
        'phy' => '物理',
        'chem' => '化學',
        'bio' => '生物',
        'ict' => 'ICT',
        'econ' => '經濟',
        'bafs' => 'BAFS',
        'hist' => '歷史',
        'chist' => '中史',
        'geog' => '地理',
        'chinlit' => '中國文學',
        'englit' => '英語文學',
        'ths' => '旅遊與款待',
        'hmsc' => '健康管理',
        _ => id,
      };
}

enum JupasAward { bachelor, associate, higherDiploma }

extension JupasAwardExt on JupasAward {
  String get label => switch (this) {
        JupasAward.bachelor => '學士',
        JupasAward.associate => '副學士',
        JupasAward.higherDiploma => '高級文憑',
      };
}

enum JupasScoreFormula {
  /// 最佳 4 科（少部份城大課程）
  best4,
  /// 最佳 5 科（常見）
  best5,
  /// 最佳 6 科／6 Graded Subjects（醫／牙等）
  best6,
  /// 英文＋數學加重（例：1.5×Eng + 1.5×Math + Best 3）
  engMathWeighted,
}

/// 選修要求：例如「生物或化學 ≥3」+「另任意選修 ≥3」
class ElectiveRequirement {
  /// 必須達到 minLevel 嘅科目池（空 = 任意 Category A 選修）
  final List<String> oneOf;
  final int minLevel;
  /// 需要幾科滿足呢個條件（通常 1）
  final int count;

  const ElectiveRequirement({
    this.oneOf = const [],
    this.minLevel = 2,
    this.count = 1,
  });

  static const anyTwoAt2 = ElectiveRequirement(minLevel: 2, count: 2);
  static const anyTwoAt3 = ElectiveRequirement(minLevel: 3, count: 2);
  static const anyOneAt2 = ElectiveRequirement(minLevel: 2, count: 1);
  static const anyOneAt3 = ElectiveRequirement(minLevel: 3, count: 1);
}

/// 單一聯招課程
class JupasProgramme {
  final String code;
  final String nameZh;
  final String nameEn;
  final String institution;
  final JupasAward award;
  final int chinMin;
  final int engMin;
  final int mathMin;
  final bool requireCsdAttained;
  final List<ElectiveRequirement> electiveRequirements;
  final JupasScoreFormula formula;
  /// 參考收生競爭分（優先用 JUPAS 官方 median；遊戲內排序／取錄）
  final int expectedScore;
  /// 科目加權（官方 PDF；空＝全 1.0）
  final Map<String, double> subjectWeights;
  /// true＝用舊換算 5**=7（CUHK MBChB）；false＝2025+ 5**=8.5
  final bool legacyScale;
  final List<String> tags;
  /// 非 DSE 條件（例：church_ref_letter）
  final List<String> requiredFlags;

  const JupasProgramme({
    required this.code,
    required this.nameZh,
    required this.nameEn,
    required this.institution,
    this.award = JupasAward.bachelor,
    this.chinMin = 3,
    this.engMin = 3,
    this.mathMin = 2,
    this.requireCsdAttained = true,
    this.electiveRequirements = const [ElectiveRequirement.anyTwoAt3],
    this.formula = JupasScoreFormula.best5,
    this.expectedScore = 20,
    this.subjectWeights = const <String, double>{},
    this.legacyScale = false,
    this.tags = const [],
    this.requiredFlags = const [],
  });

  JupasProgramme copyWith({
    JupasScoreFormula? formula,
    int? expectedScore,
    Map<String, double>? subjectWeights,
    bool? legacyScale,
    List<String>? tags,
    List<String>? requiredFlags,
  }) {
    return JupasProgramme(
      code: code,
      nameZh: nameZh,
      nameEn: nameEn,
      institution: institution,
      award: award,
      chinMin: chinMin,
      engMin: engMin,
      mathMin: mathMin,
      requireCsdAttained: requireCsdAttained,
      electiveRequirements: electiveRequirements,
      formula: formula ?? this.formula,
      expectedScore: expectedScore ?? this.expectedScore,
      subjectWeights: subjectWeights ?? this.subjectWeights,
      legacyScale: legacyScale ?? this.legacyScale,
      tags: tags ?? this.tags,
      requiredFlags: requiredFlags ?? this.requiredFlags,
    );
  }

  String get displayName => '$code $nameZh';
  String get shortLabel => '$institution · $nameZh';

  /// 神科／極少數例外：基本上唔開 non-JUPAS senior year
  bool get blocksNonJupas {
    if (award != JupasAward.bachelor) return true;
    final n = '$nameZh $nameEn'.toLowerCase();
    if (tags.contains('med') && !tags.contains('nursing')) return true;
    if (n.contains('mbbs') ||
        n.contains('mbchb') ||
        n.contains('bds') ||
        n.contains('dental') ||
        n.contains('veterinary') ||
        n.contains('bvm')) {
      return true;
    }
    if (tags.contains('law') || n.contains('llb') || n.contains('laws')) {
      return true;
    }
    if (tags.contains('pharmacy') || n.contains('pharm')) return true;
    // 物理治療等極熱門健康神科：遊戲當唔收 senior year
    if (tags.contains('health') && tags.contains('elite')) return true;
    return false;
  }

  /// 副學士 Year 2／畢業：可申請 senior year（遊戲簡化＝入大學 Year 2）
  bool get acceptsNonJupasYear2 => !blocksNonJupas;

  /// 副學士 Year 1：多數只可以非聯招 Year 1（唔入 senior year）
  bool get acceptsNonJupasYear1 {
    if (blocksNonJupas) return false;
    // 護理 senior 為主；Year 1 仍可試其他科
    return true;
  }

  /// Non-JUPAS 參考最低 GPA（4.0 制）；對口 Asso 可再降
  double get nonJupasGpaMin {
    if (blocksNonJupas) return 9; // 唔收
    if (tags.contains('business')) return 3.5;
    if (tags.contains('nursing')) return 3.2;
    if (tags.contains('elite')) return 3.4;
    if (tags.contains('engineering') || tags.contains('stem')) return 3.2;
    if (tags.contains('social') || tags.contains('education')) return 3.1;
    return 3.0; // CityU 等公開「通常 ≥3.0」
  }

  /// 收生要求摘要（UI／Profile）
  String get requirementsLabel {
    final parts = <String>[
      '中$chinMin',
      '英$engMin',
      '數$mathMin',
      if (requireCsdAttained) 'CSD Attained',
    ];
    for (final e in electiveRequirements) {
      if (e.oneOf.isEmpty) {
        parts.add('選修×${e.count}≥${e.minLevel}');
      } else {
        final names = e.oneOf.map(DseSubjectIds.label).join('/');
        parts.add('$names≥${e.minLevel}');
      }
    }
    for (final f in requiredFlags) {
      parts.add(_requiredFlagLabel(f));
    }
    return parts.join(' · ');
  }

  static String _requiredFlagLabel(String flag) => switch (flag) {
        'church_ref_letter' => '教會推薦信',
        'church_baptized' => '已受洗',
        _ => flag,
      };

  String get nonJupasLabel {
    if (blocksNonJupas) return 'Non-JUPAS：唔收（神科／例外）';
    return 'Non-JUPAS GPA≥${nonJupasGpaMin.toStringAsFixed(1)}'
        '${acceptsNonJupasYear2 ? " · 可 Year2 銜接" : ""}';
  }
}
