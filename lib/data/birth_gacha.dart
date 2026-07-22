import 'dart:math';

import '../data/cssa_welfare.dart';
import '../data/family_assets.dart';
import '../data/hk_school_data.dart';
import '../data/ib_pathway.dart';
import '../data/jupas_pathway.dart';
import '../data/elective_subjects.dart';
import '../models/enums.dart';
import '../models/player.dart';
import '../models/stat_baseline.dart';

class BirthGacha {
  static const ssrRate = 0.01;
  static const srRate = 0.19;

  static BirthTier roll([Random? random]) {
    final rng = random ?? Random();
    final roll = rng.nextDouble();
    if (roll < ssrRate) return BirthTier.ssr;
    if (roll < ssrRate + srRate) return BirthTier.sr;
    return BirthTier.r;
  }

  /// 出世時決定小學 banding — 受家庭 level 影响，带随机。
  static SchoolBand rollPrimaryBand(BirthTier tier, [Random? random]) {
    final rng = random ?? Random();
    final r = rng.nextDouble();
    return switch (tier) {
      BirthTier.ssr => r < 0.85 ? SchoolBand.band1 : SchoolBand.band2,
      BirthTier.sr =>
        r < 0.30 ? SchoolBand.band1 : (r < 0.75 ? SchoolBand.band2 : SchoolBand.band3),
      BirthTier.r =>
        r < 0.08 ? SchoolBand.band2 : SchoolBand.band3,
    };
  }

  static String primarySchoolName(SchoolBand band, BirthTier tier) {
    if (tier == BirthTier.ssr && band == SchoolBand.band1) {
      return '國際名校小學部';
    }
    final home = HkSchoolData.homeDistrictFor(tier);
    final school = HkSchoolData.pickPrimarySchool(
      band,
      tier,
      home,
      Random(tier.index * 17 + band.index),
    );
    return school.name;
  }

