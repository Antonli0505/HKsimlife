import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_data.dart';
import 'career_gov.dart';
import 'career_job_hunt.dart';
import 'career_tax.dart';
import 'luck_modifiers.dart';
import 'university_pathway.dart';

/// 大學暑期／短期實習（參考現實：銀行／四大／律所 vacation／科網／傳媒）
class InternProgram {
  final String id;
  final String titleZh;
  final String employer;
  final CareerSector targetSector;
  /// 參考現實月津貼（港幣）
  final int stipendMonthly;
  final int durationQuarters;
  final int minSmarts;
  final int minBachelorYear;
  final int minNetwork;
  final bool prestige;

  const InternProgram({
    required this.id,
    required this.titleZh,
    required this.employer,
    required this.targetSector,
    this.stipendMonthly = 12000,
    this.durationQuarters = 1,
    this.minSmarts = 50,
    this.minBachelorYear = 2,
    this.minNetwork = 0,
    this.prestige = false,
  });

  String get label =>
      employer.isEmpty ? titleZh : '$employer · $titleZh';
}

/// 實習深線：申請 → 做夠季 → 評核 → 轉正加成／Return offer
abstract final class CareerInternships {
  static const pendingFlag = 'intern_hire_pending';

  static const List<InternProgram> all = [
    InternProgram(
      id: 'bank_hsbc_ib',
      titleZh: '投行／企金暑期實習',
      employer: '滙豐 HSBC',
      targetSector: CareerSector.banking,
      // 現實大行 front office 暑期約 2.5–3.5 萬／月
      stipendMonthly: 28000,
      minSmarts: 62,
      minBachelorYear: 2,
      prestige: true,
    ),
    InternProgram(
      id: 'bank_boc_retail',
      titleZh: '零售銀行暑期實習',
      employer: '中銀香港',
      targetSector: CareerSector.banking,
      // 現實零售／分行暑期約 1.4–1.8 萬／月
      stipendMonthly: 16000,
      minSmarts: 50,
      minBachelorYear: 1,
      prestige: false,
    ),
    InternProgram(
      id: 'big4_busy',
      titleZh: '四大 Audit 暑期／Busy Season Intern',
      employer: 'PwC',
      targetSector: CareerSector.accounting,
      // 現實四大約 1.2–1.8 萬／月
      stipendMonthly: 15000,
      minSmarts: 60,
      minBachelorYear: 2,
      prestige: true,
    ),
    InternProgram(
      id: 'law_vacation',
      titleZh: '律師行 Vacation Scheme',
      employer: 'Deacons',
      targetSector: CareerSector.legalSolicitor,
      stipendMonthly: 14000,
      minSmarts: 62,
      minBachelorYear: 2,
      minNetwork: 15,
      prestige: true,
    ),
    InternProgram(
      id: 'tech_summer',
      titleZh: '科網暑期實習',
      employer: '本地初創／MNC',
      targetSector: CareerSector.it,
      stipendMonthly: 20000,
      minSmarts: 62,
      minBachelorYear: 2,
    ),
    InternProgram(
      id: 'media_intern',
      titleZh: '傳媒／新聞實習',
      employer: '報館',
      targetSector: CareerSector.media,
      stipendMonthly: 9000,
      minSmarts: 48,
      minBachelorYear: 1,
      minNetwork: 10,
    ),
    InternProgram(
      id: 'gov_csb',
      titleZh: '政府暑期實習計劃（決策局）',
      employer: '公務員事務局',
      targetSector: CareerSector.civilService,
      // 現實政府暑期生約 1–1.2 萬／月；決策局名額較搶
      stipendMonthly: 11000,
      minSmarts: 58,
      minBachelorYear: 2,
      prestige: true,
    ),
    InternProgram(
      id: 'gov_swd',
      titleZh: '社會福利署暑期實習',
      employer: '社會福利署',
      targetSector: CareerSector.civilService,
      stipendMonthly: 11000,
      minSmarts: 52,
      minBachelorYear: 2,
    ),
    InternProgram(
      id: 'gov_had',
      titleZh: '民政事務總署暑期實習',
      employer: '民政事務總署',
      targetSector: CareerSector.civilService,
      stipendMonthly: 11000,
      minSmarts: 50,
      minBachelorYear: 2,
      minNetwork: 10,
    ),
    InternProgram(
      id: 'gov_hd',
      titleZh: '房屋署暑期實習',
      employer: '房屋署',
      targetSector: CareerSector.civilService,
      stipendMonthly: 11000,
      minSmarts: 50,
      minBachelorYear: 2,
    ),
    InternProgram(
      id: 'eng_summer',
      titleZh: '工程顧問／承建暑期實習',
      employer: 'AECOM',
      targetSector: CareerSector.engineering,
      stipendMonthly: 15000,
      minSmarts: 58,
      minBachelorYear: 2,
    ),
    InternProgram(
      id: 'cater_mgmt',
      titleZh: '餐飲管理見習',
      employer: '美心',
      targetSector: CareerSector.catering,
      stipendMonthly: 11000,
      minSmarts: 42,
      minBachelorYear: 1,
    ),
    InternProgram(
      id: 'estate_intern',
      titleZh: '地產代理暑期見習',
      employer: '中原',
      targetSector: CareerSector.realEstate,
      stipendMonthly: 9000,
      minSmarts: 40,
      minBachelorYear: 1,
    ),
  ];

