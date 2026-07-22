import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_employment.dart';
import 'luck_modifiers.dart';

/// Q4 簡化薪俸稅報表：系統預填（似僱主 IR56）→ 玩家可調低 → 抽查
///
/// 現實參考（簡化入遊戲）：
/// - 僱主為僱員填 IR56B；兼職員工不論入息多少都要報
/// - 僱員個人報稅可對照副本再自行申報（遊戲允許「報少」博運）
abstract final class CareerTax {
  static const String _filedFlagPrefix = 'tax_filed_';
  static const int personalAllowance = CareerEmployment.personalAllowance;

  /// 如實申報唔抽查；少報時最低 45%，再按少報幅度加碼
  static const int cheatAuditFloor = 45;

  static bool alreadyFiledThisYear(Player p) =>
      p.unlockedFlags.contains('$_filedFlagPrefix${p.year}');

  static void markFiled(Player p) =>
      p.unlockedFlags.add('$_filedFlagPrefix${p.year}');

  static int totalActual(Player p) =>
      p.taxYearFtIncome + p.taxYearPtIncome;

  static void addFullTimeIncome(Player p, int amount) {
    if (amount <= 0) return;
    p.taxYearFtIncome += amount;
  }

  static void addPartTimeIncome(Player p, int amount) {
    if (amount <= 0) return;
    p.taxYearPtIncome += amount;
  }

  /// 工作相關現金入袋＋計入評稅入息（全職線）
  static void grantTaxablePay(Player p, int amount) {
    if (amount <= 0) return;
    p.wealth += amount;
    addFullTimeIncome(p, amount);
    syncLegacyTotal(p);
  }

  /// 兼職／實習津貼入袋＋計入評稅入息
  static void grantTaxablePartTimePay(Player p, int amount) {
    if (amount <= 0) return;
    p.wealth += amount;
    addPartTimeIncome(p, amount);
    syncLegacyTotal(p);
  }

  static void resetYearIncome(Player p) {
    p.taxYearFtIncome = 0;
    p.taxYearPtIncome = 0;
    // 舊欄位同步（個人檔／舊存檔顯示）
    p.taxYearIncome = 0;
  }

  static void syncLegacyTotal(Player p) {
    p.taxYearIncome = totalActual(p);
  }

  /// 全年總入息有冇過報稅門檻（免稅額）
  static bool mustFile(Player p) => totalActual(p) > personalAllowance;

  /// Q4 出稅卡：有入息就出，畀人睇搵咗幾錢；過免稅額先要真正報／交
  static bool shouldOfferReturn(Player p) {
    if (p.lifeStage != LifeStage.adult) return false;
    if (p.age < 18) return false;
    if (p.quarter != Quarter.q4) return false;
    if (alreadyFiledThisYear(p)) return false;
    syncLegacyTotal(p);
    return totalActual(p) > 0 || p.isEmployed || p.hasPartTime;
  }

  static int taxOnIncome(int assessableIncome) {
    final chargeable =
        (assessableIncome - personalAllowance).clamp(0, 999999999);
    if (chargeable <= 0) return 0;
    final progressive =
        CareerEmployment.progressiveSalariesTax(chargeable);
    final standard = (assessableIncome * 0.15).round();
    return progressive < standard ? progressive : standard;
  }

  /// 如實＝0%；少報 → 最少 45%，少報愈多愈易中
  static int auditChance({
    required int actual,
    required int declared,
  }) {
    if (actual <= 0) return 0;
    if (declared >= actual) return 0;
    final underRatio = (actual - declared) / actual;
    // 45% + 少報比例 × 50 → 最多約 95%
    final chance = (cheatAuditFloor + underRatio * 50).round();
    return chance.clamp(cheatAuditFloor, 95);
  }

  static String _formatMoney(int n) => '\$$n';

