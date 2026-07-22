import 'dart:math';

import '../models/enums.dart';
import '../models/player.dart';

/// 玩家理／文傾向（提高對應選科成功率）
enum StreamAffinity { none, science, arts }

extension StreamAffinityExt on StreamAffinity {
  String get label => switch (this) {
        StreamAffinity.none => '未定',
        StreamAffinity.science => '理科傾向',
        StreamAffinity.arts => '文科傾向',
      };
}

enum ElectiveCategory { science, arts, business, tech, other }

extension ElectiveCategoryExt on ElectiveCategory {
  String get label => switch (this) {
        ElectiveCategory.science => '理科',
        ElectiveCategory.arts => '文科',
        ElectiveCategory.business => '商科',
        ElectiveCategory.tech => '科技',
        ElectiveCategory.other => '其他',
      };

  bool matchesAffinity(StreamAffinity a) => switch (a) {
        StreamAffinity.science =>
          this == ElectiveCategory.science || this == ElectiveCategory.tech,
        StreamAffinity.arts =>
          this == ElectiveCategory.arts || this == ElectiveCategory.business,
        StreamAffinity.none => false,
      };
}

/// 開科現實（唔係「Band 愈高先有」咁簡單）
enum ElectiveOffering {
  /// 絕大多數中學都有：物化生、史地中史、經濟 BAFS、ICT 等
  mainstream,
  /// 名校／較強校先常見：M1 M2、英文學、中國文學
  selective,
  /// 應用學習向：旅款、健康管理等 — 唔係 Band 3 標配，多數中下／部分中游先開
  applied,
}

/// DSE 選修科（中四起）
class ElectiveSubject {
  final String id;
  final String name;
  final ElectiveCategory category;
  final ElectiveOffering offering;
  final int minSmarts;
  final int difficulty; // 1–100，愈高愈難入（校內競爭）
  final List<String> tags;

  const ElectiveSubject({
    required this.id,
    required this.name,
    required this.category,
    this.offering = ElectiveOffering.mainstream,
    this.minSmarts = 40,
    this.difficulty = 50,
    this.tags = const [],
  });
}

class ElectiveData {
  static const subjects = <ElectiveSubject>[
    // ── 主流理科：Band 1–3 都普遍有 ──
    ElectiveSubject(
      id: 'phy',
      name: '物理',
      category: ElectiveCategory.science,
      offering: ElectiveOffering.mainstream,
      minSmarts: 55,
      difficulty: 72,
      tags: ['STEM'],
    ),
    ElectiveSubject(
      id: 'chem',
      name: '化學',
      category: ElectiveCategory.science,
      offering: ElectiveOffering.mainstream,
      minSmarts: 55,
      difficulty: 70,
      tags: ['STEM'],
    ),
    ElectiveSubject(
      id: 'bio',
      name: '生物',
      category: ElectiveCategory.science,
      offering: ElectiveOffering.mainstream,
      minSmarts: 50,
      difficulty: 62,
      tags: ['STEM'],
    ),
    ElectiveSubject(
      id: 'ict',
      name: '資訊及通訊科技',
      category: ElectiveCategory.tech,
      offering: ElectiveOffering.mainstream,
      minSmarts: 45,
      difficulty: 48,
    ),
    // ── 選擇性／名校較齊：M1 M2、文學 ──
    ElectiveSubject(
      id: 'm1',
      name: '數學延伸單元一（M1）',
      category: ElectiveCategory.science,
      offering: ElectiveOffering.selective,
      minSmarts: 70,
      difficulty: 85,
      tags: ['STEM', '名額少'],
    ),
    ElectiveSubject(
      id: 'm2',
      name: '數學延伸單元二（M2）',
      category: ElectiveCategory.science,
      offering: ElectiveOffering.selective,
      minSmarts: 75,
      difficulty: 90,
      tags: ['STEM', '名額少'],
    ),
    ElectiveSubject(
      id: 'chinlit',
      name: '中國文學',
      category: ElectiveCategory.arts,
      offering: ElectiveOffering.selective,
      minSmarts: 55,
      difficulty: 68,
    ),
    ElectiveSubject(
      id: 'englit',
      name: '英國文學',
      category: ElectiveCategory.arts,
      offering: ElectiveOffering.selective,
      minSmarts: 60,
      difficulty: 78,
      tags: ['名額少', 'EMI'],
    ),
    // ── 主流文科／商科：各 Band 都常見 ──
    ElectiveSubject(
      id: 'hist',
      name: '歷史',
      category: ElectiveCategory.arts,
      offering: ElectiveOffering.mainstream,
      minSmarts: 45,
      difficulty: 55,
    ),
    ElectiveSubject(
      id: 'chist',
      name: '中國歷史',
      category: ElectiveCategory.arts,
      offering: ElectiveOffering.mainstream,
      minSmarts: 45,
      difficulty: 52,
    ),
    ElectiveSubject(
      id: 'geog',
      name: '地理',
      category: ElectiveCategory.arts,
      offering: ElectiveOffering.mainstream,
      minSmarts: 45,
      difficulty: 55,
    ),
    ElectiveSubject(
      id: 'econ',
      name: '經濟',
      category: ElectiveCategory.business,
      offering: ElectiveOffering.mainstream,
      minSmarts: 50,
      difficulty: 60,
    ),
    ElectiveSubject(
      id: 'bafs',
      name: '企業、會計與財務概論',
      category: ElectiveCategory.business,
      offering: ElectiveOffering.mainstream,
      minSmarts: 40,
      difficulty: 45,
    ),
    ElectiveSubject(
      id: 'va',
      name: '視覺藝術',
      category: ElectiveCategory.other,
      offering: ElectiveOffering.mainstream,
      minSmarts: 35,
      difficulty: 40,
    ),
    ElectiveSubject(
      id: 'pe',
      name: '體育',
      category: ElectiveCategory.other,
      offering: ElectiveOffering.mainstream,
      minSmarts: 30,
      difficulty: 38,
    ),
    ElectiveSubject(
      id: 'dat',
      name: '設計與應用科技',
      category: ElectiveCategory.tech,
      offering: ElectiveOffering.mainstream,
      minSmarts: 40,
      difficulty: 42,
    ),
    // ── 應用科：唔係 Band 3 標配；中游較常見，名校較少開，Band 3 多數冇 ──
    ElectiveSubject(
      id: 'ths',
      name: '旅遊與款待',
      category: ElectiveCategory.other,
      offering: ElectiveOffering.applied,
      minSmarts: 35,
      difficulty: 40,
      tags: ['應用'],
    ),
    ElectiveSubject(
      id: 'hmsc',
      name: '健康管理與社會關懷',
      category: ElectiveCategory.other,
      offering: ElectiveOffering.applied,
      minSmarts: 40,
      difficulty: 42,
      tags: ['應用'],
    ),
  ];

