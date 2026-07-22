import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_data.dart';
import 'career_gov.dart';
import 'career_hiring_seasons.dart';
import 'career_tax.dart';
import 'luck_modifiers.dart';
import 'part_time_jobs.dart';

/// 全職搵工：應徵 → 面試 → Offer（接受／拒絕）
abstract final class CareerJobHunt {
  static const _pendingFlag = 'job_interview_pending';
  static const _offerFlag = 'job_offer_pending';

  static bool hasPendingInterview(Player p) =>
      p.unlockedFlags.contains(_pendingFlag) && p.jobHuntSector.isNotEmpty;

  static bool hasPendingOffer(Player p) =>
      p.unlockedFlags.contains(_offerFlag) && p.jobHuntSector.isNotEmpty;

  static CareerSector? pendingSector(Player p) {
    if (p.jobHuntSector.isEmpty) return null;
    try {
      return CareerSector.values.byName(p.jobHuntSector);
    } catch (_) {
      return null;
    }
  }

  static void clearHunt(Player p) {
    p.unlockedFlags.remove(_pendingFlag);
    p.unlockedFlags.remove(_offerFlag);
    p.unlockedFlags.remove(CareerHiringSeasons.offPeakFlag);
    p.jobHuntSector = '';
    p.jobHuntEmployer = '';
    p.jobHuntPrestige = false;
  }

  /// 開始應徵（之後由 game_state flush 出面試卡）
  /// [bypassSeason]：實習／兼職轉正等內部路線，唔受招聘月限制
  static String apply(
    Player p,
    CareerSector sector, {
    String employer = '',
    bool prestige = false,
    bool bypassSeason = false,
  }) {
    if (p.isStudying) return '讀緊書唔可以應徵全職';
    if (p.isEmployed) return '你已經有全職，想轉工先辭咗而家份';
    final block = CareerData.entryBlockReason(p, sector);
    if (block != null) return '應徵唔到：$block';
    final seasonBlock = CareerHiringSeasons.blockReason(
      p,
      sector,
      prestige: prestige,
      bypassSeason: bypassSeason,
    );
    if (seasonBlock != null) return '應徵唔到：$seasonBlock';

    p.jobHuntSector = sector.name;
    p.jobHuntEmployer = employer;
    p.jobHuntPrestige = prestige;
    p.unlockedFlags.add(_pendingFlag);
    p.unlockedFlags.remove(_offerFlag);
    p.unlockedFlags.remove(CareerHiringSeasons.offPeakFlag);
    final offPeak = CareerHiringSeasons.isOffPeakSoft(
      p,
      sector,
      prestige: prestige,
      bypassSeason: bypassSeason,
    );
    if (offPeak) {
      p.unlockedFlags.add(CareerHiringSeasons.offPeakFlag);
    }

    final track = CareerData.trackFor(sector);
    final label = employer.isNotEmpty
        ? '$employer · ${track?.name ?? sector.label}'
        : (track?.name ?? sector.label);
    final seasonNote = offPeak
        ? '（淡季·機會較低；旺季 ${CareerHiringSeasons.peakHint(sector)}）'
        : '';
    p.eventLog.add(
      '${p.year}年：遞咗${prestige ? "名企" : ""}履歷 — $label$seasonNote',
    );
    return '已遞履歷：$label'
        '${offPeak ? "\n淡季應徵，面試機會較低。" : ""}'
        '\n等面試通知。';
  }

  static int interviewChance(Player p, {required int prepBonus}) {
    final prestige = p.jobHuntPrestige;
    // 底低啲、上限緊啲：有實習／轉正先睇得出差距，唔好人人 90%
    var chance = prestige ? 14 : 28;
    chance += p.smarts ~/ 6;
    chance += p.luck ~/ 10;
    chance += p.reputation ~/ 15;
    chance += prepBonus;
    if (p.uniGpa >= 3.3) chance += 5;
    if (p.uniGpa >= 3.7) chance += 3;
    if (p.unlockedFlags.contains('bachelor_graduated')) chance += 3;
    if (p.unlockedFlags.contains('pt_convert_boost')) chance += 8;
    // 從政：共用名望愈高愈易過面試
    if (pendingSector(p) == CareerSector.politics) {
      if (p.reputation >= 70) {
        chance += 14;
      } else if (p.reputation >= 55) {
        chance += 9;
      } else if (p.reputation >= 40) {
        chance += 5;
      } else if (p.reputation < 30) {
        chance -= 8;
      }
    }
    // 相關行業合格實習
    if (p.jobHuntSector.isNotEmpty) {
      final sec = p.jobHuntSector;
      if (p.unlockedFlags.contains('intern_pass_$sec')) chance += 10;
    }
    chance += CareerHiringSeasons.interviewModifier(p);
    chance += CareerHiringSeasons.peakModifier(p, pendingSector(p));
    if (p.hasCriminalRecord) chance -= 25;
    return chance.clamp(prestige ? 8 : 12, prestige ? 58 : 75);
  }

