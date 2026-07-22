import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'birth_gacha.dart';
import 'career_data.dart';
import 'elective_subjects.dart';
import 'ib_pathway.dart';
import 'jupas/jupas.dart';
import 'university_life.dart';

/// 本地 DSE → 放榜 → 交 JUPAS 志願／Asso 留位 → Main Round → **玩家揀去向**
///
/// 兩手準備：JUPAS 同 Asso 留位可同時有；出結果時先揀入讀邊個，
/// 唔使靠「先後次序」。Asso 交留位費 ≠ 即入學。
class JupasPathway {
  static const int privateCandidateFee = 8500;
  static const int jupasApplicationFee = 460;
  static const int assoDepositFee = 5000;
  static const int maxChoices = 8;

  static bool isLocalTrack(Player p) {
    if (IbPathway.isOnTrack(p)) return false;
    if (p.unlockedFlags.contains('ssa_stay_international')) return false;
    if (p.unlockedFlags.contains('ssa_force_local')) return true;
    // SR/R 等本地出生：無 bypass_dse
    return !p.unlockedFlags.contains('bypass_dse');
  }

  static bool hasSatDse(Player p) => p.dseSittingCount > 0;

  static bool isAwaitingDecision(Player p) =>
      p.unlockedFlags.contains('dse_awaiting_decision');

  static bool isDeferred(Player p) =>
      p.unlockedFlags.contains('dse_jupas_deferred') ||
      p.jupasPath == JupasPath.deferred;

  /// Q4＝正式報名；Q1＝逾期窗（對齊香港秋冬開報＋其後逾期）
  static bool isInJupasApplicationSeason(Player p) =>
      p.quarter == Quarter.q4 || p.quarter == Quarter.q1;

  static bool isJupasFormalSeason(Player p) => p.quarter == Quarter.q4;

  static bool isJupasLateSeason(Player p) => p.quarter == Quarter.q1;

  /// defer 後：下屆報名周期（Q4 正式／Q1 逾期）必彈升學卡
  static bool isDeferredReapplySeason(Player p) =>
      isDeferred(p) && isInJupasApplicationSeason(p);

  /// 可報／改 JUPAS 志願嘅時間：放榜後短窗，或報名季（含逾期）
  static bool isJupasChoiceWindow(Player p) =>
      isAwaitingDecision(p) || isInJupasApplicationSeason(p);

  static String jupasSeasonLabel(Player p) {
    if (isAwaitingDecision(p)) return '放榜後改志願／報名窗';
    if (isJupasFormalSeason(p)) return 'JUPAS 正式報名（Q4）';
    if (isJupasLateSeason(p)) return 'JUPAS 逾期窗（Q1）';
    return '非報名季（下次：Q4 正式／Q1 逾期）';
  }

  static bool isAwaitingMainRound(Player p) =>
      p.unlockedFlags.contains('jupas_awaiting_main_round');

  static bool isRetaking(Player p) =>
      p.unlockedFlags.contains('dse_retaking');

  static bool isEnrolledPostSecondary(Player p) =>
      FoundationPathway.isStudying(p) ||
      (p.isStudying &&
          (p.education == EducationLevel.bachelor ||
              p.education == EducationLevel.associate ||
              p.jupasPath == JupasPath.bachelor ||
              p.jupasPath == JupasPath.associate));

  /// 校內應考（中六／重讀一年）：唔收自修生報名費
  static bool isSchoolSitting(Player p) =>
      isRetaking(p) ||
      (p.dseSittingCount == 0 &&
          (p.lifeStage == LifeStage.secondary || p.age <= 18));

  /// 出社會後、唔讀緊中學：考試季可自費報考（自修生）
  static bool canSitAsPrivateCandidate(Player p) {
    if (IbPathway.isOnTrack(p)) return false;
    if (p.quarter != Quarter.q3 && p.quarter != Quarter.q4) return false;
    if (p.age < 18) return false;
    if (p.lifeStage != LifeStage.adult) return false;
    if (isRetaking(p)) return false;
    if (p.isStudying &&
        p.education.index >= EducationLevel.bachelor.index) {
      return false;
    }
    if (p.dseSittingCount == 0 && p.age == 18) return false;
    return true;
  }

  static bool canSitDse(Player p) {
    if (p.quarter != Quarter.q3 && p.quarter != Quarter.q4) return false;

    if (p.dseSittingCount == 0 && isLocalTrack(p)) {
      return p.age == 17 || p.age == 18;
    }

    if (isRetaking(p) &&
        p.dseSittingCount >= 1 &&
        p.age >= 18 &&
        p.dseRetakeMode != DseRetakeMode.none) {
      return true;
    }

    return canSitAsPrivateCandidate(p);
  }

  /// 中學起顯示 DSE 入口（未開考季可開 checklist 睇缺咩條件）
  static bool shouldShowDseExamEntry(Player p) {
    if (IbPathway.isOnTrack(p)) return false;
    if (!isLocalTrack(p)) return false;
    if (p.lifeStage == LifeStage.secondary && p.age >= 15) return true;
    if (canSitDse(p)) return true;
    if (isRetaking(p)) return true;
    if (hasSatDse(p) &&
        p.age >= 18 &&
        p.lifeStage == LifeStage.adult &&
        !isEnrolledPostSecondary(p)) {
      return true;
    }
    return false;
  }

  static String dseExamEntryLabel(Player p) {
    if (canSitDse(p)) {
      if (canSitAsPrivateCandidate(p) && !isSchoolSitting(p)) {
        return '【DSE】公開考試（自修生 \$${privateCandidateFee} · 可提交）';
      }
      return '【DSE】公開考試（校內應考 · 可提交）';
    }
    if (p.dseSittingCount == 0 && p.age < 17) {
      return '【DSE】17 歲 Q3/Q4 開考（㩒入睇條件）';
    }
    if (p.quarter != Quarter.q3 && p.quarter != Quarter.q4) {
      return '【DSE】${p.quarterLabel} · 等 Q3/Q4 考試季';
    }
    if (canSitAsPrivateCandidate(p) && p.wealth < privateCandidateFee) {
      return '【DSE】自修生報名費不足 \$${privateCandidateFee}';
    }
    return '【DSE】公開考試（㩒入睇條件）';
  }

  static bool canRetake(Player p) =>
      (isAwaitingDecision(p) || isOfferDecisionPending(p)) &&
      p.dseSittingCount == 1 &&
      !p.unlockedFlags.contains('dse_retake_used') &&
      !isAwaitingMainRound(p) &&
      !p.completedExams.contains('jupas');

  static bool isOfferDecisionPending(Player p) =>
      p.unlockedFlags.contains('jupas_offer_pending_choice');

  static bool hasPendingDegreeOffer(Player p) =>
      isOfferDecisionPending(p) &&
      p.unlockedFlags.contains('jupas_has_degree_offer') &&
      p.jupasCode.isNotEmpty;