  static InternProgram? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static bool hasActive(Player p) => p.activeInternId.isNotEmpty;

  static InternProgram? current(Player p) =>
      hasActive(p) ? byId(p.activeInternId) : null;

  static String displayLabel(Player p) {
    final prog = current(p);
    if (prog == null) return '無實習';
    return '${prog.label}（表現 ${p.internPerformance}｜剩 ${p.internQuartersLeft} 季）';
  }

  static String? blockReason(Player p, InternProgram prog) {
    if (!UniversityPathway.isStudyingBachelor(p) && !p.isStudying) {
      return '實習申請主要畀讀緊專上／大學';
    }
    if (p.bachelorYear > 0 && p.bachelorYear < prog.minBachelorYear) {
      return '要讀到 Year ${prog.minBachelorYear}+（而家 Year ${p.bachelorYear}）';
    }
    if (p.smarts < prog.minSmarts) {
      return '智慧唔夠（要 ${prog.minSmarts}+）';
    }
    if (p.network < prog.minNetwork) {
      return '人脈唔夠（要 ${prog.minNetwork}+）';
    }
    if (hasActive(p)) return '你而家已經有實習';
    if (p.isEmployed) return '有全職就唔好再撈暑期實習';
    return null;
  }

  static List<InternProgram> availableFor(Player p) =>
      all.where((prog) => blockReason(p, prog) == null).toList();

  static bool canApplySeason(Player p) =>
      // 現實：暑期／vacation 申請多在頭年秋冬（Q3–Q4）
      p.quarter == Quarter.q3 || p.quarter == Quarter.q4;

  static StoryEvent hireEvent(Player p) {
    if (!canApplySeason(p)) {
      return StoryEvent(
        id: 'intern_hire_off',
        title: '暑期實習',
        body: '實習招聘旺季多數係秋季／年底（Q3／Q4）。而家唔係申請季節。',
        choices: [EventChoice(label: '知道', apply: (_) {})],
      );
    }
    final pool = availableFor(p);
    if (pool.isEmpty) {
      return StoryEvent(
        id: 'intern_hire_none',
        title: '暑期實習',
        body: '暫時冇啱你條件嘅實習（年級／智慧／人脈）。'
            '\n溫書、人脈、GPA 再搏下年。',
        choices: [EventChoice(label: '算啦', apply: (_) {})],
      );
    }
    final picks = List<InternProgram>.from(pool)
      ..shuffle(Random(p.year * 13 + p.age));
    final shown = picks.take(4).toList();
    return StoryEvent(
      id: 'intern_hire',
      title: '申請暑期／短期實習',
      body: '參考現實：滙豐投行 vs 中銀零售；政府決策局／社署／民政／房屋署暑期計劃等。'
          '\n申請旺季多在 Q3／Q4；做完有評核，過關加轉正／面試優勢。',
      choices: [
        ...shown.map(
          (prog) => EventChoice(
            label: '${prog.label}（津貼約 \$${prog.stipendMonthly}/月）',
            apply: (pl) => _start(pl, prog),
          ),
        ),
        EventChoice(label: '唔申請', apply: (_) {}),
      ],
    );
  }

