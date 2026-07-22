import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_employment.dart';
import 'family_assets.dart';

enum ListingKind { private, hos, public, luxury }

class HousingListing {
  final String id;
  final String nameZh;
  final String districtZh;
  final ListingKind kind;
  final int basePrice;
  final int monthlyRent;
  final double districtMult;

  const HousingListing({
    required this.id,
    required this.nameZh,
    required this.districtZh,
    required this.kind,
    required this.basePrice,
    this.monthlyRent = 0,
    this.districtMult = 1.0,
  });
}

/// 住屋階梯：租／公屋／居屋／私樓／加按（貼近 2024 後 AVD／LTV／DSR）
abstract final class HousingMarket {
  static const minAge = 18;
  static const dsrLimit = 0.50;
  static const bankLtv = 0.70;
  static const mipLtv = 0.90;
  static const mipPriceCap = 10000000;
  static const defaultRate = 0.035;
  static const defaultTenureYears = 30;
  static const managementQuarterly = 4500;

  static const listings = <HousingListing>[
    HousingListing(
      id: 'tm_old',
      nameZh: '屯門舊樓兩房',
      districtZh: '屯門',
      kind: ListingKind.private,
      basePrice: 3800000,
      monthlyRent: 11000,
      districtMult: 0.92,
    ),
    HousingListing(
      id: 'tw_old',
      nameZh: '荃灣舊樓一房',
      districtZh: '荃灣',
      kind: ListingKind.private,
      basePrice: 4200000,
      monthlyRent: 12000,
      districtMult: 0.95,
    ),
    HousingListing(
      id: 'tko_mid',
      nameZh: '將軍澳屋苑兩房',
      districtZh: '將軍澳',
      kind: ListingKind.private,
      basePrice: 7200000,
      monthlyRent: 18000,
      districtMult: 1.05,
    ),
    HousingListing(
      id: 'st_mid',
      nameZh: '沙田中價兩房',
      districtZh: '沙田',
      kind: ListingKind.private,
      basePrice: 7800000,
      monthlyRent: 19000,
      districtMult: 1.08,
    ),
    HousingListing(
      id: 'taikoo_hi',
      nameZh: '太古城兩房',
      districtZh: '太古',
      kind: ListingKind.private,
      basePrice: 14000000,
      monthlyRent: 32000,
      districtMult: 1.25,
    ),
    HousingListing(
      id: 'kowloon_station',
      nameZh: '九龍站中層',
      districtZh: '九龍站',
      kind: ListingKind.private,
      basePrice: 22000000,
      monthlyRent: 45000,
      districtMult: 1.35,
    ),
    HousingListing(
      id: 'hos_tm',
      nameZh: '屯門居屋（二手）',
      districtZh: '屯門',
      kind: ListingKind.hos,
      basePrice: 3600000,
      districtMult: 0.88,
    ),
    HousingListing(
      id: 'hos_tko',
      nameZh: '將軍澳居屋（二手）',
      districtZh: '將軍澳',
      kind: ListingKind.hos,
      basePrice: 4800000,
      districtMult: 0.95,
    ),
    HousingListing(
      id: 'prh_generic',
      nameZh: '公屋編配單位',
      districtZh: '新界',
      kind: ListingKind.public,
      basePrice: 0,
      monthlyRent: 2500,
      districtMult: 1.0,
    ),
    HousingListing(
      id: 'luxury_peak',
      nameZh: '山頂／淺水灣單位',
      districtZh: '山頂',
      kind: ListingKind.luxury,
      basePrice: 50000000,
      districtMult: 1.5,
    ),
  ];

  static HousingListing? byId(String id) {
    for (final l in listings) {
      if (l.id == id) return l;
    }
    return null;
  }

  static bool canTransact(Player p) => p.age >= minAge;

  static int marketPrice(Player p, HousingListing l) {
    if (l.kind == ListingKind.public) return 0;
    final idx = p.hkPropertyIndex <= 0 ? 1.0 : p.hkPropertyIndex;
    return (l.basePrice * idx * l.districtMult).round();
  }

  /// 簡化 Scale 2 AVD（2024 後住宅）
  static int stampDutyAvd(int price) {
    if (price <= 3000000) return 100;
    if (price <= 4500000) {
      return max(100, (price * 0.015).round());
    }
    if (price <= 6000000) return (price * 0.0225).round();
    if (price <= 9000000) return (price * 0.03).round();
    if (price <= 20000000) return (price * 0.0375).round();
    return (price * 0.0425).round();
  }

