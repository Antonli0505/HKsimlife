import 'dart:math';

import '../models/game_event.dart';
import '../models/player.dart';

enum AssetMarket { hk, us, crypto }

enum AssetKind { etf, stock, crypto, stable }

class MarketAsset {
  final String id;
  final String nameZh;
  final AssetMarket market;
  final AssetKind kind;
  final double basePrice;
  final double quarterlyDrift;
  final double quarterlySigma;

  const MarketAsset({
    required this.id,
    required this.nameZh,
    required this.market,
    required this.kind,
    required this.basePrice,
    required this.quarterlyDrift,
    required this.quarterlySigma,
  });

  String get marketLabel => switch (market) {
        AssetMarket.hk => '港股',
        AssetMarket.us => '美股',
        AssetMarket.crypto => '加密',
      };
}

class AssetHolding {
  String assetId;
  double units;
  double avgCostHkd;

  AssetHolding({
    required this.assetId,
    this.units = 0,
    this.avgCostHkd = 0,
  });

  Map<String, dynamic> toJson() => {
        'assetId': assetId,
        'units': units,
        'avgCostHkd': avgCostHkd,
      };

  factory AssetHolding.fromJson(Map<String, dynamic> json) => AssetHolding(
        assetId: json['assetId'] as String? ?? '',
        units: (json['units'] as num?)?.toDouble() ?? 0,
        avgCostHkd: (json['avgCostHkd'] as num?)?.toDouble() ?? 0,
      );
}

/// 模擬港／美股＋加密市場（離線種子，季結更新）
abstract final class MarketEngine {
  static const minAge = 18;
  static const maxHistory = 24;

  static const catalogue = <MarketAsset>[
    MarketAsset(
      id: '2800.HK',
      nameZh: '盈富基金',
      market: AssetMarket.hk,
      kind: AssetKind.etf,
      basePrice: 24,
      quarterlyDrift: 0.015,
      quarterlySigma: 0.08,
    ),
    MarketAsset(
      id: '0700.HK',
      nameZh: '騰訊',
      market: AssetMarket.hk,
      kind: AssetKind.stock,
      basePrice: 380,
      quarterlyDrift: 0.02,
      quarterlySigma: 0.12,
    ),
    MarketAsset(
      id: '0005.HK',
      nameZh: '匯豐',
      market: AssetMarket.hk,
      kind: AssetKind.stock,
      basePrice: 65,
      quarterlyDrift: 0.01,
      quarterlySigma: 0.09,
    ),
    MarketAsset(
      id: '0388.HK',
      nameZh: '港交所',
      market: AssetMarket.hk,
      kind: AssetKind.stock,
      basePrice: 280,
      quarterlyDrift: 0.015,
      quarterlySigma: 0.11,
    ),
    MarketAsset(
      id: 'VOO',
      nameZh: '標普500 ETF',
      market: AssetMarket.us,
      kind: AssetKind.etf,
      basePrice: 420,
      quarterlyDrift: 0.02,
      quarterlySigma: 0.06,
    ),
    MarketAsset(
      id: 'AAPL',
      nameZh: '蘋果',
      market: AssetMarket.us,
      kind: AssetKind.stock,
      basePrice: 190,
      quarterlyDrift: 0.022,
      quarterlySigma: 0.09,
    ),
    MarketAsset(
      id: 'NVDA',
      nameZh: '輝達',
      market: AssetMarket.us,
      kind: AssetKind.stock,
      basePrice: 120,
      quarterlyDrift: 0.03,
      quarterlySigma: 0.16,
    ),
    MarketAsset(
      id: 'MSFT',
      nameZh: '微軟',
      market: AssetMarket.us,
      kind: AssetKind.stock,
      basePrice: 420,
      quarterlyDrift: 0.02,
      quarterlySigma: 0.08,
    ),
    MarketAsset(
      id: 'BTC',
      nameZh: '比特幣',
      market: AssetMarket.crypto,
      kind: AssetKind.crypto,
      basePrice: 650000,
      quarterlyDrift: 0.04,
      quarterlySigma: 0.25,
    ),
    MarketAsset(
      id: 'ETH',
      nameZh: '以太幣',
      market: AssetMarket.crypto,
      kind: AssetKind.crypto,
      basePrice: 22000,
      quarterlyDrift: 0.035,
      quarterlySigma: 0.28,
    ),
    MarketAsset(
      id: 'SOL',
      nameZh: 'Solana',
      market: AssetMarket.crypto,
      kind: AssetKind.crypto,
      basePrice: 1100,
      quarterlyDrift: 0.03,
      quarterlySigma: 0.35,
    ),
    MarketAsset(
      id: 'USDT',
      nameZh: '美元穩定幣',
      market: AssetMarket.crypto,
      kind: AssetKind.stable,
      basePrice: 7.8,
      quarterlyDrift: 0,
      quarterlySigma: 0.003,
    ),
  ];