  static void _start(Player p, InternProgram prog) {
    // 對齊現實：名企銀行／四大／律所好難；科網／政府中等；傳媒／餐飲／地產相對易
    final hard = prog.prestige;
    final mid = !hard && prog.stipendMonthly >= 14000;
    var chance = hard
        ? 8.0
        : mid
            ? 22.0
            : 34.0;
    chance += (p.smarts - prog.minSmarts) * (hard ? 0.35 : 0.45);
    // GPA：2.0 起計，3.0 大約 +6，3.7 大約 +10
    chance += ((p.uniGpa - 2.0).clamp(0.0, 2.0)) * (hard ? 5.5 : 6.5);
    chance += p.luck / (hard ? 14.0 : 12.0);
    if (p.network >= 40 && prog.minNetwork > 0) chance += 3;
    if (hard) {
      // 名企再篩：GPA 普通幾乎冇運行
      if (p.uniGpa < 3.0) chance -= 6;
      if (p.uniGpa >= 3.5) chance += 4;
    }
    final lo = hard ? 4.0 : mid ? 8.0 : 12.0;
    final hi = hard ? 36.0 : mid ? 52.0 : 72.0;
    chance = chance.clamp(lo, hi);
    final ok = LuckModifiers.roll(
      p,
      chance / 100.0,
      Random(p.year * 19 + prog.id.hashCode),
    );
    if (!ok) {
      p.stress = (p.stress + 4).clamp(0, 100);
      p.eventLog.add('${p.year}年：實習申請失敗 — ${prog.label}');
      return;
    }
    p.activeInternId = prog.id;
    p.internEmployer = prog.employer;
    p.internQuartersLeft = prog.durationQuarters;
    p.internPerformance = 20;
    p.eventLog.add(
      '${p.year}年：入咗實習 — ${prog.label}（${prog.durationQuarters} 季）',
    );
  }

  static String workShift(Player p) {
    final prog = current(p);
    if (prog == null) return '你冇實習。';
    p.internPerformance = (p.internPerformance + 10).clamp(0, 100);
    p.stress = (p.stress + 5).clamp(0, 100);
    p.discipline = (p.discipline + 1).clamp(0, 100);
    final pay = prog.stipendMonthly ~/ 3; // 一次出勤 ≈ 一個月津貼／比例
    CareerTax.grantTaxablePartTimePay(p, pay);
    // 讀大學時實習食溫書時間
    if (p.uniStudySessions > 0 &&
        Random(p.year + p.internPerformance).nextBool()) {
      p.uniStudySessions--;
    }
    return '實習出勤：${prog.label}\n表現 ${p.internPerformance}，'
        '入帳約 \$$pay（月津貼約 \$${prog.stipendMonthly}）';
  }

  static String overtime(Player p) {
    final prog = current(p);
    if (prog == null) return '你冇實習。';
    p.internPerformance = (p.internPerformance + 16).clamp(0, 100);
    p.stress = (p.stress + 9).clamp(0, 100);
    p.san = (p.san - 3).clamp(0, p.maxSan);
    return '實習 OT 搏表現：而家 ${p.internPerformance}';
  }