  static bool isFirstTimeBuyer(Player p) =>
      !p.everOwnedResidential && !p.ownsFlat;

  static double maxLtv(Player p, int price, {bool useMip = true}) {
    if (!useMip || !isFirstTimeBuyer(p)) return bankLtv;
    if (price <= mipPriceCap) return mipLtv;
    if (price <= 15000000) return 0.80;
    return bankLtv;
  }

  static int monthlyPayment(int principal, double annualRate, int years) {
    if (principal <= 0 || years <= 0) return 0;
    final r = annualRate / 12;
    final n = years * 12;
    if (r <= 0) return (principal / n).ceil();
    final factor = pow(1 + r, n);
    return (principal * r * factor / (factor - 1)).ceil();
  }

  static int quarterlyMortgage(Player p) {
    if (p.mortgagePrincipal <= 0) return 0;
    final years = max(1, (p.mortgageQuartersLeft / 4).ceil());
    return monthlyPayment(
          p.mortgagePrincipal,
          p.mortgageRateAnnual,
          years,
        ) *
        3;
  }

  static int estimatedQuarterlyIncome(Player p) {
    if (p.isEmployed) {
      return CareerEmployment.effectiveMonthlySalary(p) * 3;
    }
    if (p.hasPartTime) return 18000 * 3;
    if (p.livesWithFamily && p.age < 25) {
      return max(p.baseAllowance, 0);
    }
    return max(p.wealth ~/ 40, 0);
  }

  static bool passesDsr(Player p, int monthlyMort, {double stressBump = 0}) {
    final stressed = monthlyMort;
    // stress: rate+2% → monthly ≈ * (1 + bump factor)
    final adj = stressBump > 0
        ? (stressed * (1 + stressBump * 0.35)).round()
        : stressed;
    final qIncome = estimatedQuarterlyIncome(p);
    if (qIncome <= 0) return adj * 3 <= 0;
    return (adj * 3) / qIncome <= dsrLimit;
  }

  static String housingStatusLabel(Player p) {
    if (p.ownsFlat) {
      final kind = p.housingType == HousingType.hos
          ? '居屋'
          : p.housingType == HousingType.luxury
              ? '豪宅'
              : '私樓';
      final debt = p.mortgagePrincipal > 0
          ? ' · 欠按 \$${p.mortgagePrincipal}'
          : ' · 已供滿／無按';
      return '$kind ${p.estateNameZh.isNotEmpty ? p.estateNameZh : ""}'
          ' · 估值 \$${p.flatValue}$debt';
    }
    if (p.housingType == HousingType.publicHousing) {
      return '公屋${p.estateNameZh.isNotEmpty ? " · ${p.estateNameZh}" : ""}'
          ' · 月租 \$${p.monthlyRent}';
    }
    if (p.renting) {
      return '私樓租住 · 月租 \$${p.monthlyRent}';
    }
    if (p.livesWithFamily) return '住屋企';
    return p.housingType.label;
  }

  // ── Actions ────────────────────────────────────────────

  static String startPublicHousingWait(Player p) {
    if (!canTransact(p)) return '未滿 $minAge 歲唔可以申請公屋。';
    if (p.ownsFlat) return '你已經有自住物業。';
    if (p.housingType == HousingType.publicHousing) return '你已經住緊公屋。';
    if (p.unlockedFlags.contains('prh_waiting')) {
      return '你已經喺公屋輪候（等咗 ${p.publicHousingWaitQuarters} 季）。';
    }
    // 資產上限簡化
    if (p.wealth > 400000 && p.birthTier != BirthTier.r) {
      return '資產偏高，公屋申請機會好低（遊戲簡化拒辦）。';
    }
    p.unlockedFlags.add('prh_waiting');
    p.publicHousingWaitQuarters = 0;
    p.eventLog.add('${p.year}年：遞交咗公屋申請，開始輪候。');
    return '已申請公屋，進入輪候。';
  }

  static String? tickPublicHousingWait(Player p) {
    if (!p.unlockedFlags.contains('prh_waiting')) return null;
    if (p.housingType == HousingType.publicHousing) return null;
    p.publicHousingWaitQuarters++;
    final need = p.birthTier == BirthTier.r ? 6 : 10;
    final rng = Random(p.year * 41 + p.publicHousingWaitQuarters);
    final force = p.publicHousingWaitQuarters >= need;
    final lucky = p.publicHousingWaitQuarters >= 4 && rng.nextDouble() < 0.18;
    if (!force && !lucky) return null;
    return allocatePublicHousing(p);
  }

