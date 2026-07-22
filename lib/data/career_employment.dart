import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_abilities.dart';
import 'career_data.dart';
import 'career_gov.dart';
import 'career_job_hunt.dart';
import 'career_tax.dart';
import 'luck_modifiers.dart';
import 'part_time_jobs.dart';

/// 試用期、裁員、兼職轉正、花紅／強積金
abstract final class CareerEmployment {
  /// 試用期長度（季）；0＝無試用（如的士自僱）
  static int probationQuartersFor(CareerSector sector) => switch (sector) {
        CareerSector.taxi => 0,
        CareerSector.politics => 1,
        // 公務員／紀律部隊：現實約三年試用
        CareerSector.civilService || CareerSector.disciplinary =>
          CareerGov.probationQuarters,
        CareerSector.medical ||
        CareerSector.nursing ||
        CareerSector.legalSolicitor ||
        CareerSector.legalBarrister =>
          3,
        _ => 2, // 約半年
      };

  /// 每月相關入息下限／上限（強積金；跟法例量級簡化）
  static const int mpfMinMonthly = 7100;
  static const int mpfMaxMonthly = 30000;
  /// 每邊供款上限（5% × 30000）
  static const int mpfMonthlyCap = 1500;
  /// 個人免稅額（薪俸稅簡化）
  static const int personalAllowance = 132000;

  /// 入職時初始化試用／年資
  static void onHire(Player p, CareerSector sector) {
    p.jobQuartersEmployed = 0;
    p.jobProbationQuartersLeft = probationQuartersFor(sector);
    if (p.jobProbationQuartersLeft > 0) {
      p.eventLog.add(
        '${p.year}年：開始試用期（${p.jobProbationQuartersLeft} 季）',
      );
    }
  }

  static bool onProbation(Player p) =>
      p.isEmployed && p.jobProbationQuartersLeft > 0;

  static String probationLabel(Player p) {
    if (!p.isEmployed) return '—';
    if (p.jobProbationQuartersLeft <= 0) return '已過試用';
    return '試用中（剩 ${p.jobProbationQuartersLeft} 季）';
  }

  /// 每季：年資＋試用倒數＋過關／不合格
  static String? tickProbation(Player p) {
    if (!p.isEmployed) return null;
    p.jobQuartersEmployed++;
    if (p.jobProbationQuartersLeft <= 0) return null;

    p.jobProbationQuartersLeft--;
    if (p.jobProbationQuartersLeft > 0) {
      return '試用期仲有 ${p.jobProbationQuartersLeft} 季'
          '（表現而家 ${p.jobPerformance}）';
    }

    // 試用完結
    final gov = CareerGov.usesGovRules(p);
    final passBar = gov ? 40 : 35;
    if (p.jobPerformance >= passBar) {
      p.reputation = (p.reputation + 3).clamp(0, 100);
      p.jobPerformance = (p.jobPerformance + 5).clamp(0, 100);
      if (gov) {
        p.eventLog.add('${p.year}年：通過三年試用關限，之後評核先計 A');
        return '通過三年試用關限！'
            '\n表現 ${p.jobPerformance}（門檻 $passBar）'
            '\n之後每年評核有機會拎 A；累積 ${CareerGov.asForPromote} 個 A 先有資格升。';
      }
      p.eventLog.add('${p.year}年：試用期合格，轉正全職');
      return '試用期合格！正式轉正'
          '\n表現 ${p.jobPerformance}（門檻 $passBar）';
    }

    final title = p.jobTitle;
    CareerData.quitJob(p, reason: '試用期不合格被炒（$title）');
    p.stress = (p.stress + 8).clamp(0, 100);
    return '試用期不合格被炒：$title'
        '\n表現先得 ${p.jobPerformance}（要 ≥$passBar）';
  }

  // ─── 派糧：有返工先出糧；季薪＝月薪 × 3 ───────────

  static int quarterlyGross(Player p) {
    return effectiveMonthlySalary(p) * 3;
  }

