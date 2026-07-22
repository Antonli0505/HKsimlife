import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'luck_modifiers.dart';
import 'career_abilities.dart';

/// 公職職位：公務員部門／紀律部隊分位、招聘季、體能、三年試用＋評核 A
class GovPost {
  final String id;
  final CareerSector sector;
  final String deptZh;
  final String entryTitleZh;
  final List<String> rankTitles;
  final List<int> salaries;
  final Set<Quarter> peak;
  final bool hardOffPeak;
  final int minSmarts;
  final int minDiscipline;
  final int minFitness;
  final int minHp;
  final int minNetwork;
  final int minReputation;
  final EducationLevel minEducation;
  final bool needJre;
  final bool needCre;
  final bool needSocialDegree;
  final bool physicalTrack;

  const GovPost({
    required this.id,
    required this.sector,
    required this.deptZh,
    required this.entryTitleZh,
    required this.rankTitles,
    required this.salaries,
    required this.peak,
    this.hardOffPeak = true,
    this.minSmarts = 0,
    this.minDiscipline = 0,
    this.minFitness = 0,
    this.minHp = 0,
    this.minNetwork = 0,
    this.minReputation = 0,
    this.minEducation = EducationLevel.none,
    this.needJre = false,
    this.needCre = false,
    this.needSocialDegree = false,
    this.physicalTrack = false,
  });

  String get employerLabel => '$deptZh · $entryTitleZh';

  String titleFor(int rank) {
    final i = rank.clamp(0, rankTitles.length - 1);
    return rankTitles[i];
  }

  int salaryFor(int rank) {
    final i = rank.clamp(0, salaries.length - 1);
    return salaries[i];
  }
}

/// 公務員＋紀律部隊：簡化現實（三年試用、評核 A、分部門職位）
abstract final class CareerGov {
  static const appraisalKey = 'gov_appraisal_as';

  /// 三年試用＝12 季
  static const probationQuarters = 12;
  static const asForPromote = 3;

  /// 每職級增薪點數（簡化 MPS）
  static const mpsPointsPerRank = 18;
  static const payReviewFlagPrefix = 'gov_pay_review_';

