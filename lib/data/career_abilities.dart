import 'dart:math';

import '../models/enums.dart';
import '../models/player.dart';
import 'career_gov.dart';

/// 行業能力欄位定義
class CareerAbilityField {
  final String key;
  final int initial;
  final bool isRisk;

  const CareerAbilityField(
    this.key, {
    this.initial = 0,
    this.isRisk = false,
  });
}

/// 全行業能力／風險／專屬罰／玩法修正
///
/// Flow：KPI 未達 → 表現↓ → 升職／花紅／危機／公職跳 point
abstract final class CareerAbilities {
  static Map<String, CareerAbilityField> fieldsFor(CareerSector sector) =>
      switch (sector) {
        CareerSector.entertainment => {
          '粉絲數': const CareerAbilityField('粉絲數', initial: 100),
          'Views': const CareerAbilityField('Views', initial: 0),
          '好評': const CareerAbilityField('好評', initial: 50),
          '負評': const CareerAbilityField('負評', initial: 5, isRisk: true),
          '炎上風險': const CareerAbilityField('炎上風險', initial: 10, isRisk: true),
          '內容產出': const CareerAbilityField('內容產出'),
        },
        CareerSector.media => {
          '稿件數': const CareerAbilityField('稿件數'),
          '點擊／收視': const CareerAbilityField('點擊／收視', initial: 20),
          '公關危機': const CareerAbilityField('公關危機', initial: 5, isRisk: true),
        },
        CareerSector.teaching => {
          '改簿量': const CareerAbilityField('改簿量'),
          '班成績': const CareerAbilityField('班成績', initial: 55),
          '家長滿意': const CareerAbilityField('家長滿意', initial: 50),
          '家長投訴': const CareerAbilityField('家長投訴', isRisk: true),
        },
        CareerSector.socialWork => {
          '個案數': const CareerAbilityField('個案數'),
          '個案成功率': const CareerAbilityField('個案成功率', initial: 50),
          '投訴': const CareerAbilityField('投訴', isRisk: true),
        },
        CareerSector.banking => {
          '客戶數': const CareerAbilityField('客戶數'),
          'AUM': const CareerAbilityField('AUM'),
          '合規分': const CareerAbilityField('合規分', initial: 70),
          '客訴': const CareerAbilityField('客訴', isRisk: true),
        },
        CareerSector.insurance => {
          '保單數': const CareerAbilityField('保單數'),
          'MDRT進度': const CareerAbilityField('MDRT進度'),
          '退保率': const CareerAbilityField('退保率', initial: 5, isRisk: true),
          '客訴': const CareerAbilityField('客訴', isRisk: true),
        },
        CareerSector.accounting => {
          'Busy Season': const CareerAbilityField('Busy Season'),
          '完成質素': const CareerAbilityField('完成質素', initial: 60),
          '出錯風險': const CareerAbilityField('出錯風險', initial: 8, isRisk: true),
        },
        CareerSector.it => {
          'Project 數': const CareerAbilityField('Project 數'),
          'Uptime': const CareerAbilityField('Uptime', initial: 95),
          'Bug 數': const CareerAbilityField('Bug 數', isRisk: true),
          '事故風險': const CareerAbilityField('事故風險', initial: 5, isRisk: true),
        },
        CareerSector.medical => {
          '值班時數': const CareerAbilityField('值班時數'),
          '手術成功率': const CareerAbilityField('手術成功率', initial: 50),
          '醫療事故風險': const CareerAbilityField(
            '醫療事故風險',
            initial: 8,
            isRisk: true,
          ),
        },
        CareerSector.nursing => {
          '值班時數': const CareerAbilityField('值班時數'),
          '病人滿意': const CareerAbilityField('病人滿意', initial: 60),
          '投訴': const CareerAbilityField('投訴', isRisk: true),
          '疲勞': const CareerAbilityField('疲勞', initial: 10, isRisk: true),
        },
        CareerSector.pharmacy => {
          '處方覆核': const CareerAbilityField('處方覆核'),
          '準確率': const CareerAbilityField('準確率', initial: 80),
          '錯藥風險': const CareerAbilityField('錯藥風險', initial: 5, isRisk: true),
        },
        CareerSector.legalSolicitor => {
          '檔案數': const CareerAbilityField('檔案數'),
          '勝訴率': const CareerAbilityField('勝訴率', initial: 40),
          '客戶滿意': const CareerAbilityField('客戶滿意', initial: 55),
          '客戶投訴': const CareerAbilityField('客戶投訴', isRisk: true),
        },
        CareerSector.legalBarrister => {
          '上庭次數': const CareerAbilityField('上庭次數'),
          '勝訴率': const CareerAbilityField('勝訴率', initial: 40),
          '聲譽': const CareerAbilityField('聲譽', initial: 40),
          '客戶投訴': const CareerAbilityField('客戶投訴', isRisk: true),
        },
        CareerSector.realEstate => {
          '成交單': const CareerAbilityField('成交單'),
          '客源': const CareerAbilityField('客源', initial: 20),
          '客訴': const CareerAbilityField('客訴', isRisk: true),
        },
        CareerSector.flightAttendant => {
          '飛行時數': const CareerAbilityField('飛行時數'),
          '服務分': const CareerAbilityField('服務分', initial: 70),
          '時差影響': const CareerAbilityField('時差影響', isRisk: true),
          '乘客投訴': const CareerAbilityField('乘客投訴', isRisk: true),
        },
        CareerSector.civilService => {
          '公文完成量': const CareerAbilityField('公文完成量'),
          '效率分': const CareerAbilityField('效率分', initial: 55),
          '市民投訴': const CareerAbilityField('市民投訴', isRisk: true),
          '敏感風險': const CareerAbilityField('敏感風險', initial: 5, isRisk: true),
        },
        CareerSector.disciplinary => {
          '執勤次數': const CareerAbilityField('執勤次數'),
          '體能表現': const CareerAbilityField('體能表現', initial: 50),
          '違紀風險': const CareerAbilityField('違紀風險', initial: 5, isRisk: true),
          '受傷風險': const CareerAbilityField('受傷風險', initial: 8, isRisk: true),
        },
        CareerSector.engineering => {
          '工程進度': const CareerAbilityField('工程進度'),
          '品質分': const CareerAbilityField('品質分', initial: 60),
          '延誤': const CareerAbilityField('延誤', isRisk: true),
          '安全風險': const CareerAbilityField('安全風險', initial: 10, isRisk: true),
        },
        CareerSector.catering => {
          '排更班次': const CareerAbilityField('排更班次'),
          '客流': const CareerAbilityField('客流', initial: 40),
          '評分': const CareerAbilityField('評分', initial: 70),
          '食安風險': const CareerAbilityField('食安風險', initial: 8, isRisk: true),
          '差評': const CareerAbilityField('差評', isRisk: true),
        },
        CareerSector.labour => {
          '工時': const CareerAbilityField('工時'),
          '技巧': const CareerAbilityField('技巧', initial: 40),
          '工傷風險': const CareerAbilityField('工傷風險', initial: 12, isRisk: true),
        },
        CareerSector.taxi => {
          '載客量': const CareerAbilityField('載客量'),
          '收入穩定': const CareerAbilityField('收入穩定', initial: 50),
          '差評': const CareerAbilityField('差評', isRisk: true),
          '違例風險': const CareerAbilityField('違例風險', initial: 5, isRisk: true),
        },
        CareerSector.politics => {
          '票倉': const CareerAbilityField('票倉'),
          '曝光度': const CareerAbilityField('曝光度'),
          '民望': const CareerAbilityField('民望', initial: 45),
          '醜聞風險': const CareerAbilityField('醜聞風險', initial: 8, isRisk: true),
        },
        CareerSector.none || CareerSector.student => const {},
      };