  /// 顯示／OT／出糧共用：公職優先 MPS；對唔上 post 就退回 track 薪
  static int effectiveMonthlySalary(Player p) {
    final govSal = CareerGov.monthlySalary(p);
    if (govSal > 0) return govSal;
    final post = CareerGov.currentPost(p);
    if (post != null) return post.salaryFor(p.jobRank);
    final track = CareerData.trackFor(p.currentSector);
    if (track == null) return 0;
    return track.rankFor(p.jobRank).salary;
  }

  static bool _isSelfEmployed(Player p) =>
      p.currentSector == CareerSector.taxi;

  /// 每季僱員／僱主強積金（5%；有下限、上限；65 歲停強制）
  static ({int employee, int employer}) quarterlyMpfParts({
    required int grossQuarterly,
    required int age,
    required bool selfEmployed,
  }) {
    if (age >= 65) return (employee: 0, employer: 0);
    final monthly = grossQuarterly ~/ 3;
    if (monthly < mpfMinMonthly) return (employee: 0, employer: 0);
    final base = monthly.clamp(mpfMinMonthly, mpfMaxMonthly);
    final side = (base * 0.05).round().clamp(0, mpfMonthlyCap);
    final q = side * 3;
    if (selfEmployed) {
      return (employee: q, employer: 0);
    }
    return (employee: q, employer: q);
  }

  /// 花紅／一次性相關入息：按「該筆金額」計 5%，唔好再 ÷3 誤判下限
  static ({int employee, int employer}) mpfPartsForLumpSum({
    required int amount,
    required int age,
    required bool selfEmployed,
  }) {
    if (age >= 65 || amount <= 0) return (employee: 0, employer: 0);
    // 簡化：當月相關入息＝呢筆（通常連底薪會過下限）；單筆用月上限封頂
    final base = amount.clamp(0, mpfMaxMonthly);
    if (base <= 0) return (employee: 0, employer: 0);
    final side = (base * 0.05).round().clamp(0, mpfMonthlyCap);
    if (selfEmployed) return (employee: side, employer: 0);
    return (employee: side, employer: side);
  }

  /// 簡化累進薪俸稅（課稅入息實額）
  static int progressiveSalariesTax(int chargeable) {
    if (chargeable <= 0) return 0;
    var left = chargeable;
    var tax = 0;
    void band(int width, double rate) {
      if (left <= 0) return;
      final take = left < width ? left : width;
      tax += (take * rate).round();
      left -= take;
    }

    band(50000, 0.02);
    band(50000, 0.06);
    band(50000, 0.10);
    band(50000, 0.14);
    if (left > 0) tax += (left * 0.17).round();
    return tax;
  }

  /// 強積金戶口每季投資回報（簡化）
  static String? tickMpfInvestment(Player p) {
    if (p.mpfBalance <= 0) return null;
    // 約 0.4%～1.2%／季，睇幸運
    final bps = 40 + (p.luck ~/ 5); // 40–60 bps typical
    final gain = (p.mpfBalance * bps / 10000).round();
    if (gain <= 0) return null;
    p.mpfBalance += gain;
    return '強積金投資約＋\$$gain（結餘 \$${p.mpfBalance}）';
  }