  static void applyBirthTier(
    Player player,
    BirthTier tier, {
    SchoolBand? primaryBand,
  }) {
    player.birthTier = tier;
    player.phase = GamePhase.playing;
    player.age = 0;
    player.year = 2008;
    player.quarter = Quarter.q1;
    player.lifeStage = LifeStage.infant;
    player.schoolBand = SchoolBand.none;
    player.primaryBand = primaryBand ?? rollPrimaryBand(tier);
    player.dseTier = DseTier.none;
    player.dseBestScore = 0;
    player.dseSittingCount = 0;
    player.dseRetakeMode = DseRetakeMode.none;
    player.jupasPath = JupasPath.none;
    player.dseGrades.clear();
    player.jupasCode = '';
    player.jupasChoices.clear();
    player.assoHoldCode = '';
    player.assoDepositPaid = false;
    player.assoYear = 0;
    player.assoQuarters = 0;
    player.assoGpa = 0;
    player.foundationQuarters = 0;
    player.bachelorYear = 0;
    player.bachelorQuarters = 0;
    player.primaryScore = 0;
    player.placementScore = 0;
    player.ssaBandGroup = SsaBandGroup.none;
    player.ssaPathway = SsaPathway.none;
    player.ssaDpChoices = '';
    player.ibScore = 0;
    player.ibTier = IbTier.none;
    player.ibUniPath = IbUniPath.none;
    player.streamAffinity = StreamAffinity.none;
    player.electiveIds.clear();
    player.ibSubjectSlots.clear();
    player.primarySchoolId = '';
    player.primarySchoolName = '';
    player.secondarySchoolId = '';
    player.secondarySchoolName = '';
    player.homeDistrict = HkSchoolData.homeDistrictFor(tier);
    player.education = EducationLevel.none;
    player.currentSector = CareerSector.none;
    player.jobTitle = '嬰兒';
    player.isStudying = false;
    player.unlockedFlags.clear();
    player.completedExams.clear();
    player.eventLog.clear();

    switch (tier) {
      case BirthTier.ssr:
        player.smarts = 55;
        player.network = 85;
        player.san = 90;
        player.maxSan = 100;
        player.stress = 5;
        player.hp = 95;
        player.maxHp = 100;
        player.reputation = 70;
        player.luck = 65;
        player.discipline = 55;
        player.unlockedFlags.addAll([
          'international_school',
          'bypass_dse',
          'family_property_backing',
          'socio_class_ssr',
        ]);
      case BirthTier.sr:
        player.smarts = 50;
        player.network = 40;
        player.san = 50;
        player.maxSan = 100;
        player.stress = 35;
        player.hp = 85;
        player.reputation = 55;
        player.luck = 50;
        player.discipline = 60;
        player.unlockedFlags.addAll([
          'specialized_cram_school',
          'jupas_elite_track',
          'socio_class_sr',
        ]);
      case BirthTier.r:
        player.smarts = 45;
        player.network = 15;
        player.san = 35;
        player.maxSan = 100;
        player.stress = 45;
        player.hp = 75;
        player.reputation = 40;
        player.luck = 45;
        player.discipline = 40;
        player.unlockedFlags.addAll([
          'cssa_welfare',
          'student_grant_loan',
          'welfare_network',
          'socio_class_r',
        ]);
        CssaWelfare.activateAtBirth(player);
    }

    // 小學 banding 出世預派；具體校名 6 歲升小先分配
    _applyPrimaryBandBirthEffects(player);
    player.eventLog.add(
      '出生：${tier.label} · ${player.homeDistrict.label}（${player.homeDistrict.schoolNet}校網）· '
      '${player.primaryBand.primaryLabel}（6 歲升小）',
    );

    FamilyAssets.applyForTier(player, tier);

    player.baselines = StatBaselines.fromPlayer(
      hp: player.hp,
      san: player.san,
      smarts: player.smarts,
      network: player.network,
      wealth: player.wealth,
      reputation: player.reputation,
      luck: player.luck,
      discipline: player.discipline,
    );
    player.clampStats();
  }

  static void _assignPrimarySchool(Player player) {
    if (player.unlockedFlags.contains('international_school') &&
        player.primaryBand == SchoolBand.band1) {
      final intl = HkSchoolData.getPrimaryById('intl_ps');
      player.primarySchoolId = intl?.id ?? 'intl_ps';
      player.primarySchoolName = intl?.name ?? '國際名校小學部';
      return;
    }
    final school = HkSchoolData.pickPrimarySchool(
      player.primaryBand,
      player.birthTier,
      player.homeDistrict,
      Random(player.name.hashCode + player.primaryBand.index),
    );
    player.primarySchoolId = school.id;
    player.primarySchoolName = school.name;
  }

  static void _applyPrimaryBandBirthEffects(Player player) {
    switch (player.primaryBand) {
      case SchoolBand.band1:
        player.smarts = (player.smarts + 3).clamp(0, 100);
        player.discipline = (player.discipline + 2).clamp(0, 100);
      case SchoolBand.band2:
        break;
      case SchoolBand.band3:
        player.network = (player.network + 2).clamp(0, 100);
      case SchoolBand.none:
        break;
    }
  }

  static LifeStage stageForAge(int age) {
    if (age < 6) return LifeStage.infant;
    if (age < 12) return LifeStage.primary;
    if (age < 18) return LifeStage.secondary;
    return LifeStage.adult;
  }

  static void updateLifeStage(Player player) {
    if (player.age < 6) {
      _syncInfantState(player);
    } else {
      player.lifeStage = stageForAge(player.age);
    }

    if (player.age == 6 && player.lifeStage == LifeStage.primary) {
      _enterPrimary(player);
    }
    if (player.age == 12 && player.lifeStage == LifeStage.secondary) {
      _enterSecondary(player);
    }
    if (player.age >= 18 && player.lifeStage == LifeStage.adult) {
      _graduateSchool(player);
    }
  }