  /// 未過免稅額時嘅嘲諷（睇實際入息分檔）
  static String _belowThresholdRoast(int actual) {
    final lines = actual <= 0
        ? const [
            '稅局職員望住個零：「今年……無？」',
            '「恭喜，窮到連報稅表都慳到。」',
            '系統提示：搵唔到你有入息。係咪真係咁清高，定係冇人請你？',
          ]
        : actual < 40000
            ? const [
                '稅局：「呢筆數…… intern 餐飲都夠膽報多啲。」',
                '「免稅額都未掂到邊，你仲好意思問要唔要報？」',
                '同事見你入息單，以為係拎錯咗人哋個零用錢紀錄。',
                '「努力咗一年，結果連免稅額都追唔上——犀利。」',
              ]
            : actual < 90000
                ? const [
                    '「半桶水入息：夠交租就偷笑，夠交稅？未夠班。」',
                    '稅局蓋章：未達標。意思即係——你窮得安全。',
                    '「再加把勁，或者下年先有資格俾人抽稅。」',
                    '免稅額望住你，好似望住隻未長大嘅細路。',
                  ]
                : const [
                    '「就差一點點就過線——努力窮到啱啱好。」',
                    '稅局：「差少少就收你稅，可惜你偏偏唔夠格。」',
                    '「恭喜你成功企喺免稅額下面乘涼。」',
                    '入息貼近門檻但未過：稅局當你空氣，荷包當你勇士。',
                  ];
    final i = actual.abs() % lines.length;
    return lines[i];
  }

  static StoryEvent returnEvent(Player p) {
    syncLegacyTotal(p);
    final ft = p.taxYearFtIncome;
    final pt = p.taxYearPtIncome;
    final actual = totalActual(p);
    final over = mustFile(p);
    final taxIfHonest = taxOnIncome(actual);

    final body = StringBuffer()
      ..writeln('—— 本年入息一覽 ——')
      ..writeln('全職／花紅等：${_formatMoney(ft)}')
      ..writeln('兼職：${_formatMoney(pt)}')
      ..writeln('合計：${_formatMoney(actual)}')
      ..writeln('基本免稅額：${_formatMoney(personalAllowance)}')
      ..writeln('');

    if (!over) {
      body
        ..writeln('未過免稅額——唔使報稅／交稅。')
        ..writeln('')
        ..writeln(_belowThresholdRoast(actual))
        ..writeln('')
        ..writeln('呢張卡淨係畀你睇吓今年搵咗幾錢。');
      return StoryEvent(
        id: 'career_tax_return',
        title: '本年入息（Q4）',
        body: body.toString(),
        choices: [
          EventChoice(
            label: '知道喇（唔使交稅）',
            apply: (pl) => acknowledgeBelowThreshold(pl),
          ),
        ],
      );
    }

    body
      ..writeln('已過免稅額，要交薪俸稅報表（遊戲簡化版）。')
      ..writeln('系統預填如上，你可以改數再交。')
      ..writeln('兼職都要計入總入息。')
      ..writeln('若如實報，估計稅款：${_formatMoney(taxIfHonest)}')
      ..writeln('')
      ..writeln('如實申報唔會抽查；報少先有機會中——'
          '少報愈狠，中招率愈高（少報底 45% 起跳）。');

    return StoryEvent(
      id: 'career_tax_return',
      title: '薪俸稅報稅（Q4）',
      body: body.toString(),
      choices: [
        EventChoice(
          label: '如實申報 ${_formatMoney(actual)}'
              '（稅約 ${_formatMoney(taxIfHonest)}）',
          apply: (pl) => _file(pl, declared: actual),
        ),
        if (actual > 0) ..._underreportChoices(actual),
        EventChoice(
          label: '拖延／唔交（風險極大）',
          apply: (pl) => _skipFile(pl),
        ),
      ],
    );
  }

  static void acknowledgeBelowThreshold(Player p) {
    final actual = totalActual(p);
    markFiled(p);
    p.lastTaxPaid = 0;
    p.lastTaxDeclared = actual;
    p.eventLog.add(
      '${p.year}年 Q4：本年入息 ${_formatMoney(actual)}'
      '（未過免稅額，唔使交稅）',
    );
    resetYearIncome(p);
  }

  static List<EventChoice> _underreportChoices(int actual) {
    final tiers = <({String label, double keep})>[
      (label: '調低約一成', keep: 0.90),
      (label: '調低約三成', keep: 0.70),
      (label: '調低一半', keep: 0.50),
      (label: '報到免稅額邊（極進取）', keep: 0.0),
    ];
    return [
      for (final t in tiers)
        EventChoice(
          label: () {
            final declared = t.keep <= 0
                ? personalAllowance.clamp(0, actual)
                : (actual * t.keep).round();
            final d = declared.clamp(0, actual);
            final tax = taxOnIncome(d);
            final audit = auditChance(actual: actual, declared: d);
            return '${t.label} → 申報 ${_formatMoney(d)}'
                '（稅約 ${_formatMoney(tax)}｜抽查約 $audit%）';
          }(),
          apply: (pl) {
            final declared = t.keep <= 0
                ? personalAllowance.clamp(0, actual)
                : (actual * t.keep).round();
            _file(pl, declared: declared.clamp(0, actual));
          },
        ),
    ];
  }