  /// 回傳派糧說明（可能多行）
  static String? applyPayroll(Player p) {
    if (!p.isEmployed) return null;
    if (!p.jobWorkedThisQuarter) {
      p.jobPerformance = (p.jobPerformance - 8).clamp(0, 100);
      p.stress = (p.stress + 4).clamp(0, 100);
      final lines = <String>[
        '今季冇返工，唔出糧。',
        '曠工／冇開工：工作表現 -8（而家 ${p.jobPerformance}）',
      ];
      final inv = tickMpfInvestment(p);
      if (inv != null) lines.add(inv);
      p.jobWorkedThisQuarter = false;
      return lines.join('\n');
    }
    final gross = quarterlyGross(p);
    if (gross <= 0) return null;

    final mpf = quarterlyMpfParts(
      grossQuarterly: gross,
      age: p.age,
      selfEmployed: _isSelfEmployed(p),
    );
    final empMpf = mpf.employee;
    final erMpf = mpf.employer;
    final net = gross - empMpf;
    p.wealth += net;
    p.mpfBalance += empMpf + erMpf;

    // 入息總額（似 IR56：未扣僱員強積金前）累積，Q4 報稅用
    CareerTax.addFullTimeIncome(p, gross);
    CareerTax.syncLegacyTotal(p);

    final lines = <String>[
      if (_isSelfEmployed(p))
        '出糧（自僱）：總入息 \$$gross − 強積金 \$$empMpf = 入袋 \$$net'
      else
        '出糧：總薪 \$$gross − 強積金 \$$empMpf = 入袋 \$$net',
      if (empMpf + erMpf > 0)
        '強積金＋\$${empMpf + erMpf}'
            '${erMpf > 0 ? "（連僱主）" : "（自僱）"}；結餘 \$${p.mpfBalance}'
      else if (p.age >= 65)
        '已滿 65 歲：停止強制強積金供款'
      else
        '今季入息低過強積金下限，唔使供',
    ];

    final inv = tickMpfInvestment(p);
    if (inv != null) lines.add(inv);

    final bonus = _rollYearEndBonus(p);
    if (bonus != null) lines.add(bonus);

    p.jobWorkedThisQuarter = false;
    return lines.join('\n');
  }

  /// Q1：花紅（約 0.5–2 個月月薪，睇表現；試用期無）
  static String? _rollYearEndBonus(Player p) {
    if (p.quarter != Quarter.q1) return null;
    if (CareerGov.usesGovRules(p)) return null;
    if (onProbation(p)) return '試用期無花紅';
    if (p.jobQuartersEmployed < 2) return null;
    if (p.unlockedFlags.contains('bonus_${p.year}')) return null;
    p.unlockedFlags.add('bonus_${p.year}');

    final govMonthly = CareerGov.monthlySalary(p);
    final track = CareerData.trackFor(p.currentSector);
    if (govMonthly <= 0 && track == null) return null;
    final monthly = effectiveMonthlySalary(p);
    if (monthly <= 0) return null;

    double months;
    if (p.jobPerformance >= 75) {
      months = 1.5 + (p.luck >= 60 ? 0.5 : 0);
    } else if (p.jobPerformance >= 55) {
      months = 1.0;
    } else if (p.jobPerformance >= 40) {
      months = 0.5;
    } else {
      months = 0;
    }

    months += CareerAbilities.bonusMonthsModifier(p);

    // 公務員／社福／教學偏穩，少啲「雙糧」波動
    if (p.currentSector == CareerSector.socialWork ||
        p.currentSector == CareerSector.teaching) {
      months = months.clamp(0.0, 1.0);
      if (months > 0 && months < 0.5) months = 0.5;
    } else {
      months = months.clamp(0.0, 2.5);
    }

    if (months <= 0) {
      p.stress = (p.stress + 4).clamp(0, 100);
      p.eventLog.add('${p.year}年：今年無花紅');
      return '花紅：無（表現太差）';
    }

    final amount = (monthly * months).round();
    // 花紅：按該筆相關入息計強積金（唔好當季薪再 ÷3）
    final bonusMpf = mpfPartsForLumpSum(
      amount: amount,
      age: p.age,
      selfEmployed: _isSelfEmployed(p),
    );
    final emp = bonusMpf.employee;
    final er = bonusMpf.employer;
    p.wealth += amount - emp;
    p.mpfBalance += emp + er;
    CareerTax.addFullTimeIncome(p, amount);
    CareerTax.syncLegacyTotal(p);
    p.eventLog.add('${p.year}年：花紅 \$$amount（約 $months 個月）');
    return '花紅：\$$amount（約 ${months.toStringAsFixed(1)} 個月月薪）'
        '${emp + er > 0 ? "\n花紅強積金已供 \$${emp + er}" : ""}';
  }