  /// 0–5 歲：唔係小學生；修正舊存檔誤派校名
  static void syncInfantState(Player player) => _syncInfantState(player);

  static void _syncInfantState(Player player) {
    player.lifeStage = LifeStage.infant;
    player.isStudying = false;
    if (player.currentSector == CareerSector.student) {
      player.currentSector = CareerSector.none;
    }
    if (player.primarySchoolName.isNotEmpty) {
      player.primarySchoolId = '';
      player.primarySchoolName = '';
    }
    if (!player.inPrison &&
        player.currentSector == CareerSector.none &&
        !player.isEmployed) {
      player.jobTitle = player.age == 0 ? '嬰兒' : '幼兒';
    }
  }

  static void _enterPrimary(Player player) {
    if (player.primarySchoolName.isEmpty) {
      _assignPrimarySchool(player);
    }
    player.isStudying = true;
    player.currentSector = CareerSector.student;
    player.jobTitle = player.primarySchoolName.isNotEmpty
        ? player.primarySchoolName
        : primarySchoolName(player.primaryBand, player.birthTier);
    player.studyProgram = player.unlockedFlags.contains('international_school')
        ? 'IB Primary'
        : '小學課程';
    player.eventLog.add(
      '${player.year}年：升小學 — ${player.jobTitle}（${player.primaryBand.primaryLabel}）',
    );
    player.unlockedFlags.add('primary_just_enrolled');
  }

  static void _enterSecondary(Player player) {
    if (player.schoolBand == SchoolBand.none ||
        player.secondarySchoolName.isEmpty) {
      if (!player.completedExams.contains('primary_stream_test')) {
        final msg = SsaFlow.completeAllocation(player, missedExam: true);
        player.eventLog.add('${player.year}年：未完成升中流程 — $msg');
      } else if (player.secondarySchoolName.isEmpty) {
        final msg = SsaFlow.completeAllocation(player);
        player.eventLog.add('${player.year}年：統派補分配 — $msg');
      }
    }
    player.jobTitle = player.secondarySchoolName.isNotEmpty
        ? player.secondarySchoolName
        : player.schoolBand.secondaryLabel;
    player.studyProgram = '中學課程';
    // 升中唔等於中五——學歷保持 none，用年齡顯示中一至中六
    if (player.education == EducationLevel.none ||
        player.education.index < EducationLevel.f5.index) {
      // keep none until mid/late secondary milestones
    }
    player.eventLog.add(
      '${player.year}年：升中 — ${player.jobTitle}'
      '（${player.ssaBandGroup.label} · ${player.ssaPathway.label}）',
    );
    player.isStudying = true;
    player.currentSector = CareerSector.student;
    player.unlockedFlags.add('secondary_just_enrolled');
  }

  static void _graduateSchool(Player player) {
    // IB 路線：唔自動畢業，要考 IB Diploma + 選升學
    if (IbPathway.isOnTrack(player)) {
      if (!player.completedExams.contains('ib_diploma')) {
        player.lifeStage = LifeStage.secondary;
        player.isStudying = true;
        player.jobTitle = player.secondarySchoolName.isNotEmpty
            ? '${player.secondarySchoolName} · IB Year 2'
            : 'IB Diploma Year 2';
        player.studyProgram = 'IB Diploma';
        return;
      }
      if (!player.completedExams.contains('ib_university')) {
        player.lifeStage = LifeStage.adult;
        player.isStudying = true;
        player.currentSector = CareerSector.student;
        player.jobTitle = player.ibTier != IbTier.fail
            ? 'IB ${player.ibScore} 分 · 待選校'
            : 'IB 未獲 Diploma · 待決定';
        return;
      }
      return;
    }

    // 本地 DSE：未考／重讀中 → 留校
    if (JupasPathway.isLocalTrack(player)) {
      if (JupasPathway.isRetaking(player)) {
        player.lifeStage = LifeStage.secondary;
        player.isStudying = true;
        return;
      }
      if (!JupasPathway.hasSatDse(player)) {
        player.lifeStage = LifeStage.secondary;
        player.isStudying = true;
        player.jobTitle = player.secondarySchoolName.isNotEmpty
            ? '${player.secondarySchoolName} 中六'
            : '${player.schoolBand.label} 中六';
        return;
      }
      // 放榜待報／下年再報／已入讀：唔喺呢度清狀態
      return;
    }

    player.isStudying = false;
    if (player.currentSector == CareerSector.student) {
      player.currentSector = CareerSector.none;
    }
  }