  static StoryEvent interviewEvent(Player p) {
    final sector = pendingSector(p);
    if (sector == null) {
      clearHunt(p);
      return StoryEvent(
        id: 'job_interview_empty',
        title: '面試',
        body: '搵唔到應徵紀錄。',
        choices: [EventChoice(label: '算啦', apply: (_) {})],
      );
    }
    final track = CareerData.trackFor(sector);
    final emp = p.jobHuntEmployer.isNotEmpty
        ? p.jobHuntEmployer
        : (track?.ranks.first.employer ?? '');
    final title = emp.isNotEmpty ? '$emp 面試' : '${track?.name ?? sector.label} 面試';
    final body = p.jobHuntPrestige
        ? '名企面試：HR 同 hiring manager 輪流問。答得差好易飛。'
        : '面試官問你點解入行、有咩經驗、壓力點處理。';

    void resolve(Player pl, {required int prepBonus, required String style}) {
      final chance = interviewChance(pl, prepBonus: prepBonus);
      final ok = LuckModifiers.roll(pl, chance / 100.0, Random());
      pl.stress = (pl.stress + (prepBonus >= 12 ? 6 : 4)).clamp(0, 100);
      pl.unlockedFlags.remove(_pendingFlag);
      if (!ok) {
        pl.san = (pl.san - 3).clamp(0, pl.maxSan);
        pl.unlockedFlags.remove('pt_convert_boost');
        pl.eventLog.add(
          '${pl.year}年：$title 唔過（約 $chance% · $style）',
        );
        clearHunt(pl);
        return;
      }
      pl.unlockedFlags.add(_offerFlag);
      pl.network = (pl.network + 2).clamp(0, 100);
      pl.eventLog.add(
        '${pl.year}年：$title 過關（約 $chance% · $style），等 Offer',
      );
    }

    return StoryEvent(
      id: 'job_interview',
      title: title,
      body: '$body\n應徵：${track?.name ?? sector.label}'
          '${emp.isNotEmpty ? " · $emp" : ""}'
          '${p.jobHuntPrestige ? "（名企）" : ""}',
      choices: [
        EventChoice(
          label: '認真準備答題',
          apply: (pl) => resolve(pl, prepBonus: 12, style: '認真'),
        ),
        EventChoice(
          label: '普通應付',
          apply: (pl) => resolve(pl, prepBonus: 4, style: '普通'),
        ),
        EventChoice(
          label: '靠口才吹水',
          apply: (pl) => resolve(pl, prepBonus: pl.luck >= 60 ? 8 : 0, style: '吹水'),
        ),
          EventChoice(
            label: '臨時棄權唔面',
            apply: (pl) {
              pl.unlockedFlags.remove('pt_convert_boost');
              pl.eventLog.add('${pl.year}年：棄權 $title');
              clearHunt(pl);
            },
          ),
      ],
    );
  }