  /// 入職時 seed 全部能力欄（保留已有 KPI 進度）
  static void seedOnHire(Player p) {
    final fields = fieldsFor(p.currentSector);
    if (fields.isEmpty) return;
    final next = Map<String, dynamic>.from(p.careerAttributes);
    for (final e in fields.entries) {
      next.putIfAbsent(e.key, () => e.value.initial);
    }
    // 的士牌用 unlockedFlags taxi_license，唔再放裝飾欄
    p.careerAttributes = next;
  }

  static int get(Player p, String key, [int fallback = 0]) =>
      (p.careerAttributes[key] as int?) ?? fallback;

  static void set(Player p, String key, int value) {
    p.careerAttributes = {
      ...p.careerAttributes,
      key: value.clamp(0, 999999),
    };
  }

  static void add(Player p, String key, int delta, {int min = 0, int max = 999999}) {
    final v = (get(p, key) + delta).clamp(min, max);
    set(p, key, v);
  }

  /// KPI 未達：行業專屬罰（通用表現罰喺 CareerData）
  static String applyKpiFailPenalty(Player p) {
    final parts = <String>[];
    switch (p.currentSector) {
      case CareerSector.entertainment:
        add(p, '粉絲數', -15, min: 0);
        add(p, '負評', 4, max: 100);
        add(p, '炎上風險', 5, max: 100);
        parts.add('粉絲 -15、負評／炎上↑');
      case CareerSector.media:
        add(p, '點擊／收視', -8, min: 0);
        add(p, '公關危機', 4, max: 100);
        parts.add('點擊↓、公關危機↑');
      case CareerSector.teaching:
        add(p, '家長投訴', 2);
        add(p, '家長滿意', -5, min: 0, max: 100);
        add(p, '班成績', -2, min: 0, max: 100);
        parts.add('家長投訴↑、家長滿意↓、班成績↓');
      case CareerSector.socialWork:
        add(p, '投訴', 2);
        add(p, '個案成功率', -3, min: 0, max: 100);
        parts.add('投訴↑、成功率↓');
      case CareerSector.banking:
        add(p, '合規分', -4, min: 0, max: 100);
        add(p, '客訴', 1);
        parts.add('合規分↓、客訴↑');
      case CareerSector.insurance:
        add(p, '退保率', 3, max: 100);
        add(p, '客訴', 1);
        parts.add('退保／客訴↑');
      case CareerSector.accounting:
        add(p, '完成質素', -5, min: 0, max: 100);
        add(p, '出錯風險', 5, max: 100);
        parts.add('質素↓、出錯風險↑');
      case CareerSector.it:
        add(p, 'Bug 數', 3);
        add(p, 'Uptime', -2, min: 50, max: 100);
        add(p, '事故風險', 4, max: 100);
        parts.add('Bug↑、Uptime↓');
      case CareerSector.medical:
        add(p, '手術成功率', -2, min: 0, max: 100);
        add(p, '醫療事故風險', 4, max: 100);
        parts.add('手術成功率↓、事故風險↑');
      case CareerSector.nursing:
        add(p, '病人滿意', -4, min: 0, max: 100);
        add(p, '投訴', 1);
        add(p, '疲勞', 5, max: 100);
        parts.add('病人滿意↓、疲勞↑');
      case CareerSector.pharmacy:
        add(p, '準確率', -3, min: 0, max: 100);
        add(p, '錯藥風險', 4, max: 100);
        parts.add('準確率↓、錯藥風險↑');
      case CareerSector.legalSolicitor:
        add(p, '勝訴率', -2, min: 0, max: 100);
        add(p, '客戶滿意', -4, min: 0, max: 100);
        add(p, '客戶投訴', 1);
        parts.add('勝訴／滿意↓');
      case CareerSector.legalBarrister:
        add(p, '勝訴率', -2, min: 0, max: 100);
        add(p, '聲譽', -3, min: 0, max: 100);
        add(p, '客戶投訴', 1);
        parts.add('勝訴／聲譽↓');
      case CareerSector.realEstate:
        add(p, '客源', -5, min: 0);
        add(p, '客訴', 1);
        parts.add('客源↓');
      case CareerSector.flightAttendant:
        add(p, '服務分', -4, min: 0, max: 100);
        add(p, '時差影響', 3, max: 100);
        add(p, '乘客投訴', 1);
        parts.add('服務分↓、時差↑');
      case CareerSector.civilService:
        add(p, '效率分', -4, min: 0, max: 100);
        add(p, '市民投訴', 1);
        add(p, '敏感風險', 2, max: 100);
        parts.add('效率↓、投訴↑（表現↓會影響跳 point）');
      case CareerSector.disciplinary:
        add(p, '體能表現', -3, min: 0, max: 100);
        add(p, '違紀風險', 3, max: 100);
        parts.add('體能表現↓、違紀↑（表現↓會影響跳 point）');
      case CareerSector.engineering:
        add(p, '品質分', -4, min: 0, max: 100);
        add(p, '延誤', 2);
        add(p, '安全風險', 3, max: 100);
        parts.add('品質↓、延誤↑');
      case CareerSector.catering:
        add(p, '評分', -4, min: 0, max: 100);
        add(p, '差評', 2);
        add(p, '客流', -3, min: 0);
        add(p, '食安風險', 3, max: 100);
        parts.add('評分↓、差評↑、食安風險↑');
      case CareerSector.labour:
        add(p, '技巧', -2, min: 0, max: 100);
        add(p, '工傷風險', 4, max: 100);
        parts.add('技巧↓、工傷風險↑');
      case CareerSector.taxi:
        add(p, '差評', 2);
        add(p, '收入穩定', -4, min: 0, max: 100);
        parts.add('差評↑、收入穩定↓');
      case CareerSector.politics:
        add(p, '民望', -5, min: 0, max: 100);
        add(p, '醜聞風險', 4, max: 100);
        parts.add('民望↓、醜聞風險↑');
      case CareerSector.none || CareerSector.student:
        break;
    }
    return parts.isEmpty ? '' : parts.join('；');
  }