  static bool hasPaidAssoHold(Player p) =>
      p.assoDepositPaid && p.assoHoldCode.isNotEmpty;

  static void _clearOfferPending(Player p) {
    p.unlockedFlags.remove('jupas_offer_pending_choice');
    p.unlockedFlags.remove('jupas_has_degree_offer');
  }

  /// 有 Asso／HD **一般入學（22222）** 或同等（Foundation Pass／IB Diploma）
  static bool hasAssoGer(Player p) =>
      JupasRequirements.hasAssoEntrance(p, JupasMatcher.gradesOf(p));

  /// 有 UGC 學士 **一般入學（33222）**（課程 PER 另計）
  static bool hasDegreeGer(Player p) =>
      JupasRequirements.hasDegreeEntrance(p, JupasMatcher.gradesOf(p));

  static List<JupasMatch> _eligibleAssoMatches(Player p) =>
      JupasMatcher.eligibleMatches(p)
          .where((m) => _isAssoOrHd(m.programme))
          .toList();

  /// 有至少一個可報 Asso／HD（GER + 課程科目要求）
  static bool hasAssoProgrammes(Player p) => _eligibleAssoMatches(p).isNotEmpty;

  /// Asso 申請窗：放榜後短窗、等 Main Round 兩手準備、夏天 Q3、或 Foundation Pass 後
  static bool isAssoApplicationWindow(Player p) =>
      isAwaitingDecision(p) ||
      isAwaitingMainRound(p) ||
      p.quarter == Quarter.q3 ||
      FoundationPathway.hasPassed(p);

  static String assoSeasonLabel(Player p) {
    if (isAwaitingDecision(p)) return '放榜後 Asso 報名窗';
    if (isAwaitingMainRound(p)) return '等 Main Round · 可兩手準備 Asso';
    if (p.quarter == Quarter.q3) return '夏天 Asso 收生季（Q3）';
    if (FoundationPathway.hasPassed(p)) return 'Foundation Pass 後可報 Asso';
    return '非 Asso 主收生窗（下次：放榜後或 Q3）';
  }

  /// Asso／HD conditional（淨讀 Asso，或報咗 JUPAS 做兩手準備）
  /// 必須先有 22222／同等、matcher 有課程，且喺 Asso 申請窗。
  /// 已畢業學士通常唔走 Asso；退學後 education 會退回 F6 先可報。
  static bool canApplyAsso(Player p) =>
      (hasSatDse(p) || FoundationPathway.hasPassed(p)) &&
      !isRetaking(p) &&
      p.assoHoldCode.isEmpty &&
      !isEnrolledPostSecondary(p) &&
      !isOfferDecisionPending(p) &&
      !p.unlockedFlags.contains('bachelor_graduated') &&
      p.education != EducationLevel.bachelor &&
      hasAssoGer(p) &&
      hasAssoProgrammes(p) &&
      isAssoApplicationWindow(p);

  /// 可揀出社會（放榜後、Foundation Pass 後、defer 等）
  static bool canChooseWork(Player p) =>
      !isAwaitingMainRound(p) &&
      !isRetaking(p) &&
      !isEnrolledPostSecondary(p) &&
      p.jupasPath != JupasPath.work &&
      (isAwaitingDecision(p) ||
          canEditJupasChoices(p) ||
          isDeferred(p) ||
          FoundationPathway.hasPassed(p));

  static bool canPayAssoDeposit(Player p) =>
      p.assoHoldCode.isNotEmpty &&
      !p.assoDepositPaid &&
      !isEnrolledPostSecondary(p);

  /// 未達 22222 → 可讀 Foundation（一年 Pass 後先報 Asso）
  static bool canApplyFoundation(Player p) =>
      FoundationPathway.canEnroll(p);

  /// 可改／交 JUPAS 志願（未讀緊專上／未等 Main Round）
  /// 退學、畢業後都可再報（education 可以已經係 bachelor）
  static bool canEditJupasChoices(Player p) =>
      hasSatDse(p) &&
      !isRetaking(p) &&
      !isAwaitingMainRound(p) &&
      !isOfferDecisionPending(p) &&
      !isEnrolledPostSecondary(p) &&
      isJupasChoiceWindow(p);

  static bool canApplyJupas(Player p) => canEditJupasChoices(p) && hasDegreeGer(p);

  static bool canSubmitJupas(Player p) =>
      canEditJupasChoices(p) &&
      hasDegreeGer(p) &&
      p.jupasChoices.isNotEmpty;

  static DseTier tierFromBest5(int best5) {
    if (best5 >= 30) return DseTier.godTier;
    if (best5 >= 20) return DseTier.university;
    if (best5 >= 12) return DseTier.associate;
    return DseTier.blueCollar;
  }

  static DseTier tierFromScore(int score) => tierFromBest5(score);

  static DseTier admissionTier(Player p) => tierFromBest5(p.dseBestScore);

  static bool _isJupasDegreeProgramme(JupasProgramme prog) =>
      prog.award == JupasAward.bachelor &&
      !prog.tags.contains('community');

  static bool _isAssoOrHd(JupasProgramme prog) =>
      prog.award == JupasAward.associate ||
      prog.award == JupasAward.higherDiploma;

