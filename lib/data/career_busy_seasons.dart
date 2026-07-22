import '../models/enums.dart';

/// 行業工作旺季（對齊日曆季：Q1=1–3月、Q2=4–6、Q3=7–9、Q4=10–12）
class BusySeasonProfile {
  final Set<Quarter> peak;
  final String peakLabelZh;

  const BusySeasonProfile({
    required this.peak,
    required this.peakLabelZh,
  });

  bool isPeak(Quarter q) => peak.contains(q);
}

/// 各行業最忙季度 — 旺季 KPI 目標 +1
abstract final class CareerBusySeasons {
  static const kpiBonus = 1;

  static BusySeasonProfile profileFor(CareerSector sector) =>
      switch (sector) {
        // 四大／核數：1–4 月 audit busy season（香港常見 12 月年結）
        CareerSector.accounting => const BusySeasonProfile(
            peak: {Quarter.q1, Quarter.q2},
            peakLabelZh: '核數旺季 Q1–Q2（1–6 月）',
          ),
        // 教學：考試改簿（5–6 月）＋年終測考（11–12 月）
        CareerSector.teaching => const BusySeasonProfile(
            peak: {Quarter.q2, Quarter.q4},
            peakLabelZh: '考試季 Q2／Q4',
          ),
        // 醫護：冬季流感高峰（12–3 月）
        CareerSector.medical ||
        CareerSector.nursing =>
          const BusySeasonProfile(
            peak: {Quarter.q1, Quarter.q4},
            peakLabelZh: '冬季流感高峰 Q1／Q4',
          ),
        CareerSector.pharmacy => const BusySeasonProfile(
            peak: {Quarter.q1, Quarter.q4},
            peakLabelZh: '流感／冬病旺季 Q1／Q4',
          ),
        // 銀行：年底衝刺＋新一年開戶（10–3 月）
        CareerSector.banking => const BusySeasonProfile(
            peak: {Quarter.q4, Quarter.q1},
            peakLabelZh: '年結衝刺 Q4／Q1',
          ),
        CareerSector.insurance => const BusySeasonProfile(
            peak: {Quarter.q4, Quarter.q1},
            peakLabelZh: '年尾衝保單 Q4／Q1',
          ),
        // 地產：金三銀四＋暑假／秋遷旺季
        CareerSector.realEstate => const BusySeasonProfile(
            peak: {Quarter.q2, Quarter.q3, Quarter.q4},
            peakLabelZh: '成交旺季 Q2–Q4',
          ),
        // 餐飲：暑假＋聖誕新年
        CareerSector.catering => const BusySeasonProfile(
            peak: {Quarter.q3, Quarter.q4},
            peakLabelZh: '暑假／節日 Q3–Q4',
          ),
        CareerSector.labour => const BusySeasonProfile(
            peak: {Quarter.q4, Quarter.q1},
            peakLabelZh: '零售節日／新年 Q4／Q1',
          ),
        // 空服：暑假旅遊＋聖誕新年
        CareerSector.flightAttendant => const BusySeasonProfile(
            peak: {Quarter.q3, Quarter.q4, Quarter.q1},
            peakLabelZh: '旅遊高峰 Q3／Q4／Q1',
          ),
        // IT：年底交 project／新財年開案
        CareerSector.it => const BusySeasonProfile(
            peak: {Quarter.q4, Quarter.q1},
            peakLabelZh: '年結交付 Q4／Q1',
          ),
        CareerSector.media => const BusySeasonProfile(
            peak: {Quarter.q3, Quarter.q4},
            peakLabelZh: '活動／年尾製作 Q3–Q4',
          ),
        // 工程：年尾趕工＋農曆年前
        CareerSector.engineering => const BusySeasonProfile(
            peak: {Quarter.q4, Quarter.q1},
            peakLabelZh: '趕工旺季 Q4／Q1',
          ),
        CareerSector.socialWork => const BusySeasonProfile(
            peak: {Quarter.q1, Quarter.q2},
            peakLabelZh: '財政年度結算 Q1–Q2',
          ),
        CareerSector.legalSolicitor ||
        CareerSector.legalBarrister =>
          const BusySeasonProfile(
            peak: {Quarter.q1, Quarter.q4},
            peakLabelZh: '年結交易／年尾案件 Q1／Q4',
          ),
        // 公務員：預算案（4 月）＋年終報告
        CareerSector.civilService => const BusySeasonProfile(
            peak: {Quarter.q2, Quarter.q4},
            peakLabelZh: '預算／年結 Q2／Q4',
          ),
        CareerSector.disciplinary => const BusySeasonProfile(
            peak: {Quarter.q1, Quarter.q4},
            peakLabelZh: '節日保安 Q1／Q4',
          ),
        CareerSector.taxi => const BusySeasonProfile(
            peak: {Quarter.q1, Quarter.q3, Quarter.q4},
            peakLabelZh: '新年／暑假／節日 Q1／Q3／Q4',
          ),
        CareerSector.politics => const BusySeasonProfile(
            peak: {Quarter.q4},
            peakLabelZh: '選舉／年尾政務 Q4',
          ),
        CareerSector.entertainment => const BusySeasonProfile(
            peak: {Quarter.q4, Quarter.q1},
            peakLabelZh: '頒獎／新年商演 Q4／Q1',
          ),
        CareerSector.none || CareerSector.student => const BusySeasonProfile(
            peak: {},
            peakLabelZh: '—',
          ),
      };

  static bool isBusy(CareerSector sector, Quarter quarter) =>
      profileFor(sector).isPeak(quarter);

  static String? busyHint(CareerSector sector, Quarter quarter) {
    if (!isBusy(sector, quarter)) return null;
    return profileFor(sector).peakLabelZh;
  }
}