  static const List<GovPost> posts = [
    // ── 公務員共通職系 ──
    GovPost(
      id: 'ao',
      sector: CareerSector.civilService,
      deptZh: '各決策局／部門',
      entryTitleZh: '政務主任 AO',
      rankTitles: ['政務主任', '高級政務主任', '首長級／局長助理'],
      salaries: [52000, 75000, 120000],
      peak: {Quarter.q3, Quarter.q4},
      minSmarts: 60,
      minEducation: EducationLevel.bachelor,
      needJre: true,
    ),
    GovPost(
      id: 'eo',
      sector: CareerSector.civilService,
      deptZh: '各決策局／部門',
      entryTitleZh: '二級行政主任 EO II',
      rankTitles: ['二級行政主任', '一級行政主任', '高級行政主任'],
      salaries: [35000, 52000, 75000],
      peak: {Quarter.q2, Quarter.q3, Quarter.q4},
      minSmarts: 50,
      minEducation: EducationLevel.bachelor,
      needCre: true,
    ),
    // ── 社署 ──
    GovPost(
      id: 'swd_sso',
      sector: CareerSector.civilService,
      deptZh: '社會福利署',
      entryTitleZh: '二級社會保障主任',
      rankTitles: ['二級社會保障主任', '一級社會保障主任', '高級社會保障主任'],
      salaries: [32000, 56000, 85000],
      peak: {Quarter.q2, Quarter.q4},
      minSmarts: 52,
      minEducation: EducationLevel.bachelor,
      needCre: true,
    ),
    GovPost(
      id: 'swd_aswo',
      sector: CareerSector.civilService,
      deptZh: '社會福利署',
      entryTitleZh: '助理社會工作主任 ASWO',
      rankTitles: ['助理社會工作主任', '社會工作主任', '高級社會工作主任'],
      salaries: [36850, 62000, 95000],
      peak: {Quarter.q2, Quarter.q3},
      minSmarts: 50,
      minEducation: EducationLevel.bachelor,
      needSocialDegree: true,
    ),
    GovPost(
      id: 'swd_ww',
      sector: CareerSector.civilService,
      deptZh: '社會福利署',
      entryTitleZh: '福利工作員',
      rankTitles: ['福利工作員', '高級福利工作員', '總福利工作員'],
      salaries: [22000, 32000, 45000],
      peak: {Quarter.q1, Quarter.q3},
      minSmarts: 40,
      minEducation: EducationLevel.f5,
      hardOffPeak: false,
    ),
    // ── 民政事務總署 ──
    GovPost(
      id: 'had_lo',
      sector: CareerSector.civilService,
      deptZh: '民政事務總署',
      entryTitleZh: '二級聯絡主任',
      rankTitles: ['二級聯絡主任', '一級聯絡主任', '高級聯絡主任'],
      salaries: [28790, 52000, 75000],
      peak: {Quarter.q2, Quarter.q4},
      minSmarts: 48,
      minNetwork: 20,
      minEducation: EducationLevel.f5,
    ),
    // ── 房屋署 ──
    GovPost(
      id: 'hd_ho',
      sector: CareerSector.civilService,
      deptZh: '房屋署',
      entryTitleZh: '房屋事務主任',
      rankTitles: ['房屋事務主任', '副房屋事務經理', '房屋事務經理'],
      salaries: [25115, 52000, 82000],
      peak: {Quarter.q2, Quarter.q4},
      minSmarts: 50,
      minDiscipline: 40,
      minEducation: EducationLevel.f5,
    ),
    // ── 警務處 ──
    GovPost(
      id: 'police_pc',
      sector: CareerSector.disciplinary,
      deptZh: '香港警務處',
      entryTitleZh: '警員',
      rankTitles: ['警員', '警長', '警署警長'],
      salaries: [28000, 38000, 52000],
      peak: {Quarter.q1, Quarter.q3},
      minDiscipline: 50,
      minFitness: 55,
      minHp: 50,
      minEducation: EducationLevel.f5,
      physicalTrack: true,
    ),
    GovPost(
      id: 'police_ip',
      sector: CareerSector.disciplinary,
      deptZh: '香港警務處',
      entryTitleZh: '見習督察',
      rankTitles: ['見習督察', '督察', '高級督察'],
      salaries: [52000, 65000, 85000],
      peak: {Quarter.q2, Quarter.q4},
      minSmarts: 58,
      minDiscipline: 55,
      minFitness: 60,
      minHp: 52,
      minEducation: EducationLevel.bachelor,
      physicalTrack: true,
    ),
    // ── 消防處 ──
    GovPost(
      id: 'fire_ff',
      sector: CareerSector.disciplinary,
      deptZh: '消防處',
      entryTitleZh: '消防員',
      rankTitles: ['消防員', '隊目', '站長'],
      salaries: [24725, 35000, 48000],
      peak: {Quarter.q1, Quarter.q3},
      minDiscipline: 48,
      minFitness: 62,
      minHp: 55,
      minEducation: EducationLevel.f5,
      physicalTrack: true,
    ),
    GovPost(
      id: 'fire_so',
      sector: CareerSector.disciplinary,
      deptZh: '消防處',
      entryTitleZh: '消防隊長（行動）',
      rankTitles: ['消防隊長', '高級隊長', '區長'],
      salaries: [48000, 62000, 85000],
      peak: {Quarter.q2, Quarter.q4},
      minSmarts: 55,
      minDiscipline: 52,
      minFitness: 58,
      minHp: 55,
      minEducation: EducationLevel.bachelor,
      physicalTrack: true,
    ),
    // ── 海關 ──
    GovPost(
      id: 'customs_co',
      sector: CareerSector.disciplinary,
      deptZh: '香港海關',
      entryTitleZh: '關員',
      rankTitles: ['關員', '高級關員', '總關員'],
      salaries: [24725, 35000, 48000],
      peak: {Quarter.q1, Quarter.q3},
      minSmarts: 42,
      minDiscipline: 48,
      minFitness: 52,
      minHp: 50,
      minEducation: EducationLevel.f5,
      physicalTrack: true,
    ),
    GovPost(
      id: 'customs_ci',
      sector: CareerSector.disciplinary,
      deptZh: '香港海關',
      entryTitleZh: '海關督察',
      rankTitles: ['海關督察', '高級督察', '總督察'],
      salaries: [48000, 62000, 85000],
      peak: {Quarter.q2, Quarter.q4},
      minSmarts: 55,
      minDiscipline: 52,
      minFitness: 55,
      minHp: 50,
      minEducation: EducationLevel.bachelor,
      physicalTrack: true,
    ),
    // ── ICAC ──
    GovPost(
      id: 'icac_inv',
      sector: CareerSector.disciplinary,
      deptZh: '廉政公署 ICAC',
      entryTitleZh: '調查員',
      rankTitles: ['見習調查員', '調查員', '高級調查員'],
      salaries: [35000, 48000, 70000],
      peak: {Quarter.q2, Quarter.q4},
      minSmarts: 58,
      minDiscipline: 55,
      minFitness: 50,
      minHp: 48,
      minReputation: 35,
      minEducation: EducationLevel.bachelor,
      physicalTrack: true,
    ),
  ];

