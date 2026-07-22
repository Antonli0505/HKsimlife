import 'dart:math';

import '../models/enums.dart';
import '../models/player.dart';

/// 屋企資產 vs 個人零用錢 — 家族財力不可直接花，只影響零用錢、利是同事件。
class FamilyAssets {
  static void applyForTier(Player player, BirthTier tier) {
    player.livesWithFamily = true;
    player.ownsFlat = false;
    player.renting = false;
    player.flatValue = 0;

    switch (tier) {
      case BirthTier.ssr:
        player.familyWealth = 20000000;
        player.familyPropertyValue = 80000000;
        player.familyOwnsHome = true;
        player.housingType = HousingType.luxury;
        player.baseAllowance = 12000;
        player.wealth = 3000;
      case BirthTier.sr:
        player.familyWealth = 500000;
        player.familyPropertyValue = 0;
        player.familyOwnsHome = false;
        player.housingType = HousingType.privateRental;
        player.renting = true;
        player.baseAllowance = 3500;
        player.wealth = 800;
      case BirthTier.r:
        player.familyWealth = 8000;
        player.familyPropertyValue = 0;
        player.familyOwnsHome = true;
        player.housingType = HousingType.publicHousing;
        player.baseAllowance = 400;
        player.wealth = 200;
    }
  }

  static Random _rng(Player p) =>
      Random(p.year * 997 + p.quarter.index * 131 + p.age * 17 + p.name.hashCode);

  /// 18 歲前、同住、未出粮 — 每季**不一定**有零用钱。
  static bool shouldReceiveAllowance(Player p) {
    if (p.age >= 18) return false;
    if (!p.livesWithFamily || p.inPrison) return false;

    var chance = switch (p.birthTier) {
      BirthTier.ssr => 70,
      BirthTier.sr => 55,
      BirthTier.r => 40,
    };

    if (p.birthTier == BirthTier.r && p.familyWealth < 3000) chance -= 15;
    if (p.discipline >= 60) chance += 8;
    if (p.stress > 60) chance -= 5;

    return _rng(p).nextInt(100) < chance.clamp(10, 90);
  }

  /// 本季零用钱金额（仅当 shouldReceiveAllowance 为 true 时使用）。
  static int quarterlyAllowanceAmount(Player p) {
    if (p.age >= 18) return 0;
    if (!p.livesWithFamily || p.inPrison) return 0;

    var amount = p.baseAllowance;
    if (p.age >= 6) amount = (amount * 1.1).round();
    if (p.age >= 12) amount = (amount * 1.3).round();
    if (p.age >= 16) amount = (amount * 1.5).round();

    switch (p.birthTier) {
      case BirthTier.ssr:
        if (p.discipline >= 55) amount = (amount * 1.1).round();
      case BirthTier.sr:
        if (p.smarts >= 70) amount = (amount * 1.08).round();
      case BirthTier.r:
        if (p.familyWealth < 3000) amount = (amount * 0.5).round();
    }

    // 小幅随机波动 ±20%
    final rng = _rng(p);
    final variance = (amount * 0.2 * (rng.nextDouble() * 2 - 1)).round();
    return (amount + variance).clamp(0, 999999);
  }

  /// 新年 Q1 派利是 — 随机 range，18 岁后金额递减但仍可能有。
  static int? rollLaiSee(Player p) {
    if (p.quarter != Quarter.q1 || !p.livesWithFamily || p.inPrison) {
      return null;
    }

    final rng = _rng(p);
    final (min, max) = _laiSeeRange(p);
    if (max <= 0) return null;
    return min + rng.nextInt(max - min + 1);
  }

  static (int min, int max) _laiSeeRange(Player p) {
    final adult = p.age >= 18;
    return switch (p.birthTier) {
      BirthTier.ssr => adult ? (3000, 15000) : (8000, 60000),
      BirthTier.sr => adult ? (200, 1500) : (500, 6000),
      BirthTier.r => adult ? (50, 300) : (100, 1500),
    };
  }

  static String laiSeeRangeLabel(Player p) {
    final (min, max) = _laiSeeRange(p);
    return '\$$min – \$$max';
  }

  static String allowanceStatusLabel(Player p) {
    if (p.age >= 18) return '已成年，冇零用錢';
    if (!p.livesWithFamily) return '已搬出';
    return '唔定期（睇屋企）';
  }

  static bool requestFromFamily(Player p, int amount, {String reason = ''}) {
    if (!p.livesWithFamily) return false;
    if (p.familyWealth < amount) {
      p.eventLog.add('${p.year}年：向屋企要錢失敗——屋企流動資金唔夠。');
      return false;
    }

    final askKey = 'family_ask_${p.year}_${p.quarter.name}';
    final asksThisQuarter = p.unlockedFlags
        .where((f) => f.startsWith('family_ask_ok_') || f == askKey)
        .length;
    // 同季愈問愈難；草根更易被拒
    var chance = switch (p.birthTier) {
      BirthTier.ssr => 0.82,
      BirthTier.sr => 0.55,
      BirthTier.r => 0.32,
    };
    chance -= asksThisQuarter * 0.18;
    chance -= p.stress / 250;
    if (p.discipline < 30) chance -= 0.08;
    chance = chance.clamp(0.08, 0.9);

    final ok = _rng(p).nextDouble() < chance;
    if (!ok) {
      p.stress = (p.stress + 4).clamp(0, 100);
      p.san = (p.san - 2).clamp(0, p.maxSan);
      p.unlockedFlags.add(askKey);
      p.eventLog.add(
        '${p.year}年：向屋企要錢——被拒'
        '${reason.isNotEmpty ? "（$reason）" : ""}。'
        '阿爸阿媽話「唔係提款機」。',
      );
      return false;
    }

    p.familyWealth -= amount;
    p.wealth += amount;
    p.unlockedFlags.add('family_ask_ok_${p.year}_${p.quarter.name}_$asksThisQuarter');
    if (reason.isNotEmpty) {
      p.eventLog.add('${p.year}年：向屋企要錢 — $reason (\$$amount)');
    }
    return true;
  }

  static bool familyPays(Player p, int amount, {String reason = ''}) {
    if (p.familyWealth < amount) return false;
    p.familyWealth -= amount;
    if (reason.isNotEmpty) {
      p.eventLog.add('${p.year}年：屋企代付 — $reason (\$$amount)');
    }
    return true;
  }

  static String familyWealthLabel(Player p) {
    if (p.familyWealth >= 1000000) {
      return '\$${(p.familyWealth / 1000000).toStringAsFixed(1)}M（屋企）';
    }
    if (p.familyWealth >= 1000) {
      return '\$${(p.familyWealth / 1000).toStringAsFixed(0)}K（屋企）';
    }
    return '\$${p.familyWealth}（屋企）';
  }
}
