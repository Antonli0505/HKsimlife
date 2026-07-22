import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'jupas/jupas.dart';
import 'jupas_pathway.dart';
import 'part_time_jobs.dart';
import 'social_circle.dart';
import 'university_pathway.dart';
import 'university_societies.dart';

/// 大學生活 MVP：Hall、學費、GPA、probation／延遲／勸退
abstract final class UniversityLife {
  static const double minGraduateGpa = 1.0;
  static const double probationGpa = 1.5;
  static const int maxDelayYears = 2;
  /// 本地學士全年學費；每學期收一半（一年兩學期）
  static const int annualTuition = 44320;
  static int get semesterTuition => annualTuition ~/ 2; // 22160

  /// 屋企幫手：有幫但唔會幫晒；R 主要靠 grant／loan 補
  static double familySupportRate(Player p) => switch (p.birthTier) {
        BirthTier.ssr => 0.60,
        BirthTier.sr => 0.35,
        BirthTier.r => 0.15,
      };

  /// R：家庭之後剩餘開支，政府 grant 承擔比例（唔使還）
  static const double rGrantRate = 0.55;

  static String honoursForGpa(double gpa) {
    if (gpa >= 3.60) return 'First Class Honours';
    if (gpa >= 3.00) return 'Second Class Honours (Division I)';
    if (gpa >= 2.40) return 'Second Class Honours (Division II)';
    if (gpa >= 1.70) return 'Third Class Honours';
    if (gpa >= minGraduateGpa) return 'Pass';
    return '未達畢業';
  }

  static String honoursLabelZh(String honours) => switch (honours) {
        'First Class Honours' => '一級榮譽',
        'Second Class Honours (Division I)' => '二級甲等榮譽',
        'Second Class Honours (Division II)' => '二級乙等榮譽',
        'Third Class Honours' => '三級榮譽',
        'Pass' => '及格畢業',
        _ => honours,
      };

  static bool needsOrientation(Player p) =>
      UniversityPathway.isStudyingBachelor(p) &&
      !p.unlockedFlags.contains('uni_orientation_done');

  /// 入學時重置大學生活欄位
  static void resetOnEnroll(Player p) {
    p.uniGpa = 0;
    p.uniStudyLoad = UniStudyLoad.none;
    p.uniStudySessions = 0;
    p.inHall = false;
    p.hallPoints = 0;
    p.uniProbation = false;
    p.uniDelayYears = 0;
    p.uniHonours = '';
    // studentLoanDebt 保留（舊債要繼續還）
    UniversitySocieties.resetOnEnroll(p);
    p.unlockedFlags.remove('uni_orientation_done');
    p.unlockedFlags.remove('uni_dismissed');
    p.unlockedFlags.remove('uni_dropped_out');
    p.unlockedFlags.add('exchange_locked');
  }

  static StoryEvent? orientationEvent(Player p) {
    if (!needsOrientation(p)) return null;
    final inst = p.studyProgram.isNotEmpty ? p.studyProgram : '大學';
    return StoryEvent(
      id: 'uni_orientation',
      title: '大學開學 · $inst',
      body: '迎新週開始。要唔要申請 Hall？\n'
          '（Y1 申請成功率較高。溫書力度之後每季自己揀，耗不同 AP。）',
      isSystem: true,
      choices: [
        EventChoice(
          label: '申請 Hall',
          apply: (pl) => _completeOrientation(pl, applyHall: true),
        ),
        EventChoice(
          label: '唔申請 Hall（住屋企／外面）',
          apply: (pl) => _completeOrientation(pl, applyHall: false),
        ),
      ],
    );
  }

  static void _completeOrientation(Player p, {required bool applyHall}) {
    p.unlockedFlags.add('uni_orientation_done');

    if (applyHall) {
      final chance = p.bachelorYear <= 1 ? 0.85 : 0.45;
      if (Random(p.year * 31 + p.age * 7 + p.hallPoints).nextDouble() <
          chance) {
        p.inHall = true;
        p.livesWithFamily = false;
        p.hallPoints += 5;
        p.eventLog.add('${p.year}年：成功入 Hall。');
      } else {
        p.inHall = false;
        p.eventLog.add('${p.year}年：Hall 申請失敗，繼續住屋企／外面。');
      }
    } else {
      p.inHall = false;
      p.eventLog.add('${p.year}年：唔申請 Hall。');
    }
  }