  static MarketAsset? byId(String id) {
    for (final a in catalogue) {
      if (a.id == id) return a;
    }
    return null;
  }

  static bool canTrade(Player p) => p.age >= minAge;

  static void ensureInitialized(Player p) {
    if (p.marketSeed == 0) {
      p.marketSeed = p.year * 997 + p.age * 31 + p.wealth.hashCode.abs() % 9999;
    }
    if (p.assetPrices.isEmpty) {
      for (final a in catalogue) {
        p.assetPrices[a.id] = a.basePrice;
        p.assetPriceHistory[a.id] = [a.basePrice];
      }
    }
    if (p.hkPropertyIndex <= 0) p.hkPropertyIndex = 1.0;
  }

  static double priceOf(Player p, String id) {
    ensureInitialized(p);
    return p.assetPrices[id] ?? byId(id)?.basePrice ?? 0;
  }

  static List<double> historyOf(Player p, String id) {
    ensureInitialized(p);
    return List<double>.from(p.assetPriceHistory[id] ?? const []);
  }

  static double _gauss(Random rng) {
    // Box-Muller
    final u1 = (rng.nextDouble() + 1e-12).clamp(1e-12, 1.0);
    final u2 = rng.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  static Random _rng(Player p, String salt) => Random(
        p.marketSeed +
            p.year * 131 +
            p.quarter.index * 17 +
            salt.hashCode +
            p.holdings.length * 3,
      );

  /// 季結：更新 12 資產價＋樓價指數；回傳提示（可空）
  static String? tickQuarter(Player p) {
    ensureInitialized(p);
    final msgs = <String>[];
    var bigDrop = false;

    for (final a in catalogue) {
      final rng = _rng(p, a.id);
      double ret;
      if (a.kind == AssetKind.stable) {
        if (rng.nextDouble() < 0.005) {
          ret = -(0.05 + rng.nextDouble() * 0.1);
          msgs.add('USDT 短暫脫錨：${(ret * 100).toStringAsFixed(1)}%');
        } else {
          ret = a.quarterlyDrift + a.quarterlySigma * _gauss(rng);
          ret = ret.clamp(-0.01, 0.01);
        }
      } else {
        ret = a.quarterlyDrift + a.quarterlySigma * _gauss(rng);
        ret = ret.clamp(-0.55, 0.8);
      }
      final old = p.assetPrices[a.id] ?? a.basePrice;
      final next = (old * (1 + ret)).clamp(a.basePrice * 0.05, a.basePrice * 40);
      p.assetPrices[a.id] = next;
      final hist = p.assetPriceHistory.putIfAbsent(a.id, () => []);
      hist.add(next);
      while (hist.length > maxHistory) {
        hist.removeAt(0);
      }
      if (ret <= -0.25) bigDrop = true;
    }

    // 樓價指數：低波動
    final propRng = _rng(p, 'hk_prop');
    final propRet =
        (0.005 + 0.035 * _gauss(propRng)).clamp(-0.12, 0.1);
    p.hkPropertyIndex =
        (p.hkPropertyIndex * (1 + propRet)).clamp(0.55, 1.8);

    if (bigDrop) {
      msgs.add('市場動盪：有資產單季急跌超過 25%。');
    }
    return msgs.isEmpty ? null : msgs.join('\n');
  }

  static double feeRate(MarketAsset a) => switch (a.market) {
        AssetMarket.hk => 0.001,
        AssetMarket.us => 0.0025,
        AssetMarket.crypto => 0.004,
      };

  static AssetHolding _holding(Player p, String id) {
    for (final h in p.holdings) {
      if (h.assetId == id) return h;
    }
    final h = AssetHolding(assetId: id);
    p.holdings.add(h);
    return h;
  }

  static String buy(Player p, String assetId, int spendHkd) {
    if (!canTrade(p)) return '未滿 $minAge 歲唔可以投資。';
    ensureInitialized(p);
    final a = byId(assetId);
    if (a == null) return '搵唔到呢個資產。';
    if (spendHkd < 1000) return '最少投資 \$1000。';
    if (p.wealth < spendHkd) return '現金唔夠（要約 \$$spendHkd）。';

    final price = priceOf(p, assetId);
    if (price <= 0) return '價格異常。';
    final fee = (spendHkd * feeRate(a)).round().clamp(1, spendHkd ~/ 10);
    final net = spendHkd - fee;
    final units = net / price;
    final h = _holding(p, assetId);
    final oldCost = h.avgCostHkd * h.units;
    h.units += units;
    h.avgCostHkd = h.units > 0 ? (oldCost + net) / h.units : 0;
    p.wealth -= spendHkd;
    final msg =
        '買入 ${a.nameZh}（${a.id}）：花 \$$spendHkd（含手續費 \$$fee）'
        '· ${units.toStringAsFixed(4)} 單位 · 現價 \$${price.toStringAsFixed(2)}';
    p.eventLog.add('${p.year}年：$msg');
    return msg;
  }

  static String sell(Player p, String assetId, {double? fraction}) {
    if (!canTrade(p)) return '未滿 $minAge 歲唔可以投資。';
    ensureInitialized(p);
    final a = byId(assetId);
    if (a == null) return '搵唔到呢個資產。';
    final h = _holding(p, assetId);
    if (h.units <= 1e-9) return '你冇持有 ${a.nameZh}。';

    final frac = (fraction ?? 1.0).clamp(0.0, 1.0);
    final units = h.units * frac;
    final price = priceOf(p, assetId);
    final gross = (units * price).round();
    final fee = (gross * feeRate(a)).round().clamp(0, gross ~/ 10);
    final net = gross - fee;
    final costBasis = h.avgCostHkd * units;
    final pnl = net - costBasis.round();
    h.units = (h.units - units).clamp(0, 1e18);
    if (h.units < 1e-9) {
      h.units = 0;
      h.avgCostHkd = 0;
    }
    p.wealth += net;
    final msg =
        '賣出 ${a.nameZh}：到手 \$$net（手續費 \$$fee）'
        '· ${pnl >= 0 ? "賺" : "蝕"} \$${pnl.abs()}';
    p.eventLog.add('${p.year}年：$msg');
    return msg;
  }

  static int portfolioValue(Player p) {
    ensureInitialized(p);
    var sum = 0.0;
    for (final h in p.holdings) {
      if (h.units <= 0) continue;
      sum += h.units * priceOf(p, h.assetId);
    }
    return sum.round();
  }

  static int portfolioCost(Player p) {
    var sum = 0.0;
    for (final h in p.holdings) {
      if (h.units <= 0) continue;
      sum += h.units * h.avgCostHkd;
    }
    return sum.round();
  }

  static String statusSummary(Player p) {
    ensureInitialized(p);
    final v = portfolioValue(p);
    final c = portfolioCost(p);
    if (v == 0 && c == 0) return '未有持倉';
    final pnl = v - c;
    return '市值 \$$v · 成本 \$$c · '
        '${pnl >= 0 ? "浮盈" : "浮虧"} \$${pnl.abs()}';
  }

  static double quarterChangePct(Player p, String id) {
    final hist = historyOf(p, id);
    if (hist.length < 2) return 0;
    final prev = hist[hist.length - 2];
    if (prev <= 0) return 0;
    return (hist.last - prev) / prev * 100;
  }

  static const buyAmounts = [5000, 20000, 100000];

  static StoryEvent assetPicker(Player p, {required bool selling}) {
    ensureInitialized(p);
    return StoryEvent(
      id: selling ? 'invest_sell_pick' : 'invest_buy_pick',
      title: selling ? '賣邊隻？' : '買邊隻？',
      body: selling
          ? '揀持倉賣出（可賣一半或清倉）。'
          : '港股／美股／加密共 12 隻。滿 $minAge 歲先可以買賣。'
              '加密波動極大。',
      choices: [
        for (final a in catalogue)
          if (!selling ||
              p.holdings.any((h) => h.assetId == a.id && h.units > 0))
            EventChoice(
              label: () {
                final px = priceOf(p, a.id);
                final ch = quarterChangePct(p, a.id);
                final sign = ch >= 0 ? '+' : '';
                return '${a.nameZh}（${a.id}）\n'
                    '${a.marketLabel} · \$${px.toStringAsFixed(2)} · '
                    '今季 $sign${ch.toStringAsFixed(1)}%';
              }(),
              apply: (pl) {
                pl.unlockedFlags.removeWhere(
                  (f) => f.startsWith('invest_focus_'),
                );
                pl.unlockedFlags.add('invest_focus_${a.id}');
                pl.unlockedFlags.add(
                  selling ? 'invest_sell_amount_pending' : 'invest_buy_amount_pending',
                );
              },
            ),
        EventChoice(label: '取消', apply: (_) {}),
      ],
    );
  }

  static String? focusedAssetId(Player p) {
    for (final f in p.unlockedFlags) {
      if (f.startsWith('invest_focus_')) {
        return f.substring('invest_focus_'.length);
      }
    }
    return null;
  }

  static StoryEvent buyAmountPicker(Player p) {
    final id = focusedAssetId(p) ?? '2800.HK';
    final a = byId(id);
    final name = a?.nameZh ?? id;
    return StoryEvent(
      id: 'invest_buy_amount',
      title: '買入 $name — 花幾多？',
      body: '現價 \$${priceOf(p, id).toStringAsFixed(2)}',
      choices: [
        for (final amt in buyAmounts)
          EventChoice(
            label: '投入 \$$amt',
            apply: (pl) => buy(pl, id, amt),
          ),
        EventChoice(
          label: '取消',
          apply: (pl) {
            pl.unlockedFlags.removeWhere((f) => f.startsWith('invest_focus_'));
          },
        ),
      ],
    );
  }

  static StoryEvent sellAmountPicker(Player p) {
    final id = focusedAssetId(p) ?? '2800.HK';
    final a = byId(id);
    final name = a?.nameZh ?? id;
    return StoryEvent(
      id: 'invest_sell_amount',
      title: '賣出 $name — 賣幾多？',
      body: '現價 \$${priceOf(p, id).toStringAsFixed(2)}',
      choices: [
        EventChoice(
          label: '賣一半',
          apply: (pl) => sell(pl, id, fraction: 0.5),
        ),
        EventChoice(
          label: '清倉',
          apply: (pl) => sell(pl, id, fraction: 1.0),
        ),
        EventChoice(
          label: '取消',
          apply: (pl) {
            pl.unlockedFlags.removeWhere((f) => f.startsWith('invest_focus_'));
          },
        ),
      ],
    );
  }
}