  /// 考 DSE → 分科放榜
  static String applySitting(Player p, {bool missed = false}) {
    if (FoundationPathway.isStudying(p) ||
        (p.isStudying &&
            (p.education == EducationLevel.associate ||
                p.education == EducationLevel.bachelor))) {
      return '讀緊專上／Foundation，唔可以喺呢度重考清檔。';
    }

    if (p.electiveIds.isEmpty && !p.completedExams.contains('f4_electives')) {
      ElectiveData.finalize(p, forceMinimum: true);
    }

    final private = canSitAsPrivateCandidate(p) && !isSchoolSitting(p);
    if (private) {
      if (p.wealth < privateCandidateFee) {
        p.eventLog.add(
          '${p.year}年：自修生報考 DSE 失敗（報名費不足 \$$privateCandidateFee）。',
        );
        return '報名費不足：需要 \$$privateCandidateFee';
      }
      p.wealth -= privateCandidateFee;
      p.dseRetakeMode = DseRetakeMode.none;
    }

    final latest = DseGradeGenerator.generate(p, missed: missed);
    final latestBest5 = DseGradeGenerator.bestNScore(latest, 5);
    p.dseGrades = DseGradeGenerator.mergeBest(p.dseGrades, latest);
    p.dseSittingCount += 1;
    p.dseBestScore = DseGradeGenerator.bestNScore(p.dseGrades, 5);
    p.dseTier = tierFromBest5(p.dseBestScore);
    p.completedExams.add('dse_exam');
    p.education = EducationLevel.f6;
    p.isStudying = false;
    p.lifeStage = LifeStage.adult;
    p.currentSector = CareerSector.none;
    p.studyProgram = '';
    p.jupasCode = '';
    p.jupasChoices = [];
    p.assoHoldCode = '';
    p.assoDepositPaid = false;
    p.unlockedFlags.remove('jupas_awaiting_main_round');
    p.unlockedFlags.remove('jupas_resolve_next_quarter');

    // 放榜後可再決定聯招／Asso（未入讀學士／副學士讀書中先開）
    if (!isEnrolledPostSecondary(p)) {
      p.completedExams.remove('jupas');
      p.jupasPath = JupasPath.none;
      p.unlockedFlags.add('dse_awaiting_decision');
      p.unlockedFlags.remove('dse_jupas_deferred');
    }

    p.unlockedFlags.remove('dse_retaking');
    if (p.dseSittingCount >= 2 && !private) {
      p.unlockedFlags.add('dse_retake_used');
      p.dseRetakeMode = DseRetakeMode.none;
    }

    p.unlockedFlags.removeAll([
      'dse_god_tier',
      'dse_university',
      'dse_associate',
      'blue_collar',
      'med_degree',
      'law_degree',
      'studying_medicine',
      'studying_law',
      'elite_uni',
      'local_uni',
    ]);

    final sitLabel = private
        ? '自修生應考（第${p.dseSittingCount}次 · 報名費 \$$privateCandidateFee）'
        : (p.dseSittingCount == 1
            ? '第一次應考'
            : '重考（第${p.dseSittingCount}次）');
    p.jobTitle =
        'DSE 放榜 · Best5 ${p.dseBestScore}（${p.dseTier.label}）';
    final gradeLine = DseGradeGenerator.summaryLabel(p.dseGrades);
    p.eventLog.add(
      '${p.year}年：DSE $sitLabel · 今次 Best5 $latestBest5；'
      '合計 Best5 ${p.dseBestScore}（${p.dseTier.label}）。\n$gradeLine',
    );

    final eligible = JupasMatcher.eligibleMatches(p)
        .where((m) => _isJupasDegreeProgramme(m.programme))
        .length;
    return 'DSE $sitLabel\n'
        '今次 Best5：$latestBest5 · 合計 Best5：${p.dseBestScore}（${p.dseTier.label}）\n'
        '$gradeLine\n'
        '可報 JUPAS 學士約 $eligible 科 · 亦可申請 Asso／HD 兩手準備'
        '${canRetake(p) ? "／校內重讀一年" : ""}';
  }

  static String choicesLabel(Player p) {
    if (p.jupasChoices.isEmpty) return '（未有志願）';
    final parts = <String>[];
    for (var i = 0; i < p.jupasChoices.length; i++) {
      final code = p.jupasChoices[i];
      final prog = JupasCatalogue.byCode(code);
      parts.add('${i + 1}. $code${prog != null ? " ${prog.nameEn}" : ""}');
    }
    return parts.join('\n');
  }

  static String addJupasChoice(Player p, String code) {
    if (!canEditJupasChoices(p)) {
      if (hasSatDse(p) && !isJupasChoiceWindow(p)) {
        return '非 JUPAS 報名季。下次：Q4 正式開報，或 Q1 逾期窗。';
      }
      return '而家唔可以改志願。';
    }
    final prog = JupasCatalogue.byCode(code);
    if (prog == null || !_isJupasDegreeProgramme(prog)) {
      return '呢個唔係 JUPAS 學士課程。';
    }
    final grades = JupasMatcher.gradesOf(p);
    // 先 GER 33222，再課程科目要求（PER）
    if (!JupasRequirements.meetsDegreeGer(grades)) {
      return JupasRequirements.degreeGerFailReason(grades);
    }
    if (!JupasRequirements.meetsAll(p, prog, grades)) {
      return '成績未達 ${prog.code} 要求（${JupasRequirements.failReasonAll(p, prog, grades)}）。';
    }
    if (p.jupasChoices.contains(code)) {
      return '志願清單已有 ${prog.code}。';
    }
    if (p.jupasChoices.length >= maxChoices) {
      return '最多 $maxChoices 個志願。';
    }
    p.jupasChoices = [...p.jupasChoices, code];
    p.jobTitle =
        '整緊 JUPAS 志願（${p.jupasChoices.length}/$maxChoices）';
    return '已加入第 ${p.jupasChoices.length} 志願：${prog.displayName}';
  }

  static String clearJupasChoices(Player p) {
    if (!canEditJupasChoices(p)) return '而家唔可以改志願。';
    p.jupasChoices = [];
    return '已清空 JUPAS 志願。';
  }

  /// 確認提交志願 → 等到夏天 Q3 出 Main Round（Q3 內提交則下季出）
  static String submitJupas(Player p) {
    if (!canSubmitJupas(p)) {
      if (hasSatDse(p) && !isJupasChoiceWindow(p)) {
        return '非 JUPAS 報名季。下次：Q4 正式開報，或 Q1 逾期窗。';
      }
      if (!hasDegreeGer(p)) {
        return JupasRequirements.degreeGerFailReason(JupasMatcher.gradesOf(p));
      }
      if (p.jupasChoices.isEmpty) return '請先加入最少 1 個志願。';
      return '而家唔可以提交 JUPAS。';
    }
    if (p.wealth < jupasApplicationFee) {
      return 'JUPAS 報名費不足：需要 \$$jupasApplicationFee';
    }
    p.wealth -= jupasApplicationFee;
    p.jupasPath = JupasPath.awaitingOffer;
    p.unlockedFlags.remove('dse_awaiting_decision');
    p.unlockedFlags.remove('dse_jupas_deferred');
    p.unlockedFlags.add('jupas_awaiting_main_round');
    p.unlockedFlags.remove('jupas_resolve_next_quarter');
    // Q3 提交（放榜季）→ 下季出結果；其餘 → 等下一個 Q3
    final resolveNext = p.quarter == Quarter.q3;
    if (resolveNext) {
      p.unlockedFlags.add('jupas_resolve_next_quarter');
    }
    p.lifeStage = LifeStage.adult;
    p.isStudying = false;
    p.currentSector = CareerSector.none;
    final hold = p.assoDepositPaid && p.assoHoldCode.isNotEmpty
        ? '\n兩手準備：已交 Asso／HD 留位費（${p.assoHoldCode}）。'
        : (p.assoHoldCode.isNotEmpty
            ? '\n提示：有 Asso conditional，記得交留位費。'
            : '\n提示：可同時申請 Asso／HD 做兩手準備。');
    final when = resolveNext
        ? '下一個 quarter 出 Main Round'
        : '等到下一個 Q3（夏天）出 Main Round';
    p.jobTitle = resolveNext
        ? '已報 JUPAS · 下季出 Main Round'
        : '已報 JUPAS · 等 Q3 Main Round';
    p.eventLog.add(
      '${p.year}年：提交 JUPAS（報名費 \$$jupasApplicationFee）。'
      '$when。\n${choicesLabel(p)}$hold',
    );
    return '已提交 JUPAS 志願（\$$jupasApplicationFee）。\n'
        '$when。\n'
        '${choicesLabel(p)}$hold';
  }