  static String allocatePublicHousing(Player p) {
    final l = byId('prh_generic')!;
    p.unlockedFlags.remove('prh_waiting');
    p.housingType = HousingType.publicHousing;
    p.renting = true;
    p.ownsFlat = false;
    p.livesWithFamily = false;
    p.monthlyRent = l.monthlyRent;
    p.estateNameZh = l.nameZh;
    p.housingListingId = l.id;
    p.flatValue = 0;
    p.mortgagePrincipal = 0;
    p.eventLog.add('${p.year}年：編配公屋 — ${l.nameZh}。');
    return '公屋編配成功：${l.nameZh}（月租約 \$${l.monthlyRent}）';
  }

  static String ballotHos(Player p) {
    if (!canTransact(p)) return '未滿 $minAge 歲唔可以申請居屋。';
    if (p.ownsFlat) return '你已經有自住物業。';
    final rng = Random(p.year * 77 + p.hosBallotFails * 13 + p.age);
    var chance = p.birthTier == BirthTier.r ? 0.28 : 0.14;
    chance += p.hosBallotFails * 0.04;
    chance = chance.clamp(0.08, 0.55);
    if (rng.nextDouble() >= chance) {
      p.hosBallotFails++;
      p.eventLog.add('${p.year}年：居屋抽籤失敗（第 ${p.hosBallotFails} 次）。');
      return '居屋抽籤失敗。累計失敗 ${p.hosBallotFails} 次，下次機會略升。';
    }
    p.unlockedFlags.add('hos_offer_pending');
    p.eventLog.add('${p.year}年：居屋抽中！可以揀單位。');
    return '居屋抽中！去「確認買居屋」揀單位上車。';
  }

  static String rentPrivate(Player p, String listingId) {
    if (!canTransact(p)) return '未滿 $minAge 歲唔可以簽租約。';
    if (p.ownsFlat) return '你住緊自置物業。';
    final l = byId(listingId);
    if (l == null || l.monthlyRent <= 0) return '呢個盤唔出租。';
    if (l.kind == ListingKind.public || l.kind == ListingKind.hos) {
      return '呢個唔係私樓出租盤。';
    }
    p.renting = true;
    p.livesWithFamily = false;
    if (p.housingType == HousingType.publicHousing) {
      p.unlockedFlags.remove('prh_waiting');
    }
    p.housingType = HousingType.privateRental;
    p.monthlyRent = l.monthlyRent;
    p.estateNameZh = l.nameZh;
    p.housingListingId = listingId;
    p.eventLog.add(
      '${p.year}年：租住 ${l.nameZh}（月租 \$${l.monthlyRent}）。',
    );
    return '已租 ${l.nameZh} · 月租 \$${l.monthlyRent}';
  }

  static String purchase(
    Player p,
    String listingId, {
    bool useMip = true,
    bool familyHelp = false,
    bool skipDsr = false,
  }) {
    if (!canTransact(p)) return '未滿 $minAge 歲唔可以買樓。';
    final l = byId(listingId);
    if (l == null) return '搵唔到樓盤。';
    if (l.kind == ListingKind.public) return '公屋唔可以咁買。';
    if (p.ownsFlat) return '你已經有自住物業（MVP 只支援一層）。';

    final price = marketPrice(p, l);
    final ltv = maxLtv(p, price, useMip: useMip);
    final loan = (price * ltv).round();
    final down = price - loan;
    final stamp = stampDutyAvd(price);
    final legal = (price * 0.01).round().clamp(20000, 200000);
    var cashNeed = down + stamp + legal;

    if (familyHelp && p.birthTier != BirthTier.r) {
      final help = min(cashNeed ~/ 3, 200000);
      if (FamilyAssets.requestFromFamily(p, help, reason: '首期／置業資助')) {
        cashNeed = (cashNeed - help).clamp(0, cashNeed);
      }
    }

    // SSR 家族背書：豪宅首期由家族出，本金可免／極低
    var ssrLuxury = false;
    if (p.unlockedFlags.contains('family_property_backing') &&
        l.kind == ListingKind.luxury) {
      FamilyAssets.familyPays(p, down, reason: '家族代付首期');
      cashNeed = stamp + legal;
      ssrLuxury = true;
      skipDsr = true;
    }

    final monthly = monthlyPayment(
      ssrLuxury ? 0 : loan,
      defaultRate,
      defaultTenureYears,
    );
    if (!skipDsr &&
        loan > 0 &&
        !passesDsr(p, monthly, stressBump: 0.02)) {
      return '銀行拒批：供款壓力測試／DSR 超標'
          '（月供約 \$$monthly，收入不足）。'
          '試細啲單位、加首期、或等人工升。';
    }
    if (p.wealth < cashNeed) {
      return '現金唔夠成交（約要 \$$cashNeed：首期＋印花＋雜費）。';
    }

    p.wealth -= cashNeed;
    p.ownsFlat = true;
    p.renting = false;
    p.livesWithFamily = false;
    p.flatValue = price;
    p.estateNameZh = l.nameZh;
    p.housingListingId = l.id;
    p.monthlyRent = 0;
    p.everOwnedResidential = true;
    if (ssrLuxury) {
      p.mortgagePrincipal = 0;
      p.mortgageQuartersLeft = 0;
    } else {
      p.mortgagePrincipal = loan;
      p.mortgageRateAnnual = defaultRate;
      p.mortgageQuartersLeft = defaultTenureYears * 4;
    }
    p.mortgageMissedQuarters = 0;
    p.hosPremiumPaid = l.kind != ListingKind.hos;
    p.housingType = switch (l.kind) {
      ListingKind.hos => HousingType.hos,
      ListingKind.luxury => HousingType.luxury,
      _ => HousingType.ownedPrivate,
    };
    p.unlockedFlags.remove('hos_offer_pending');
    p.unlockedFlags.remove('prh_waiting');

    final msg =
        '成交 ${l.nameZh}：\$$price\n'
        '首期+稅費約 \$$cashNeed · '
        '${ssrLuxury ? "家族免按揭" : "按揭 \$$loan（${(ltv * 100).round()}%）"}\n'
        '${ssrLuxury ? "" : "月供約 \$$monthly · "}'
        '${p.housingType == HousingType.hos ? "居屋（未補地價）" : "私樓／豪宅"}';
    p.eventLog.add('${p.year}年：$msg');
    return msg;
  }