  /// Q1 考試結算 GPA
  static String? settleExamGpa(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return null;

    final semester = _computeSemesterGpa(p);
    if (p.uniGpa <= 0) {
      p.uniGpa = semester;
    } else {
      p.uniGpa =
          double.parse(((p.uniGpa * 0.55) + (semester * 0.45)).toStringAsFixed(2));
    }
    p.uniGpa = p.uniGpa.clamp(0.0, 4.3);

    p.eventLog.add(
      '${p.year}年 Q1：學期 GPA ${semester.toStringAsFixed(2)}'
      ' → 累積 ${p.uniGpa.toStringAsFixed(2)}'
      '（溫書點數 ${p.uniStudySessions}）',
    );
    return '考試放榜：學期 GPA ${semester.toStringAsFixed(2)}\n'
        '累積 GPA ${p.uniGpa.toStringAsFixed(2)}'
        '${p.uniProbation ? "（試讀中）" : ""}';
  }

  static double _computeSemesterGpa(Player p) {
    // 底分靠溫書累積（輕鬆／均衡／硬食耗 AP 換 sessions）
    const base = 1.8;
    final sessions = p.uniStudySessions.clamp(0, 18) * 0.14;
    final smarts = p.smarts / 100.0 * 0.9;
    final discipline = p.discipline / 100.0 * 0.35;
    final stressPenalty = p.stress / 100.0 * 0.85;
    final hallMod = p.inHall ? -0.1 : 0.0;
    final raw =
        base + sessions + smarts + discipline + hallMod - stressPenalty;
    return double.parse(raw.clamp(0.0, 4.3).toStringAsFixed(2));
  }

  /// Q4／Q2 收學期學費；每季扣生活／宿費
  static String? applyQuarterlyCosts(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return null;

    final chargeTuition =
        p.quarter == Quarter.q4 || p.quarter == Quarter.q2;
    final tuition = chargeTuition ? semesterTuition : 0;
    final living = p.inHall
        ? 4500
        : (p.livesWithFamily ? 1500 : 6000);
    final hallFee = p.inHall ? 4000 : 0;
    final total = tuition + living + hallFee;

    final familyTarget = (total * familySupportRate(p)).round();
    final familyPaid = p.familyWealth.clamp(0, familyTarget);
    if (familyPaid > 0) {
      p.familyWealth -= familyPaid;
      p.eventLog.add(
        '${p.year}年：屋企代付 \$$familyPaid'
        '（目標 ${(familySupportRate(p) * 100).round()}%）',
      );
    }

    var remaining = total - familyPaid;
    final msgs = <String>[];

    // R：政府 grant 先減一截（唔使還），其餘先現金再 loan
    if (remaining > 0 && p.birthTier == BirthTier.r) {
      final grant = (remaining * rGrantRate).round();
      if (grant > 0) {
        remaining -= grant;
        p.eventLog.add('${p.year}年：學費 grant \$$grant（唔使還）');
        msgs.add('學費 grant \$$grant');
      }
    }

    if (remaining > 0) {
      final cashUse = p.wealth.clamp(0, remaining);
      p.wealth -= cashUse;
      final shortfall = remaining - cashUse;

      if (shortfall > 0) {
        p.studentLoanDebt += shortfall;
        p.eventLog.add(
          '${p.year}年：學生貸款 \$$shortfall'
          '（尚欠 \$${p.studentLoanDebt}）',
        );
        msgs.add('學生貸款 \$$shortfall（要還）');
      }
    }

    if (chargeTuition) {
      msgs.insert(0, '學期學費 \$$semesterTuition（全年 \$$annualTuition）');
    }

    if (p.wealth < 0) {
      p.stress = (p.stress + 6).clamp(0, 100);
      p.san = (p.san - 3).clamp(0, p.maxSan);
    }

    return msgs.isEmpty ? null : msgs.join('\n');
  }

  /// 有貸款則從現金還（預設每季上限；[maxPay] 可一次還晒）
  static String? repayStudentLoan(Player p, {int? maxPay}) {
    if (p.studentLoanDebt <= 0 || p.wealth <= 0) return null;
    final cap = maxPay ?? 8000;
    final pay =
        [p.studentLoanDebt, p.wealth, cap].reduce((a, b) => a < b ? a : b);
    if (pay <= 0) return null;
    p.wealth -= pay;
    p.studentLoanDebt -= pay;
    final allClear = p.studentLoanDebt <= 0;
    p.eventLog.add(
      allClear
          ? '${p.year}年：已還晒學生貸款（今次 \$$pay）。'
          : '${p.year}年：償還學生貸款 \$$pay（尚欠 \$${p.studentLoanDebt}）',
    );
    return allClear
        ? '已還晒學生貸款！'
        : '還學生貸款 \$$pay（尚欠 \$${p.studentLoanDebt}）';
  }

  static String? repayStudentLoanInFull(Player p) {
    if (p.studentLoanDebt <= 0) return '冇學生貸款要還';
    if (p.wealth < p.studentLoanDebt) {
      return '現金唔夠還晒（要 \$${p.studentLoanDebt}，而家 \$${p.wealth}）';
    }
    return repayStudentLoan(p, maxPay: p.studentLoanDebt);
  }