  /// 本季應否結算 Main Round（Q3 夏天；或 Q3 內提交後之下一季）
  static bool shouldResolveMainRoundThisQuarter(Player p) {
    if (!isAwaitingMainRound(p)) return false;
    if (p.unlockedFlags.contains('jupas_resolve_next_quarter')) return true;
    return p.quarter == Quarter.q3;
  }

  /// 申請 Asso／HD conditional offer（未交留位費）
  static String offerAssoConditional(Player p, String code) {
    if (!canApplyAsso(p)) {
      if (!hasAssoGer(p) && canApplyFoundation(p)) {
        return '未達 22222，請先讀 Foundation；Pass 後先可報 Asso／HD。';
      }
      if (hasAssoGer(p) && !isAssoApplicationWindow(p)) {
        return '非 Asso 主收生窗。${assoSeasonLabel(p)}'
            '（放榜後、Q3 夏天、或 Foundation Pass 後）。';
      }
      return '而家唔可以申請 Asso／HD。';
    }
    final prog = JupasCatalogue.byCode(code);
    if (prog == null || !_isAssoOrHd(prog)) {
      return '呢個唔係副學士／高級文憑課程。';
    }
    final grades = JupasMatcher.gradesOf(p);
    // Foundation Pass＝視同 22222；社區 Asso／HD 科目檢查由院校接納豁免
    final foundationOk = FoundationPathway.hasPassed(p) &&
        prog.tags.contains('community');
    if (!foundationOk && !JupasRequirements.meets(prog, grades)) {
      return '成績未達 ${prog.code} 科目要求'
          '（${JupasRequirements.failReason(prog, grades)}）。';
    }
    p.assoHoldCode = code;
    p.assoDepositPaid = false;
    p.jobTitle = 'Asso／HD conditional · ${prog.nameEn}（未交留位費）';
    p.eventLog.add(
      '${p.year}年：獲 ${prog.displayName} conditional offer；'
      '交留位費 \$$assoDepositFee 先確實有位。',
    );
    return 'Conditional offer：${prog.displayName}\n'
        '請繳交留位費 \$$assoDepositFee 確認學位。';
  }

  /// 交留位費：只鎖位，**唔即入學**；出結果／確認入讀時先揀
  static String payAssoDeposit(Player p) {
    if (!canPayAssoDeposit(p)) {
      if (p.assoHoldCode.isEmpty) return '未有 conditional offer。';
      if (p.assoDepositPaid) return '已交過留位費。';
      return '而家唔可以交留位費。';
    }
    if (p.wealth < assoDepositFee) {
      return '留位費不足：需要 \$$assoDepositFee';
    }
    final prog = JupasCatalogue.byCode(p.assoHoldCode);
    p.wealth -= assoDepositFee;
    p.assoDepositPaid = true;

    final dual = isAwaitingMainRound(p)
        ? '兩手準備：等 JUPAS Main Round 出結果時再揀入讀學士定 Asso。'
        : (canEditJupasChoices(p)
            ? '已留位。可再報 JUPAS 做兩手準備；或於升學卡確認入讀 Asso。'
            : '已留位。可於升學卡確認入讀，或等報名季再報 JUPAS。');
    p.jobTitle =
        'Asso／HD 已留位 · ${prog?.nameEn ?? p.assoHoldCode}（未確認入讀）';
    p.eventLog.add(
      '${p.year}年：繳交 Asso／HD 留位費 \$$assoDepositFee'
      '（${prog?.displayName ?? p.assoHoldCode}）。$dual',
    );
    return '已交留位費 \$$assoDepositFee\n'
        '${prog?.displayName ?? p.assoHoldCode}\n'
        '未即入學。$dual';
  }

  /// 確認入讀已留位嘅 Asso／HD（淨讀，或不取錄／放棄學士後）
  static String confirmAssoEnroll(
    Player p, {
    bool fromOfferDecision = false,
  }) {
    if (!hasPaidAssoHold(p)) return '未有已交留位費嘅 Asso／HD。';
    if (!fromOfferDecision && isAwaitingMainRound(p)) {
      return '仲等緊 JUPAS Main Round；出結果時再揀入讀邊個。';
    }
    if (!fromOfferDecision &&
        isOfferDecisionPending(p) &&
        hasPendingDegreeOffer(p)) {
      return '請喺「升學去向」事件卡揀入讀學士定 Asso。';
    }
    final prog = JupasCatalogue.byCode(p.assoHoldCode);
    if (prog == null) return '留位課程無效。';
    final grades = JupasMatcher.gradesOf(p);
    final score = JupasRequirements.admissionScore(prog, grades);
    final msg = _enroll(
      p,
      JupasMatch(programme: prog, score: score, meetsExpected: true),
      source: 'Asso／HD 留位確認入讀',
    );
    p.assoHoldCode = '';
    p.assoDepositPaid = false;
    p.jupasCode = '';
    _clearOfferPending(p);
    p.unlockedFlags.remove('dse_awaiting_decision');
    p.unlockedFlags.remove('dse_jupas_deferred');
    p.jupasChoices = [];
    p.completedExams.remove('jupas');
    return '已確認入讀 Asso／HD\n$msg';
  }

  /// 接受 Main Round 學士取錄
  static String acceptDegreeOffer(Player p) {
    if (!hasPendingDegreeOffer(p)) return '未有學士取錄可接受。';
    final prog = JupasCatalogue.byCode(p.jupasCode);
    if (prog == null) return '取錄課程無效。';
    final grades = JupasMatcher.gradesOf(p);
    final score = JupasRequirements.admissionScore(prog, grades);
    final match = JupasMatch(
      programme: prog,
      score: score,
      meetsExpected: true,
    );
    if (hasPaidAssoHold(p)) {
      p.eventLog.add(
        '${p.year}年：放棄 Asso／HD 留位（${p.assoHoldCode}）；'
        '留位費 \$$assoDepositFee 不退。',
      );
      p.assoHoldCode = '';
      p.assoDepositPaid = false;
    }
    p.completedExams.add('jupas');
    final msg = _enroll(p, match, source: 'JUPAS Main Round（玩家確認）');
    _clearOfferPending(p);
    p.unlockedFlags.remove('dse_awaiting_decision');
    p.unlockedFlags.remove('dse_jupas_deferred');
    p.jupasChoices = [];
    return '已確認入讀學士\n$msg';
  }