  /// 65 歲或以上／退休可提取強積金（60–64 提早提取有註明）
  static String? withdrawMpf(Player p) {
    if (p.mpfBalance <= 0) return '強積金戶口無錢';
    final retired = p.unlockedFlags.contains('retired');
    if (p.age < 60 && !retired) {
      return '未夠歲（要 60+ 提早／65 退休歲，或已退休）先可以提取強積金';
    }
    final amt = p.mpfBalance;
    p.wealth += amt;
    p.mpfBalance = 0;
    final early = p.age < 65 && !retired;
    p.eventLog.add(
      '${p.year}年：提取強積金 \$$amt${early ? "（提早）" : ""}',
    );
    return early
        ? '提早提取強積金 \$$amt 入現金（現實會有限制，遊戲簡化允許）'
        : '已提取強積金 \$$amt 入現金';
  }

  // ─── 裁員潮 ───────────────────────────────────────

  static int layoffBaseChance(CareerSector sector) => switch (sector) {
        CareerSector.civilService ||
        CareerSector.medical ||
        CareerSector.nursing ||
        CareerSector.teaching ||
        CareerSector.socialWork ||
        CareerSector.disciplinary =>
          4,
        CareerSector.banking ||
        CareerSector.accounting ||
        CareerSector.it ||
        CareerSector.media ||
        CareerSector.realEstate ||
        CareerSector.entertainment ||
        CareerSector.engineering =>
          14,
        CareerSector.labour ||
        CareerSector.insurance ||
        CareerSector.catering =>
          10,
        _ => 8,
      };

  /// 有機會出裁員事件卡；否則 null
  static StoryEvent? layoffEvent(Player p, Random rng) {
    if (!p.isEmployed) return null;
    if (onProbation(p)) return null; // 試用另有不合格機制
    if (p.currentSector == CareerSector.taxi) return null;

    var chance = layoffBaseChance(p.currentSector);
    if (p.quarter == Quarter.q1) chance += 4; // 年初重組
    if (p.jobPerformance < 40) chance += 10;
    if (p.jobPerformance >= 70) chance -= 6;
    if (p.employerId.contains('Google') ||
        p.employerId.contains('HSBC') ||
        p.employerId.contains('PwC') ||
        p.employerId.contains('Deloitte') ||
        p.employerId.contains('EY') ||
        p.employerId.contains('KPMG') ||
        p.employerId.contains('Microsoft')) {
      chance += 3; // 名企都有裁
    }
    chance = chance.clamp(2, 35);
    if (rng.nextInt(100) >= chance) return null;

    final title = p.jobTitle;
    return StoryEvent(
      id: 'career_layoff_wave',
      title: '裁員潮',
      body: '公司傳緊裁員／架構重組。你份工（$title）都喺討論名單入面。'
          '\n表現而家 ${p.jobPerformance}。點做？',
      choices: [
        EventChoice(
          label: 'OT 搏命表現自己',
          apply: (pl) {
            pl.jobPerformance = (pl.jobPerformance + 12).clamp(0, 100);
            pl.stress = (pl.stress + 10).clamp(0, 100);
            pl.san = (pl.san - 4).clamp(0, pl.maxSan);
            final survive = pl.jobPerformance >= 45 ||
                LuckModifiers.roll(pl, 0.55, Random());
            if (!survive) {
              CareerData.quitJob(pl, reason: '裁員潮：仍然被裁（$title）');
              pl.eventLog.add('${pl.year}年：搏命都好，仍然被裁');
            } else {
              pl.reputation = (pl.reputation + 2).clamp(0, 100);
              pl.eventLog.add('${pl.year}年：裁員潮留低咗');
            }
          },
        ),
        EventChoice(
          label: '低調做，祈禱唔中籤',
          apply: (pl) {
            final survive = pl.jobPerformance >= 50
                ? LuckModifiers.roll(pl, 0.7, Random())
                : LuckModifiers.roll(pl, 0.35, Random());
            if (!survive) {
              CareerData.quitJob(pl, reason: '裁員潮：中籤被裁（$title）');
            } else {
              pl.stress = (pl.stress + 5).clamp(0, 100);
              pl.eventLog.add('${pl.year}年：裁員潮僥倖留低');
            }
          },
        ),
        EventChoice(
          label: '主動辭工走人（保留面子）',
          apply: (pl) {
            CareerData.quitJob(pl, reason: '裁員潮前主動辭工');
            pl.reputation = (pl.reputation + 1).clamp(0, 100);
            pl.network = (pl.network + 2).clamp(0, 100);
          },
        ),
      ],
    );
  }