  /// 生活 tab：還款掣（讀緊／出社會都得）
  static List<ActionButton> loanRepayActions(Player p) {
    if (p.studentLoanDebt <= 0 || p.wealth <= 0) return const [];
    // 今次實際會還：min(尚欠, 現金, 8000)
    final installment =
        [p.studentLoanDebt, p.wealth, 8000].reduce((a, b) => a < b ? a : b);
    final buttons = <ActionButton>[
      ActionButton(
        label: '還學生貸款（今次 \$$installment）',
        apCost: 0,
        onExecute: (pl) => repayStudentLoan(pl),
      ),
    ];
    if (p.wealth >= p.studentLoanDebt && p.studentLoanDebt > installment) {
      buttons.add(ActionButton(
        label: '還晒學生貸款（\$${p.studentLoanDebt}）',
        apCost: 0,
        onExecute: (pl) => repayStudentLoanInFull(pl),
      ));
    } else if (p.wealth >= p.studentLoanDebt) {
      // 一次就清得晒，只顯示還晒
      buttons
        ..clear()
        ..add(ActionButton(
          label: '還晒學生貸款（\$${p.studentLoanDebt}）',
          apCost: 0,
          onExecute: (pl) => repayStudentLoanInFull(pl),
        ));
    }
    return buttons;
  }

  /// Q1：未清貸款收年息 2%
  static String? accrueStudentLoanInterest(Player p) {
    if (p.studentLoanDebt <= 0 || p.quarter != Quarter.q1) return null;
    final interest = (p.studentLoanDebt * 0.02).round().clamp(1, 999999);
    p.studentLoanDebt += interest;
    p.eventLog.add(
      '${p.year}年：學生貸款年息 \$$interest（尚欠 \$${p.studentLoanDebt}）',
    );
    return '學生貸款利息 \$$interest';
  }

  /// 學年結束：probation／延遲／勸退／升年／畢業
  static String resolveAcademicYear(Player p) {
    p.uniStudySessions = 0;

    final gpa = p.uniGpa;
    if (gpa > 0 && gpa < 1.0) {
      if (p.uniProbation) {
        return _dismiss(p, 'GPA 持續低於 1.0，校方勸退');
      }
      p.uniProbation = true;
      p.eventLog.add(
        '${p.year}年：GPA ${gpa.toStringAsFixed(2)} 極低，入咗試讀。',
      );
    } else if (gpa > 0 && gpa < probationGpa) {
      if (!p.uniProbation) {
        p.uniProbation = true;
        p.eventLog.add(
          '${p.year}年：GPA ${gpa.toStringAsFixed(2)} 偏低，入咗試讀。',
        );
      }
    } else if (gpa >= 2.0 && p.uniProbation) {
      p.uniProbation = false;
      p.unlockedFlags.remove('uni_probation_seen');
      p.eventLog.add('${p.year}年：GPA 回升至 ${gpa.toStringAsFixed(2)}，過咗試讀。');
    }

    final needed =
        UniversityPathway.degreeDuration(p) + p.uniDelayYears;

    if (p.bachelorYear >= needed) {
      if (_canGraduate(p)) {
        return UniversityPathway.graduate(p);
      }
      if (p.uniDelayYears < maxDelayYears && gpa >= minGraduateGpa) {
        p.uniDelayYears++;
        p.bachelorYear++;
        UniversitySocieties.onAcademicYearAdvance(p);
        final inst = p.studyProgram.isNotEmpty ? p.studyProgram : '大學';
        p.jobTitle = '$inst · Year ${p.bachelorYear}（延遲）';
        p.eventLog.add(
          '${p.year}年：延遲畢業一年（累計延遲 ${p.uniDelayYears} 年）。',
        );
        return 'GPA／狀態未達穩妥畢業線，延遲一年。\n'
            '而家 Year ${p.bachelorYear}（延遲 ${p.uniDelayYears} 年）';
      }
      return _dismiss(p, 'GPA／試讀唔過關，畢唔到業');
    }

    p.bachelorYear++;
    final inst = p.studyProgram.isNotEmpty ? p.studyProgram : '大學';
    p.jobTitle = '$inst · Year ${p.bachelorYear}';
    UniversitySocieties.onAcademicYearAdvance(p);
    final note = p.uniProbation ? '（仲係試讀中）' : '';
    return '大學升 Year ${p.bachelorYear}$note（$inst）';
  }

  static bool _canGraduate(Player p) =>
      p.uniGpa >= minGraduateGpa && !p.uniProbation;

