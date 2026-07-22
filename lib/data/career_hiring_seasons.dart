import '../models/enums.dart';
import '../models/player.dart';

/// 淡季處理：全年可應徵／可應但減成功率／硬封鎖
enum HiringOffPeak { open, soft, hard }

/// 行業招聘季節（簡化對齊香港現實：校園秋招 Q3–Q4、春招 Q2、服務業較全年）
class HiringSeasonProfile {
  final Set<Quarter> peak;
  final HiringOffPeak offPeak;
  final HiringOffPeak prestigeOffPeak;
  final String peakLabelZh;

  const HiringSeasonProfile({
    required this.peak,
    this.offPeak = HiringOffPeak.open,
    this.prestigeOffPeak = HiringOffPeak.soft,
    required this.peakLabelZh,
  });

  bool isPeak(Quarter q) => peak.contains(q);
}

/// 全職招聘旺淡季
abstract final class CareerHiringSeasons {
  static const offPeakFlag = 'job_hunt_off_peak';

  static const _yearRound = HiringSeasonProfile(
    peak: {Quarter.q1, Quarter.q2, Quarter.q3, Quarter.q4},
    offPeak: HiringOffPeak.open,
    prestigeOffPeak: HiringOffPeak.open,
    peakLabelZh: '全年',
  );

  static HiringSeasonProfile profileFor(CareerSector sector) =>
      switch (sector) {
        // 金融／專業服務：主打秋季校園招聘（約 9–11 月）
        CareerSector.banking ||
        CareerSector.accounting ||
        CareerSector.legalSolicitor ||
        CareerSector.legalBarrister =>
          const HiringSeasonProfile(
            peak: {Quarter.q3, Quarter.q4},
            offPeak: HiringOffPeak.soft,
            prestigeOffPeak: HiringOffPeak.hard,
            peakLabelZh: '秋招 Q3–Q4',
          ),
        // 公務員入職／部門招：考完試後多在下半年；春夏亦有
        CareerSector.civilService => const HiringSeasonProfile(
            peak: {Quarter.q2, Quarter.q3, Quarter.q4},
            offPeak: HiringOffPeak.soft,
            prestigeOffPeak: HiringOffPeak.hard,
            peakLabelZh: 'Q2–Q4',
          ),
        // 教學：學年開始前（暑假至開學）最旺
        CareerSector.teaching => const HiringSeasonProfile(
            peak: {Quarter.q2, Quarter.q3},
            offPeak: HiringOffPeak.soft,
            prestigeOffPeak: HiringOffPeak.hard,
            peakLabelZh: '開學前 Q2–Q3',
          ),
        // HA／護理／藥劑：新畢業生批次多在年中前後
        CareerSector.medical ||
        CareerSector.nursing ||
        CareerSector.pharmacy =>
          const HiringSeasonProfile(
            peak: {Quarter.q2, Quarter.q3},
            offPeak: HiringOffPeak.soft,
            prestigeOffPeak: HiringOffPeak.hard,
            peakLabelZh: '年中批次 Q2–Q3',
          ),
        // 社福、工程：校園／機構招偏秋春
        CareerSector.socialWork || CareerSector.engineering =>
          const HiringSeasonProfile(
            peak: {Quarter.q2, Quarter.q3, Quarter.q4},
            offPeak: HiringOffPeak.soft,
            prestigeOffPeak: HiringOffPeak.soft,
            peakLabelZh: 'Q2–Q4',
          ),
        // 空服、紀律部隊：公開招募批次，唔係日日開
        CareerSector.flightAttendant => const HiringSeasonProfile(
            peak: {Quarter.q1, Quarter.q3},
            offPeak: HiringOffPeak.hard,
            prestigeOffPeak: HiringOffPeak.hard,
            peakLabelZh: '公開招募 Q1／Q3',
          ),
        CareerSector.disciplinary => const HiringSeasonProfile(
            peak: {Quarter.q1, Quarter.q3},
            offPeak: HiringOffPeak.hard,
            prestigeOffPeak: HiringOffPeak.hard,
            peakLabelZh: '招募期 Q1／Q3',
          ),
        // 娛樂訓練班：秋季（同 TVB 試鏡）
        CareerSector.entertainment => const HiringSeasonProfile(
            peak: {Quarter.q3},
            offPeak: HiringOffPeak.hard,
            prestigeOffPeak: HiringOffPeak.hard,
            peakLabelZh: '秋季 Q3',
          ),
        // IT／初創較全年；名企 grad 仍偏秋
        CareerSector.it => const HiringSeasonProfile(
            peak: {Quarter.q1, Quarter.q2, Quarter.q3, Quarter.q4},
            offPeak: HiringOffPeak.open,
            prestigeOffPeak: HiringOffPeak.soft,
            peakLabelZh: '全年（名企偏秋）',
          ),
        // 藍領、保險、地產、傳媒、餐飲、的士、政治：較全年
        CareerSector.labour ||
        CareerSector.insurance ||
        CareerSector.realEstate ||
        CareerSector.media ||
        CareerSector.catering ||
        CareerSector.taxi ||
        CareerSector.politics ||
        CareerSector.none ||
        CareerSector.student =>
          _yearRound,
      };

  static String peakHint(CareerSector sector) =>
      profileFor(sector).peakLabelZh;

  /// null＝可以應徵；非 null＝硬封鎖理由
  static String? blockReason(
    Player p,
    CareerSector sector, {
    bool prestige = false,
    bool bypassSeason = false,
  }) {
    if (bypassSeason) return null;
    final profile = profileFor(sector);
    if (profile.isPeak(p.quarter)) return null;
    // IT 名企淡季：秋招外用 soft，唔硬封
    final mode = prestige ? profile.prestigeOffPeak : profile.offPeak;
    if (mode == HiringOffPeak.hard) {
      return '而家唔係${sector.label}招聘旺季（旺季：${profile.peakLabelZh}）';
    }
    return null;
  }

  /// 淡季軟懲罰：仍可應，面試扣分
  static bool isOffPeakSoft(
    Player p,
    CareerSector sector, {
    bool prestige = false,
    bool bypassSeason = false,
  }) {
    if (bypassSeason) return false;
    final profile = profileFor(sector);
    if (profile.isPeak(p.quarter)) return false;
    final mode = prestige ? profile.prestigeOffPeak : profile.offPeak;
    // IT 名企：非全年概念上 peak 係全部 Q，但 prestigeOffPeak=soft
    // 對 IT：peak 含四季 → isPeak 永遠 true → 唔會 soft。要特別處理名企秋招。
    if (sector == CareerSector.it && prestige) {
      return p.quarter != Quarter.q3 && p.quarter != Quarter.q4;
    }
    return mode == HiringOffPeak.soft;
  }

  static int interviewModifier(Player p) {
    if (!p.unlockedFlags.contains(offPeakFlag)) return 0;
    return -14;
  }

  static int peakModifier(Player p, CareerSector? sector) {
    if (sector == null) return 0;
    if (sector == CareerSector.it) {
      // 本地 IT 全年；名企 grad 旺季先微加成
      if (p.jobHuntPrestige &&
          (p.quarter == Quarter.q3 || p.quarter == Quarter.q4)) {
        return 4;
      }
      return 0;
    }
    final profile = profileFor(sector);
    if (!profile.isPeak(p.quarter)) return 0;
    if (profile.offPeak == HiringOffPeak.open &&
        profile.prestigeOffPeak == HiringOffPeak.open) {
      return 0;
    }
    return 4;
  }
}