  /// 每季：倒數＋完結評核
  static String? tickQuarter(Player p) {
    if (!hasActive(p)) {
      // 在職專業實習評核（藥劑／醫生）
      return _tickProfessionalTraining(p);
    }
    final prog = current(p)!;
    p.internQuartersLeft--;
    if (p.internQuartersLeft > 0) {
      return '實習仲有 ${p.internQuartersLeft} 季（表現 ${p.internPerformance}）';
    }
    return _finish(p, prog);
  }

  static String _finish(Player p, InternProgram prog) {
    final pass = p.internPerformance >= 40;
    final flag = 'intern_pass_${prog.targetSector.name}';
    final id = prog.id;
    p.activeInternId = '';
    p.internEmployer = '';
    p.internQuartersLeft = 0;
    if (pass) {
      p.unlockedFlags.add(flag);
      p.unlockedFlags.add('intern_pass_$id');
      p.unlockedFlags.add('pt_convert_boost'); // 轉正／面試加成
      p.reputation = (p.reputation + 3).clamp(0, 100);
      p.network = (p.network + 4).clamp(0, 100);
      p.eventLog.add(
        '${p.year}年：實習合格 — ${prog.label}（可爭取 return offer／轉正）',
      );
      return '實習評核合格：${prog.label}'
          '\n表現 ${p.internPerformance} ≥ 40'
          '\n之後搵${prog.targetSector.label}會易啲；可申請轉正。';
    }
    p.stress = (p.stress + 6).clamp(0, 100);
    p.eventLog.add('${p.year}年：實習不合格 — ${prog.label}');
    return '實習評核唔過：${prog.label}'
        '\n表現先得 ${p.internPerformance}（要 ≥40）';
  }

  /// 藥劑一年實習／醫生駐院前實習：每季導師評核味道
  static String? _tickProfessionalTraining(Player p) {
    if (!p.isEmployed) return null;
    if (p.currentSector == CareerSector.pharmacy &&
        p.unlockedFlags.contains('pharm_local_grad') &&
        p.jobRank == 0 &&
        p.jobQuartersInRank > 0 &&
        p.jobQuartersInRank <= 4) {
      final ok = p.jobPerformance >= 35;
      if (!ok && p.jobQuartersInRank == 4) {
        p.stress = (p.stress + 8).clamp(0, 100);
        return '藥劑實習年終評核：表現偏低，註冊會更難（繼續做好本份）。';
      }
      if (p.jobQuartersInRank == 2 || p.jobQuartersInRank == 4) {
        return ok
            ? '藥劑實習導師評核：今季合格（表現 ${p.jobPerformance}）'
            : '藥劑實習導師評核：今季勉強／不合格味道——快啲加把勁';
      }
    }
    if (p.currentSector == CareerSector.medical && p.jobRank == 0) {
      if (p.jobQuartersInRank == 2 || p.jobQuartersInRank == 4) {
        final ok = p.jobPerformance >= 40;
        return ok
            ? 'HA 實習醫生中期評核：過關'
            : 'HA 實習醫生中期評核：要加強臨床表現';
      }
    }
    return null;
  }

  /// 實習轉正 → 對應行業面試（有加成）
  static String? convertBlockReason(Player p) {
    if (hasActive(p)) return '實習未完，未到轉正';
    if (p.isStudying) return '讀緊書：可先攞 return offer 意向，畢業先入職';
    if (p.isEmployed) return '你已經有全職';
    // 搵有冇任何 intern_pass_* sector
    CareerSector? sector;
    for (final s in CareerSector.values) {
      if (p.unlockedFlags.contains('intern_pass_${s.name}')) {
        sector = s;
        break;
      }
    }
    if (sector == null) return '未有合格實習紀錄';
    final block = CareerData.entryBlockReason(p, sector);
    if (block != null) return '轉正條件：$block';
    return null;
  }

  static CareerSector? convertSector(Player p) {
    for (final s in CareerSector.values) {
      if (p.unlockedFlags.contains('intern_pass_${s.name}')) return s;
    }
    return null;
  }