  /// 勸退／自行輟學：清入學狀態，可返去做嘢或再報讀
  static String leaveWithoutGraduate(
    Player p, {
    required String reason,
    bool dismissed = false,
  }) {
    p.isStudying = false;
    p.currentSector = CareerSector.none;
    p.inHall = false;
    p.bachelorYear = 0;
    p.bachelorQuarters = 0;
    p.uniProbation = false;
    p.uniDelayYears = 0;
    p.uniStudySessions = 0;
    p.uniStudyLoad = UniStudyLoad.none;
    p.studyProgram = '';
    p.jupasCode = '';
    p.jupasChoices = [];
    p.jupasPath = JupasPath.none;
    p.completedExams.remove('jupas');
    UniversitySocieties.resetOnEnroll(p); // clear societies on leave
    p.unlockedFlags.remove('jupas_awaiting_main_round');
    p.unlockedFlags.remove('jupas_resolve_next_quarter');
    p.unlockedFlags.remove('jupas_offer_pending_choice');
    p.unlockedFlags.remove('jupas_has_degree_offer');
    p.unlockedFlags.remove('studying_medicine');
    p.unlockedFlags.remove('studying_law');
    p.unlockedFlags.remove('studying_pharmacy');
    p.unlockedFlags.remove('studying_nursing');
    p.unlockedFlags.remove('studying_social');
    p.unlockedFlags.remove('studying_education');

    // 有 DSE：學歷退回 F6，方便再報 JUPAS；IB 等保留 bachelor 紀錄但唔再讀
    if (p.dseSittingCount > 0) {
      p.education = EducationLevel.f6;
    }

    if (dismissed) {
      p.unlockedFlags.add('uni_dismissed');
      p.jobTitle = '大學退學 · 待業';
    } else {
      p.unlockedFlags.add('uni_dropped_out');
      p.jobTitle = '待業';
    }
    p.eventLog.add('${p.year}年：$reason（可再報讀或出社會搵工）');
    return dismissed
        ? '勸退：$reason\n你可以出社會做嘢，或者之後再報學士／Asso。'
        : '已退學唔讀：$reason\n你可以出社會做嘢，或者之後再報學士／Asso。';
  }

  static String _dismiss(Player p, String reason) =>
      leaveWithoutGraduate(p, reason: reason, dismissed: true);

  /// 已畢業／退學／輟學後，可再追另一個學士（Non-JUPAS 入口）
  static bool canApplyAnotherBachelor(Player p) {
    if (p.lifeStage != LifeStage.adult || p.isStudying) return false;
    if (p.unlockedFlags.contains('jupas_awaiting_main_round')) return false;
    if (p.unlockedFlags.contains('jupas_offer_pending_choice')) return false;
    return p.unlockedFlags.contains('bachelor_graduated') ||
        p.unlockedFlags.contains('uni_dismissed') ||
        p.unlockedFlags.contains('uni_dropped_out');
  }

  static StoryEvent anotherBachelorEvent(Player p) {
    final ranked = p.dseSittingCount > 0
        ? JupasMatcher.rankedForPlayer(p, limit: 12)
            .where((m) => m.programme.award == JupasAward.bachelor)
            .take(8)
            .toList()
        : JupasCatalogue.all
            .where((prog) =>
                prog.award == JupasAward.bachelor &&
                !prog.tags.contains('community'))
            .take(8)
            .map((prog) => JupasMatch(
                  programme: prog,
                  score: 50,
                  meetsExpected: true,
                ))
            .toList();

    final choices = <EventChoice>[
      for (final m in ranked)
        EventChoice(
          label: 'Non-JUPAS：${m.programme.displayName}',
          apply: (pl) {
            JupasPathway.enrollBachelorProgramme(
              pl,
              m.programme,
              source: pl.unlockedFlags.contains('bachelor_graduated')
                  ? '第二個學士（Non-JUPAS）'
                  : '再入讀學士（Non-JUPAS）',
            );
          },
        ),
      EventChoice(
        label: '暫時唔報',
        apply: (_) {},
      ),
    ];

    return StoryEvent(
      id: 'another_bachelor',
      title: p.unlockedFlags.contains('bachelor_graduated')
          ? '再讀一個學士？'
          : '再入讀學士',
      body: p.unlockedFlags.contains('bachelor_graduated')
          ? '你已經有一個學位。可以用 Non-JUPAS 再報另一個學士'
              '（或者等到 Q4／Q1 用舊 DSE 再走 JUPAS）。'
          : '用 Non-JUPAS 再入讀學士，或者等到報名季走 JUPAS／Asso。',
      isSystem: true,
      choices: choices,
    );
  }

  // ── 溫書：三檔，耗不同 AP ──

  static void studyLight(Player p) {
    p.uniStudyLoad = UniStudyLoad.light;
    p.uniStudySessions += 1;
    p.smarts = (p.smarts + 1).clamp(0, 100);
    p.stress = (p.stress + 2).clamp(0, 100);
    p.san = (p.san - 1).clamp(0, p.maxSan);
  }