  // ─── 兼職轉正 ─────────────────────────────────────

  /// 兼職 id → 可轉正嘅全職行業（所有現有兼職都有對應）
  static CareerSector convertSectorFor(String partTimeId) =>
      switch (partTimeId) {
        'tutor_basic' || 'tutor_dse' => CareerSector.teaching,
        'bank_pt' => CareerSector.banking,
        'audit_pt' => CareerSector.accounting,
        'helpdesk_pt' => CareerSector.it,
        'news_pt' => CareerSector.media,
        'estate_pt' => CareerSector.realEstate,
        'insurance_pt' => CareerSector.insurance,
        'clinic_pt' => CareerSector.nursing,
        'pharm_pt' => CareerSector.pharmacy,
        'social_pt' => CareerSector.socialWork,
        'restaurant' || 'barista' || 'kfc' || 'mcd' => CareerSector.catering,
        // 零售／倉務／保安／文職／推廣 → 藍領服務
        '7eleven' ||
        'ok_store' ||
        'warehouse' ||
        'security' ||
        'clerk' ||
        'promo' ||
        'event' =>
          CareerSector.labour,
        _ => CareerSector.labour,
      };

  static String? convertBlockReason(Player p) {
    if (!PartTimeJobs.hasJob(p)) return '你冇兼職';
    if (p.isStudying) return '讀緊書唔可以轉全職';
    if (p.isEmployed) return '你已經有全職';
    if (p.age < 18) return '轉正要滿 18 歲';
    if (p.partTimeShiftsTotal < 8) {
      return '要返夠 8 更兼職先可以申請轉正（而家 ${p.partTimeShiftsTotal}）';
    }
    final sector = convertSectorFor(p.partTimeJobId);
    final block = CareerData.entryBlockReason(p, sector);
    if (block != null) {
      return '轉正去${sector.label}條件唔夠：$block';
    }
    return null;
  }

  static bool canApplyConvert(Player p) => convertBlockReason(p) == null;

  /// 申請轉正 → 走面試流程（成功率有加成）
  static String applyConvert(Player p) {
    final block = convertBlockReason(p);
    if (block != null) return block;
    final job = PartTimeJobs.current(p)!;
    final sector = convertSectorFor(job.id);
    final msg = CareerJobHunt.apply(
      p,
      sector,
      employer: job.employer.isNotEmpty ? job.employer : job.titleZh,
      prestige: false,
      bypassSeason: true,
    );
    // 內部員工加成：暫時提高 luck 感 — 用 flag
    p.unlockedFlags.add('pt_convert_boost');
    p.eventLog.add(
      '${p.year}年：以兼職身份申請轉正 → ${sector.label}（${job.label}）',
    );
    return '$msg\n內部轉正（${sector.label}）：面試會易啲過。';
  }

  static List<ActionButton> convertActions(Player p) {
    if (p.age < 16) return const [];
    if (!PartTimeJobs.hasJob(p)) return const [];
    if (p.isStudying || p.isEmployed) return const [];
    final block = convertBlockReason(p);
    final sector = convertSectorFor(p.partTimeJobId);
    return [
      ActionButton(
        label: block == null
            ? '申請轉正 → ${sector.label}'
            : '申請轉正（未夠條件）',
        apCost: 2,
        enabled: block == null,
        onExecute: (pl) {
          if (block != null) {
            pl.eventLog.add('${pl.year}年：轉正唔得 — $block');
            return;
          }
          pl.eventLog.add(applyConvert(pl));
        },
      ),
    ];
  }
}