  static String sell(Player p) {
    if (!canTransact(p)) return '未滿 $minAge 歲唔可以賣樓。';
    if (!p.ownsFlat) return '你冇自住物業可賣。';
    var proceeds = p.flatValue;
    if (p.housingType == HousingType.hos && !p.hosPremiumPaid) {
      final premium = (proceeds * 0.35).round();
      proceeds -= premium;
    }
    final fee = (p.flatValue * 0.01).round();
    proceeds -= fee;
    final debt = p.mortgagePrincipal;
    proceeds -= debt;
    if (proceeds < 0) {
      p.wealth += proceeds; // 負資產要貼錢
      p.stress = (p.stress + 20).clamp(0, 100);
    } else {
      p.wealth += proceeds;
    }
    final name = p.estateNameZh;
    p.ownsFlat = false;
    p.flatValue = 0;
    p.mortgagePrincipal = 0;
    p.mortgageQuartersLeft = 0;
    p.mortgageMissedQuarters = 0;
    p.estateNameZh = '';
    p.housingListingId = '';
    p.housingType = HousingType.privateRental;
    p.renting = true;
    p.monthlyRent = 15000;
    p.eventLog.add(
      '${p.year}年：賣出 $name，到手約 \$${max(0, proceeds)}'
      '${debt > 0 ? "（已還清按揭 \$$debt）" : ""}。',
    );
    return '已賣 $name。淨額約 \$${max(0, proceeds)}';
  }

  static String refinance(Player p) {
    if (!canTransact(p)) return '未滿 $minAge 歲唔可以加按。';
    if (!p.ownsFlat) return '你冇物業可加按。';
    final maxLoan = (p.flatValue * bankLtv).round();
    final room = maxLoan - p.mortgagePrincipal;
    if (room < 100000) return '按揭空間唔夠（估值／成數不足）。';
    final cash = (room * 0.7).round();
    p.mortgagePrincipal += cash;
    p.wealth += cash;
    p.stress = (p.stress + 8).clamp(0, 100);
    p.mortgageRateAnnual =
        (p.mortgageRateAnnual + 0.002).clamp(0.03, 0.06);
    p.eventLog.add('${p.year}年：加按套現 \$$cash。');
    return '加按套現 \$$cash（壓力↑、利率略升）';
  }