  /// 結算 Main Round：計有冇學士取錄，**唔自動入學**；之後由玩家揀去向
  static String resolveMainRound(Player p, {Random? random}) {
    if (!isAwaitingMainRound(p)) return '';

    final rng = random ?? Random(p.year * 41 + p.dseBestScore * 7);
    if (p.dseGrades.isEmpty) {
      p.dseGrades = DseGradeGenerator.generate(p);
      p.dseBestScore = DseGradeGenerator.bestNScore(p.dseGrades, 5);
    }

    p.unlockedFlags.remove('jupas_awaiting_main_round');
    p.unlockedFlags.remove('jupas_resolve_next_quarter');
    p.unlockedFlags.remove('dse_awaiting_decision');

    JupasMatch? offer;
    for (final code in p.jupasChoices) {
      final prog = JupasCatalogue.byCode(code);
      if (prog == null) continue;
      final hit = _evaluateOffer(p, prog, rng);
      if (hit != null) {
        offer = hit;
        break;
      }
    }

    p.unlockedFlags.add('jupas_offer_pending_choice');
    p.isStudying = false;
    p.currentSector = CareerSector.none;

    if (offer != null) {
      p.jupasCode = offer.programme.code;
      p.unlockedFlags.add('jupas_has_degree_offer');
      p.jupasPath = JupasPath.none;
      p.jobTitle = 'Main Round 取錄 · 揀去邊';
      final assoLine = hasPaidAssoHold(p)
          ? '\n同時有 Asso／HD 留位（${p.assoHoldCode}），可二選一。'
          : '';
      p.eventLog.add(
        '${p.year}年：JUPAS Main Round 取錄 ${offer.programme.displayName}。'
        '你揀入讀定放棄。$assoLine',
      );
      return 'JUPAS Main Round：獲取錄\n'
          '${offer.programme.displayName}\n'
          '收生分 ${offer.score}'
          '${offer.meetsExpected ? "" : "（邊緣）"}'
          '$assoLine\n'
          '請喺下一張卡揀去向。';
    }

    p.jupasCode = '';
    p.unlockedFlags.remove('jupas_has_degree_offer');
    p.jupasPath = JupasPath.none;
    p.jobTitle = hasPaidAssoHold(p)
        ? 'Main Round 未取錄 · 可入讀 Asso 留位'
        : 'Main Round 未取錄 · 揀去邊';
    final assoLine = hasPaidAssoHold(p)
        ? '\n你有 Asso／HD 留位（${p.assoHoldCode}）可入讀。'
        : (p.assoHoldCode.isNotEmpty && !p.assoDepositPaid
            ? '\n（有 conditional 但未交留位費，學位已失。）'
            : '');
    if (p.assoHoldCode.isNotEmpty && !p.assoDepositPaid) {
      p.assoHoldCode = '';
    }
    p.eventLog.add(
      '${p.year}年：JUPAS Main Round 未取錄。$assoLine'
      '你揀入讀 Asso／defer／重考／出社會。',
    );
    return 'JUPAS Main Round 未取錄$assoLine\n'
        '請喺下一張卡揀去向。';
  }

  static JupasMatch? _evaluateOffer(
    Player p,
    JupasProgramme prog,
    Random rng,
  ) {
    final grades = JupasMatcher.gradesOf(p);
    // 學士：先 33222 GER，再課程 PER
    if (_isJupasDegreeProgramme(prog) &&
        !JupasRequirements.meetsDegreeGer(grades)) {
      return null;
    }
    if (!JupasRequirements.meetsAll(p, prog, grades)) return null;
    var score = JupasRequirements.admissionScoreExact(prog, grades);
    if (p.dseSittingCount > 1 && prog.tags.contains('elite')) {
      score -= 2;
    }
    score += JupasMatcher.articulationBoost(p, prog);
    final expected = prog.expectedScore.toDouble();
    final solid = score >= expected - 1;
    final edge = score >= expected - 4 && rng.nextDouble() < 0.45;
    if (!solid && !edge) return null;
    return JupasMatch(
      programme: prog,
      score: score.round(),
      meetsExpected: score >= expected - 2,
    );
  }

  static String _enroll(
    Player p,
    JupasMatch match, {
    required String source,
  }) {
    final prog = match.programme;
    CareerData.onStartStudying(p);
    p.jupasCode = prog.code;
    p.isStudying = true;
    p.currentSector = CareerSector.student;
    p.jobTitle = '${prog.institution} · ${prog.nameZh}';
    p.studyProgram = prog.displayName;
    p.lifeStage = LifeStage.adult;

    switch (prog.award) {
      case JupasAward.bachelor:
        p.jupasPath = JupasPath.bachelor;
        p.education = EducationLevel.bachelor;
        p.unlockedFlags.add('local_uni');
        if (prog.tags.contains('med')) {
          p.unlockedFlags.addAll(['dse_god_tier', 'studying_medicine']);
          p.dseTier = DseTier.godTier;
        } else if (prog.tags.contains('pharmacy')) {
          p.unlockedFlags.addAll(['dse_god_tier', 'studying_pharmacy']);
          p.dseTier = DseTier.godTier;
        } else if (prog.tags.contains('law')) {
          p.unlockedFlags.addAll(['dse_god_tier', 'studying_law']);
          p.dseTier = DseTier.godTier;
        } else if (prog.tags.contains('nursing')) {
          p.unlockedFlags.add('studying_nursing');
          p.dseTier = DseTier.university;
          p.unlockedFlags.add('dse_university');
        } else if (prog.tags.contains('social') ||
            prog.tags.contains('social_work')) {
          p.unlockedFlags.add('studying_social');
          p.dseTier = DseTier.university;
          p.unlockedFlags.add('dse_university');
        } else if (prog.tags.contains('education')) {
          p.unlockedFlags.add('studying_education');
          p.dseTier = DseTier.university;
          p.unlockedFlags.add('dse_university');
        } else if (prog.tags.contains('elite')) {
          p.unlockedFlags.addAll(['dse_university', 'elite_uni']);
          p.dseTier = DseTier.university;
        } else {
          p.unlockedFlags.add('dse_university');
          p.dseTier = DseTier.university;
        }
        p.bachelorYear = 1;
        p.bachelorQuarters = 0;
        UniversityLife.resetOnEnroll(p);
        // 再入讀時清退學／輟學標記
        p.unlockedFlags.remove('uni_dismissed');
        p.unlockedFlags.remove('uni_dropped_out');
      case JupasAward.associate:
      case JupasAward.higherDiploma:
        p.jupasPath = JupasPath.associate;
        p.education = EducationLevel.associate;
        p.unlockedFlags.add('dse_associate');
        p.dseTier = DseTier.associate;
        for (final t in prog.tags) {
          if (t.startsWith('artic_') || t.startsWith('feed_')) {
            p.unlockedFlags.add(t);
          }
        }
        AssoArticulation.onEnrollAsso(p);
    }

    final articNote = prog.tags.contains('artic_social_work')
        ? '\n銜接優勢：升讀社工學士較有利'
        : (prog.tags.any((t) => t.startsWith('feed_'))
            ? '\n銜接優勢：對口院校學士較有利'
            : '');

    p.eventLog.add(
      '${p.year}年：$source → ${prog.displayName}'
      '（${prog.award.label} · 收生分 ${match.score}）。$articNote',
    );
    return '${prog.displayName}\n'
        '${prog.institution} · ${prog.award.label}\n'
        '收生分 ${match.score}'
        '${match.meetsExpected ? "" : "（邊緣取錄）"}'
        '$articNote';
  }