  static StoryEvent offerEvent(Player p) {
    final sector = pendingSector(p);
    if (sector == null) {
      clearHunt(p);
      return StoryEvent(
        id: 'job_offer_empty',
        title: 'Offer',
        body: 'Offer 過期咗。',
        choices: [EventChoice(label: '得啦', apply: (_) {})],
      );
    }
    final track = CareerData.trackFor(sector)!;
    // 預估起跳 rank／薪金（同 enterCareer 完全一致）
    var previewRank = 0;
    var previewSalary = track.rankFor(0).salary;
    var previewTitle = track.ranks.first.title;
    final govPost = CareerGov.fromEmployer(p.jobHuntEmployer);
    if (govPost != null) {
      previewRank = 0;
      previewSalary = govPost.salaryFor(0);
      previewTitle = '${govPost.deptZh} · ${govPost.titleFor(0)}';
    } else {
      previewRank = CareerData.previewStartRank(p, sector);
      final rank = track.rankFor(previewRank);
      previewSalary = rank.salary;
      previewTitle = CareerData.previewHireTitle(p, sector);
    }
    final emp = p.jobHuntEmployer.isNotEmpty
        ? p.jobHuntEmployer.split('#').first
        : '';
    final display = emp.isNotEmpty
        ? (govPost != null ? previewTitle : '$emp · $previewTitle')
        : previewTitle;
    final bonusNote = p.jobHuntPrestige ? '\n名企起薪／面子會好啲。' : '';
    final govNote = govPost != null
        ? '\n公職：約三年試用；過關後評核攞 A，累積 3 個 A 先有資格升。'
        : '';

    return StoryEvent(
      id: 'job_offer',
      title: '收到 Offer',
      body: '公司出 Offer：\n$display\n月薪約 \$$previewSalary$bonusNote$govNote\n接唔接？',
      choices: [
        EventChoice(
          label: '接受 Offer',
          apply: (pl) {
            final prestige = pl.jobHuntPrestige;
            final employer = pl.jobHuntEmployer;
            final converting = pl.unlockedFlags.contains('pt_convert_boost');
            clearHunt(pl);
            CareerData.enterCareer(
              pl,
              sector,
              employerOverride: employer.isEmpty ? null : employer,
            );
            if (prestige) {
              pl.reputation = (pl.reputation + 6).clamp(0, 100);
              pl.jobPerformance = (pl.jobPerformance + 8).clamp(0, 100);
            }
            if (converting) {
              pl.unlockedFlags.remove('pt_convert_boost');
              PartTimeJobs.quit(pl);
              pl.jobPerformance = (pl.jobPerformance + 5).clamp(0, 100);
              pl.eventLog.add('${pl.year}年：兼職轉正成功，辭咗兼職');
            }
            pl.eventLog.add('${pl.year}年：接受 Offer — ${pl.jobTitle}');
          },
        ),
        EventChoice(
          label: '試吓傾高少少',
          apply: (pl) {
            final prestige = pl.jobHuntPrestige;
            final employer = pl.jobHuntEmployer;
            final converting = pl.unlockedFlags.contains('pt_convert_boost');
            final ok = LuckModifiers.roll(pl, 0.35, Random());
            clearHunt(pl);
            CareerData.enterCareer(
              pl,
              sector,
              employerOverride: employer.isEmpty ? null : employer,
            );
            if (converting) {
              pl.unlockedFlags.remove('pt_convert_boost');
              PartTimeJobs.quit(pl);
            }
            if (ok) {
              final bump = prestige ? 4000 : 2000;
              CareerTax.grantTaxablePay(pl, bump);
              pl.reputation = (pl.reputation + 2).clamp(0, 100);
              pl.eventLog.add(
                '${pl.year}年：傾到簽約獎金 \$$bump — ${pl.jobTitle}',
              );
            } else {
              pl.stress = (pl.stress + 3).clamp(0, 100);
              pl.eventLog.add(
                '${pl.year}年：傾價唔成，照原價入職 — ${pl.jobTitle}',
              );
            }
          },
        ),
        EventChoice(
          label: '拒絕 Offer',
          apply: (pl) {
            pl.unlockedFlags.remove('pt_convert_boost');
            pl.eventLog.add('${pl.year}年：拒絕咗 $display');
            clearHunt(pl);
            pl.network = (pl.network + 1).clamp(0, 100);
          },
        ),
      ],
    );
  }

  /// 低門檻「街頭／網上搵工」：抽可入行業再入面試
  static String walkInHunt(Player p) {
    if (p.isStudying) return '讀緊書唔可以做全職';
    if (p.isEmployed) return '你已經有全職';
    final pool = <CareerSector>[
      CareerSector.labour,
      CareerSector.realEstate,
      CareerSector.insurance,
      CareerSector.media,
      CareerSector.catering,
      CareerSector.disciplinary,
    ];
    final available = pool
        .where(
          (s) =>
              CareerData.canEnter(p, s) &&
              CareerHiringSeasons.blockReason(p, s) == null,
        )
        .toList();
    if (available.isEmpty) {
      return '暫時冇啱你條件嘅低門檻工';
    }
    if (!LuckModifiers.roll(p, 0.55, Random())) {
      p.network = (p.network + 2).clamp(0, 100);
      p.eventLog.add('${p.year}年：街頭／網上搵工未有下文');
      return '未有回音，人脈 +2';
    }
    final sector = available[Random(p.year + p.age).nextInt(available.length)];
    if (sector == CareerSector.disciplinary) {
      const ids = ['police_pc', 'fire_ff', 'customs_co'];
      final id = ids[Random(p.age * 7).nextInt(ids.length)];
      final post = CareerGov.byId(id)!;
      if (CareerGov.blockReason(p, post) != null ||
          CareerGov.seasonBlock(p, post) != null) {
        return apply(p, CareerSector.labour);
      }
      return apply(
        p,
        sector,
        employer: CareerGov.taggedEmployer(post),
        bypassSeason: true,
      );
    }
    return apply(p, sector);
  }
}