  /// 行業行動成功時推能力（KPI 計數由 doSectorAction 另加）
  static void onSectorActionSuccess(Player p) {
    switch (p.currentSector) {
      case CareerSector.entertainment:
        final views = 800 + Random(p.year + p.age).nextInt(2200);
        add(p, 'Views', views);
        add(p, '粉絲數', 15 + p.luck ~/ 10);
        if (Random(p.year * 3 + p.jobPerformance).nextInt(100) < 60) {
          add(p, '好評', 2, max: 100);
        } else {
          add(p, '負評', 1, max: 100);
        }
      case CareerSector.media:
        add(p, '點擊／收視', 5 + p.luck ~/ 15);
      case CareerSector.teaching:
        add(p, '班成績', 1, max: 100);
        add(p, '家長滿意', 1, max: 100);
      case CareerSector.socialWork:
        add(p, '個案成功率', 1, max: 100);
      case CareerSector.banking:
        add(p, 'AUM', 50 + p.luck);
        add(p, '合規分', 1, max: 100);
      case CareerSector.insurance:
        add(p, 'MDRT進度', 1);
      case CareerSector.accounting:
        add(p, '完成質素', 1, max: 100);
      case CareerSector.it:
        add(p, 'Uptime', 1, max: 100);
        if (get(p, 'Bug 數') > 0) add(p, 'Bug 數', -1, min: 0);
      case CareerSector.medical:
        add(p, '手術成功率', 1, max: 100);
      case CareerSector.nursing:
        add(p, '病人滿意', 1, max: 100);
        add(p, '疲勞', 2, max: 100);
      case CareerSector.pharmacy:
        add(p, '準確率', 1, max: 100);
      case CareerSector.legalSolicitor:
        add(p, '客戶滿意', 1, max: 100);
        add(p, '勝訴率', 1, max: 100);
      case CareerSector.legalBarrister:
        add(p, '聲譽', 1, max: 100);
        add(p, '勝訴率', 1, max: 100);
      case CareerSector.realEstate:
        add(p, '客源', 2);
      case CareerSector.flightAttendant:
        add(p, '服務分', 1, max: 100);
        add(p, '時差影響', 1, max: 100);
        if (get(p, '時差影響') >= 25) {
          add(p, '服務分', -2, min: 0, max: 100);
        }
      case CareerSector.civilService:
        add(p, '效率分', 1, max: 100);
      case CareerSector.disciplinary:
        add(p, '體能表現', 1, max: 100);
        p.fitness = (p.fitness + 1).clamp(0, 100);
      case CareerSector.engineering:
        add(p, '品質分', 1, max: 100);
      case CareerSector.catering:
        add(p, '客流', 2);
        add(p, '評分', 1, max: 100);
      case CareerSector.labour:
        add(p, '技巧', 1, max: 100);
      case CareerSector.taxi:
        add(p, '收入穩定', 1, max: 100);
      case CareerSector.politics:
        add(p, '民望', 1, max: 100);
      case CareerSector.none || CareerSector.student:
        break;
    }
  }