  /// Non-JUPAS／再入讀：直接入讀指定學士課程
  static String enrollBachelorProgramme(
    Player p,
    JupasProgramme prog, {
    required String source,
  }) {
    return _enroll(
      p,
      JupasMatch(programme: prog, score: 50, meetsExpected: true),
      source: source,
    );
  }

  static String deferJupas(Player p) {
    if (isEnrolledPostSecondary(p)) {
      return '已入讀專上／大學，唔可以 defer。';
    }
    if (hasPaidAssoHold(p)) {
      p.eventLog.add(
        '${p.year}年：放棄 Asso／HD 留位（${p.assoHoldCode}）；'
        '留位費 \$$assoDepositFee 不退。',
      );
      p.assoHoldCode = '';
      p.assoDepositPaid = false;
    } else {
      p.assoHoldCode = '';
      p.assoDepositPaid = false;
    }
    _clearOfferPending(p);
    p.jupasCode = '';
    p.jupasChoices = [];
    p.completedExams.remove('jupas');
    p.jupasPath = JupasPath.deferred;
    p.unlockedFlags.remove('dse_awaiting_decision');
    p.unlockedFlags.add('dse_jupas_deferred');
    p.isStudying = false;
    p.currentSector = CareerSector.none;
    p.jobTitle =
        '持 DSE Best5 ${p.dseBestScore} · 下屆 Q4／Q1 再報聯招';
    p.eventLog.add(
      '${p.year}年：唔報今屆／放棄取錄；成績永久有效。'
      '下屆報名：Q4 正式開報、Q1 逾期窗。',
    );
    return '已決定下屆再報聯招。\n'
        '下次可報：Q4（正式）或 Q1（逾期窗）。'
        '合計成績仍有效（院校可見所有 sitting）。';
  }

  static String startRetake(Player p, DseRetakeMode mode) {
    if (isEnrolledPostSecondary(p)) {
      return '已入讀專上／大學，唔可以重讀。';
    }
    if (!canRetake(p) || mode == DseRetakeMode.none) {
      return '未能申請重考。';
    }

    p.dseRetakeMode = mode;
    p.unlockedFlags.remove('dse_awaiting_decision');
    p.unlockedFlags.remove('dse_jupas_deferred');
    p.unlockedFlags.remove('jupas_awaiting_main_round');
    p.unlockedFlags.remove('jupas_resolve_next_quarter');
    _clearOfferPending(p);
    p.unlockedFlags.add('dse_retaking');
    p.unlockedFlags.add('dse_retake_used');
    p.jupasPath = JupasPath.none;
    p.jupasChoices = [];
    p.assoHoldCode = '';
    p.assoDepositPaid = false;
    p.lifeStage = LifeStage.secondary;
    p.education = EducationLevel.f6;
    p.completedExams.remove('dse_exam');

    switch (mode) {
      case DseRetakeMode.selfStudy:
        p.isStudying = true;
        p.currentSector = CareerSector.student;
        p.jobTitle = '自修生 · 備戰 DSE 重考';
        p.studyProgram = 'DSE 自修';
        p.wealth = (p.wealth - 8000).clamp(-999999, 999999999);
        p.discipline = (p.discipline + 3).clamp(0, 100);
        p.stress = (p.stress + 5).clamp(0, 100);
      case DseRetakeMode.originalSchool:
        p.isStudying = true;
        p.currentSector = CareerSector.student;
        final school = p.secondarySchoolName.isNotEmpty
            ? p.secondarySchoolName
            : p.schoolBand.secondaryLabel;
        p.jobTitle = '$school · 重讀中六';
        p.studyProgram = 'DSE 重讀（原校）';
        p.wealth = (p.wealth - 12000).clamp(-999999, 999999999);
        BirthGacha.applyStudyGain(p, base: 2);
        p.stress = (p.stress + 8).clamp(0, 100);
      case DseRetakeMode.transferSchool:
        p.isStudying = true;
        p.currentSector = CareerSector.student;
        p.jobTitle = '轉校重讀中六';
        p.studyProgram = 'DSE 重讀（轉校）';
        p.wealth = (p.wealth - 18000).clamp(-999999, 999999999);
        p.network = (p.network + 2).clamp(0, 100);
        p.stress = (p.stress + 10).clamp(0, 100);
        if (p.schoolBand == SchoolBand.band3) {
          p.schoolBand = SchoolBand.band2;
        }
      case DseRetakeMode.none:
        break;
    }

    p.eventLog.add(
      '${p.year}年：選擇${mode.label}，來年 Q3/Q4 再考 DSE。'
      '往屆成績會一併交聯招院校。',
    );
    return '${mode.label}\n來年考試季可再考；往屆＋應屆成績院校都會睇到。';
  }

  static String goWork(Player p) {
    if (isEnrolledPostSecondary(p)) {
      return '已入讀專上／大學，唔可以改做出社會。';
    }
    if (hasPaidAssoHold(p)) {
      p.eventLog.add(
        '${p.year}年：放棄 Asso／HD 留位（${p.assoHoldCode}）；'
        '留位費 \$$assoDepositFee 不退。',
      );
    }
    p.assoHoldCode = '';
    p.assoDepositPaid = false;
    _clearOfferPending(p);
    p.jupasCode = '';
    p.jupasChoices = [];
    p.completedExams.remove('jupas');
    p.jupasPath = JupasPath.work;
    p.unlockedFlags.remove('dse_awaiting_decision');
    p.unlockedFlags.remove('dse_jupas_deferred');
    p.unlockedFlags.add('workforce');
    p.isStudying = false;
    p.currentSector = CareerSector.none;
    p.jobTitle = '待業（出社會）';
    p.eventLog.add(
      '${p.year}年：唔報聯招／放棄取錄，出社會搵工。'
      '之後考試季仍可自費報 DSE；'
      '有成績可於 Q4／Q1 再報 JUPAS。',
    );
    return '已選擇出社會搵工。';
  }

