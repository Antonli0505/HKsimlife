import '../data/birth_gacha.dart';
import '../data/family_assets.dart';
import '../data/housing_market.dart';
import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';

/// Lifelong narrative branches keyed to Gacha socioeconomic class tag.
class SynergyEvents {
  static List<StoryEvent> forPlayer(Player p) {
    final events = <StoryEvent>[];

    switch (p.birthTier) {
      case BirthTier.ssr:
        events.addAll(_ssrEvents(p));
      case BirthTier.sr:
        events.addAll(_srEvents(p));
      case BirthTier.r:
        events.addAll(_rEvents(p));
    }

    return events;
  }

  // ── SSR: Kadoorie Hill elite ──

  static List<StoryEvent> _ssrEvents(Player p) {
    final events = <StoryEvent>[];

    if (p.investigation != InvestigationStatus.none &&
        !p.unlockedFlags.contains('synergy_ssr_counsel')) {
      events.add(StoryEvent(
        id: 'ssr_senior_counsel',
        title: '家族法律團隊',
        body: '老豆收到風聲，即刻叫秘書 contact 御用 Senior Counsel。'
            '律師話「令郎嘅 case，我哋有辦法」。',
        choices: [
          EventChoice(
            label: '跟屋企安排，交畀大律師搞掂',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_ssr_counsel');
              pl.investigation = InvestigationStatus.none;
              FamilyAssets.familyPays(pl, 500000, reason: 'Senior Counsel 費用');
              pl.san = (pl.san + 10).clamp(0, pl.maxSan);
              pl.eventLog.add('${pl.year}年：Senior Counsel 介入，調查壓咗落去。');
            },
          ),
          EventChoice(
            label: '話要靠自己面對',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_ssr_counsel');
              pl.reputation = (pl.reputation + 5).clamp(0, 100);
            },
          ),
        ],
        isSystem: true,
      ));
    }

    if (p.lifeStage == LifeStage.adult &&
        p.age >= HousingMarket.minAge &&
        !p.ownsFlat &&
        p.livesWithFamily &&
        p.unlockedFlags.contains('family_property_backing') &&
        !p.unlockedFlags.contains('synergy_ssr_property')) {
      events.add(StoryEvent(
        id: 'ssr_family_property',
        title: '家族置業背書',
        body: '阿爸話「上車唔使擔心 stress test，家族 office 可以擔保」。'
            '首期由信託出，但物業寫你名。你自己荷包唔使掏太多。',
        choices: [
          EventChoice(
            label: '跟家族擔保，直接上車',
            apply: (pl) {
              if (pl.age < HousingMarket.minAge) {
                pl.eventLog.add(
                  '${pl.year}年：未滿 ${HousingMarket.minAge} 歲，置業延後。',
                );
                return;
              }
              pl.unlockedFlags.add('synergy_ssr_property');
              pl.unlockedFlags.add('family_property_backing');
              final msg = HousingMarket.purchase(pl, 'luxury_peak');
              pl.eventLog.add('${pl.year}年：家族置業 — $msg');
              pl.stress = (pl.stress - 15).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '自己捱，唔靠老豆',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_ssr_property');
              pl.discipline = (pl.discipline + 5).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    if (p.lifeStage == LifeStage.infant &&
        !p.unlockedFlags.contains('synergy_ssr_allowance')) {
      events.add(StoryEvent(
        id: 'ssr_allowance',
        title: '家族期望',
        body: '阿爺阿嫲好錫你，但信託基金要成年先動用。'
            '老豆話「利是新年先派，平時零用錢都要睇表現」。',
        choices: [
          EventChoice(
            label: '接受規矩，做好細路',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_ssr_allowance');
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '買玩具慶祝',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_ssr_allowance');
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
              pl.wealth = (pl.wealth - 200).clamp(0, 999999999);
            },
          ),
        ],
      ));
    }

    if (p.lifeStage == LifeStage.infant &&
        !p.unlockedFlags.contains('synergy_ssr_legacy')) {
      events.add(StoryEvent(
        id: 'ssr_family_legacy',
        title: '家族傳承',
        body: '你喺淺水灣大屋出世，滿月酒嚟咗成個商界。'
            '阿爺話「呢個孫，係我哋第三代嘅繼承人」。',
        choices: [
          EventChoice(
            label: '跟家族期望嚟',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_ssr_legacy');
              pl.network = (pl.network + 5).clamp(0, 100);
              pl.stress = (pl.stress + 5).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '暫時唔理，做個普通細路',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_ssr_legacy');
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
            },
          ),
        ],
      ));
    }

    return events;
  }

  // ── SR: Taikoo Shing middle-class ──

  static List<StoryEvent> _srEvents(Player p) {
    final events = <StoryEvent>[];

    if (p.lifeStage == LifeStage.adult &&
        p.currentSector != CareerSector.civilService &&
        !p.unlockedFlags.contains('synergy_sr_ao_pressure')) {
      events.add(StoryEvent(
        id: 'sr_ao_pressure',
        title: '父母逼考 AO',
        body: '阿媽喺廚房話「讀咁多書，點解唔考政府工？AO 有鐵飯碗㗎！」'
            '阿爸遞張 CRE 報名表俾你。',
        choices: [
          EventChoice(
            label: '應承會諗下考公',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_sr_ao_pressure');
              pl.stress = (pl.stress + 8).clamp(0, 100);
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '話有自己嘅職業規劃',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_sr_ao_pressure');
              pl.san = (pl.san - 5).clamp(0, pl.maxSan);
              pl.reputation = (pl.reputation + 2).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    if (p.lifeStage == LifeStage.adult &&
        p.age >= HousingMarket.minAge &&
        !p.ownsFlat &&
        !p.unlockedFlags.contains('synergy_sr_downpayment')) {
      events.add(StoryEvent(
        id: 'sr_downpayment_struggle',
        title: '首期壓力',
        body: '你同阿爸阿媽去睇樓 — 將軍澳、荃灣、甚至舊樓都睇過。'
            '經紀話細單位首期都要百幾 200 萬，按揭 stress test 又嚴。'
            '阿爸話「幫補到一部分，但買唔買、買邊區，你自己決定」。',
        choices: [
          EventChoice(
            label: '揀個負擔得起嘅單位，接受父母資助上車',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_sr_downpayment');
              final msg = HousingMarket.purchase(
                pl,
                'tm_old',
                familyHelp: true,
              );
              pl.eventLog.add('${pl.year}年：$msg');
            },
          ),
          EventChoice(
            label: '繼續租，儲夠先 — 唔急上車',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_sr_downpayment');
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
              pl.eventLog.add('${pl.year}年：揀咗繼續租屋。');
            },
          ),
          EventChoice(
            label: '換細盤睇過，今次唔買',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_sr_downpayment');
              pl.network = (pl.network + 1).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    if (p.lifeStage == LifeStage.secondary &&
        !p.unlockedFlags.contains('synergy_sr_exam')) {
      events.add(StoryEvent(
        id: 'sr_exam_anxiety',
        title: '考試焦慮',
        body: '阿媽每日問「今日測驗幾分？」補習社導師話你 DSE 要衝 5**。',
        choices: [
          EventChoice(
            label: '加把勁，唔想令阿爸阿媽失望',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_sr_exam');
              BirthGacha.applyStudyGain(pl, base: 3);
              pl.san = (pl.san - 5).clamp(0, pl.maxSan);
            },
          ),
          EventChoice(
            label: '頂唔順，出街透氣',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_sr_exam');
              pl.san = (pl.san + 4).clamp(0, pl.maxSan);
            },
          ),
        ],
      ));
    }

    return events;
  }

  // ── R: Public housing grassroots ──

  static List<StoryEvent> _rEvents(Player p) {
    final events = <StoryEvent>[];

    if (p.isEmployed &&
        !p.unlockedFlags.contains('synergy_r_family_support')) {
      events.add(StoryEvent(
        id: 'r_family_support',
        title: '畀家用',
        body: '出糧後第一日，阿媽話「你大個喇，要幫補屋企」。'
            '阿爸話水電煤都等你供。公屋嘅生活唔容易。',
        choices: [
          EventChoice(
            label: '每月畀 \$8000 家用',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_family_support');
              pl.wealth = (pl.wealth - 8000).clamp(-999999, 999999999);
              pl.reputation = (pl.reputation + 5).clamp(0, 100);
              pl.network = (pl.network + 2).clamp(0, 100);
              pl.eventLog.add('${pl.year}年：開始畀家用。');
            },
          ),
          EventChoice(
            label: '講明要儲錢，畀少啲',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_family_support');
              pl.wealth = (pl.wealth - 3000).clamp(-999999, 999999999);
              pl.san = (pl.san - 5).clamp(0, pl.maxSan);
            },
          ),
        ],
      ));
    }

    if (p.livesWithFamily &&
        p.lifeStage == LifeStage.secondary &&
        !p.unlockedFlags.contains('synergy_r_tight_allowance')) {
      events.add(StoryEvent(
        id: 'r_tight_allowance',
        title: '零用錢縮水',
        body: '阿媽話「屋企呢個月緊，零用錢減一半」。你知佢哋已經好盡力。',
        choices: [
          EventChoice(
            label: '明白，慳住花',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_tight_allowance');
              pl.baseAllowance = (pl.baseAllowance * 0.7).round();
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '唔開心但唔敢出聲',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_tight_allowance');
              pl.san = (pl.san - 5).clamp(0, pl.maxSan);
            },
          ),
        ],
      ));
    }

    if (p.unlockedFlags.contains('med_degree') ||
        p.unlockedFlags.contains('law_degree') ||
        p.currentSector == CareerSector.medical ||
        p.currentSector == CareerSector.legalBarrister ||
        p.currentSector == CareerSector.legalSolicitor) {
      if (!p.unlockedFlags.contains('synergy_r_elite_climb')) {
        events.add(StoryEvent(
          id: 'r_elite_climb',
          title: '草根升神科',
          body: p.housingType == HousingType.publicHousing
              ? '同事喺茶水間竊竊私語：「公屋出身做到 doctor/lawyer，好少見。」'
                  '有人欣賞你，有人話你「攀高枝」。'
              : '你嘅背景同呢行精英圈子有落差，但能力擺喺度。',
          choices: [
            EventChoice(
              label: '靠真功夫證明自己',
              apply: (pl) {
                pl.unlockedFlags.add('synergy_r_elite_climb');
                pl.reputation = (pl.reputation + 8).clamp(0, 100);
                pl.stress = (pl.stress + 6).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '唔理人講三講四，專心做嘢',
              apply: (pl) {
                pl.unlockedFlags.add('synergy_r_elite_climb');
                pl.san = (pl.san + 3).clamp(0, pl.maxSan);
                pl.discipline = (pl.discipline + 4).clamp(0, 100);
              },
            ),
          ],
        ));
      }
    }

    if (p.lifeStage == LifeStage.infant &&
        !p.unlockedFlags.contains('synergy_r_dense')) {
      events.add(StoryEvent(
        id: 'r_dense_living',
        title: '公屋生活',
        body: '成日聽到隔壁單位嘈交，走廊逼到行唔到。'
            '但街坊好有人情味，婆婆會留低啲湯俾你。',
        choices: [
          EventChoice(
            label: '學識喺逼位入面捱',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_dense');
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
              pl.san = (pl.san - 3).clamp(0, pl.maxSan);
            },
          ),
          EventChoice(
            label: '同街坊搞好關係',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_dense');
              pl.network = (pl.network + 4).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    if (p.unlockedFlags.contains('cssa_welfare') &&
        p.lifeStage == LifeStage.secondary &&
        !p.unlockedFlags.contains('synergy_r_grant')) {
      events.add(StoryEvent(
        id: 'r_student_grant',
        title: '學生資助',
        body: '學校話你可以申請 Grant/Loan Scheme，'
            '但要填一堆表格，證明屋企收入。',
        choices: [
          EventChoice(
            label: '申請資助',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_grant');
              pl.wealth += 15000;
              pl.stress = (pl.stress + 3).clamp(0, 100);
              pl.eventLog.add('${pl.year}年：獲批學生資助。');
            },
          ),
          EventChoice(
            label: '唔申請，自己捱',
            apply: (pl) {
              pl.unlockedFlags.add('synergy_r_grant');
              pl.reputation = (pl.reputation + 3).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    return events;
  }
}