  /// 政府實習合格 → 畢業轉正優先對應部門職位
  static String? convertGovEmployer(Player p) {
    final pairs = <String, String>{
      'intern_pass_gov_swd': 'swd_sso',
      'intern_pass_gov_had': 'had_lo',
      'intern_pass_gov_hd': 'hd_ho',
      'intern_pass_gov_csb': 'eo',
    };
    for (final e in pairs.entries) {
      if (!p.unlockedFlags.contains(e.key)) continue;
      final post = CareerGov.byId(e.value);
      if (post == null) continue;
      if (CareerGov.blockReason(p, post) != null) continue;
      return CareerGov.taggedEmployer(post);
    }
    // 社署實習 + 社工學位 → ASWO
    if (p.unlockedFlags.contains('intern_pass_gov_swd')) {
      final aswo = CareerGov.byId('swd_aswo');
      if (aswo != null && CareerGov.blockReason(p, aswo) == null) {
        return CareerGov.taggedEmployer(aswo);
      }
    }
    // 決策局實習 + JRE → AO
    if (p.unlockedFlags.contains('intern_pass_gov_csb') &&
        p.unlockedFlags.contains('jre_passed')) {
      final ao = CareerGov.byId('ao');
      if (ao != null && CareerGov.blockReason(p, ao) == null) {
        return CareerGov.taggedEmployer(ao);
      }
    }
    return null;
  }

  static String applyConvert(Player p) {
    final block = convertBlockReason(p);
    if (block != null) return block;
    final sector = convertSector(p)!;
    p.unlockedFlags.add('pt_convert_boost');
    final govEmployer = sector == CareerSector.civilService
        ? convertGovEmployer(p)
        : null;
    final msg = CareerJobHunt.apply(
      p,
      sector,
      employer: govEmployer ?? '',
      prestige: p.unlockedFlags.contains('intern_pass_bank_hsbc_ib') ||
          p.unlockedFlags.contains('intern_pass_big4_busy') ||
          p.unlockedFlags.contains('intern_pass_law_vacation') ||
          p.unlockedFlags.contains('intern_pass_gov_csb'),
      bypassSeason: true,
    );
    final deptNote = govEmployer != null
        ? '\n對口部門實習紀錄：優先走該部門入職線。'
        : '';
    return '$msg$deptNote\n實習轉正路線：面試有內部加成。';
  }

  static List<ActionButton> actions(Player p) {
    final buttons = <ActionButton>[];
    final studying = UniversityPathway.isStudyingBachelor(p) || p.isStudying;
    if (studying && canApplySeason(p) && !hasActive(p) && !p.isEmployed) {
      buttons.add(ActionButton(
        label: '申請暑期／短期實習',
        apCost: 2,
        onExecute: (pl) {
          pl.unlockedFlags.add(pendingFlag);
        },
      ));
    }
    if (hasActive(p)) {
      final prog = current(p)!;
      buttons.add(ActionButton(
        label: '返實習（${prog.titleZh}）',
        apCost: 1,
        onExecute: (pl) => pl.eventLog.add(workShift(pl)),
      ));
      buttons.add(ActionButton(
        label: '實習 OT 搏表現',
        apCost: 2,
        onExecute: (pl) => pl.eventLog.add(overtime(pl)),
      ));
    }
    if (!p.isStudying &&
        !p.isEmployed &&
        convertSector(p) != null) {
      final block = convertBlockReason(p);
      final sector = convertSector(p)!;
      buttons.add(ActionButton(
        label: block == null
            ? '實習轉正 → ${sector.label}'
            : '實習轉正（未夠條件）',
        apCost: 2,
        enabled: block == null,
        onExecute: (pl) {
          if (block != null) {
            pl.eventLog.add('${pl.year}年：轉正唔得 — $block');
            return;
          }
          pl.eventLog.add(applyConvert(pl));
        },
      ));
    }
    return buttons;
  }
}