  /// 放榜／報名事件卡選項（交志願 + Asso 兩手準備；無自動派位）
  static List<({String id, String label, void Function(Player) apply})>
      postResultsChoices(Player p) {
    final list =
        <({String id, String label, void Function(Player) apply})>[];

    if (canEditJupasChoices(p)) {
      list.addAll(_jupasChoiceBuilder(p));
    } else if (hasSatDse(p) &&
        !isAwaitingMainRound(p) &&
        !isEnrolledPostSecondary(p) &&
        !isRetaking(p) &&
        !isJupasChoiceWindow(p)) {
      list.add((
        id: 'jupas_season_closed',
        label:
            'JUPAS 報名未開放（而家 ${p.quarterLabel}）'
            '\n正式報名：Q4 · 逾期窗：Q1',
        apply: (pl) {
          pl.eventLog.add(
            '${pl.year}年：非報名季，未能改／交 JUPAS 志願。'
            '下次：Q4 正式／Q1 逾期。',
          );
        },
      ));
    }

    if (canApplyAsso(p) || canPayAssoDeposit(p)) {
      list.addAll(_assoChoices(p));
    } else if ((hasSatDse(p) || FoundationPathway.hasPassed(p)) &&
        hasAssoGer(p) &&
        !isRetaking(p) &&
        !isEnrolledPostSecondary(p) &&
        p.assoHoldCode.isEmpty &&
        !isAssoApplicationWindow(p)) {
      list.add((
        id: 'asso_season_closed',
        label:
            'Asso／HD 主收生窗未開（而家 ${p.quarterLabel}）'
            '\n放榜後、Q3 夏天、或 Foundation Pass 後可報',
        apply: (pl) {
          pl.eventLog.add(
            '${pl.year}年：${assoSeasonLabel(pl)}。暫未能申請 Asso／HD。',
          );
        },
      ));
    }

    if (canApplyFoundation(p)) {
      list.add((
        id: 'foundation',
        label:
            '報讀 Foundation／基礎專上文憑（\$${FoundationPathway.fee} · 一年）'
            '\n未達 22222：Pass 後先可報 Asso／HD',
        apply: (pl) {
          final msg = FoundationPathway.enroll(pl, source: 'DSE 未達 22222');
          pl.eventLog.add(msg);
        },
      ));
    }

    if (isAwaitingMainRound(p)) {
      final when = p.unlockedFlags.contains('jupas_resolve_next_quarter')
          ? '下季'
          : '下一個 Q3（夏天）';
      list.add((
        id: 'wait_main',
        label: '繼續等 $when JUPAS Main Round 結果',
        apply: (pl) {
          pl.eventLog.add('${pl.year}年：繼續等 JUPAS Main Round（$when）。');
        },
      ));
    }

    if (isAwaitingDecision(p) && !isAwaitingMainRound(p)) {
      list.add((
        id: 'defer',
        label: '今年唔報，下屆 Q4／Q1 再報聯招',
        apply: (pl) => deferJupas(pl),
      ));
    } else if (isOfferDecisionPending(p)) {
      list.add((
        id: 'defer',
        label: '全部唔讀，下屆 Q4／Q1 再報聯招',
        apply: (pl) => deferJupas(pl),
      ));
    }
    if (canRetake(p)) {
      list.add((
        id: 'retake_self',
        label: '自修生重考一年',
        apply: (pl) => startRetake(pl, DseRetakeMode.selfStudy),
      ));
      list.add((
        id: 'retake_orig',
        label: '原校重讀一年',
        apply: (pl) => startRetake(pl, DseRetakeMode.originalSchool),
      ));
      list.add((
        id: 'retake_xfer',
        label: '轉校重讀一年',
        apply: (pl) => startRetake(pl, DseRetakeMode.transferSchool),
      ));
    }
    if (canChooseWork(p)) {
      list.add((
        id: 'work',
        label: '唔讀大學，出社會搵工',
        apply: (pl) => goWork(pl),
      ));
    }
    return list;
  }

  /// 而家應否顯示升學規劃卡（有卡必有 ≥1 個選項）
  static bool shouldShowPostResultsPlanner(Player p) =>
      !isOfferDecisionPending(p) && postResultsChoices(p).isNotEmpty;

  static List<EventChoice> postResultsEventChoices(Player p) {
    final choices = postResultsChoices(p);
    assert(choices.isNotEmpty, 'postResultsEventChoices called with no options');
    return [
      for (final c in choices)
        EventChoice(label: c.label, apply: (pl) => c.apply(pl)),
    ];
  }

  static List<({String id, String label, void Function(Player) apply})>
      _jupasChoiceBuilder(Player p) {
    final list =
        <({String id, String label, void Function(Player) apply})>[];
    final grades = JupasMatcher.gradesOf(p);
    if (!JupasRequirements.meetsDegreeGer(grades)) {
      list.add((
        id: 'ger_degree_blocked',
        label:
            '未達大學一般入學 33222：${JupasRequirements.degreeGerFailReason(grades)}'
            '\n（有 22222 可報 Asso／HD；否則讀 Foundation）',
        apply: (pl) {
          pl.eventLog.add(
            '${pl.year}年：未達 33222，未能報 JUPAS 學士志願。',
          );
        },
      ));
      return list;
    }

    final ranked = JupasMatcher.rankedForPlayer(p, limit: 10)
        .where((m) => _isJupasDegreeProgramme(m.programme))
        .where((m) => !p.jupasChoices.contains(m.programme.code))
        .take(6);

    for (final m in ranked) {
      final prog = m.programme;
      final tag = prog.tags.contains('sssdp') ? 'SSSDP' : 'JUPAS';
      list.add((
        id: 'add_${prog.code}',
        label:
            '加入志願：${prog.code} ${prog.nameEn}（$tag · 分 ${m.score}）',
        apply: (pl) => addJupasChoice(pl, prog.code),
      ));
    }

    if (p.jupasChoices.isNotEmpty) {
      list.add((
        id: 'clear_choices',
        label: '清空志願（而家 ${p.jupasChoices.length} 個）',
        apply: (pl) => clearJupasChoices(pl),
      ));
      final when = p.quarter == Quarter.q3
          ? '下季出 Main Round'
          : '等下一個 Q3（夏天）出 Main Round';
      list.add((
        id: 'submit_jupas',
        label:
            '確認提交 JUPAS（\$$jupasApplicationFee · $when）\n'
            '${choicesLabel(p)}',
        apply: (pl) => submitJupas(pl),
      ));
    } else if (list.isEmpty) {
      list.add((
        id: 'no_degree_match',
        label:
            '未有符合科目要求的 JUPAS 學士課程'
            '\n（已達 33222，但選修未配合；可報 Asso／HD 或 Foundation）',
        apply: (pl) {
          pl.eventLog.add('${pl.year}年：未有合適學士志願可加入。');
        },
      ));
    }
    return list;
  }