  /// 季結住房支出；回傳提示
  static String? tickQuarter(Player p) {
    final msgs = <String>[];
    final waitMsg = tickPublicHousingWait(p);
    if (waitMsg != null) msgs.add(waitMsg);

    // 更新估值
    if (p.ownsFlat && p.housingListingId.isNotEmpty) {
      final l = byId(p.housingListingId);
      if (l != null) {
        p.flatValue = marketPrice(p, l);
        if (p.mortgagePrincipal > p.flatValue) {
          msgs.add(
            '負資產風險：估值 \$${p.flatValue} < 欠款 \$${p.mortgagePrincipal}',
          );
        }
      }
    }

    if (p.lifeStage != LifeStage.adult && p.age < minAge) {
      return msgs.isEmpty ? null : msgs.join('\n');
    }

    if (p.ownsFlat) {
      final pay = quarterlyMortgage(p);
      final cost = pay + managementQuarterly;
      if (p.wealth >= cost) {
        p.wealth -= cost;
        if (pay > 0 && p.mortgagePrincipal > 0) {
          final interest =
              (p.mortgagePrincipal * p.mortgageRateAnnual / 4).round();
          final principalPay = (pay - interest).clamp(0, p.mortgagePrincipal);
          p.mortgagePrincipal =
              (p.mortgagePrincipal - principalPay).clamp(0, 1 << 62);
          p.mortgageQuartersLeft =
              (p.mortgageQuartersLeft - 1).clamp(0, 200);
          if (p.mortgagePrincipal == 0) {
            p.mortgageQuartersLeft = 0;
            msgs.add('按揭供滿！');
          }
        }
        p.mortgageMissedQuarters = 0;
      } else {
        p.mortgageMissedQuarters++;
        p.stress = (p.stress + 12).clamp(0, 100);
        p.san = (p.san - 5).clamp(0, p.maxSan);
        msgs.add('斷供警告：現金唔夠交今季供款／管理費。');
        if (p.mortgageMissedQuarters >= 2) {
          msgs.add(sell(p));
          msgs.add('銀行强制收回／逼賣物業。');
        }
      }
    } else if (p.renting && !p.livesWithFamily) {
      final qRent = p.monthlyRent * 3;
      if (qRent > 0) {
        if (p.wealth >= qRent) {
          p.wealth -= qRent;
        } else {
          p.wealth = 0;
          p.stress = (p.stress + 10).clamp(0, 100);
          msgs.add('交唔起租：壓力↑');
        }
      }
    }

    // 公屋藏富抽查
    if (p.housingType == HousingType.publicHousing &&
        p.wealth > 600000 &&
        Random(p.year + p.wealth).nextDouble() < 0.12) {
      p.stress = (p.stress + 8).clamp(0, 100);
      msgs.add('房署抽查資產：公屋住戶現金偏高，你好緊張。');
    }

    return msgs.isEmpty ? null : msgs.join('\n\n');
  }

  static List<HousingListing> privateRentals() => listings
      .where((l) =>
          l.kind == ListingKind.private && l.monthlyRent > 0)
      .toList();

  static List<HousingListing> forSale({bool hosOnly = false}) => listings
      .where((l) => hosOnly
          ? l.kind == ListingKind.hos
          : l.kind == ListingKind.private ||
              l.kind == ListingKind.hos ||
              l.kind == ListingKind.luxury)
      .toList();

  static StoryEvent rentPicker(Player p) {
    final list = privateRentals();
    return StoryEvent(
      id: 'housing_rent_pick',
      title: '租邊個盤？',
      body: '私人租樓（滿 $minAge 歲）。每季扣月租×3。',
      choices: [
        for (final l in list)
          EventChoice(
            label: '${l.nameZh} · 月租 \$${l.monthlyRent}',
            apply: (pl) => rentPrivate(pl, l.id),
          ),
        EventChoice(label: '取消', apply: (_) {}),
      ],
    );
  }

  static StoryEvent buyPicker(Player p, {bool hosOnly = false}) {
    final list = forSale(hosOnly: hosOnly);
    return StoryEvent(
      id: hosOnly ? 'housing_hos_buy_pick' : 'housing_buy_pick',
      title: hosOnly ? '揀居屋單位' : '睇樓／揀盤',
      body: '顯示現價、估首期（按揭成數視乎首置／MIP）。成交要過 DSR。',
      choices: [
        for (final l in list)
          EventChoice(
            label: () {
              final price = marketPrice(p, l);
              final ltv = maxLtv(p, price);
              final down = price - (price * ltv).round();
              final stamp = stampDutyAvd(price);
              return '${l.nameZh} · \$$price\n'
                  '估首期+稅 ~\$${down + stamp}（${(ltv * 100).round()}%）';
            }(),
            apply: (pl) => purchase(
              pl,
              l.id,
              familyHelp: pl.birthTier == BirthTier.sr,
            ),
          ),
        EventChoice(label: '取消', apply: (_) {}),
      ],
    );
  }
}