  static void _file(Player p, {required int declared}) {
    final actual = totalActual(p);
    final safeDeclared = declared.clamp(0, actual > 0 ? actual : declared);
    final taxDue = taxOnIncome(safeDeclared);
    final chance = auditChance(actual: actual, declared: safeDeclared);
    final audited = LuckModifiers.roll(
      p,
      chance / 100.0,
      Random(p.year * 97 + actual + safeDeclared),
    );

    p.wealth -= taxDue;
    p.lastTaxPaid = taxDue;
    p.lastTaxDeclared = safeDeclared;
    markFiled(p);

    final lines = <String>[
      '已交薪俸稅報表：申報 ${_formatMoney(safeDeclared)}'
          '（系統數 ${_formatMoney(actual)}）',
      '暫繳／結算稅款 ${_formatMoney(taxDue)}',
    ];

    if (audited) {
      lines.addAll(_resolveAudit(p, actual: actual, declared: safeDeclared));
    } else if (safeDeclared >= actual) {
      lines.add('如實申報，唔使抽查。');
    } else {
      lines.add('今次未中抽查（你報少咗，但稅局未抽到）。');
    }

    resetYearIncome(p);
    p.eventLog.add('${p.year}年 Q4 報稅：\n${lines.join('\n')}');
  }

  static List<String> _resolveAudit(
    Player p, {
    required int actual,
    required int declared,
  }) {
    if (declared >= actual) {
      p.eventLog.add('${p.year}年：報稅抽查 — 核對數目正確');
      return ['稅局抽查：核對系統／僱主紀錄，數目正確，無事。'];
    }

    final honestTax = taxOnIncome(actual);
    final paid = taxOnIncome(declared);
    final underpaid = (honestTax - paid).clamp(0, 999999999);
    final underRatio =
        actual > 0 ? (actual - declared) / actual : 0.0;
    // 罰款：少交稅 ×（1.5～3.0）
    final fineMult = 1.5 + underRatio * 1.5;
    final fine = (underpaid * fineMult).round().clamp(underpaid, 999999999);
    final totalBill = underpaid + fine;

    p.wealth -= totalBill;
    p.lastTaxPaid = paid + totalBill;
    p.stress = (p.stress + 12 + (underRatio * 10).round()).clamp(0, 100);
    p.reputation = (p.reputation - 6 - (underRatio * 8).round()).clamp(0, 100);

    if (underRatio >= 0.45) {
      p.investigation = InvestigationStatus.police;
      p.unlockedFlags.add('tax_fraud_flag');
    }

    p.eventLog.add(
      '${p.year}年：報稅抽查中招！少報被追 ${_formatMoney(totalBill)}',
    );

    return [
      '稅局抽查中招！對照僱主／兼職紀錄，發現少報。',
      '要補回稅差 ${_formatMoney(underpaid)}＋罰款 ${_formatMoney(fine)}'
          '＝ ${_formatMoney(totalBill)}',
      if (underRatio >= 0.45) '個案嚴重，已轉介調查（灰色標記）。',
    ];
  }

  static void _skipFile(Player p) {
    markFiled(p);
    final actual = totalActual(p);
    final honestTax = taxOnIncome(actual);
    // 唔交：當全數被追 + 重罰
    final fine = (honestTax * 2).clamp(5000, 999999999);
    final bill = honestTax + fine;
    p.wealth -= bill;
    p.lastTaxPaid = bill;
    p.lastTaxDeclared = 0;
    p.stress = (p.stress + 18).clamp(0, 100);
    p.reputation = (p.reputation - 10).clamp(0, 100);
    p.investigation = InvestigationStatus.police;
    p.unlockedFlags.add('tax_fraud_flag');
    resetYearIncome(p);
    final msg = '逾期／唔交報稅表：稅局直接評稅＋罰款'
        '\n應繳約 ${_formatMoney(bill)}（含重罰）';
    p.eventLog.add('${p.year}年：$msg');
  }

  /// 玩家撳下一季跳過報稅卡
  static void forceMissedReturn(Player p) => _skipFile(p);
}