  /// 升職修正（能力好加分、風險高扣分）
  static int promoteChanceModifier(Player p) {
    if (!p.isEmployed) return 0;
    var m = 0;
    switch (p.currentSector) {
      case CareerSector.entertainment:
        if (get(p, '粉絲數') >= 500) m += 6;
        if (get(p, 'Views') >= 20000) m += 4;
        if (get(p, '好評') >= 70) m += 4;
        if (get(p, '好評') < 35) m -= 5;
        if (get(p, '負評') >= 30) m -= 8;
        if (get(p, '炎上風險') >= 40) m -= 6;
      case CareerSector.teaching:
        if (get(p, '班成績') >= 70) m += 5;
        if (get(p, '家長滿意') >= 70) m += 5;
        if (get(p, '家長滿意') < 40) m -= 6;
        if (get(p, '家長投訴') >= 3) m -= 8;
      case CareerSector.banking:
        if (get(p, 'AUM') >= 500) m += 5;
        if (get(p, '合規分') < 50) m -= 10;
      case CareerSector.insurance:
        if (get(p, 'MDRT進度') >= 5) m += 6;
        if (get(p, '退保率') >= 20) m -= 6;
      case CareerSector.accounting:
        if (get(p, '完成質素') >= 75) m += 5;
        if (get(p, '出錯風險') >= 25) m -= 7;
      case CareerSector.it:
        if (get(p, 'Uptime') >= 98) m += 5;
        if (get(p, 'Bug 數') >= 10) m -= 8;
      case CareerSector.medical:
        if (get(p, '手術成功率') >= 70) m += 6;
        if (get(p, '醫療事故風險') >= 25) m -= 10;
      case CareerSector.nursing:
        if (get(p, '病人滿意') >= 75) m += 5;
        if (get(p, '投訴') >= 3) m -= 6;
      case CareerSector.legalSolicitor || CareerSector.legalBarrister:
        if (get(p, '勝訴率') >= 55) m += 6;
        if (get(p, '客戶滿意') >= 70 || get(p, '聲譽') >= 60) m += 4;
        if (get(p, '客戶投訴') >= 2) m -= 7;
      case CareerSector.civilService:
        if (get(p, '效率分') >= 70) m += 4;
        if (get(p, '市民投訴') >= 3) m -= 6;
      case CareerSector.disciplinary:
        if (get(p, '體能表現') >= 70) m += 4;
        if (get(p, '違紀風險') >= 20) m -= 10;
      case CareerSector.politics:
        // 共用角色名望 reputation：愈高愈易升
        if (p.reputation >= 70) {
          m += 10;
        } else if (p.reputation >= 55) {
          m += 6;
        } else if (p.reputation >= 40) {
          m += 3;
        } else if (p.reputation < 30) {
          m -= 6;
        }
        if (get(p, '民望') >= 60) m += 8;
        if (get(p, '票倉') >= 5) m += 5;
        if (get(p, '醜聞風險') >= 25) m -= 10;
      case CareerSector.catering:
        if (get(p, '評分') >= 80) m += 5;
        if (get(p, '客流') >= 60) m += 3;
        if (get(p, '差評') >= 5) m -= 6;
      case CareerSector.realEstate:
        if (get(p, '客源') >= 40) m += 4;
      case CareerSector.flightAttendant:
        if (get(p, '服務分') >= 80) m += 5;
        if (get(p, '時差影響') >= 30) m -= 5;
        if (get(p, '乘客投訴') >= 3) m -= 6;
      case CareerSector.engineering:
        if (get(p, '品質分') >= 75) m += 5;
        if (get(p, '延誤') >= 4) m -= 6;
      case CareerSector.pharmacy:
        if (get(p, '準確率') >= 90) m += 5;
        if (get(p, '錯藥風險') >= 20) m -= 10;
      case CareerSector.media:
        if (get(p, '點擊／收視') >= 80) m += 5;
        if (get(p, '公關危機') >= 25) m -= 7;
      case CareerSector.socialWork:
        if (get(p, '個案成功率') >= 70) m += 4;
        if (get(p, '投訴') >= 3) m -= 6;
      case CareerSector.labour:
        if (get(p, '技巧') >= 70) m += 4;
        if (get(p, '工傷風險') >= 30) m -= 5;
      case CareerSector.taxi:
        if (get(p, '收入穩定') >= 70) m += 3;
        if (get(p, '差評') >= 5) m -= 6;
      case CareerSector.none || CareerSector.student:
        break;
    }
    return m;
  }