  /// 呈分試 → 升中 Band。小學 band 有加成，呈分试表现决定最终分配。
  // allocateBand 已廢棄 — 升中由 HkSchoolData.placementScore 處理

  /// 小學阶段每季被动效果
  static void applyPrimaryQuarterlyEffects(Player player) {
    if (player.lifeStage != LifeStage.primary) return;
    switch (player.primaryBand) {
      case SchoolBand.band1:
        player.smarts = (player.smarts + 1).clamp(0, 100);
        player.san = (player.san - 2).clamp(0, player.maxSan);
        player.stress = (player.stress + 1).clamp(0, 100);
      case SchoolBand.band2:
        break;
      case SchoolBand.band3:
        player.network = (player.network + 1).clamp(0, 100);
      case SchoolBand.none:
        break;
    }
  }

  /// 温书加成 — 小學 band 影响（未套遞減）
  static int primaryStudyGain(Player player) {
    var gain = 3;
    switch (player.primaryBand) {
      case SchoolBand.band1:
        gain = 5;
      case SchoolBand.band2:
        gain = 3;
      case SchoolBand.band3:
        gain = 2;
      case SchoolBand.none:
        gain = 3;
    }
    return gain;
  }

  /// 中學溫書基礎收益（未套遞減）
  static int secondaryStudyGainBase() => 4;

  /// 智慧愈高，溫書收益愈低（後期遞減）
  static int diminishStudyGain(int base, int smarts) {
    if (base <= 0) return 0;
    if (smarts >= 85) return base >= 4 ? 1 : 0;
    if (smarts >= 75) return max(1, (base * 0.35).round());
    if (smarts >= 65) return max(1, (base * 0.50).round());
    if (smarts >= 55) return max(1, (base * 0.70).round());
    return base;
  }

  /// 學校階段實際溫書智慧加成
  static int studySmartsGain(Player player) {
    final base = player.lifeStage == LifeStage.primary
        ? primaryStudyGain(player)
        : secondaryStudyGainBase();
    return diminishStudyGain(base, player.smarts);
  }

  /// 補習等大額加成亦套遞減
  static int tutoringSmartsGain(Player player, {int base = 6}) =>
      diminishStudyGain(base, player.smarts);

  /// 統一溫書入口（事件／行動共用）
  /// [harsh]＝呈分／Past Paper：智慧加多啲，但神智／生命代價更大
  static int applyStudyGain(
    Player player, {
    int? base,
    bool harsh = false,
  }) {
    final gain = base != null
        ? diminishStudyGain(base, player.smarts)
        : studySmartsGain(player);
    player.smarts = (player.smarts + gain).clamp(0, 100);
    if (harsh) {
      player.san = (player.san - 5).clamp(0, player.maxSan);
      player.stress = (player.stress + 5).clamp(0, 100);
      if (player.stress >= 70) {
        player.hp = (player.hp - 2).clamp(0, player.maxHp);
      }
    } else {
      player.san = (player.san - 3).clamp(0, player.maxSan);
      player.stress = (player.stress + 2).clamp(0, 100);
    }
    // 神智見底仲狂溫 → 傷生命
    if (player.san <= 15) {
      player.hp = (player.hp - 3).clamp(0, player.maxHp);
    }
    return gain;
  }
}