  static ElectiveSubject? byId(String id) {
    try {
      return subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 按學校 Band 決定開科池（貼近現實，唔係「Band 愈高先有物化」）
  static List<ElectiveSubject> poolForSchool(SchoolBand band) {
    return subjects.where((s) {
      switch (s.offering) {
        case ElectiveOffering.mainstream:
          // 物化生、史地、經濟 BAFS 等：各 Band 都有
          return true;
        case ElectiveOffering.selective:
          // M1/M2、英文學：Band 1 齊；Band 2 多數有；Band 3 好很少開
          return band == SchoolBand.band1 || band == SchoolBand.band2;
        case ElectiveOffering.applied:
          // 旅款、健康管理：中游（Band 2）較常見；名校較少；Band 3 多數冇
          return band == SchoolBand.band2;
      }
    }).toList();
  }

  /// Band 1「更強選擇」：同一科池入面，選擇性科目較齊 + 可多選一科
  static int maxElectives(Player p) {
    var max = 1;
    if (p.smarts >= 50 || p.discipline >= 55) max = 2;
    if (p.smarts >= 68 || p.schoolBand == SchoolBand.band1) max = 3;
    // Band 3 學生要好叻先到 3 科；一般最多 2
    if (p.schoolBand == SchoolBand.band3 && p.smarts < 75) {
      max = max.clamp(1, 2);
    }
    return max.clamp(1, 3);
  }

  /// 單一科目取錄成功率（0–100）
  static int successChance(Player p, ElectiveSubject sub) {
    var chance = 55;
    chance += (p.smarts - sub.minSmarts);
    chance += (p.discipline - 50) ~/ 3;
    chance -= (sub.difficulty - 50) ~/ 2;

    // 校內取錄：名校資源好但搶位；Band 3 主流科有開但班底／名額較亂
    switch (p.schoolBand) {
      case SchoolBand.band1:
        chance += sub.offering == ElectiveOffering.selective ? 12 : 8;
      case SchoolBand.band2:
        chance += sub.offering == ElectiveOffering.selective ? 2 : 6;
        if (sub.offering == ElectiveOffering.applied) chance += 8;
      case SchoolBand.band3:
        chance -= 5;
      case SchoolBand.none:
        break;
    }

    // 理／文傾向
    if (p.streamAffinity != StreamAffinity.none) {
      if (sub.category.matchesAffinity(p.streamAffinity)) {
        chance += 22;
      } else if (sub.category == ElectiveCategory.other) {
        chance += 4;
      } else {
        chance -= 12;
      }
    }

    if (p.unlockedFlags.contains('specialized_cram_school')) chance += 5;
    return chance.clamp(8, 95);
  }

  static Random _rng(Player p, [int salt = 0]) =>
      Random(p.year * 911 + p.age * 17 + p.name.hashCode + salt + p.electiveIds.length);

  /// 嘗試選一科；成功則加入 electiveIds
  static String trySelect(Player p, String subjectId) {
    if (p.electiveIds.contains(subjectId)) {
      return '你已經選咗呢科。';
    }
    final max = maxElectives(p);
    if (p.electiveIds.length >= max) {
      return '已達選科上限（最多 $max 科）。';
    }
    final sub = byId(subjectId);
    if (sub == null) return '科目唔存在。';

    final pool = poolForSchool(p.schoolBand);
    if (!pool.any((s) => s.id == subjectId)) {
      return '${p.schoolBand.secondaryLabel}未有開「${sub.name}」。';
    }

    final chance = successChance(p, sub);
    final roll = _rng(p, subjectId.hashCode).nextInt(100);
    if (roll < chance) {
      p.electiveIds.add(subjectId);
      p.eventLog.add(
        '${p.year}年：選科成功 — ${sub.name}（${sub.category.label} · 勝算$chance%）',
      );
      // 選科成功小幅屬性
      if (sub.category == ElectiveCategory.science) {
        p.smarts = (p.smarts + 1).clamp(0, 100);
      } else if (sub.category == ElectiveCategory.arts) {
        p.network = (p.network + 1).clamp(0, 100);
      }
      return '取錄：${sub.name}（勝算 $chance%，已選 ${p.electiveIds.length}/$max）';
    }

    p.eventLog.add(
      '${p.year}年：選科失敗 — ${sub.name}（勝算$chance%，未取錄）',
    );
    return '未取錄：${sub.name}（勝算 $chance%）。可改選其他科。';
  }

  static String electivesLabel(Player p) {
    if (p.electiveIds.isEmpty) return '未選科';
    return p.electiveIds
        .map((id) => byId(id)?.name ?? id)
        .join('、');
  }

  /// 未揀理文時保底（智慧 ≥55 → 理科，否則文科）
  static void ensureStreamAffinity(Player p) {
    if (p.streamAffinity != StreamAffinity.none) return;
    p.streamAffinity =
        p.smarts >= 55 ? StreamAffinity.science : StreamAffinity.arts;
    p.unlockedFlags.add('stream_affinity_auto');
    p.eventLog.add(
      '${p.year}年：未揀理文傾向，自動定為${p.streamAffinity.label}。',
    );
  }

  /// 完成選科（至少 1 科，或明確跳過只得最少）
  static String finalize(Player p, {bool forceMinimum = false}) {
    ensureStreamAffinity(p);
    p.completedExams.add('f4_electives');
    p.unlockedFlags.add('f4_electives_done');

    if (p.electiveIds.isEmpty && forceMinimum) {
      // 保底派一科最易入
      final pool = poolForSchool(p.schoolBand)
        ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
      if (pool.isEmpty) {
        p.electiveIds.add('ths');
      } else {
        // 按傾向揀保底
        ElectiveSubject pick = pool.first;
        if (p.streamAffinity != StreamAffinity.none) {
          final matched = pool
              .where((s) => s.category.matchesAffinity(p.streamAffinity))
              .toList();
          if (matched.isNotEmpty) pick = matched.first;
        }
        p.electiveIds.add(pick.id);
      }
    }

    final label = electivesLabel(p);
    p.studyProgram = p.electiveIds.isEmpty ? '中四（未選科）' : '中四選修：$label';
    p.eventLog.add(
      '${p.year}年：中四選科確定 — $label'
      '（${p.streamAffinity.label} · 上限 ${maxElectives(p)} 科）',
    );
    return '選科完成：$label';
  }

  /// 自動套餐（checklist 用）：按傾向 + 能力盡量填滿
  static String autoSelectPackage(Player p) {
    final max = maxElectives(p);
    final pool = poolForSchool(p.schoolBand);

    List<ElectiveSubject> preferred;
    if (p.streamAffinity == StreamAffinity.science) {
      preferred = pool
          .where((s) => s.category.matchesAffinity(StreamAffinity.science))
          .toList()
        ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    } else if (p.streamAffinity == StreamAffinity.arts) {
      preferred = pool
          .where((s) => s.category.matchesAffinity(StreamAffinity.arts))
          .toList()
        ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    } else {
      preferred = List.of(pool)
        ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    }

    // 先試傾向科，失敗再試易入科
    for (final sub in preferred) {
      if (p.electiveIds.length >= max) break;
      trySelect(p, sub.id);
    }
    if (p.electiveIds.length < max) {
      final easy = List.of(pool)
        ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
      for (final sub in easy) {
        if (p.electiveIds.length >= max) break;
        if (!p.electiveIds.contains(sub.id)) trySelect(p, sub.id);
      }
    }

    return finalize(p, forceMinimum: true);
  }
}