  /// 花紅月數修正（公務員／紀律回傳 0 唔用）
  static double bonusMonthsModifier(Player p) {
    if (CareerGov.usesGovRules(p)) return 0;
    var m = 0.0;
    switch (p.currentSector) {
      case CareerSector.entertainment:
        if (get(p, '粉絲數') >= 800) m += 0.3;
        if (get(p, 'Views') >= 30000) m += 0.2;
        if (get(p, '好評') >= 75) m += 0.15;
        if (get(p, '負評') >= 25) m -= 0.4;
      case CareerSector.banking:
        if (get(p, 'AUM') >= 800) m += 0.4;
        if (get(p, '合規分') < 55) m -= 0.5;
      case CareerSector.insurance:
        if (get(p, 'MDRT進度') >= 8) m += 0.5;
        if (get(p, '退保率') >= 18) m -= 0.3;
      case CareerSector.accounting:
        if (get(p, '完成質素') >= 80) m += 0.25;
        if (get(p, '出錯風險') >= 30) m -= 0.4;
      case CareerSector.it:
        if (get(p, 'Bug 數') >= 12) m -= 0.35;
        if (get(p, 'Uptime') >= 99) m += 0.2;
      case CareerSector.realEstate:
        if (get(p, '成交單') >= 6) m += 0.3;
      case CareerSector.catering:
        if (get(p, '評分') >= 85) m += 0.25;
        if (get(p, '差評') >= 6) m -= 0.3;
      case CareerSector.taxi:
        if (get(p, '收入穩定') < 40) m -= 0.3;
        if (get(p, '差評') >= 4) m -= 0.2;
      case CareerSector.media:
        if (get(p, '點擊／收視') >= 100) m += 0.25;
      default:
        break;
    }
    return m;
  }