  static List<({String id, String label, void Function(Player) apply})>
      _assoChoices(Player p) {
    final list =
        <({String id, String label, void Function(Player) apply})>[];

    if (canPayAssoDeposit(p)) {
      final prog = JupasCatalogue.byCode(p.assoHoldCode);
      list.add((
        id: 'pay_deposit',
        label:
            '繳交留位費 \$$assoDepositFee（${prog?.nameEn ?? p.assoHoldCode}）'
            '\n只鎖位，出結果／確認時先揀入讀',
        apply: (pl) => payAssoDeposit(pl),
      ));
    }

    if (hasPaidAssoHold(p) &&
        !isAwaitingMainRound(p) &&
        !isOfferDecisionPending(p)) {
      final prog = JupasCatalogue.byCode(p.assoHoldCode);
      list.add((
        id: 'confirm_asso',
        label:
            '確認入讀 Asso／HD：${prog?.nameZh ?? p.assoHoldCode}'
            '\n（放棄再等聯招）',
        apply: (pl) => confirmAssoEnroll(pl),
      ));
    }

    if (canApplyAsso(p)) {
      final assos = _eligibleAssoMatches(p);
      // 按院校分組；每間展示其全部學院方向（達門檻先出現）
      final ordered = <JupasMatch>[];
      final seenInst = <String>{};
      for (final m in assos) {
        seenInst.add(m.programme.institution);
      }
      for (final inst in seenInst) {
        ordered.addAll(
          assos.where((m) => m.programme.institution == inst),
        );
      }
      for (final m in ordered) {
        final prog = m.programme;
        final hints = <String>[];
        if (prog.tags.contains('artic_social_work')) {
          hints.add('升社工有利');
        }
        if (prog.tags.contains('artic_law')) hints.add('升法律有利');
        if (prog.tags.contains('artic_nursing') ||
            prog.tags.contains('artic_health')) {
          hints.add('升護理／健康有利');
        }
        for (final t in prog.tags) {
          if (t.startsWith('feed_')) {
            hints.add('對口${t.substring(5)}');
          }
        }
        final field = prog.tags.contains('business')
            ? '商'
            : prog.tags.contains('engineering')
                ? '工'
                : prog.tags.contains('stem')
                    ? '理'
                    : prog.tags.contains('social')
                        ? '社科'
                        : prog.tags.contains('education')
                            ? '教育'
                            : prog.tags.contains('law')
                                ? '法律'
                                : prog.tags.contains('nursing') ||
                                        prog.tags.contains('health')
                                    ? '健康'
                                    : prog.tags.contains('arts')
                                        ? '文'
                                        : '一般';
        final hint = hints.isEmpty ? '' : ' · ${hints.join("、")}';
        list.add((
          id: 'asso_${prog.code}',
          label:
              '申請${prog.award.label}〔$field〕：${prog.institution} · ${prog.nameZh}'
              '$hint（留位費 \$$assoDepositFee）',
          apply: (pl) => offerAssoConditional(pl, prog.code),
        ));
      }
    }
    return list;
  }

  /// 統一入口：交志願／Asso 事件卡（含 defer／重考／搵工）
  /// 呼叫方應先用 [shouldShowPostResultsPlanner]；空選項唔應 insert。
  static StoryEvent applicationEvent(Player p) {
    final g = JupasMatcher.gradesOf(p);
    final grades = DseGradeGenerator.summaryLabel(p.dseGrades);
    final body = StringBuffer()
      ..writeln('Best5 ${p.dseBestScore}（${p.dseTier.label}）')
      ..writeln(grades)
      ..writeln(
        '一般入學：Asso／HD 22222＝'
        '${JupasRequirements.meetsAssoGer(g) || FoundationPathway.hasPassed(p) ? "達標" : "未達"}'
        ' · 大學 33222＝'
        '${JupasRequirements.meetsDegreeGer(g) ? "達標" : "未達"}',
      )
      ..writeln('報名窗：${jupasSeasonLabel(p)}')
      ..writeln('JUPAS 志願：')
      ..writeln(choicesLabel(p));
    if (p.assoHoldCode.isNotEmpty) {
      body.writeln(
        'Asso／HD：${p.assoHoldCode}'
        '${p.assoDepositPaid ? "（已交留位費）" : "（未交留位費）"}',
      );
    }
    body.write(
      '33222／22222＝入場資格；各課程仲有自己科目要求。'
      'JUPAS：Q4 正式／Q1 逾期；放榜後短窗可改；Main Round 喺 Q3（夏天）。'
      'Asso 交留位＝鎖位唔即入學；出結果時再揀學士／Asso／放棄。',
    );

    return StoryEvent(
      id: 'jupas_programme_pick',
      title: isAwaitingMainRound(p)
          ? '兩手準備 · 等 Main Round'
          : '報 JUPAS／Asso · 兩手準備',
      body: body.toString(),
      choices: postResultsEventChoices(p),
      isSystem: true,
    );
  }

  static StoryEvent mainRoundResultEvent(Player p, String resultMsg) =>
      offerDecisionEvent(p, resultMsg: resultMsg);

  /// Main Round 後：玩家揀學士／Asso／defer／重考／出社會
  static StoryEvent offerDecisionEvent(Player p, {String resultMsg = ''}) {
    final hasDegree = hasPendingDegreeOffer(p);
    final hasAsso = hasPaidAssoHold(p);
    final degreeProg =
        hasDegree ? JupasCatalogue.byCode(p.jupasCode) : null;
    final assoProg =
        hasAsso ? JupasCatalogue.byCode(p.assoHoldCode) : null;

    final body = StringBuffer();
    if (resultMsg.isNotEmpty) {
      body.writeln(resultMsg);
      body.writeln();
    }
    body.writeln(
      hasDegree
          ? '學士取錄：${degreeProg?.displayName ?? p.jupasCode}'
          : '學士：未取錄',
    );
    body.writeln(
      hasAsso
          ? 'Asso／HD 留位：${assoProg?.displayName ?? p.assoHoldCode}'
          : 'Asso／HD：無已交留位',
    );
    body.write(
      '請揀今屆去向。兩個都唔想要可以 defer、重考或出社會。',
    );

    final choices = <EventChoice>[];
    if (hasDegree) {
      choices.add(EventChoice(
        label: '入讀學士：${degreeProg?.nameZh ?? p.jupasCode}',
        apply: (pl) => acceptDegreeOffer(pl),
      ));
    }
    if (hasAsso) {
      choices.add(EventChoice(
        label: '入讀 Asso／HD：${assoProg?.nameZh ?? p.assoHoldCode}',
        apply: (pl) => confirmAssoEnroll(pl, fromOfferDecision: true),
      ));
    }
    if (canRetake(p)) {
      choices.add(EventChoice(
        label: '自修生重考一年',
        apply: (pl) => startRetake(pl, DseRetakeMode.selfStudy),
      ));
      choices.add(EventChoice(
        label: '原校重讀一年',
        apply: (pl) => startRetake(pl, DseRetakeMode.originalSchool),
      ));
      choices.add(EventChoice(
        label: '轉校重讀一年',
        apply: (pl) => startRetake(pl, DseRetakeMode.transferSchool),
      ));
    }
    choices.add(EventChoice(
      label: '全部唔讀，下屆 Q4／Q1 再報',
      apply: (pl) => deferJupas(pl),
    ));
    choices.add(EventChoice(
      label: '唔讀，出社會搵工',
      apply: (pl) => goWork(pl),
    ));

    return StoryEvent(
      id: 'jupas_offer_decision',
      title: '升學去向決定',
      body: body.toString(),
      choices: choices,
      isSystem: true,
    );
  }
}
