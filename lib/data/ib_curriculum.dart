import 'dart:math';

import '../models/player.dart';
import 'elective_subjects.dart';
import 'ib_curriculum.dart';

/// IB DP Subject Groups（官方 1–6）
enum IbGroup {
  g1, // Language & Literature
  g2, // Language Acquisition
  g3, // Individuals & Societies
  g4, // Sciences
  g5, // Mathematics
  g6, // The Arts（可用另一科代替）
}

extension IbGroupExt on IbGroup {
  String get label => switch (this) {
        IbGroup.g1 => 'Group 1 · 語言與文學',
        IbGroup.g2 => 'Group 2 · 語言習得',
        IbGroup.g3 => 'Group 3 · 個人與社會',
        IbGroup.g4 => 'Group 4 · 科學',
        IbGroup.g5 => 'Group 5 · 數學',
        IbGroup.g6 => 'Group 6 · 藝術／替代',
      };

  String get shortLabel => switch (this) {
        IbGroup.g1 => 'G1',
        IbGroup.g2 => 'G2',
        IbGroup.g3 => 'G3',
        IbGroup.g4 => 'G4',
        IbGroup.g5 => 'G5',
        IbGroup.g6 => 'G6',
      };
}

enum IbLevel { sl, hl }

extension IbLevelExt on IbLevel {
  String get label => this == IbLevel.hl ? 'HL' : 'SL';
}

/// 單一 IB 科目定義
class IbSubject {
  final String id;
  final String name;
  final IbGroup group;
  final bool hlAvailable;
  final ElectiveCategory lean; // 用嚟配理／文傾向
  final int difficulty; // HL 難度參考

  const IbSubject({
    required this.id,
    required this.name,
    required this.group,
    this.hlAvailable = true,
    this.lean = ElectiveCategory.other,
    this.difficulty = 50,
  });
}

/// 玩家已選：科目 + HL/SL
class IbPick {
  final String subjectId;
  final IbLevel level;

  const IbPick({required this.subjectId, required this.level});

  String get encode => '$subjectId:${level.name}';

  factory IbPick.decode(String raw) {
    final parts = raw.split(':');
    final id = parts.first;
    final level = parts.length > 1 && parts[1] == 'hl' ? IbLevel.hl : IbLevel.sl;
    return IbPick(subjectId: id, level: level);
  }

  IbSubject? get subject => IbCurriculum.byId(subjectId);

  String get display {
    final s = subject;
    if (s == null) return encode;
    return '${s.name} ${level.label}';
  }
}

/// DP 課程套餐（3 HL + 3 SL，涵蓋六組規則）
class IbPackage {
  final String id;
  final String name;
  final String description;
  final StreamAffinity affinity;
  final List<IbPick> picks; // 必須 6 科

  const IbPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.affinity,
    required this.picks,
  });
}