  /// 危機事件額外觸發機率（0–40）
  static int crisisChanceBonus(Player p) {
    if (!p.isEmployed) return 0;
    var b = 0;
    switch (p.currentSector) {
      case CareerSector.entertainment:
        b += get(p, '炎上風險') ~/ 3;
        b += get(p, '負評') ~/ 4;
        b -= get(p, '好評', 50) ~/ 20; // 好評高少啲危機
      case CareerSector.media:
        b += get(p, '公關危機') ~/ 3;
      case CareerSector.teaching:
        b += get(p, '家長投訴') * 4;
      case CareerSector.socialWork:
        b += get(p, '投訴') * 4;
      case CareerSector.banking:
        b += (70 - get(p, '合規分', 70)).clamp(0, 40) ~/ 2;
        b += get(p, '客訴') * 3;
      case CareerSector.insurance:
        b += get(p, '退保率') ~/ 2;
        b += get(p, '客訴') * 3;
      case CareerSector.accounting:
        b += get(p, '出錯風險') ~/ 2;
      case CareerSector.it:
        b += get(p, 'Bug 數');
        b += get(p, '事故風險') ~/ 2;
      case CareerSector.medical:
        b += get(p, '醫療事故風險') ~/ 2;
      case CareerSector.nursing:
        b += get(p, '投訴') * 3;
        b += get(p, '疲勞') ~/ 4;
      case CareerSector.pharmacy:
        b += get(p, '錯藥風險') ~/ 2;
      case CareerSector.legalSolicitor || CareerSector.legalBarrister:
        b += get(p, '客戶投訴') * 5;
      case CareerSector.civilService:
        b += get(p, '市民投訴') * 4;
        b += get(p, '敏感風險') ~/ 3;
      case CareerSector.disciplinary:
        b += get(p, '違紀風險') ~/ 2;
        b += get(p, '受傷風險') ~/ 3;
      case CareerSector.engineering:
        b += get(p, '延誤') * 3;
        b += get(p, '安全風險') ~/ 3;
      case CareerSector.catering:
        b += get(p, '差評') * 3;
        b += get(p, '食安風險') ~/ 3;
      case CareerSector.labour:
        b += get(p, '工傷風險') ~/ 3;
      case CareerSector.taxi:
        b += get(p, '差評') * 3;
        b += get(p, '違例風險') ~/ 2;
      case CareerSector.politics:
        b += get(p, '醜聞風險') ~/ 2;
        b += (50 - get(p, '民望', 45)).clamp(0, 40) ~/ 2;
        if (get(p, '票倉') < 2) b += 4;
      case CareerSector.flightAttendant:
        b += get(p, '乘客投訴') * 4;
        b += get(p, '時差影響') ~/ 3;
      case CareerSector.realEstate:
        b += get(p, '客訴') * 4;
      case CareerSector.none || CareerSector.student:
        break;
    }
    return b.clamp(0, 40);
  }

  /// Profile：能力欄（非風險；只顯示本行業定義欄）
  static List<MapEntry<String, dynamic>> abilityEntries(Player p) {
    final fields = fieldsFor(p.currentSector);
    return p.careerAttributes.entries
        .where((e) => fields.containsKey(e.key) && fields[e.key]!.isRisk != true)
        .toList();
  }

  /// Profile：風險欄
  static List<MapEntry<String, dynamic>> riskEntries(Player p) {
    final fields = fieldsFor(p.currentSector);
    return p.careerAttributes.entries
        .where((e) => fields[e.key]?.isRisk == true)
        .toList();
  }
}
