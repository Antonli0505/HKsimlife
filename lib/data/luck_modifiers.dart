import 'dart:math';

import '../models/player.dart';

/// luck 50＝基準；影響搵工、賭博、投資（唔影響 DSE）
abstract final class LuckModifiers {
  /// luck 50→0%；100→+10%；0→-10%（小幅）
  static double oddsBonus(Player p) => (p.luck - 50) / 500.0;

  static bool roll(Player p, double baseChance, Random rng) {
    final chance = (baseChance + oddsBonus(p)).clamp(0.05, 0.95);
    return rng.nextDouble() < chance;
  }

  /// 投資回報率（-30%～+35%），luck 略為拉高期望值
  static double investmentReturnRate(Player p, Random rng) {
    final luckShift = (p.luck - 50) * 0.002;
    final noise = (rng.nextDouble() - 0.48) * 0.55;
    return (noise + luckShift).clamp(-0.30, 0.35);
  }
}