  static GovPost? byId(String id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  static GovPost? fromEmployer(String employer) {
    if (employer.isEmpty) return null;
    for (final p in posts) {
      if (employer.contains(p.deptZh) &&
          (employer.contains(p.entryTitleZh) ||
              employer.contains(p.id) ||
              p.rankTitles.any((t) => employer.contains(t)))) {
        return p;
      }
      // 標記：僱主字串尾「#postId」
      if (employer.endsWith('#${p.id}') || employer.contains('#${p.id}')) {
        return p;
      }
    }
    // 舊存檔／無 #id：粗略對應
    if (employer.contains('ICAC') || employer.contains('廉政')) {
      return byId('icac_inv');
    }
    if (employer.contains('警務') || employer.contains('警隊')) {
      return byId('police_pc');
    }
    if (employer.contains('消防')) return byId('fire_ff');
    if (employer.contains('海關')) return byId('customs_co');
    if (employer.contains('社署') || employer.contains('社會福利')) {
      return byId('swd_sso');
    }
    if (employer.contains('民政')) return byId('had_lo');
    if (employer.contains('房屋')) return byId('hd_ho');
    if (employer.contains('政務')) return byId('ao');
    if (employer.contains('行政主任') || employer.contains('一般職系')) {
      return byId('eo');
    }
    // 淨係「政府」→ EO 線（避免月薪 $0）
    if (employer == '政府' || employer.startsWith('政府')) {
      return byId('eo');
    }
    return null;
  }

  /// 入職時未指定 post：揀一個玩家過到門檻嘅預設職位
  static GovPost? defaultPostFor(CareerSector sector, Player p) {
    if (sector != CareerSector.civilService &&
        sector != CareerSector.disciplinary) {
      return null;
    }
    for (final post in posts) {
      if (post.sector != sector) continue;
      if (blockReason(p, post) == null) return post;
    }
    return null;
  }

  static GovPost? currentPost(Player p) => fromEmployer(p.employerId);

  static bool usesGovRules(Player p) =>
      p.currentSector == CareerSector.civilService ||
      p.currentSector == CareerSector.disciplinary;

  static bool isGovSector(CareerSector s) =>
      s == CareerSector.civilService || s == CareerSector.disciplinary;

  static String taggedEmployer(GovPost post) =>
      '${post.deptZh} · ${post.entryTitleZh}#${post.id}';

  static String? blockReason(Player p, GovPost post) {
    if (p.education.index < post.minEducation.index) {
      return '學歷唔夠（${post.entryTitleZh}）';
    }
    if (p.smarts < post.minSmarts) {
      return '智慧唔夠（要 ${post.minSmarts}+）';
    }
    if (p.discipline < post.minDiscipline) {
      return '紀律唔夠（要 ${post.minDiscipline}+）';
    }
    if (post.physicalTrack && p.fitness < post.minFitness) {
      return '體能唔夠（要 ${post.minFitness}+；而家 ${p.fitness}）'
          '——去做體能訓練';
    }
    if (p.hp < post.minHp) {
      return '生命唔夠（要 ${post.minHp}+）';
    }
    if (p.network < post.minNetwork) {
      return '人脈唔夠（要 ${post.minNetwork}+）';
    }
    if (p.reputation < post.minReputation) {
      return '名望唔夠（要 ${post.minReputation}+）';
    }
    if (post.needJre && !p.unlockedFlags.contains('jre_passed')) {
      return '要過 JRE';
    }
    if (post.needCre && !p.unlockedFlags.contains('cre_passed')) {
      return '要過 CRE';
    }
    if (post.needSocialDegree &&
        !p.unlockedFlags.contains('social_degree') &&
        !p.unlockedFlags.contains('grad_social')) {
      return 'ASWO 要認可社工學位';
    }
    if (p.hasCriminalRecord) return '有案底好難入公職／紀律部隊';
    return null;
  }

  static String? seasonBlock(Player p, GovPost post) {
    if (post.peak.contains(p.quarter)) return null;
    if (post.hardOffPeak) {
      final peaks = post.peak.map((q) => q.label).join('／');
      return '而家唔係${post.deptZh}「${post.entryTitleZh}」招募期（旺季：$peaks）';
    }
    return null; // soft：交畀 soft flag
  }

  static bool seasonSoft(Player p, GovPost post) =>
      !post.peak.contains(p.quarter) && !post.hardOffPeak;

  static List<GovPost> visiblePosts(Player p, CareerSector sector) =>
      posts.where((post) => post.sector == sector).toList();

  static int appraisalAs(Player p) =>
      (p.careerAttributes[appraisalKey] as int?) ?? p.jobAppraisalAs;

  static void setAppraisalAs(Player p, int n) {
    p.jobAppraisalAs = n.clamp(0, 99);
    p.careerAttributes = {
      ...p.careerAttributes,
      appraisalKey: p.jobAppraisalAs,
    };
  }

  static void initPayScale(Player p) {
    p.jobGovMpsPoint = 0;
    p.jobGovPayScaleBps = 10000;
    p.jobGovPointFreezeQuarters = 0;
  }

  /// 本職級頂薪點（未升職前）
  static int rankTopSalary(GovPost post, int rank) {
    final entry = post.salaryFor(rank);
    if (rank < post.salaries.length - 1) {
      final next = post.salaryFor(rank + 1);
      return (next * 0.94).round().clamp(entry, next - 1);
    }
    return (entry * 1.35).round();
  }

  /// 公職實際月薪（起薪點＋增薪點＋累計划一調整）
  static int monthlySalary(Player p) {
    final post = currentPost(p);
    if (post == null || !usesGovRules(p)) return 0;
    final entry = post.salaryFor(p.jobRank);
    final top = rankTopSalary(post, p.jobRank);
    final pt = p.jobGovMpsPoint.clamp(0, mpsPointsPerRank);
    final step = mpsPointsPerRank > 0
        ? ((top - entry) / mpsPointsPerRank).round()
        : 0;
    final base = entry + step * pt;
    final bps = p.jobGovPayScaleBps.clamp(9000, 13000);
    return (base * bps / 10000).round();
  }

  static String payScaleLabel(Player p) {
    final pct = (p.jobGovPayScaleBps - 10000) / 100.0;
    if (pct.abs() < 0.05) return '划一調整 0%';
    final sign = pct >= 0 ? '+' : '';
    return '划一調整 $sign${pct.toStringAsFixed(1)}%';
  }

  static String mpsLabel(Player p) =>
      '增薪點 ${p.jobGovMpsPoint}/$mpsPointsPerRank'
      '${p.jobGovMpsPoint >= mpsPointsPerRank ? '（頂點）' : ''}';

  /// Q2：年度划一調薪＋按表現跳 point（參考現實；試用期內唔計）
  static String? tickAnnualPay(Player p) {
    if (!p.isEmployed || !usesGovRules(p)) return null;
    if (p.jobProbationQuartersLeft > 0) return null;
    if (p.quarter != Quarter.q2) return null;
    final flag = '$payReviewFlagPrefix${p.year}';
    if (p.unlockedFlags.contains(flag)) return null;
    p.unlockedFlags.add(flag);

    final rng = Random(p.year * 31 + p.jobQuartersEmployed);
    // 划一調整：近年多數 0–3%（簡化）
    const adjOptions = [0, 150, 200, 250, 300];
    final adjBps = adjOptions[rng.nextInt(adjOptions.length)];
    p.jobGovPayScaleBps = (p.jobGovPayScaleBps + adjBps).clamp(9000, 13000);

    final lines = <String>[
      '政府年度薪酬檢討（Q2）',
      '划一調整：+${(adjBps / 100).toStringAsFixed(1)}%'
          '（累計 ${payScaleLabel(p)}）',
    ];
    p.eventLog.add(
      '${p.year}年：公務員划一調薪 +${(adjBps / 100).toStringAsFixed(1)}%',
    );

    if (p.jobGovPointFreezeQuarters > 0) {
      p.jobGovPointFreezeQuarters--;
      lines.add(
        '增薪點暫停（拉Curve／表現欠佳）'
        '，剩 ${p.jobGovPointFreezeQuarters} 季',
      );
      return lines.join('\n');
    }

    final post = currentPost(p);
    if (post == null) return lines.join('\n');

    if (p.jobGovMpsPoint >= mpsPointsPerRank) {
      lines.add('已達本職級頂薪點，今年唔跳 point（等升職）');
      return lines.join('\n');
    }

    // 跳 point：按表現分層（你要求版本）
    // >=80：100%；50-79：約 70%；<49：較易凍增薪點
    var incChance = 70;
    if (p.jobPerformance >= 80) {
      incChance = 100;
    } else if (p.jobPerformance < 49) {
      incChance = 30;
    }
    if (p.discipline < 40) incChance -= 12;

    final ok = LuckModifiers.roll(p, incChance / 100.0, rng);
    if (!ok) {
      if (p.jobPerformance < 49) {
        p.jobGovPointFreezeQuarters = 2;
        lines.add('評核偏低：拉Curve 下凍增薪點約半年');
        p.eventLog.add('${p.year}年：公務員凍增薪點（表現欠佳）');
      } else {
        lines.add('今年冇跳增薪點（評核未達自動晉級）');
      }
      return lines.join('\n');
    }

    p.jobGovMpsPoint++;
    final sal = monthlySalary(p);
    lines.add(
      '跳增薪點 +1 → ${mpsLabel(p)}'
      '\n月薪約 \$$sal',
    );
    p.eventLog.add(
      '${p.year}年：公務員跳增薪點（${p.jobGovMpsPoint}/$mpsPointsPerRank）',
    );
    return lines.join('\n');
  }

  static void onHireGov(Player p, GovPost post) {
    p.employerId = taggedEmployer(post);
    p.jobRank = 0;
    p.jobTitle = '${post.deptZh} · ${post.titleFor(0)}';
    setAppraisalAs(p, 0);
    initPayScale(p);
  }

  static void applyTitle(Player p) {
    final post = currentPost(p);
    if (post == null) return;
    p.jobTitle = '${post.deptZh} · ${post.titleFor(p.jobRank)}';
  }

  /// 試用合格後先可以攞 A；每年（每 4 季）評一次
  static String? tickAppraisal(Player p) {
    if (!p.isEmployed || !usesGovRules(p)) return null;
    if (p.jobProbationQuartersLeft > 0) return null;
    if (p.jobQuartersEmployed <= 0 || p.jobQuartersEmployed % 4 != 0) {
      return null;
    }

    var chance = 8;
    if (p.jobPerformance >= 75) {
      chance = 55;
    } else if (p.jobPerformance >= 60) {
      chance = 32;
    } else if (p.jobPerformance >= 45) {
      chance = 16;
    }
    if (p.discipline >= 70) chance += 8;
    chance = chance.clamp(5, 75);

    final ok = LuckModifiers.roll(
      p,
      chance / 100.0,
      Random(p.year * 17 + p.jobQuartersEmployed),
    );
    if (ok) {
      setAppraisalAs(p, appraisalAs(p) + 1);
      p.eventLog.add(
        '${p.year}年：工作表現評核獲 A（累計 ${appraisalAs(p)} 個 A）',
      );
      return '年終評核：拎到 A！'
          '\n累計 ${appraisalAs(p)} 個 A'
          '（升職通常要 ≥$asForPromote；過試用先計）';
    }
    p.stress = (p.stress + 2).clamp(0, 100);
    return '年終評核：今次未有 A（表現 ${p.jobPerformance}）'
        '\n累計仲係 ${appraisalAs(p)} 個 A';
  }

  static String? promoteBlock(Player p) {
    if (!usesGovRules(p)) return null;
    if (p.jobProbationQuartersLeft > 0) {
      return '三年試用未過關，未可以升職（過關後先計評核 A）';
    }
    final as = appraisalAs(p);
    if (as < asForPromote) {
      return '評核 A 未夠（要 ≥$asForPromote，而家 $as）'
          '\n過試用後每年評核先有機會拎 A';
    }
    return null;
  }

  static int promoteChanceBonus(Player p) {
    if (!usesGovRules(p)) return 0;
    final extra = appraisalAs(p) - asForPromote;
    if (extra <= 0) return 0;
    return (extra * 8).clamp(0, 32);
  }

  static void onPromoteResetAs(Player p) {
    if (!usesGovRules(p)) return;
    setAppraisalAs(p, 0);
    p.jobGovMpsPoint = 0;
    applyTitle(p);
  }

  static String trainFitness(Player p) {
    p.fitness = (p.fitness + 8).clamp(0, 100);
    p.hp = (p.hp + 2).clamp(0, p.maxHp);
    p.stress = (p.stress + 4).clamp(0, 100);
    p.discipline = (p.discipline + 1).clamp(0, 100);
    // 在職紀律部隊：同步行業「體能表現」，唔好雙軌脫節
    if (p.currentSector == CareerSector.disciplinary) {
      CareerAbilities.add(p, '體能表現', 3, max: 100);
      return '體能訓練：體能 ${p.fitness}、體能表現 ${CareerAbilities.get(p, '體能表現')}';
    }
    return '體能訓練：體能 ${p.fitness}（紀律部隊入職／在職都靠呢樣）';
  }

  static List<ActionButton> fitnessActions(Player p) {
    if (p.lifeStage != LifeStage.adult) return [];
    if (p.age < 16) return [];
    return [
      ActionButton(
        label: '體能訓練（而家 ${p.fitness}）',
        apCost: 1,
        onExecute: (pl) => pl.eventLog.add(trainFitness(pl)),
      ),
    ];
  }
}