  static void studyBalanced(Player p) {
    p.uniStudyLoad = UniStudyLoad.balanced;
    p.uniStudySessions += 2;
    p.smarts = (p.smarts + 2).clamp(0, 100);
    p.discipline = (p.discipline + 1).clamp(0, 100);
    p.stress = (p.stress + 3).clamp(0, 100);
    p.san = (p.san - 2).clamp(0, p.maxSan);
  }

  static void studyHard(Player p) {
    p.uniStudyLoad = UniStudyLoad.hard;
    p.uniStudySessions += 3;
    p.smarts = (p.smarts + 4).clamp(0, 100);
    p.discipline = (p.discipline + 2).clamp(0, 100);
    p.stress = (p.stress + 6).clamp(0, 100);
    p.san = (p.san - 4).clamp(0, p.maxSan);
    SocialCircle.markHarshStudy(p);
  }

  /// 兼容舊呼叫 → 當均衡
  static void studyAction(Player p) => studyBalanced(p);

  static List<ActionButton> studyButtons() => [
        ActionButton(
          label: '溫書·輕鬆',
          apCost: 1,
          onExecute: studyLight,
        ),
        ActionButton(
          label: '溫書·均衡',
          apCost: 2,
          onExecute: studyBalanced,
        ),
        ActionButton(
          label: '溫書·硬食',
          apCost: 3,
          onExecute: studyHard,
        ),
      ];

  static void clubAction(Player p) {
    // 舊掣：打開加入學會流程用 flag（由 game_state flush）
    p.unlockedFlags.add('uni_society_join_pending');
  }

  static void partTimeAction(Player p) {
    // 兼容舊呼叫 → 轉去真實兼職系統
    if (PartTimeJobs.hasJob(p)) {
      p.eventLog.add(PartTimeJobs.workShift(p));
    } else {
      p.unlockedFlags.add('pt_hire_pending');
      p.eventLog.add('${p.year}年：未有兼職，去搵一份先');
    }
  }

  static void hallActivityAction(Player p) {
    if (!p.inHall) return;
    p.hallPoints = (p.hallPoints + 6).clamp(0, 100);
    p.network = (p.network + 3).clamp(0, 100);
    p.san = (p.san + 4).clamp(0, p.maxSan);
    p.stress = (p.stress - 2).clamp(0, 100);
    SocialCircle.tryMeet(p, FriendSource.uni, baseChance: 0.35);
  }

  static void socialAction(Player p) {
    p.network = (p.network + 4).clamp(0, 100);
    p.san = (p.san + 5).clamp(0, p.maxSan);
    p.stress = (p.stress - 3).clamp(0, 100);
    if (p.wealth >= 300) p.wealth -= 300;
    SocialCircle.tryMeet(p, FriendSource.uni, baseChance: 0.45);
  }

  static void exchangeLockedAction(Player p) {
    p.eventLog.add(
      '${p.year}年：海外交換暫時未開放（MVP）。',
    );
  }

  static List<ActionButton> lifestyleActions(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return const [];

    final buttons = <ActionButton>[
      ...studyButtons(),
      ActionButton(
        label: '加入／管理學會',
        apCost: 1,
        onExecute: clubAction,
      ),
      ActionButton(
        label: '社交聚會',
        apCost: 1,
        onExecute: socialAction,
      ),
      ActionButton(
        label: PartTimeJobs.hasJob(p) ? '兼職返工' : '搵兼職',
        apCost: 1,
        onExecute: partTimeAction,
      ),
      ActionButton(
        label: '海外交換（未開放）',
        apCost: 0,
        enabled: false,
        onExecute: exchangeLockedAction,
      ),
    ];

    if (p.inHall) {
      buttons.insert(
        3,
        ActionButton(
          label: 'Hall 活動',
          apCost: 1,
          onExecute: hallActivityAction,
        ),
      );
    }

    if (UniversitySocieties.needsDutyPrompt(p)) {
      final pending = UniversitySocieties.pendingDutyIds(p);
      final first = pending.isNotEmpty ? pending.first : 'astro';
      final name =
          UniversitySocieties.byId(first)?.nameZh ?? '學會';
      buttons.insert(
        1,
        ActionButton(
          label: '學會活動：$name',
          apCost: 2,
          isConditional: true,
          onExecute: (pl) => UniversitySocieties.runDuty(pl, first),
        ),
      );
    }

    return buttons;
  }

