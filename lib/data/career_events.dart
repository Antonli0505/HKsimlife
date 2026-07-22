import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_abilities.dart';
import 'career_data.dart';
import 'career_employment.dart';
import 'career_tax.dart';

/// 在職行業專屬季度卡（廣東話）
/// 能力／風險變差 → 危機觸發機率↑
/// 「認真」選項：下季 AP -2（真正 trade-off）
abstract final class CareerEvents {
  /// 揀認真／正面選項：下個季度少 1 AP
  static void markGoodChoiceCost(Player pl) {
    pl.unlockedFlags.add(Player.nextApPenaltyFlag);
  }

  static StoryEvent? quarterlyEvent(Player p, Random rng) {
    if (!p.isEmployed) return null;
    // 基礎 35% + 風險加成（最高 +40）
    final chance = (35 + CareerAbilities.crisisChanceBonus(p)).clamp(10, 80);
    if (rng.nextInt(100) >= chance) return null;

    return switch (p.currentSector) {
      CareerSector.socialWork => _social(p),
      CareerSector.teaching => _teaching(p),
      CareerSector.nursing => _nursing(p),
      CareerSector.banking => _banking(p),
      CareerSector.accounting => _accounting(p),
      CareerSector.it => _it(p),
      CareerSector.media => _media(p),
      CareerSector.realEstate => _realEstate(p),
      CareerSector.pharmacy => _pharmacy(p),
      CareerSector.insurance => _insurance(p),
      CareerSector.civilService => _civil(p),
      CareerSector.flightAttendant => _flight(p),
      CareerSector.labour => _labour(p),
      CareerSector.legalSolicitor || CareerSector.legalBarrister => _legal(p),
      CareerSector.politics => _politics(p),
      CareerSector.entertainment => _entertainment(p, rng),
      CareerSector.medical => _medical(p),
      CareerSector.engineering => _engineering(p),
      CareerSector.catering => _catering(p),
      CareerSector.disciplinary => _disciplinary(p),
      CareerSector.taxi => _taxi(p, rng),
      _ => null,
    };
  }

  /// 表現長期極差 → 有機會被炒
  static String? maybeFireForPerformance(Player p) {
    if (!p.isEmployed) return null;
    if (CareerEmployment.onProbation(p)) return null;
    if (CareerGovSafe.isGov(p)) return null; // 公職另有評核／試用
    if (p.jobPerformance >= 25) return null;
    if (p.jobQuartersInRank < 3) return null;
    var fireChance = 35 + CareerAbilities.crisisChanceBonus(p) ~/ 2;
    if (Random(p.year * 17 + p.jobPerformance).nextInt(100) >= fireChance) {
      return null;
    }
    final title = p.jobTitle;
    CareerData.quitJob(p, reason: '因為表現太差被炒（$title）');
    return '因為表現太差被炒：$title';
  }