class IbCurriculum {
  static const subjects = <IbSubject>[
    // G1
    IbSubject(
      id: 'eng_a',
      name: 'English A: Language & Literature',
      group: IbGroup.g1,
      lean: ElectiveCategory.arts,
      difficulty: 60,
    ),
    IbSubject(
      id: 'chi_a',
      name: '中文 A：語言與文學',
      group: IbGroup.g1,
      lean: ElectiveCategory.arts,
      difficulty: 58,
    ),
    // G2
    IbSubject(
      id: 'chi_b',
      name: '中文 B',
      group: IbGroup.g2,
      lean: ElectiveCategory.arts,
      difficulty: 45,
    ),
    IbSubject(
      id: 'eng_b',
      name: 'English B',
      group: IbGroup.g2,
      lean: ElectiveCategory.arts,
      difficulty: 48,
    ),
    IbSubject(
      id: 'fr_b',
      name: 'French B',
      group: IbGroup.g2,
      lean: ElectiveCategory.arts,
      difficulty: 55,
      hlAvailable: true,
    ),
    // G3
    IbSubject(
      id: 'hist',
      name: 'History',
      group: IbGroup.g3,
      lean: ElectiveCategory.arts,
      difficulty: 65,
    ),
    IbSubject(
      id: 'econ',
      name: 'Economics',
      group: IbGroup.g3,
      lean: ElectiveCategory.business,
      difficulty: 62,
    ),
    IbSubject(
      id: 'geog',
      name: 'Geography',
      group: IbGroup.g3,
      lean: ElectiveCategory.arts,
      difficulty: 55,
    ),
    IbSubject(
      id: 'busman',
      name: 'Business Management',
      group: IbGroup.g3,
      lean: ElectiveCategory.business,
      difficulty: 52,
    ),
    IbSubject(
      id: 'psych',
      name: 'Psychology',
      group: IbGroup.g3,
      lean: ElectiveCategory.arts,
      difficulty: 58,
    ),
    // G4
    IbSubject(
      id: 'phy',
      name: 'Physics',
      group: IbGroup.g4,
      lean: ElectiveCategory.science,
      difficulty: 78,
    ),
    IbSubject(
      id: 'chem',
      name: 'Chemistry',
      group: IbGroup.g4,
      lean: ElectiveCategory.science,
      difficulty: 75,
    ),
    IbSubject(
      id: 'bio',
      name: 'Biology',
      group: IbGroup.g4,
      lean: ElectiveCategory.science,
      difficulty: 68,
    ),
    IbSubject(
      id: 'ess',
      name: 'Environmental Systems & Societies',
      group: IbGroup.g4, // 亦可作 G3；遊戲簡化放 G4
      lean: ElectiveCategory.science,
      difficulty: 50,
      hlAvailable: false,
    ),
    IbSubject(
      id: 'cs',
      name: 'Computer Science',
      group: IbGroup.g4,
      lean: ElectiveCategory.tech,
      difficulty: 70,
    ),
    // G5
    IbSubject(
      id: 'math_aa',
      name: 'Mathematics: Analysis & Approaches',
      group: IbGroup.g5,
      lean: ElectiveCategory.science,
      difficulty: 80,
    ),
    IbSubject(
      id: 'math_ai',
      name: 'Mathematics: Applications & Interpretation',
      group: IbGroup.g5,
      lean: ElectiveCategory.science,
      difficulty: 58,
    ),
    // G6 Arts
    IbSubject(
      id: 'visual',
      name: 'Visual Arts',
      group: IbGroup.g6,
      lean: ElectiveCategory.other,
      difficulty: 50,
    ),
    IbSubject(
      id: 'theatre',
      name: 'Theatre',
      group: IbGroup.g6,
      lean: ElectiveCategory.arts,
      difficulty: 52,
    ),
  ];

  static const packages = <IbPackage>[
    IbPackage(
      id: 'sci_hl',
      name: '理科向 · 3HL',
      description: 'Phy HL + Chem HL + Math AA HL；Eng A / 中文 B / Econ SL',
      affinity: StreamAffinity.science,
      picks: [
        IbPick(subjectId: 'eng_a', level: IbLevel.sl),
        IbPick(subjectId: 'chi_b', level: IbLevel.sl),
        IbPick(subjectId: 'econ', level: IbLevel.sl),
        IbPick(subjectId: 'phy', level: IbLevel.hl),
        IbPick(subjectId: 'chem', level: IbLevel.hl),
        IbPick(subjectId: 'math_aa', level: IbLevel.hl),
      ],
    ),
    IbPackage(
      id: 'sci_bio',
      name: '醫科預備 · 3HL',
      description: 'Bio HL + Chem HL + Math AA HL；Eng A / 中文 B / Psych SL',
      affinity: StreamAffinity.science,
      picks: [
        IbPick(subjectId: 'eng_a', level: IbLevel.sl),
        IbPick(subjectId: 'chi_b', level: IbLevel.sl),
        IbPick(subjectId: 'psych', level: IbLevel.sl),
        IbPick(subjectId: 'bio', level: IbLevel.hl),
        IbPick(subjectId: 'chem', level: IbLevel.hl),
        IbPick(subjectId: 'math_aa', level: IbLevel.hl),
      ],
    ),
    IbPackage(
      id: 'arts_hl',
      name: '文科向 · 3HL',
      description: 'Eng A HL + Hist HL + Econ HL；中文 B / Bio / Math AI SL',
      affinity: StreamAffinity.arts,
      picks: [
        IbPick(subjectId: 'eng_a', level: IbLevel.hl),
        IbPick(subjectId: 'chi_b', level: IbLevel.sl),
        IbPick(subjectId: 'hist', level: IbLevel.hl),
        IbPick(subjectId: 'econ', level: IbLevel.hl),
        IbPick(subjectId: 'bio', level: IbLevel.sl),
        IbPick(subjectId: 'math_ai', level: IbLevel.sl),
      ],
    ),
    IbPackage(
      id: 'arts_lit',
      name: '人文向 · 3HL',
      description: '中文 A HL + Hist HL + Geog HL；Eng B / ESS / Math AI SL',
      affinity: StreamAffinity.arts,
      picks: [
        IbPick(subjectId: 'chi_a', level: IbLevel.hl),
        IbPick(subjectId: 'eng_b', level: IbLevel.sl),
        IbPick(subjectId: 'hist', level: IbLevel.hl),
        IbPick(subjectId: 'geog', level: IbLevel.hl),
        IbPick(subjectId: 'ess', level: IbLevel.sl),
        IbPick(subjectId: 'math_ai', level: IbLevel.sl),
      ],
    ),
    IbPackage(
      id: 'mixed',
      name: '均衡 · 3HL',
      description: 'Econ HL + Bio HL + Math AA SL；Eng A HL / 中文 B / Chem SL',
      affinity: StreamAffinity.none,
      picks: [
        IbPick(subjectId: 'eng_a', level: IbLevel.hl),
        IbPick(subjectId: 'chi_b', level: IbLevel.sl),
        IbPick(subjectId: 'econ', level: IbLevel.hl),
        IbPick(subjectId: 'bio', level: IbLevel.hl),
        IbPick(subjectId: 'chem', level: IbLevel.sl),
        IbPick(subjectId: 'math_aa', level: IbLevel.sl),
      ],
    ),
    IbPackage(
      id: 'business',
      name: '商科向 · 3HL',
      description: 'Econ HL + BusMan HL + Math AI HL；Eng A / 中文 B / ESS SL',
      affinity: StreamAffinity.arts,
      picks: [
        IbPick(subjectId: 'eng_a', level: IbLevel.sl),
        IbPick(subjectId: 'chi_b', level: IbLevel.sl),
        IbPick(subjectId: 'econ', level: IbLevel.hl),
        IbPick(subjectId: 'busman', level: IbLevel.hl),
        IbPick(subjectId: 'ess', level: IbLevel.sl),
        IbPick(subjectId: 'math_ai', level: IbLevel.hl),
      ],
    ),
  ];