  /// 系統卡：開學／probation／學會義務
  static List<StoryEvent> systemCards(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return const [];
    final events = <StoryEvent>[];

    final daily = uniDailyEvent(p);
    if (daily != null) events.add(daily);

    final orient = orientationEvent(p);
    if (orient != null) events.add(orient);

    final duty = UniversitySocieties.dutyEvent(p);
    if (duty != null) events.add(duty);

    final gossip = UniversitySocieties.gossipEvent(p);
    if (gossip != null) events.add(gossip);

    final campus = campusLifeEvent(p);
    if (campus != null) events.add(campus);

    if (p.uniProbation &&
        !p.unlockedFlags.contains('uni_probation_seen')) {
      p.unlockedFlags.add('uni_probation_seen');
      events.add(StoryEvent(
        id: 'uni_probation',
        title: '試讀警告（Probation）',
        body: '你 GPA（${p.uniGpa.toStringAsFixed(2)}）低到學校出信。\n'
            '已經入咗試讀警告。再低就有機會勸退，或者要延遲畢業。',
        isSystem: true,
        choices: [
          EventChoice(
            label: '知啦，會加把勁',
            apply: (pl) {
              pl.stress = (pl.stress + 5).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    return events;
  }

  /// 每季 1 張：大學日常（必出）
  static StoryEvent? uniDailyEvent(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return null;

    final pool = <StoryEvent Function(Player)>[
      (pl) => StoryEvent(
            id: 'uni_daily_lib_${pl.year}_${pl.quarter.name}',
            title: '图书馆占座',
            body: '期末周图书馆逼到无位，有人用书包占座去食饭。',
            isSystem: true,
            choices: [
              EventChoice(
                label: '早啲去霸位',
                apply: (x) {
                  x.uniStudySessions = (x.uniStudySessions + 1).clamp(0, 99);
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 2).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '返屋企温',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.uniStudySessions = (x.uniStudySessions + 1).clamp(0, 99);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'uni_daily_canteen_${pl.year}_${pl.quarter.name}',
            title: '饭堂排队',
            body: '午饭时间饭堂排长龙，同同学倾选科同实习。',
            isSystem: true,
            choices: [
              EventChoice(
                label: '同同学倾计',
                apply: (x) {
                  x.network = (x.network + 3).clamp(0, 100);
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '买外卖返宿舍',
                apply: (x) {
                  if (x.wealth >= 60) x.wealth -= 60;
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'uni_daily_intern_${pl.year}_${pl.quarter.name}',
            title: '实习招聘季',
            body: 'Career fair 有银行、四大、科网摆档，'
                '师兄话要早准备 CV。',
            isSystem: true,
            choices: [
              EventChoice(
                label: '去 fair 派 CV',
                apply: (x) {
                  x.network = (x.network + 4).clamp(0, 100);
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '专心 GPA 先',
                apply: (x) {
                  x.uniStudySessions = (x.uniStudySessions + 2).clamp(0, 99);
                  x.smarts = (x.smarts + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'uni_daily_night_${pl.year}_${pl.quarter.name}',
            title: '通宵赶 due',
            body: '份 report 听日交，你同室友轮流冲咖啡。',
            isSystem: true,
            choices: [
              EventChoice(
                label: '通宵完成',
                apply: (x) {
                  x.uniStudySessions = (x.uniStudySessions + 2).clamp(0, 99);
                  x.san = (x.san - 5).clamp(0, x.maxSan);
                  x.hp = (x.hp - 3).clamp(0, x.maxHp);
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '求教授延期',
                apply: (x) {
                  x.network = (x.network + 1).clamp(0, 100);
                  x.reputation = (x.reputation - 2).clamp(0, 100);
                  x.stress = (x.stress + 4).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'uni_daily_sports_${pl.year}_${pl.quarter.name}',
            title: '校队 / 运动',
            body: '书院杯赛事开锣，可以下场或者做啦啦队。',
            isSystem: true,
            choices: [
              EventChoice(
                label: '落场打波',
                apply: (x) {
                  x.hp = (x.hp + 3).clamp(0, x.maxHp);
                  x.network = (x.network + 2).clamp(0, 100);
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '留喺度温书',
                apply: (x) {
                  x.uniStudySessions = (x.uniStudySessions + 1).clamp(0, 99);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'uni_daily_parttime_${pl.year}_${pl.quarter.name}',
            title: '边读边做',
            body: '生活费紧，同学话补习、零售兼职都好多人做。',
            isSystem: true,
            choices: [
              EventChoice(
                label: '去搵兼职',
                apply: (x) {
                  x.unlockedFlags.add('pt_hire_pending');
                  x.eventLog.add('${x.year}年：去搵兼职');
                },
              ),
              EventChoice(
                label: '专心读书',
                apply: (x) {
                  x.uniStudySessions = (x.uniStudySessions + 1).clamp(0, 99);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
            ],
          ),
    ];

    final idx = (p.year * 13 + p.quarter.index * 7 + p.bachelorYear * 3 + p.smarts) %
        pool.length;
    return pool[idx](p);
  }

  /// 每季 50%：大學生活卡（唔使入學會／上莊）
  static StoryEvent? campusLifeEvent(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return null;

    final flag = 'uni_campus_y${p.year}_q${p.quarter.name}';
    if (p.unlockedFlags.contains(flag)) return null;

    final rng = Random(p.year * 901 + p.quarter.index * 77 + p.smarts * 3);
    if (rng.nextDouble() >= 0.5) {
      p.unlockedFlags.add(flag);
      return null;
    }
    p.unlockedFlags.add(flag);

    final type = rng.nextInt(6);
    return switch (type) {
      0 => StoryEvent(
          id: 'uni_campus_freerider',
          title: '小組作業有人摸魚',
          body: '有個組員成日唔出糧，臨交先出現。交嘢日子就嚟到。',
          isSystem: true,
          choices: [
            EventChoice(
              label: '自己成份功課孭起',
              apply: (pl) {
                pl.stress = (pl.stress + 8).clamp(0, 100);
                pl.discipline = (pl.discipline + 3).clamp(0, 100);
                pl.uniStudySessions =
                    (pl.uniStudySessions + 1).clamp(0, 99);
                pl.san = (pl.san - 4).clamp(0, pl.maxSan);
                pl.network = (pl.network - 2).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：小組作業自己孭晒。');
              },
            ),
            EventChoice(
              label: '去同導師投訴佢',
              apply: (pl) {
                pl.reputation = (pl.reputation + 2).clamp(0, 100);
                pl.network = (pl.network - 5).clamp(0, 100);
                pl.stress = (pl.stress + 3).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：投訴組員摸魚。');
              },
            ),
            EventChoice(
              label: '一齊擺爛算',
              apply: (pl) {
                pl.stress = (pl.stress - 2).clamp(0, 100);
                pl.uniStudySessions =
                    (pl.uniStudySessions - 1).clamp(0, 99);
                pl.discipline = (pl.discipline - 4).clamp(0, 100);
                pl.reputation = (pl.reputation - 3).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：小組作業一齊擺爛。');
              },
            ),
          ],
        ),
      1 => StoryEvent(
          id: 'uni_campus_exam_fail',
          title: '期中測考得差',
          body: '卷難過預期，出嚟好似考燶。下個測好快又嚟。',
          isSystem: true,
          choices: [
            EventChoice(
              label: '加把勁溫返',
              apply: (pl) {
                pl.uniStudySessions =
                    (pl.uniStudySessions + 2).clamp(0, 99);
                pl.stress = (pl.stress + 7).clamp(0, 100);
                pl.san = (pl.san - 3).clamp(0, pl.maxSan);
                pl.discipline = (pl.discipline + 2).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：測差咗，加碼溫書。');
              },
            ),
            EventChoice(
              label: '去搵教授問清楚',
              apply: (pl) {
                pl.smarts = (pl.smarts + 2).clamp(0, 100);
                pl.uniStudySessions =
                    (pl.uniStudySessions + 1).clamp(0, 99);
                pl.network = (pl.network + 2).clamp(0, 100);
                pl.stress = (pl.stress + 2).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '算啦，當自己衰運',
              apply: (pl) {
                pl.san = (pl.san + 4).clamp(0, pl.maxSan);
                pl.discipline = (pl.discipline - 2).clamp(0, 100);
                pl.uniStudySessions =
                    (pl.uniStudySessions - 1).clamp(0, 99);
              },
            ),
          ],
        ),
      2 => StoryEvent(
          id: 'uni_campus_cannabis',
          title: '派對有人遞「草」',
          body: 'Hall／派對有人遞大麻，話「試下無妨㗎」。周圍有人影相。',
          isSystem: true,
          choices: [
            EventChoice(
              label: '唔要，走人',
              apply: (pl) {
                pl.discipline = (pl.discipline + 4).clamp(0, 100);
                pl.reputation = (pl.reputation + 1).clamp(0, 100);
                pl.network = (pl.network - 2).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：派對拒毒品。');
              },
            ),
            EventChoice(
              label: '試一口（好大風險）',
              apply: (pl) {
                pl.san = (pl.san + 6).clamp(0, pl.maxSan);
                pl.stress = (pl.stress - 4).clamp(0, 100);
                pl.discipline = (pl.discipline - 6).clamp(0, 100);
                pl.smarts = (pl.smarts - 2).clamp(0, 100);
                pl.uniStudySessions =
                    (pl.uniStudySessions - 1).clamp(0, 99);
                if (Random(pl.year + pl.age).nextDouble() < 0.25) {
                  pl.reputation = (pl.reputation - 10).clamp(0, 100);
                  pl.investigation = InvestigationStatus.police;
                  pl.eventLog.add('${pl.year}年：派對吸毒傳開，惹麻煩。');
                } else {
                  pl.eventLog.add('${pl.year}年：派對試咗大麻。');
                }
              },
            ),
            EventChoice(
              label: '勸佢哋唔好，自己走',
              apply: (pl) {
                pl.reputation = (pl.reputation + 3).clamp(0, 100);
                pl.network = (pl.network + 1).clamp(0, 100);
                pl.stress = (pl.stress + 2).clamp(0, 100);
              },
            ),
          ],
        ),
      3 => StoryEvent(
          id: 'uni_campus_allnighter',
          title: '通宵趕功課',
          body: '聽朝一早就要交。通宵定瞓？',
          isSystem: true,
          choices: [
            EventChoice(
              label: '通宵趕',
              apply: (pl) {
                pl.uniStudySessions =
                    (pl.uniStudySessions + 2).clamp(0, 99);
                pl.hp = (pl.hp - 8).clamp(0, pl.maxHp);
                pl.stress = (pl.stress + 6).clamp(0, 100);
                pl.san = (pl.san - 4).clamp(0, pl.maxSan);
              },
            ),
            EventChoice(
              label: '交半成品，瞓先',
              apply: (pl) {
                pl.hp = (pl.hp + 3).clamp(0, pl.maxHp);
                pl.uniStudySessions =
                    (pl.uniStudySessions - 1).clamp(0, 99);
                pl.reputation = (pl.reputation - 2).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '叫組員／朋友幫手',
              apply: (pl) {
                if (pl.network >= 40) {
                  pl.uniStudySessions =
                      (pl.uniStudySessions + 1).clamp(0, 99);
                  pl.network = (pl.network - 2).clamp(0, 100);
                } else {
                  pl.stress = (pl.stress + 4).clamp(0, 100);
                  pl.eventLog.add('${pl.year}年：人脈唔夠，冇人幫手趕工。');
                }
              },
            ),
          ],
        ),
      4 => StoryEvent(
          id: 'uni_campus_romance',
          title: '有人約你出街',
          body: SocialCircle.isDating(p)
              ? '有人約你出街；你而家拍緊拖，要小心處理。'
              : '有人約你出街；但你知下個星期有大測。'
                  '（去嘅話可能識到傾得埋嘅對象）',
          isSystem: true,
          choices: [
            EventChoice(
              label: SocialCircle.isDating(p) ? '去傾下（唔越界）' : '去啦',
              apply: (pl) {
                pl.san = (pl.san + 8).clamp(0, pl.maxSan);
                pl.stress = (pl.stress - 3).clamp(0, 100);
                pl.network = (pl.network + 3).clamp(0, 100);
                pl.uniStudySessions =
                    (pl.uniStudySessions - 1).clamp(0, 99);
                if (pl.wealth >= 400) pl.wealth -= 400;
                if (SocialCircle.isDating(pl)) {
                  pl.eventLog.add(
                    '${pl.year}年：出街見咗人，但守住拍拖界線。',
                  );
                  return;
                }
                final meet = SocialCircle.tryMeet(
                  pl,
                  FriendSource.uni,
                  baseChance: 1.0,
                  ignoreQuarterCap: true,
                  affinityOverride: 58 + (pl.network ~/ 20).clamp(0, 8),
                );
                if (meet == null) {
                  pl.eventLog.add('${pl.year}年：出街傾得好開心，但未加到通訊錄。');
                }
              },
            ),
            EventChoice(
              label: '唔去，專心溫書',
              apply: (pl) {
                pl.uniStudySessions =
                    (pl.uniStudySessions + 1).clamp(0, 99);
                pl.discipline = (pl.discipline + 2).clamp(0, 100);
                pl.san = (pl.san - 2).clamp(0, pl.maxSan);
                SocialCircle.markHarshStudy(pl);
              },
            ),
          ],
        ),
      _ => StoryEvent(
          id: 'uni_campus_parttime_conflict',
          title: '兼職同堂撞期',
          body: '老闆叫你頂更，但嗰日有堂一定要去。',
          isSystem: true,
          choices: [
            EventChoice(
              label: '去兼職賺銀',
              apply: (pl) {
                pl.wealth += 3500;
                pl.uniStudySessions =
                    (pl.uniStudySessions - 1).clamp(0, 99);
                pl.stress = (pl.stress + 4).clamp(0, 100);
                pl.discipline = (pl.discipline - 2).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '返學（工可能冇）',
              apply: (pl) {
                pl.uniStudySessions =
                    (pl.uniStudySessions + 1).clamp(0, 99);
                pl.wealth = (pl.wealth - 500).clamp(0, 999999999);
                pl.reputation = (pl.reputation + 1).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '請病假，兩頭呃',
              apply: (pl) {
                pl.discipline = (pl.discipline - 5).clamp(0, 100);
                pl.reputation = (pl.reputation - 4).clamp(0, 100);
                pl.stress = (pl.stress + 2).clamp(0, 100);
                pl.san = (pl.san + 3).clamp(0, pl.maxSan);
              },
            ),
          ],
        ),
    };
  }
}