  static StoryEvent _social(Player p) => StoryEvent(
        id: 'career_social_case',
        title: '棘手個案',
        body: '有服務對象情緒爆發，同事望住你：「你跟住呢單啦。」',
        choices: [
          EventChoice(
            label: '慢慢傾，跟足程序（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 10).clamp(0, 100);
              pl.stress = (pl.stress + 8).clamp(0, 100);
              pl.reputation = (pl.reputation + 3).clamp(0, 100);
              CareerAbilities.add(pl, '個案數', 1);
              CareerAbilities.add(pl, '個案成功率', 2, max: 100);
            },
          ),
          EventChoice(
            label: '叫保安／轉介走數',
            apply: (pl) {
              pl.stress = (pl.stress - 2).clamp(0, 100);
              pl.jobPerformance = (pl.jobPerformance - 4).clamp(0, 100);
              CareerAbilities.add(pl, '投訴', 1);
            },
          ),
        ],
      );

  static StoryEvent _teaching(Player p) => StoryEvent(
        id: 'career_teach_parent',
        title: '家長投訴',
        body: '家長 WhatsApp 群爆煲，話你改簿唔公平、功課太多。',
        choices: [
          EventChoice(
            label: '約見家長解釋（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 8).clamp(0, 100);
              pl.stress = (pl.stress + 6).clamp(0, 100);
              pl.reputation = (pl.reputation + 2).clamp(0, 100);
              CareerAbilities.add(pl, '家長滿意', 3, max: 100);
            },
          ),
          EventChoice(
            label: '裝睇唔到',
            apply: (pl) {
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
              pl.jobPerformance = (pl.jobPerformance - 6).clamp(0, 100);
              CareerAbilities.add(pl, '家長投訴', 1);
              CareerAbilities.add(pl, '家長滿意', -5, min: 0, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _nursing(Player p) => StoryEvent(
        id: 'career_nurse_shift',
        title: '病房爆滿',
        body: '夜更人手唔夠，護士長問你可唔可以加更。',
        choices: [
          EventChoice(
            label: '頂硬上加更（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 12).clamp(0, 100);
              pl.hp = (pl.hp - 6).clamp(0, pl.maxHp);
              pl.stress = (pl.stress + 10).clamp(0, 100);
              CareerTax.grantTaxablePay(pl, 2500);
              CareerAbilities.add(pl, '值班時數', 1);
              CareerAbilities.add(pl, '病人滿意', 2, max: 100);
              CareerAbilities.add(pl, '疲勞', 8, max: 100);
            },
          ),
          EventChoice(
            label: '拒絕，保護自己',
            apply: (pl) {
              pl.san = (pl.san + 4).clamp(0, pl.maxSan);
              pl.jobPerformance = (pl.jobPerformance - 3).clamp(0, 100);
              CareerAbilities.add(pl, '疲勞', -3, min: 0);
            },
          ),
        ],
      );

  static StoryEvent _banking(Player p) => StoryEvent(
        id: 'career_bank_kpi',
        title: '銷售 KPI',
        body: '分行經理話今季要開幾張信用卡同投資戶口，唔達標就「傾下」。',
        choices: [
          EventChoice(
            label: '硬銷搏達標（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 11).clamp(0, 100);
              pl.stress = (pl.stress + 7).clamp(0, 100);
              pl.reputation = (pl.reputation - 2).clamp(0, 100);
              CareerAbilities.add(pl, '客戶數', 2);
              CareerAbilities.add(pl, 'AUM', 120);
              CareerAbilities.add(pl, '合規分', -3, min: 0, max: 100);
              CareerAbilities.add(pl, '客訴', 1);
            },
          ),
          EventChoice(
            label: '寧願慢，唔亂推',
            apply: (pl) {
              pl.reputation = (pl.reputation + 3).clamp(0, 100);
              pl.jobPerformance = (pl.jobPerformance - 2).clamp(0, 100);
              CareerAbilities.add(pl, '合規分', 2, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _accounting(Player p) => StoryEvent(
        id: 'career_audit_busy',
        title: 'Busy Season',
        body: '客戶帳目一塌糊塗，partner 話「weekend 返黎 overtime」。',
        choices: [
          EventChoice(
            label: '周末 OT 清數（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 14).clamp(0, 100);
              pl.stress = (pl.stress + 12).clamp(0, 100);
              pl.san = (pl.san - 6).clamp(0, pl.maxSan);
              CareerTax.grantTaxablePay(pl, 3000);
              CareerAbilities.add(pl, 'Busy Season', 1);
              CareerAbilities.add(pl, '完成質素', 3, max: 100);
            },
          ),
          EventChoice(
            label: '請病假溜走',
            apply: (pl) {
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
              pl.jobPerformance = (pl.jobPerformance - 10).clamp(0, 100);
              CareerAbilities.add(pl, '出錯風險', 6, max: 100);
              CareerAbilities.add(pl, '完成質素', -5, min: 0, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _it(Player p) => StoryEvent(
        id: 'career_it_outage',
        title: 'Production 爆機',
        body: '凌晨 monitoring 狂響，客戶群組已經開始罵。',
        choices: [
          EventChoice(
            label: '即刻上線修（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 13).clamp(0, 100);
              pl.stress = (pl.stress + 9).clamp(0, 100);
              pl.smarts = (pl.smarts + 1).clamp(0, 100);
              CareerAbilities.add(pl, 'Project 數', 1);
              CareerAbilities.add(pl, 'Uptime', 2, max: 100);
              if (CareerAbilities.get(pl, 'Bug 數') > 0) {
                CareerAbilities.add(pl, 'Bug 數', -2, min: 0);
              }
            },
          ),
          EventChoice(
            label: '推畀 on-call 第二個',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 5).clamp(0, 100);
              pl.network = (pl.network - 2).clamp(0, 100);
              CareerAbilities.add(pl, 'Bug 數', 2);
              CareerAbilities.add(pl, '事故風險', 5, max: 100);
              CareerAbilities.add(pl, 'Uptime', -3, min: 50, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _media(Player p) => StoryEvent(
        id: 'career_media_deadline',
        title: '截稿前夕',
        body: '總編話封面故事要今晚交，料源仲未肯出聲。',
        choices: [
          EventChoice(
            label: '追料搏出稿（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 10).clamp(0, 100);
              pl.stress = (pl.stress + 8).clamp(0, 100);
              pl.reputation = (pl.reputation + 3).clamp(0, 100);
              CareerAbilities.add(pl, '稿件數', 1);
              CareerAbilities.add(pl, '點擊／收視', 12);
            },
          ),
          EventChoice(
            label: '改寫舊料頂檔',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance + 2).clamp(0, 100);
              pl.reputation = (pl.reputation - 3).clamp(0, 100);
              CareerAbilities.add(pl, '公關危機', 4, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _realEstate(Player p) => StoryEvent(
        id: 'career_property_client',
        title: '客仔殺價',
        body: '客睇完盤即場話「再平十万先傾」，你佣金眼睇住飛。',
        choices: [
          EventChoice(
            label: '死撐價錢（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              if (Random(pl.year + pl.luck).nextBool()) {
                CareerTax.grantTaxablePay(pl, 12000);
                pl.jobPerformance = (pl.jobPerformance + 10).clamp(0, 100);
                CareerAbilities.add(pl, '成交單', 1);
                CareerAbilities.add(pl, '客源', 3);
              } else {
                pl.jobPerformance = (pl.jobPerformance - 3).clamp(0, 100);
                pl.stress = (pl.stress + 4).clamp(0, 100);
                CareerAbilities.add(pl, '客訴', 1);
              }
            },
          ),
          EventChoice(
            label: '讓少少成交',
            apply: (pl) {
              CareerTax.grantTaxablePay(pl, 5000);
              pl.jobPerformance = (pl.jobPerformance + 6).clamp(0, 100);
              CareerAbilities.add(pl, '成交單', 1);
              CareerAbilities.add(pl, '客源', 1);
            },
          ),
        ],
      );

  static StoryEvent _pharmacy(Player p) => StoryEvent(
        id: 'career_pharm_otc',
        title: '客人硬要處方藥',
        body: '客人冇醫生紙，鬧住要你「通融下」。',
        choices: [
          EventChoice(
            label: '堅守規矩拒絕（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 7).clamp(0, 100);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.stress = (pl.stress + 4).clamp(0, 100);
              CareerAbilities.add(pl, '準確率', 2, max: 100);
              CareerAbilities.add(pl, '錯藥風險', -2, min: 0);
            },
          ),
          EventChoice(
            label: '怕事通融（風險）',
            apply: (pl) {
              CareerTax.grantTaxablePay(pl, 800);
              pl.jobPerformance = (pl.jobPerformance - 8).clamp(0, 100);
              CareerAbilities.add(pl, '錯藥風險', 10, max: 100);
              CareerAbilities.add(pl, '準確率', -5, min: 0, max: 100);
              if (Random(pl.year).nextInt(100) < 20) {
                pl.investigation = InvestigationStatus.police;
              }
            },
          ),
        ],
      );

  static StoryEvent _insurance(Player p) => StoryEvent(
        id: 'career_ins_friend',
        title: '朋友避保險',
        body: '同學聚會，人人一聽到你做保險就借故去廁所。',
        choices: [
          EventChoice(
            label: '照推，唔好意思都要開單（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 8).clamp(0, 100);
              pl.network = (pl.network - 3).clamp(0, 100);
              CareerAbilities.add(pl, '保單數', 1);
              CareerAbilities.add(pl, 'MDRT進度', 1);
              CareerAbilities.add(pl, '退保率', 2, max: 100);
            },
          ),
          EventChoice(
            label: '今日唔講工作',
            apply: (pl) {
              pl.network = (pl.network + 4).clamp(0, 100);
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
            },
          ),
        ],
      );

  static StoryEvent _civil(Player p) => StoryEvent(
        id: 'career_civil_paper',
        title: '公文山',
        body: '上司丟嚟一疊「急件」，其實全部都寫「盡快」。',
        choices: [
          EventChoice(
            label: '加班清晒（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 9).clamp(0, 100);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.stress = (pl.stress + 6).clamp(0, 100);
              CareerAbilities.add(pl, '公文完成量', 1);
              CareerAbilities.add(pl, '效率分', 3, max: 100);
            },
          ),
          EventChoice(
            label: '蛇王，拖到下季',
            apply: (pl) {
              pl.san = (pl.san + 4).clamp(0, pl.maxSan);
              pl.jobPerformance = (pl.jobPerformance - 5).clamp(0, 100);
              pl.discipline = (pl.discipline - 2).clamp(0, 100);
              CareerAbilities.add(pl, '效率分', -4, min: 0, max: 100);
              CareerAbilities.add(pl, '市民投訴', 1);
            },
          ),
        ],
      );

  static StoryEvent _flight(Player p) => StoryEvent(
        id: 'career_flight_pax',
        title: '客艙麻煩客',
        body: '有乘客喝醉鬧事，purser 叫你幫手處理。',
        choices: [
          EventChoice(
            label: '專業冷靜處理（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 10).clamp(0, 100);
              pl.stress = (pl.stress + 7).clamp(0, 100);
              pl.reputation = (pl.reputation + 2).clamp(0, 100);
              CareerAbilities.add(pl, '服務分', 3, max: 100);
              CareerAbilities.add(pl, '時差影響', -5, min: 0); // 處理得好，狀態回復
            },
          ),
          EventChoice(
            label: '叫第二個同事頂',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 4).clamp(0, 100);
              CareerAbilities.add(pl, '乘客投訴', 1);
              CareerAbilities.add(pl, '服務分', -3, min: 0, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _labour(Player p) => StoryEvent(
        id: 'career_labour_ot',
        title: '店長叫 OT',
        body: '人手短缺，店長話「今日收工遲啲，有補水」。',
        choices: [
          EventChoice(
            label: 'OT 賺多啲（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              CareerTax.grantTaxablePay(pl, 1800);
              pl.jobPerformance = (pl.jobPerformance + 7).clamp(0, 100);
              pl.stress = (pl.stress + 5).clamp(0, 100);
              pl.hp = (pl.hp - 3).clamp(0, pl.maxHp);
              CareerAbilities.add(pl, '工時', 1);
              CareerAbilities.add(pl, '技巧', 1, max: 100);
              CareerAbilities.add(pl, '工傷風險', 2, max: 100);
            },
          ),
          EventChoice(
            label: '準時走人',
            apply: (pl) {
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
              pl.jobPerformance = (pl.jobPerformance - 2).clamp(0, 100);
            },
          ),
        ],
      );

  static StoryEvent _legal(Player p) => StoryEvent(
        id: 'career_legal_case',
        title: '大案殺到',
        body: '客戶凌晨丟嚟緊急 injunction，deadline 係朝早。',
        choices: [
          EventChoice(
            label: '通宵寫 Affidavit（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 12).clamp(0, 100);
              pl.smarts = (pl.smarts + 1).clamp(0, 100);
              pl.stress = (pl.stress + 11).clamp(0, 100);
              pl.san = (pl.san - 5).clamp(0, pl.maxSan);
              if (pl.currentSector == CareerSector.legalSolicitor) {
                CareerAbilities.add(pl, '檔案數', 1);
                CareerAbilities.add(pl, '客戶滿意', 2, max: 100);
              } else {
                CareerAbilities.add(pl, '上庭次數', 1);
                CareerAbilities.add(pl, '聲譽', 2, max: 100);
              }
              CareerAbilities.add(pl, '勝訴率', 1, max: 100);
            },
          ),
          EventChoice(
            label: '推話睇唔到 email',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 8).clamp(0, 100);
              pl.reputation = (pl.reputation - 4).clamp(0, 100);
              CareerAbilities.add(pl, '客戶投訴', 1);
              CareerAbilities.add(pl, '勝訴率', -2, min: 0, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _politics(Player p) => StoryEvent(
        id: 'career_politics_media',
        title: '傳媒追訪',
        body: '記者追問你對區內爭議項目嘅立場，鏡頭已經對住。',
        choices: [
          EventChoice(
            label: '小心回應，企硬原則（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 8).clamp(0, 100);
              pl.reputation = (pl.reputation + 4).clamp(0, 100);
              pl.stress = (pl.stress + 5).clamp(0, 100);
              CareerAbilities.add(pl, '曝光度', 1);
              CareerAbilities.add(pl, '民望', 3, max: 100);
            },
          ),
          EventChoice(
            label: '「無可奉告」走人',
            apply: (pl) {
              pl.reputation = (pl.reputation - 3).clamp(0, 100);
              pl.jobPerformance = (pl.jobPerformance - 2).clamp(0, 100);
              CareerAbilities.add(pl, '民望', -3, min: 0, max: 100);
              CareerAbilities.add(pl, '醜聞風險', 2, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _entertainment(Player p, Random rng) {
    final hot = CareerAbilities.get(p, '炎上風險') >= 25 ||
        CareerAbilities.get(p, '負評') >= 20;
    if (hot && rng.nextBool()) {
      return StoryEvent(
        id: 'career_kol_flame',
        title: '被炎上',
        body: '舊片／舊帖被翻出嚟，留言一面倒負評，品牌開始問「可唔可以 freeze」。',
        choices: [
          EventChoice(
            label: '道歉澄清，停更兩日（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.stress = (pl.stress + 10).clamp(0, 100);
              pl.jobPerformance = (pl.jobPerformance - 2).clamp(0, 100);
              CareerAbilities.add(pl, '炎上風險', -8, min: 0);
              CareerAbilities.add(pl, '負評', -3, min: 0);
              CareerAbilities.add(pl, '粉絲數', -40, min: 0);
            },
          ),
          EventChoice(
            label: '硬剛反擊',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 6).clamp(0, 100);
              pl.reputation = (pl.reputation - 5).clamp(0, 100);
              CareerAbilities.add(pl, '炎上風險', 12, max: 100);
              CareerAbilities.add(pl, '負評', 8, max: 100);
              CareerAbilities.add(pl, '粉絲數', -80, min: 0);
            },
          ),
        ],
      );
    }
    return StoryEvent(
      id: 'career_kol_brand',
      title: '品牌合作邀請',
      body: '一個品牌 DM 你拍廣告，片酬幾萬，但要你「講好產品」。',
      choices: [
        EventChoice(
          label: '接，搏曝光同錢（下季 AP -2）',
          apply: (pl) {
            CareerEvents.markGoodChoiceCost(pl);
            CareerTax.grantTaxablePay(pl, 18000);
            pl.jobPerformance = (pl.jobPerformance + 8).clamp(0, 100);
            CareerAbilities.add(pl, 'Views', 5000);
            CareerAbilities.add(pl, '粉絲數', 60);
            CareerAbilities.add(pl, '好評', 2, max: 100);
            if (Random(pl.year).nextInt(100) < 35) {
              CareerAbilities.add(pl, '負評', 4, max: 100);
              CareerAbilities.add(pl, '炎上風險', 6, max: 100);
            }
          },
        ),
        EventChoice(
          label: '拒，保人設',
          apply: (pl) {
            pl.reputation = (pl.reputation + 3).clamp(0, 100);
            pl.san = (pl.san + 2).clamp(0, pl.maxSan);
            CareerAbilities.add(pl, '好評', 1, max: 100);
          },
        ),
      ],
    );
  }

  static StoryEvent _medical(Player p) => StoryEvent(
        id: 'career_med_case',
        title: '急症室高峰',
        body: '流感高峰，急症室爆滿，上級叫你加更處理危殆個案。',
        choices: [
          EventChoice(
            label: '頂更救人（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 12).clamp(0, 100);
              pl.hp = (pl.hp - 5).clamp(0, pl.maxHp);
              pl.stress = (pl.stress + 10).clamp(0, 100);
              CareerAbilities.add(pl, '值班時數', 1);
              CareerAbilities.add(pl, '手術成功率', 2, max: 100);
            },
          ),
          EventChoice(
            label: '按更表走人',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 4).clamp(0, 100);
              CareerAbilities.add(pl, '醫療事故風險', 3, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _engineering(Player p) => StoryEvent(
        id: 'career_eng_deadline',
        title: '地盤趕工',
        body: '業主催交樓，工地主任問你可唔可以趕進度，但安全檢查未完。',
        choices: [
          EventChoice(
            label: '跟足安全再交（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 7).clamp(0, 100);
              pl.stress = (pl.stress + 5).clamp(0, 100);
              CareerAbilities.add(pl, '工程進度', 1); // 認真都計 KPI
              CareerAbilities.add(pl, '品質分', 3, max: 100);
              CareerAbilities.add(pl, '安全風險', -3, min: 0);
            },
          ),
          EventChoice(
            label: '趕工搏交貨',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance + 10).clamp(0, 100);
              CareerAbilities.add(pl, '工程進度', 1);
              CareerAbilities.add(pl, '延誤', -1, min: 0);
              CareerAbilities.add(pl, '安全風險', 8, max: 100);
              CareerAbilities.add(pl, '品質分', -4, min: 0, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _catering(Player p) => StoryEvent(
        id: 'career_cater_review',
        title: 'OpenRice 差評',
        body: '有客留一星：「侍應態度差，餸冷。」老闆 WhatsApp 你。',
        choices: [
          EventChoice(
            label: '道歉＋改善流程（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 6).clamp(0, 100);
              pl.stress = (pl.stress + 4).clamp(0, 100);
              CareerAbilities.add(pl, '評分', 2, max: 100);
              CareerAbilities.add(pl, '差評', -1, min: 0);
            },
          ),
          EventChoice(
            label: '回覆硬剛',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 5).clamp(0, 100);
              CareerAbilities.add(pl, '差評', 3);
              CareerAbilities.add(pl, '評分', -5, min: 0, max: 100);
              CareerAbilities.add(pl, '客流', -4, min: 0);
            },
          ),
        ],
      );

  static StoryEvent _disciplinary(Player p) => StoryEvent(
        id: 'career_disc_duty',
        title: '突發勤務',
        body: '深夜有大型活動／事故，上級叫你加班執勤。',
        choices: [
          EventChoice(
            label: '即刻出動（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 10).clamp(0, 100);
              pl.hp = (pl.hp - 3).clamp(0, pl.maxHp);
              pl.stress = (pl.stress + 6).clamp(0, 100);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              CareerAbilities.add(pl, '執勤次數', 1);
              CareerAbilities.add(pl, '體能表現', 2, max: 100);
              CareerAbilities.add(pl, '受傷風險', 2, max: 100);
            },
          ),
          EventChoice(
            label: '請病假避更',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 6).clamp(0, 100);
              CareerAbilities.add(pl, '違紀風險', 5, max: 100);
              CareerAbilities.add(pl, '體能表現', -2, min: 0, max: 100);
            },
          ),
        ],
      );

  static StoryEvent _taxi(Player p, Random rng) => StoryEvent(
        id: 'career_taxi_pax',
        title: '乘客爭議',
        body: '乘客話你「繞路」，鬧住要投訴同拒俾錢。',
        choices: [
          EventChoice(
            label: '開機顯示路線解釋（下季 AP -2）',
            apply: (pl) {
              CareerEvents.markGoodChoiceCost(pl);
              pl.jobPerformance = (pl.jobPerformance + 6).clamp(0, 100);
              pl.stress = (pl.stress + 3).clamp(0, 100);
              CareerAbilities.add(pl, '收入穩定', 2, max: 100);
              if (rng.nextInt(100) < 30) {
                CareerAbilities.add(pl, '差評', 1);
              }
            },
          ),
          EventChoice(
            label: '對罵趕走客',
            apply: (pl) {
              pl.jobPerformance = (pl.jobPerformance - 5).clamp(0, 100);
              CareerAbilities.add(pl, '差評', 3);
              CareerAbilities.add(pl, '違例風險', 4, max: 100);
              CareerAbilities.add(pl, '收入穩定', -4, min: 0, max: 100);
            },
          ),
        ],
      );
}

/// 避免 career_events ↔ career_gov 循環 import 過重：本地薄封裝
abstract final class CareerGovSafe {
  static bool isGov(Player p) =>
      p.currentSector == CareerSector.civilService ||
      p.currentSector == CareerSector.disciplinary;
}