  static IbSubject? byId(String id) {
    try {
      return subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<IbPick> picksOf(Player p) =>
      p.ibSubjectSlots.map(IbPick.decode).toList();

  static String subjectsLabel(Player p) {
    if (p.ibSubjectSlots.isEmpty) return '未選 DP 科目';
    return picksOf(p).map((e) => e.display).join(' · ');
  }

  static int hlCount(Player p) =>
      picksOf(p).where((e) => e.level == IbLevel.hl).length;

  static bool isValidDiplomaProgramme(Player p) {
    final picks = picksOf(p);
    if (picks.length != 6) return false;
    if (hlCount(p) < 3) return false;
    // 每組至少概念上覆蓋：簡化 — 唔重複同一 subject id
    final ids = picks.map((e) => e.subjectId).toSet();
    return ids.length == 6;
  }

  /// 套餐取錄成功率（傾向 + 能力）
  static int packageSuccessChance(Player p, IbPackage pack) {
    var chance = 70;
    if (p.streamAffinity != StreamAffinity.none &&
        pack.affinity == p.streamAffinity) {
      chance += 20;
    } else if (pack.affinity != StreamAffinity.none &&
        p.streamAffinity != StreamAffinity.none &&
        pack.affinity != p.streamAffinity) {
      chance -= 15;
    }
    chance += (p.smarts - 55) ~/ 2;
    chance += (p.discipline - 50) ~/ 4;
    // HL 愈難愈考智慧
    final hlHard = pack.picks
        .where((e) => e.level == IbLevel.hl)
        .map((e) => byId(e.subjectId)?.difficulty ?? 50)
        .fold<int>(0, (a, b) => a + b);
    if (hlHard > 220) chance -= 10;
    return chance.clamp(15, 95);
  }

  static Random _rng(Player p, [int salt = 0]) =>
      Random(p.year * 773 + p.age * 19 + p.name.hashCode + salt);

  static String tryApplyPackage(Player p, IbPackage pack) {
    final chance = packageSuccessChance(p, pack);
    if (_rng(p, pack.id.hashCode).nextInt(100) >= chance) {
      p.eventLog.add(
        '${p.year}年：DP 套餐「${pack.name}」未獲導師批准（勝算 $chance%）。',
      );
      return '未獲批准：${pack.name}（勝算 $chance%）。可改揀其他套餐。';
    }
    return applyPackage(p, pack);
  }

  static String applyPackage(Player p, IbPackage pack) {
    p.ibSubjectSlots
      ..clear()
      ..addAll(pack.picks.map((e) => e.encode));
    p.completedExams.add('ib_dp_subjects');
    p.unlockedFlags.add('ib_dp_selected');
    p.studyProgram = 'IB DP · ${pack.name}';
    p.eventLog.add(
      '${p.year}年：IB DP 選科 — ${pack.name}\n${subjectsLabel(p)}',
    );
    return '已確認 DP：${pack.name}\n${subjectsLabel(p)}';
  }

  /// 按傾向自動派合法套餐
  static String autoSelectPackage(Player p) {
    final preferred = packages.where((pack) {
      if (p.streamAffinity == StreamAffinity.none) return true;
      return pack.affinity == p.streamAffinity ||
          pack.affinity == StreamAffinity.none;
    }).toList();
    final pool = preferred.isNotEmpty ? preferred : packages;
    // 智慧高優先難套餐
    pool.sort((a, b) {
      final ah = a.picks.where((e) => e.level == IbLevel.hl).length;
      final bh = b.picks.where((e) => e.level == IbLevel.hl).length;
      return bh.compareTo(ah);
    });
    IbPackage chosen = pool.first;
    for (final pack in pool) {
      if (packageSuccessChance(p, pack) >= 50) {
        chosen = pack;
        break;
      }
    }
    return applyPackage(p, chosen);
  }

  /// 單科 predicted grade 1–7
  static int subjectGrade(Player p, IbPick pick, Random rng) {
    final sub = byId(pick.subjectId);
    if (sub == null) return 4;
    var raw = 3.0 + p.smarts / 28.0 + p.discipline / 50.0;
    if (pick.level == IbLevel.hl) {
      raw -= sub.difficulty / 80.0;
      raw += p.smarts >= 70 ? 0.6 : -0.4;
    } else {
      raw -= sub.difficulty / 120.0;
    }
    // 傾向對口
    if (p.streamAffinity != StreamAffinity.none &&
        sub.lean.matchesAffinity(p.streamAffinity)) {
      raw += 0.7;
    } else if (p.streamAffinity != StreamAffinity.none &&
        sub.lean != ElectiveCategory.other &&
        !sub.lean.matchesAffinity(p.streamAffinity)) {
      raw -= 0.35;
    }
    raw += (rng.nextDouble() - 0.5) * 0.8;
    return raw.round().clamp(1, 7);
  }

  /// TOK+EE → core bonus 0–3（官方矩陣簡化）
  static int coreBonus(Player p) {
    var tok = 0; // 0=E/D, 1=C, 2=B, 3=A 簡化分數
    var ee = 0;
    if (p.unlockedFlags.contains('ib_tok_strong')) {
      tok = p.smarts >= 65 ? 3 : 2;
    } else {
      tok = p.smarts >= 55 ? 1 : 0;
    }
    if (p.unlockedFlags.contains('ib_ee_done')) {
      ee = p.discipline >= 55 ? 3 : 2;
    } else {
      ee = p.smarts >= 60 ? 1 : 0;
    }
    // 簡化矩陣
    final sum = tok + ee;
    if (sum >= 5) return 3;
    if (sum >= 4) return 2;
    if (sum >= 2) return 1;
    return 0;
  }

  /// 完整 IB 分數：6 科×7 + core ≤ 45
  static ({int total, List<String> breakdown, bool diplomaOk}) calculateDiploma(
    Player p, {
    bool missed = false,
  }) {
    // 未選科 → 自動補
    if (p.ibSubjectSlots.length != 6) {
      autoSelectPackage(p);
    }
    final rng = _rng(p, 45);
    final picks = picksOf(p);
    final lines = <String>[];
    var total = 0;
    var hlTotal = 0;
    var hasOne = false;

    for (final pick in picks) {
      var g = subjectGrade(p, pick, rng);
      if (missed) g = (g - 1).clamp(1, 7);
      total += g;
      if (pick.level == IbLevel.hl) hlTotal += g;
      if (g == 1) hasOne = true;
      lines.add('${pick.display}: $g');
    }

    var bonus = coreBonus(p);
    if (p.unlockedFlags.contains('ib_cas_strong')) {
      // CAS 唔直接加分，但缺 CAS 會影響 diploma；有強 CAS 略穩
      bonus = bonus.clamp(0, 3);
    } else if (bonus > 0 && rng.nextInt(100) < 15) {
      bonus = (bonus - 1).clamp(0, 3);
    }
    if (missed) bonus = 0;
    total = (total + bonus).clamp(0, 45);
    lines.add('Core (TOK+EE): +$bonus');

    // Diploma 規則簡化：≥24、HL≥12、無 1 分、有做 CAS/EE 傾向
    final diplomaOk = total >= 24 &&
        hlTotal >= 12 &&
        !hasOne &&
        (p.unlockedFlags.contains('ib_ee_done') || total >= 28);

    return (total: total, breakdown: lines, diplomaOk: diplomaOk);
  }
}
