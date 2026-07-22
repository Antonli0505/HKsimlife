import 'dart:math';

import '../data/birth_gacha.dart';
import '../data/career_data.dart';
import '../data/career_employment.dart';
import '../data/career_events.dart';
import '../data/career_exams.dart';
import '../data/elective_subjects.dart';
import '../data/family_assets.dart';
import '../data/hk_school_data.dart';
import '../data/housing_market.dart';
import '../data/ib_curriculum.dart';
import '../data/ib_pathway.dart';
import '../data/jupas/jupas.dart';
import '../data/jupas_pathway.dart';
import '../data/synergy_events.dart';
import '../data/university_life.dart';
import '../data/university_pathway.dart';
import '../data/university_societies.dart';
import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';

/// Quarterly story & action event generator with life-stage pools.
class EventEngine {
  final _rng = DateTime.now().millisecondsSinceEpoch;

  int _seed = 0;
  int get _next => (_seed = (_seed * 1103515245 + 12345 + _rng) & 0x7fffffff);

  bool _chance(int pct) => (_next % 100) < pct;

  List<StoryEvent> generateQuarterEvents(Player player) {
    final events = <StoryEvent>[];

    switch (player.lifeStage) {
      case LifeStage.infant:
        events.addAll(_infantEvents(player));
      case LifeStage.primary:
        events.addAll(_primaryEvents(player));
      case LifeStage.secondary:
        events.addAll(_secondaryEvents(player));
      case LifeStage.adult:
        events.addAll(_adultEvents(player));
    }

    if (player.investigation != InvestigationStatus.none) {
      events.add(_investigationEvent(player));
    }
    if (player.inPrison) {
      events.add(_prisonEvent(player));
    }

    // Lifelong Gacha class synergy branches
    events.addAll(SynergyEvents.forPlayer(player));

    return events;
  }

  // ── 0-5 Infant ──

  List<StoryEvent> _infantEvents(Player p) {
    final events = <StoryEvent>[
      _infantDailyEvent(p),
    ];

    final milestone = _infantMilestoneEvent(p);
    if (milestone != null) events.add(milestone);

    events.addAll(_infantTierEvents(p));
    return events;
  }

  /// 每季 1 張：幼兒日常（輪換，唔再淨係重複「報幼稚園」）
  StoryEvent _infantDailyEvent(Player p) {
    final pool = <StoryEvent Function(Player)>[
      (pl) => StoryEvent(
            id: 'infant_daily_sick_${pl.year}_${pl.quarter.name}',
            title: '發燒睇醫生',
            body: '半夜燒到 39 度，阿媽急急帶你去急症室排隊。'
                '護士話「细路好常见，但今次要食足五日药」。',
            choices: [
              EventChoice(
                label: '乖乖食药休息',
                apply: (x) {
                  x.hp = (x.hp + 4).clamp(0, x.maxHp);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                  x.san = (x.san - 2).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '扭计唔肯食药',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.discipline = (x.discipline - 2).clamp(0, 100);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'infant_daily_park_${pl.year}_${pl.quarter.name}',
            title: '街公園放電',
            body: '阿爸放工帶你去${pl.homeDistrict.label}附近街公園，'
                '滑梯同鞦韆逼到满。你识同陌生小朋友借玩具。',
            choices: [
              EventChoice(
                label: '主动同其他人玩',
                apply: (x) {
                  x.network = (x.network + 3).clamp(0, 100);
                  x.hp = (x.hp + 2).clamp(0, x.maxHp);
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '自己玩沙坑',
                apply: (x) {
                  x.san = (x.san + 4).clamp(0, x.maxSan);
                  x.smarts = (x.smarts + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'infant_daily_mcd_${pl.year}_${pl.quarter.name}',
            title: '奖励餐',
            body: '今个星期表现不错，屋企带你去食开心乐园餐。'
                '你最钟意个玩具同苹果派。',
            choices: [
              EventChoice(
                label: '开心食晒',
                apply: (x) {
                  x.san = (x.san + 5).clamp(0, x.maxSan);
                  x.hp = (x.hp + 1).clamp(0, x.maxHp);
                },
              ),
              EventChoice(
                label: '留部分同家人分享',
                apply: (x) {
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                  x.network = (x.network + 2).clamp(0, 100);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'infant_daily_cartoon_${pl.year}_${pl.quarter.name}',
            title: '卡通片时间',
            body: '下昼阿妈开电视给你看卡通。'
                '你学会咗几句广告对白，成日喺度重复。',
            choices: [
              EventChoice(
                label: '跟住学讲',
                apply: (x) {
                  x.smarts = (x.smarts + 2).clamp(0, 100);
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '睇到唔肯停，扭计',
                apply: (x) {
                  x.san = (x.san + 4).clamp(0, x.maxSan);
                  x.discipline = (x.discipline - 2).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'infant_daily_neighbor_${pl.year}_${pl.quarter.name}',
            title: '街坊人情',
            body: pl.housingType == HousingType.publicHousing
                ? '隔壁婆婆留咗啲汤同糖俾你；走廊逼但有人情味。'
                : '管理处搞节日活动，你拎咗小礼物同邻居打招呼。',
            choices: [
              EventChoice(
                label: '多谢并帮手拎嘢',
                apply: (x) {
                  x.network = (x.network + 3).clamp(0, 100);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '害羞躲喺阿妈后面',
                apply: (x) {
                  x.san = (x.san - 1).clamp(0, x.maxSan);
                  x.network = (x.network + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'infant_daily_rain_${pl.year}_${pl.quarter.name}',
            title: '打风日落雨',
            body: '成日落雨，出唔到街。喺屋企砌图、画纸，'
                '或者听窗外雨声发呆。',
            choices: [
              EventChoice(
                label: '静下心砌图/画纸',
                apply: (x) {
                  x.smarts = (x.smarts + 2).clamp(0, 100);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '闷到喺度捣乱',
                apply: (x) {
                  x.san = (x.san - 3).clamp(0, x.maxSan);
                  x.stress = (x.stress + 4).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'infant_daily_relative_${pl.year}_${pl.quarter.name}',
            title: '亲戚探访',
            body: '周末亲戚上嚟食饭，长辈不停问「识唔识叫叔叔」'
                '「几多岁啦」。',
            choices: [
              EventChoice(
                label: '礼貌叫人',
                apply: (x) {
                  x.network = (x.network + 2).clamp(0, 100);
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.reputation = (x.reputation + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '躲入房唔出嚟',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.network = (x.network - 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'infant_daily_nap_${pl.year}_${pl.quarter.name}',
            title: '午睡战争',
            body: '阿妈话要瞓晏，你精神到唔想停。'
                '窗望出去有装修声同雀仔叫。',
            choices: [
              EventChoice(
                label: '听阿妈话休息',
                apply: (x) {
                  x.hp = (x.hp + 3).clamp(0, x.maxHp);
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '偷偷起身玩',
                apply: (x) {
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                  x.discipline = (x.discipline - 1).clamp(0, 100);
                  x.stress = (x.stress + 2).clamp(0, 100);
                },
              ),
            ],
          ),
    ];

    final idx = (_next + p.age * 7 + p.year) % pool.length;
    return pool[idx](p);
  }

  /// 按年龄一次性里程碑
  StoryEvent? _infantMilestoneEvent(Player p) {
    if (p.age == 1 && !p.unlockedFlags.contains('infant_milestone_walk')) {
      return StoryEvent(
        id: 'infant_milestone_walk',
        title: '学行',
        body: '你扶住梳化行第一步，成屋人都拍掌。'
            '阿爸话「跌亲唔使惊，再嚟」。',
        choices: [
          EventChoice(
            label: '勇敢再试',
            apply: (pl) {
              pl.unlockedFlags.add('infant_milestone_walk');
              pl.hp = (pl.hp + 3).clamp(0, pl.maxHp);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '惊，要揽',
            apply: (pl) {
              pl.unlockedFlags.add('infant_milestone_walk');
              pl.san = (pl.san + 4).clamp(0, pl.maxSan);
            },
          ),
        ],
      );
    }
    if (p.age == 2 && !p.unlockedFlags.contains('infant_milestone_talk')) {
      return StoryEvent(
        id: 'infant_milestone_talk',
        title: '学讲嘢',
        body: '你开始识讲短句：「要」「唔要」「我自己嚟」。'
            '有时讲错嘢整到成屋笑。',
        choices: [
          EventChoice(
            label: '多同大人讲',
            apply: (pl) {
              pl.unlockedFlags.add('infant_milestone_talk');
              pl.smarts = (pl.smarts + 3).clamp(0, 100);
              pl.network = (pl.network + 2).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '用扭计代替说话',
            apply: (pl) {
              pl.unlockedFlags.add('infant_milestone_talk');
              pl.stress = (pl.stress + 4).clamp(0, 100);
              pl.discipline = (pl.discipline - 2).clamp(0, 100);
            },
          ),
        ],
      );
    }
    if ((p.age == 3 || p.age == 4) && !p.unlockedFlags.contains('kg_decided')) {
      return StoryEvent(
        id: 'infant_kindergarten',
        title: '幼稚园选择',
        body: '到你报幼稚园，家人要决定送你去边间。'
            '有人话早上班可以学规矩，有人话迟啲入学都唔迟。',
        choices: [
          EventChoice(
            label: p.unlockedFlags.contains('international_school')
                ? '报国际幼稚园'
                : '报区内幼稚园',
            apply: (pl) {
              pl.unlockedFlags.add('kg_decided');
              pl.unlockedFlags.add('kg_enrolled');
              pl.smarts = (pl.smarts + 2).clamp(0, 100);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              if (pl.unlockedFlags.contains('international_school')) {
                pl.network = (pl.network + 2).clamp(0, 100);
              }
              pl.eventLog.add('${pl.year}年：入读幼稚园');
            },
          ),
          EventChoice(
            label: '迟啲先读，多玩一年',
            apply: (pl) {
              pl.unlockedFlags.add('kg_decided');
              pl.unlockedFlags.add('kg_deferred');
              pl.san = (pl.san + 4).clamp(0, pl.maxSan);
              pl.discipline = (pl.discipline - 1).clamp(0, 100);
              pl.eventLog.add('${pl.year}年：延迟一年先报幼稚园');
            },
          ),
        ],
      );
    }
    if (p.age == 5 &&
        p.quarter == Quarter.q4 &&
        !p.unlockedFlags.contains('infant_ready_primary')) {
      return StoryEvent(
        id: 'infant_ready_primary',
        title: '准备升小',
        body: '快 6 岁，阿妈开始讲升小学：校网系 ${p.homeDistrict.schoolNet}，'
            '你属 ${p.primaryBand.primaryLabel} 方向。'
            '可以温下简单字，或者尽情玩最后一段幼儿时光。',
        choices: [
          EventChoice(
            label: '听故事学字准备升小',
            apply: (pl) {
              pl.unlockedFlags.add('infant_ready_primary');
              pl.smarts = (pl.smarts + 3).clamp(0, 100);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.primaryScore += 1;
            },
          ),
          EventChoice(
            label: '尽情玩，升小先讲',
            apply: (pl) {
              pl.unlockedFlags.add('infant_ready_primary');
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
            },
          ),
        ],
      );
    }
    if (p.unlockedFlags.contains('kg_enrolled') &&
        p.age >= 4 &&
        p.age <= 5 &&
        _chance(45)) {
      return StoryEvent(
        id: 'infant_kg_life_${p.year}_${p.quarter.name}',
        title: '幼稚园生活',
        body: '幼稚园有唱歌、画画同排队洗手。'
            '今日老师话要分享玩具，有同学抢你积木。',
        choices: [
          EventChoice(
            label: '同老师讲',
            apply: (pl) {
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.network = (pl.network + 1).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '自己抢返',
            apply: (pl) {
              pl.stress = (pl.stress + 3).clamp(0, 100);
              pl.discipline = (pl.discipline - 1).clamp(0, 100);
            },
          ),
        ],
      );
    }
    return null;
  }

  List<StoryEvent> _infantTierEvents(Player p) {
    final events = <StoryEvent>[];

    if (p.birthTier == BirthTier.r && _chance(35)) {
      events.add(StoryEvent(
        id: 'family_stress_r_${p.year}_${p.quarter.name}',
        title: '家庭压力',
        body: '阿妈同阿爸为咗租金同生活费嘈交，你喺度喊但无人理。',
        choices: [
          EventChoice(
            label: '自己玩，学识独立',
            apply: (pl) {
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.san = (pl.san - 4).clamp(0, pl.maxSan);
            },
          ),
          EventChoice(
            label: '搵隔篱婆婆陪吓',
            apply: (pl) {
              pl.network = (pl.network + 3).clamp(0, 100);
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
            },
          ),
        ],
      ));
    }

    if (p.birthTier == BirthTier.sr && _chance(40)) {
      events.add(StoryEvent(
        id: 'sr_infant_compare_${p.year}_${p.quarter.name}',
        title: '父母比较',
        body: '阿妈同其他家长饮茶，听到「某某已经识认字、学钢琴」。'
            '返到屋企开始问你要唔要报兴趣班。',
        choices: [
          EventChoice(
            label: '答应试堂（屋企俾钱）',
            apply: (pl) {
              if (FamilyAssets.familyPays(pl, 3000, reason: '幼儿兴趣班')) {
                pl.smarts = (pl.smarts + 2).clamp(0, 100);
                pl.discipline = (pl.discipline + 2).clamp(0, 100);
                pl.stress = (pl.stress + 3).clamp(0, 100);
              } else {
                pl.san = (pl.san - 2).clamp(0, pl.maxSan);
              }
            },
          ),
          EventChoice(
            label: '话想多玩',
            apply: (pl) {
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
              pl.discipline = (pl.discipline - 1).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    if (p.birthTier == BirthTier.ssr && _chance(40)) {
      events.add(StoryEvent(
        id: 'nanny_life_${p.year}_${p.quarter.name}',
        title: '外籍保姆',
        body: '菲佣姐姐带你去会所 playgroup，其他小朋友讲流利英文。',
        choices: [
          EventChoice(
            label: '搏命学英文',
            apply: (pl) {
              pl.smarts = (pl.smarts + 3).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '玩够本，享受童年',
            apply: (pl) {
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
            },
          ),
        ],
      ));
    }

    if (p.quarter == Quarter.q1 && p.livesWithFamily && _chance(55)) {
      events.add(StoryEvent(
        id: 'infant_laisee_${p.year}',
        title: '新年拜年',
        body: '拜年走亲戚，大人逗你讲吉祥说话。'
            '利是会在季度结算派（${FamilyAssets.laiSeeRangeLabel(p)}）。',
        choices: [
          EventChoice(
            label: '乖乖说恭喜发财',
            apply: (pl) {
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.network = (pl.network + 2).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '害羞躲喺阿妈后面',
            apply: (pl) {
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
              pl.network = (pl.network + 1).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    return events;
  }

  // ── 6-11 Primary ──

  List<StoryEvent> _primaryEvents(Player p) {
    final events = <StoryEvent>[];

    final milestone = _primaryMilestoneEvent(p);
    if (milestone != null) events.add(milestone);

    events.add(_primaryDailyEvent(p));

    if (_chance(60)) {
      events.add(
        p.quarter.index.isEven
            ? _primaryHomeworkEvent(p)
            : _primaryLeisureEvent(p),
      );
    }

    events.addAll(_primaryTierAndSsaEvents(p));
    return events;
  }

  StoryEvent? _primaryMilestoneEvent(Player p) {
    if (p.unlockedFlags.contains('primary_just_enrolled') ||
        (p.age == 6 && !p.unlockedFlags.contains('primary_first_day'))) {
      final bandNote = switch (p.primaryBand) {
        SchoolBand.band1 => 'Band 1 名校：功课多，但资源同机会都多。',
        SchoolBand.band2 => 'Band 2：功课压力适中，要靠自己自律。',
        SchoolBand.band3 => 'Band 3：同学背景多元，有人早放学去球场。',
        SchoolBand.none => '继续加油。',
      };
      return StoryEvent(
        id: 'primary_first_day',
        title: '升小開學',
        body: '6 歲，背住新书包去 ${p.jobTitle}。\n'
            '校网 ${p.homeDistrict.schoolNet} · ${p.primaryBand.primaryLabel}\n'
            '$bandNote',
        choices: [
          EventChoice(
            label: '同阿妈击掌，勇敢入课室',
            apply: (pl) {
              pl.unlockedFlags.add('primary_first_day');
              pl.unlockedFlags.remove('primary_just_enrolled');
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
              pl.network = (pl.network + 2).clamp(0, 100);
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
            },
          ),
          EventChoice(
            label: '扭计唔肯入课室',
            apply: (pl) {
              pl.unlockedFlags.add('primary_first_day');
              pl.unlockedFlags.remove('primary_just_enrolled');
              pl.san = (pl.san - 3).clamp(0, pl.maxSan);
              pl.stress = (pl.stress + 4).clamp(0, 100);
            },
          ),
        ],
      );
    }

    if (p.age == 9 &&
        !p.unlockedFlags.contains('primary_stream_intro')) {
      return StoryEvent(
        id: 'primary_stream_intro',
        title: '呈分試預告',
        body: '老師話小五、小六會計呈分，影响升中 Band 同校网派位。'
            '而家累积嘅 ${p.primaryScore} 分开始有意义。',
        choices: [
          EventChoice(
            label: '认真听，开始准备',
            apply: (pl) {
              pl.unlockedFlags.add('primary_stream_intro');
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.stress = (pl.stress + 2).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '仲有排，唔使咁急',
            apply: (pl) {
              pl.unlockedFlags.add('primary_stream_intro');
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
            },
          ),
        ],
      );
    }

    if (p.age == 10 &&
        p.quarter == Quarter.q2 &&
        !p.unlockedFlags.contains('primary_mock_score')) {
      return StoryEvent(
        id: 'primary_mock_score',
        title: '模拟呈分评估',
        body: '学校做校内评估，老师话可以估算你而家嘅呈分水平。'
            '你 ${p.homeDistrict.schoolNet} 校网竞争都几激烈。',
        choices: [
          EventChoice(
            label: '温习迎考',
            apply: (pl) {
              pl.unlockedFlags.add('primary_mock_score');
              BirthGacha.applyStudyGain(pl, base: 4);
              pl.primaryScore += 2;
              pl.san = (pl.san - 2).clamp(0, pl.maxSan);
            },
          ),
          EventChoice(
            label: '平常心，当练习',
            apply: (pl) {
              pl.unlockedFlags.add('primary_mock_score');
              pl.primaryScore += 1;
            },
          ),
        ],
      );
    }

    return null;
  }

  StoryEvent _primaryDailyEvent(Player p) {
    final pool = <StoryEvent Function(Player)>[
      (pl) => StoryEvent(
            id: 'primary_daily_test_${pl.year}_${pl.quarter.name}',
            title: '小测／默书',
            body: '中文默书同数学小测一齐嚟，'
                '错字要抄十遍。',
            choices: [
              EventChoice(
                label: '昨晚有温习',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 2);
                  x.primaryScore += 1;
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '唔记得，尽力答',
                apply: (x) {
                  x.san = (x.san - 2).clamp(0, x.maxSan);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'primary_daily_sports_${pl.year}_${pl.quarter.name}',
            title: '陆运会 / 校队',
            body: '学校搞陆运会，你可以报名跑步或者帮同学打气。',
            choices: [
              EventChoice(
                label: '参加跑步',
                apply: (x) {
                  x.hp = (x.hp + 3).clamp(0, x.maxHp);
                  x.network = (x.network + 2).clamp(0, 100);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '做啦啦队',
                apply: (x) {
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                  x.network = (x.network + 3).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'primary_daily_trip_${pl.year}_${pl.quarter.name}',
            title: '学校旅行',
            body: '全班去科学馆／郊野公园，'
                '阿Sir话要组队、准时集合。',
            choices: [
              EventChoice(
                label: '做小组长',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.network = (x.network + 2).clamp(0, 100);
                  x.smarts = (x.smarts + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '同朋友慢慢逛',
                apply: (x) {
                  x.san = (x.san + 4).clamp(0, x.maxSan);
                  x.network = (x.network + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'primary_daily_library_${pl.year}_${pl.quarter.name}',
            title: '图书馆时间',
            body: '下昼放學留喺图书馆，可以借书或者做功课。',
            choices: [
              EventChoice(
                label: '借科普书',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 2);
                  x.smarts = (x.smarts + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '同同学倾计',
                apply: (x) {
                  x.network = (x.network + 3).clamp(0, 100);
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'primary_daily_bully_${pl.year}_${pl.quarter.name}',
            title: '同学摩擦',
            body: '有同学笑你书包旧／抢你文具，'
                '你要决定点处理。',
            choices: [
              EventChoice(
                label: '同老师讲',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 2).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '自己解决',
                apply: (x) {
                  x.network = (x.network + 1).clamp(0, 100);
                  x.stress = (x.stress + 4).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'primary_daily_club_${pl.year}_${pl.quarter.name}',
            title: '课外活动',
            body: '学校有奥数、合唱、足球等课外活动，'
                '要报名同交材料费。',
            choices: [
              EventChoice(
                label: '报奥数 / 学术类',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 2);
                  x.primaryScore += 1;
                  if (FamilyAssets.familyPays(x, 800, reason: '课外活动')) {
                    x.discipline = (x.discipline + 1).clamp(0, 100);
                  }
                },
              ),
              EventChoice(
                label: '报运动 / 艺术类',
                apply: (x) {
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                  x.hp = (x.hp + 2).clamp(0, x.maxHp);
                  if (FamilyAssets.familyPays(x, 800, reason: '课外活动')) {
                    x.network = (x.network + 2).clamp(0, 100);
                  }
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'primary_daily_lunch_${pl.year}_${pl.quarter.name}',
            title: '午饭同小息',
            body: '同班同学讨论边间小食好食，'
                '有人带妈妈整嘅便当。',
            choices: [
              EventChoice(
                label: '同大家分享',
                apply: (x) {
                  x.network = (x.network + 3).clamp(0, 100);
                  x.reputation = (x.reputation + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '自己食，温下书',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 1);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'primary_daily_parent_${pl.year}_${pl.quarter.name}',
            title: '家长日',
            body: '阿妈去开家长会，老师话你${pl.discipline >= 55 ? "表现不错" : "要加把劲"}。'
                '返到屋企有奖励或者唠叨。',
            choices: [
              EventChoice(
                label: '承诺会改进',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 2).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '话老师太严格',
                apply: (x) {
                  x.san = (x.san - 2).clamp(0, x.maxSan);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
            ],
          ),
    ];

    final idx = (_next + p.age * 11 + p.year + p.primaryScore) % pool.length;
    return pool[idx](p);
  }

  StoryEvent _primaryHomeworkEvent(Player p) => StoryEvent(
        id: 'primary_homework_${p.year}_${p.quarter.name}',
        title: '小學功課',
        body: '老師話呈分試就嚟，每日都有大量功課同 dictation。'
            '${p.homeDistrict.schoolNet.isNotEmpty ? " 你屬${p.homeDistrict.schoolNet}校網。" : ""}',
        choices: [
          EventChoice(
            label: '乖乖做晒啲功課',
            apply: (pl) {
              BirthGacha.applyStudyGain(pl, base: 3);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.san = (pl.san - 2).clamp(0, pl.maxSan);
              pl.primaryScore += 1;
            },
          ),
          EventChoice(
            label: '蛇王，抄同學答案',
            apply: (pl) {
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
              pl.discipline = (pl.discipline - 2).clamp(0, 100);
            },
          ),
          if (p.unlockedFlags.contains('specialized_cram_school'))
            EventChoice(
              label: '去補習社加強（屋企代付）',
              apply: (pl) {
                if (pl.wealth >= 3000) {
                  pl.wealth -= 3000;
                  BirthGacha.applyStudyGain(pl, base: 5);
                  pl.primaryScore += 3;
                  pl.unlockedFlags.add('ssa_cram_boost');
                } else if (FamilyAssets.familyPays(pl, 5000, reason: '補習社')) {
                  BirthGacha.applyStudyGain(pl, base: 5);
                  pl.primaryScore += 3;
                  pl.unlockedFlags.add('ssa_cram_boost');
                }
              },
            ),
        ],
      );

  StoryEvent _primaryLeisureEvent(Player p) => StoryEvent(
        id: 'primary_leisure_${p.year}_${p.quarter.name}',
        title: '放學後',
        body: '下晝放學，你可以揀補習定係去玩。',
        choices: [
          EventChoice(
            label: '去補習 / 做練習',
            apply: (pl) {
              BirthGacha.applyStudyGain(pl, base: 2);
              pl.primaryScore += 1;
            },
          ),
          EventChoice(
            label: '去球場/playground 玩',
            apply: (pl) {
              pl.san = (pl.san + 4).clamp(0, pl.maxSan);
              pl.hp = (pl.hp + 2).clamp(0, pl.maxHp);
              pl.network = (pl.network + 2).clamp(0, 100);
            },
          ),
        ],
      );

  List<StoryEvent> _primaryTierAndSsaEvents(Player p) {
    final events = <StoryEvent>[];

    if (p.unlockedFlags.contains('international_school') &&
        (p.age == 10 || p.age == 11) &&
        !p.unlockedFlags.contains('ssa_stay_international') &&
        !p.unlockedFlags.contains('ssa_force_local')) {
      events.insert(
        0,
        StoryEvent(
          id: 'ssr_secondary_path',
          title: '國際定本地？',
          body: '屋企商量：你而家讀國際小學，升中可以繼續 IB／國際學校，'
              '亦可以轉入本地資助／官立中學，跟呈分試同 SSA 統派。\n'
              '揀國際 → 唔使爭學位，之後考 IB；揀本地 → 要走完整升中，之後考 DSE。',
          choices: [
            EventChoice(
              label: '繼續國際學校（IB）',
              apply: (pl) {
                SsaFlow.chooseStayInternational(pl);
              },
            ),
            EventChoice(
              label: '轉入本地，搏 Band 1',
              apply: (pl) {
                SsaFlow.chooseForceLocal(pl);
              },
            ),
          ],
        ),
      );
    }

    // 小六：升中資訊／自行分配季（國際 SSR 未轉本地前唔參加）
    if (p.age == 11 &&
        (p.quarter == Quarter.q1 || p.quarter == Quarter.q2) &&
        !p.completedExams.contains('ssa_discretionary') &&
        !p.unlockedFlags.contains('ssa_stay_international') &&
        (!p.unlockedFlags.contains('international_school') ||
            p.unlockedFlags.contains('ssa_force_local')) &&
        _chance(70)) {
      final primary = HkSchoolData.getPrimaryById(p.primarySchoolId);
      final hasLink = primary?.hasFeederLink ?? false;
      final candidates = HkSchoolData.dpCandidates(p).take(2).toList();
      final c1 = candidates.isNotEmpty ? candidates[0].name : '區內 Band 1';
      final c2 = candidates.length > 1 ? candidates[1].name : '跨網名校';

      events.add(StoryEvent(
        id: 'ssa_dp_season',
        title: '自行分配學位季',
        body: '小六上學期：中學開始收自行分配申請（每生最多兩間）。\n'
            '你住${p.homeDistrict.label}（${p.homeDistrict.schoolNet}校網）。'
            '${hasLink ? "\n你小學有一條龍／聯繫中學，可以優先試。" : ""}\n'
            '熱門志願：$c1、$c2',
        choices: [
          if (hasLink)
            EventChoice(
              label: '搏一條龍／聯繫升中',
              apply: (pl) {
                pl.unlockedFlags.add('ssa_try_through_train');
                SsaFlow.completeDiscretionary(pl, tryThroughTrain: true);
              },
            ),
          EventChoice(
            label: '申請兩間中學面試',
            apply: (pl) {
              SsaFlow.completeDiscretionary(pl);
            },
          ),
          EventChoice(
            label: '唔申請，等統派',
            apply: (pl) {
              SsaFlow.completeDiscretionary(pl, skip: true);
            },
          ),
        ],
      ));
    }

    if (p.age == 11 && p.quarter == Quarter.q3 && _chance(40)) {
      events.add(StoryEvent(
        id: 'ssa_pre_central',
        title: '填統派志願',
        body: '教育局將發統一派位選擇表格：甲部可填最多 3 個跨網志願，'
            '乙部填本網（${p.homeDistrict.schoolNet}）學校。'
            '你目前估計呈分約 ${HkSchoolData.placementScore(p)}。',
        choices: [
          EventChoice(
            label: '搏甲部名校（跨網）',
            apply: (pl) {
              pl.unlockedFlags.add('ssa_prefer_part_a');
              pl.stress = (pl.stress + 3).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '穩陣填本網乙部',
            apply: (pl) {
              pl.unlockedFlags.add('ssa_prefer_part_b');
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    return events;
  }

  // ── 12-17 Secondary ──

  List<StoryEvent> _secondaryEvents(Player p) {
    if (IbPathway.isOnTrack(p)) return _ibSecondaryEvents(p);

    final events = <StoryEvent>[];

    final milestone = _secondaryMilestoneEvent(p);
    if (milestone != null) events.add(milestone);

    events.add(_secondaryDailyEvent(p));

    if (_chance(55)) {
      events.add(_secondaryBandPressureEvent(p));
    }

    if (p.schoolBand == SchoolBand.band3 && _chance(25)) {
      events.add(_goAstrayTeenEvent());
    }

    if (p.age >= 17 && _chance(70)) {
      events.add(_dsePressureEvent());
    }

    // 中三（14 歲）：每季必出理文卡，直至揀咗
    if (p.age == 14 &&
        p.streamAffinity == StreamAffinity.none &&
        !IbPathway.isOnTrack(p)) {
      events.insert(0, _streamAffinityEvent());
    }

    // 中三尾／中四（14–15）：選修科；未定理文會喺選科時保底
    if (p.age >= 14 &&
        p.age <= 15 &&
        !IbPathway.isOnTrack(p) &&
        !p.completedExams.contains('f4_electives')) {
      events.add(_electiveSelectionEvent(p));
    }

    return events;
  }

  StoryEvent electiveSelectionEventPublic(Player p) =>
      _electiveSelectionEvent(p);

  StoryEvent? _secondaryMilestoneEvent(Player p) {
    if (p.unlockedFlags.contains('secondary_just_enrolled') ||
        (p.age == 12 && !p.unlockedFlags.contains('secondary_first_day'))) {
      return StoryEvent(
        id: 'secondary_first_day',
        title: '升中開學',
        body: '12 歲，背着新书包入 ${p.jobTitle}。\n'
            '${p.schoolBand.secondaryLabel} · ${p.ssaBandGroup.label}\n'
            '${_bandFlavor(p)}',
        choices: [
          EventChoice(
            label: '同新同学打招呼',
            apply: (pl) {
              pl.unlockedFlags.add('secondary_first_day');
              pl.unlockedFlags.remove('secondary_just_enrolled');
              pl.network = (pl.network + 4).clamp(0, 100);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '低调观察，慢慢适应',
            apply: (pl) {
              pl.unlockedFlags.add('secondary_first_day');
              pl.unlockedFlags.remove('secondary_just_enrolled');
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
              pl.smarts = (pl.smarts + 1).clamp(0, 100);
            },
          ),
        ],
      );
    }

    if (p.age == 13 && !p.unlockedFlags.contains('secondary_clubs_intro')) {
      return StoryEvent(
        id: 'secondary_clubs_intro',
        title: '社团招新',
        body: '学校社团摆位：篮球、辩论、音乐、服务团……'
            '班主任话参与课外活动对升大学有帮助。',
        choices: [
          EventChoice(
            label: '报学术/服务类',
            apply: (pl) {
              pl.unlockedFlags.add('secondary_clubs_intro');
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
              pl.network = (pl.network + 2).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '报运动/艺术类',
            apply: (pl) {
              pl.unlockedFlags.add('secondary_clubs_intro');
              pl.hp = (pl.hp + 3).clamp(0, pl.maxHp);
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
            },
          ),
        ],
      );
    }

    if (p.age == 16 &&
        p.quarter == Quarter.q2 &&
        !p.unlockedFlags.contains('secondary_mock_dse')) {
      return StoryEvent(
        id: 'secondary_mock_dse',
        title: '模拟 DSE / 测评周',
        body: '学校搞模拟考，成绩会反映你而家 DSE 水平。'
            '选修：${ElectiveData.electivesLabel(p)}',
        choices: [
          EventChoice(
            label: '全力冲刺',
            apply: (pl) {
              pl.unlockedFlags.add('secondary_mock_dse');
              BirthGacha.applyStudyGain(pl, base: 5);
              pl.san = (pl.san - 4).clamp(0, pl.maxSan);
              pl.stress = (pl.stress + 5).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '当练习，唔好太大压力',
            apply: (pl) {
              pl.unlockedFlags.add('secondary_mock_dse');
              BirthGacha.applyStudyGain(pl, base: 2);
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
            },
          ),
        ],
      );
    }

    return null;
  }

  StoryEvent _secondaryDailyEvent(Player p) {
    final pool = <StoryEvent Function(Player)>[
      (pl) => StoryEvent(
            id: 'sec_daily_canteen_${pl.year}_${pl.quarter.name}',
            title: '午饭同小息',
            body: '饭堂排长龙，同学讨论测验同 Netflix。',
            choices: [
              EventChoice(
                label: '同同学倾计',
                apply: (x) {
                  x.network = (x.network + 3).clamp(0, 100);
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '一个人温书',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 2);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'sec_daily_phone_${pl.year}_${pl.quarter.name}',
            title: '手机被没收',
            body: '上课偷睇手机被老师捉到，要家长签名先还。',
            choices: [
              EventChoice(
                label: '认错，保证唔犯',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '觉得老师太严格',
                apply: (x) {
                  x.san = (x.san - 2).clamp(0, x.maxSan);
                  x.stress = (x.stress + 4).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'sec_daily_sports_${pl.year}_${pl.quarter.name}',
            title: '校际比赛',
            body: '体育节／校际赛，你可以上场或者做后勤。',
            choices: [
              EventChoice(
                label: '落场搏',
                apply: (x) {
                  x.hp = (x.hp + 3).clamp(0, x.maxHp);
                  x.network = (x.network + 3).clamp(0, 100);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '做啦啦队',
                apply: (x) {
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                  x.network = (x.network + 2).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'sec_daily_tutor_${pl.year}_${pl.quarter.name}',
            title: '补习班压力',
            body: '放學去补习社，导师话「DSE 唔系咁易」。',
            choices: [
              EventChoice(
                label: '认真听课',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 3);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '偷偷玩手机',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.discipline = (x.discipline - 2).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'sec_daily_volunteer_${pl.year}_${pl.quarter.name}',
            title: '义工服务',
            body: '学校安排社区服务时数，去老人院或者卖旗。',
            choices: [
              EventChoice(
                label: '用心做',
                apply: (x) {
                  x.reputation = (x.reputation + 3).clamp(0, 100);
                  x.network = (x.network + 2).clamp(0, 100);
                },
              ),
              EventChoice(
                label: 'hea hea 交差',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.discipline = (x.discipline - 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'sec_daily_rumor_${pl.year}_${pl.quarter.name}',
            title: '校园八卦',
            body: '同学之间流传恋爱同小圈子话题，'
                '你要决定参唔参与。',
            choices: [
              EventChoice(
                label: '保持距离，专注学业',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  BirthGacha.applyStudyGain(x, base: 1);
                },
              ),
              EventChoice(
                label: '同朋友八卦',
                apply: (x) {
                  x.network = (x.network + 4).clamp(0, 100);
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.stress = (x.stress + 2).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'sec_daily_parent_${pl.year}_${pl.quarter.name}',
            title: '家长日',
            body: '阿妈见完老师返嚟，${pl.discipline >= 55 ? "话你表现 OK" : "话要加把劲"}。'
                '屋企开始问你将来想读咩。',
            choices: [
              EventChoice(
                label: '承诺会努力',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '话有自己节奏',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.reputation = (x.reputation + 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'sec_daily_exam_${pl.year}_${pl.quarter.name}',
            title: '测验周',
            body: '连续几科小测，${pl.schoolBand == SchoolBand.band1 ? "竞争激烈" : "有人hea 有人搏"}。',
            choices: [
              EventChoice(
                label: '通宵温书',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 4);
                  x.san = (x.san - 4).clamp(0, x.maxSan);
                  x.hp = (x.hp - 2).clamp(0, x.maxHp);
                },
              ),
              EventChoice(
                label: '正常作息',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 2);
                  x.san = (x.san + 1).clamp(0, x.maxSan);
                },
              ),
            ],
          ),
    ];

    final idx = (_next + p.age * 13 + p.year + p.schoolBand.index) % pool.length;
    return pool[idx](p);
  }

  StoryEvent _secondaryBandPressureEvent(Player p) => StoryEvent(
        id: 'secondary_pressure_${p.year}_${p.quarter.name}',
        title: '${p.schoolBand.secondaryLabel} 日常',
        body: _bandFlavor(p),
        choices: [
          EventChoice(
            label: 'OT 溫書到凌晨',
            apply: (pl) {
              final base = pl.schoolBand == SchoolBand.band1 ? 5 : 3;
              final sanLoss = pl.schoolBand == SchoolBand.band1 ? 6 : 3;
              BirthGacha.applyStudyGain(pl, base: base);
              pl.san = (pl.san - sanLoss).clamp(0, pl.maxSan);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '蛇王，出街玩',
            apply: (pl) {
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
              if (pl.schoolBand == SchoolBand.band3) {
                pl.network = (pl.network + 3).clamp(0, 100);
              }
            },
          ),
        ],
      );

  StoryEvent _goAstrayTeenEvent() => StoryEvent(
        id: 'go_astray_teen',
        title: '走偏路誘惑',
        body: '同學話「唔使讀書，跟我去賺快錢」。你知唔係正路，但好吸引。',
        choices: [
          EventChoice(
            label: '跟佢哋去',
            apply: (pl) {
              pl.network = (pl.network + 4).clamp(0, 100);
              pl.wealth += 500;
              pl.unlockedFlags.add('teen_astray');
              if (_chance(20)) {
                pl.investigation = InvestigationStatus.police;
              }
            },
          ),
          EventChoice(
            label: '拒絕，繼續讀書',
            apply: (pl) {
              pl.discipline = (pl.discipline + 4).clamp(0, 100);
              BirthGacha.applyStudyGain(pl, base: 2);
            },
          ),
        ],
      );

  StoryEvent _dsePressureEvent() => StoryEvent(
        id: 'dse_pressure',
        title: 'DSE 備戰',
        body: 'DSE 就嚟，past paper 堆到天花板。成績取決於你多年積累。',
        choices: [
          EventChoice(
            label: '通宵 OT 衝刺',
            apply: (pl) {
              BirthGacha.applyStudyGain(pl, base: 4);
              pl.san = (pl.san - 6).clamp(0, pl.maxSan);
              pl.hp = (pl.hp - 3).clamp(0, pl.maxHp);
            },
          ),
          EventChoice(
            label: '適當休息，保持狀態',
            apply: (pl) {
              pl.san = (pl.san + 4).clamp(0, pl.maxSan);
            },
          ),
        ],
      );

  StoryEvent streamAffinityEventPublic() => _streamAffinityEvent();

  StoryEvent _streamAffinityEvent() => StoryEvent(
        id: 'stream_affinity',
        title: '【重要】理組定文組？',
        body: '中三要決定中四選科方向。\n'
            '揀理科：物理／化學／生物較易取錄。\n'
            '揀文科：歷史／地理／經濟／BAFS 較易取錄。\n'
            '唔揀都得——系統會按智慧自動保底，但對口科會難啲。',
        choices: [
          EventChoice(
            label: '走理科方向',
            apply: (pl) {
              pl.streamAffinity = StreamAffinity.science;
              pl.unlockedFlags.remove('stream_undecided');
              pl.eventLog.add('${pl.year}年：定為理科傾向。');
            },
          ),
          EventChoice(
            label: '走文科方向',
            apply: (pl) {
              pl.streamAffinity = StreamAffinity.arts;
              pl.unlockedFlags.remove('stream_undecided');
              pl.eventLog.add('${pl.year}年：定為文科傾向。');
            },
          ),
          EventChoice(
            label: '暫時未定（之後自動保底）',
            apply: (pl) {
              pl.unlockedFlags.add('stream_undecided');
              pl.eventLog.add('${pl.year}年：理文傾向未定，稍後保底。');
            },
          ),
        ],
      );

  StoryEvent _electiveSelectionEvent(Player p) {
    final max = ElectiveData.maxElectives(p);
    final pool = ElectiveData.poolForSchool(p.schoolBand)
        .where((s) => !p.electiveIds.contains(s.id))
        .toList()
      ..sort((a, b) {
        final am = a.category.matchesAffinity(p.streamAffinity) ? 0 : 1;
        final bm = b.category.matchesAffinity(p.streamAffinity) ? 0 : 1;
        if (am != bm) return am.compareTo(bm);
        return a.difficulty.compareTo(b.difficulty);
      });

    final current = ElectiveData.electivesLabel(p);
    final choices = <EventChoice>[];

    for (final sub in pool.take(6)) {
      choices.add(EventChoice(
        label: '申請：${sub.name}',
        apply: (pl) {
          ElectiveData.trySelect(pl, sub.id);
          if (pl.electiveIds.length >= ElectiveData.maxElectives(pl)) {
            ElectiveData.finalize(pl);
          }
        },
      ));
    }

    if (p.electiveIds.isNotEmpty) {
      choices.add(EventChoice(
        label: '完成選科（確認現有科目）',
        apply: (pl) => ElectiveData.finalize(pl),
      ));
    }

    choices.add(EventChoice(
      label: p.electiveIds.isEmpty ? '稍後再選' : '暫時唔再加科',
      apply: (pl) {
        if (pl.electiveIds.isNotEmpty) {
          ElectiveData.finalize(pl);
        }
      },
    ));

    final bandHint = switch (p.schoolBand) {
      SchoolBand.band1 =>
        '你校 Band 1：物化生／文商主流齊，另有 M1／M2、文學等強科；旅款等應用科較少開。',
      SchoolBand.band2 =>
        '你校 Band 2：主流理文商齊，多數有 M1／文學；旅款／健康管理等應用科較常見。',
      SchoolBand.band3 =>
        '你校 Band 3：物化生、史地、經濟 BAFS 等主流科都有；M1／M2／英文學同旅款多數冇。',
      SchoolBand.none => '',
    };

    return StoryEvent(
      id: 'f4_elective_pick',
      title: '中四選科（${p.electiveIds.length}/$max）',
      body: '可選 1–$max 科選修（按能力同學校 Band）。\n'
          '傾向：${p.streamAffinity.label} — 對口科目較易取錄。\n'
          '$bandHint\n'
          '目前：${p.electiveIds.isEmpty ? "未有" : current}',
      choices: choices,
    );
  }

  List<StoryEvent> _ibSecondaryEvents(Player p) {
    final events = <StoryEvent>[
      _ibDailyEvent(p),
    ];

    if ((p.age == 15 || p.age == 16) &&
        p.streamAffinity == StreamAffinity.none &&
        !p.completedExams.contains('ib_dp_subjects') &&
        _chance(70)) {
      events.add(StoryEvent(
        id: 'ib_stream',
        title: 'IB · HL 方向',
        body: '導師問你 DP 想偏理科 HL（Phy/Chem/Math）定文科 HL（Hist/Econ/Eng A）？\n'
            '傾向會提高對口套餐同科目 grade。',
        choices: [
          EventChoice(
            label: '理科 HL 方向',
            apply: (pl) {
              pl.streamAffinity = StreamAffinity.science;
              pl.eventLog.add('${pl.year}年：IB 定為理科 HL 傾向。');
            },
          ),
          EventChoice(
            label: '文科 HL 方向',
            apply: (pl) {
              pl.streamAffinity = StreamAffinity.arts;
              pl.eventLog.add('${pl.year}年：IB 定為文科 HL 傾向。');
            },
          ),
          EventChoice(
            label: '均衡／未定',
            apply: (pl) {
              pl.unlockedFlags.add('ib_stream_undecided');
            },
          ),
        ],
      ));
    }

    if (p.age == 16 &&
        !p.completedExams.contains('ib_dp_subjects') &&
        _chance(90)) {
      events.add(_ibDpSelectionEvent(p));
    }

    if (p.age >= 16 &&
        !p.unlockedFlags.contains('ib_ee_done') &&
        _chance(50)) {
      events.add(StoryEvent(
        id: 'ib_ee',
        title: 'Extended Essay',
        body: '要交 4000 字 EE，同 TOK 一齊影響核心加分（最多 +3）。',
        choices: [
          EventChoice(
            label: '認真做完 EE',
            apply: (pl) {
              BirthGacha.applyStudyGain(pl, base: 5);
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
              pl.san = (pl.san - 5).clamp(0, pl.maxSan);
              pl.unlockedFlags.add('ib_ee_done');
            },
          ),
          EventChoice(
            label: '抄網上資料應付',
            apply: (pl) {
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
              pl.discipline = (pl.discipline - 4).clamp(0, 100);
            },
          ),
        ],
      ));
    }

    if (p.age >= 16 && _chance(35)) {
      events.add(StoryEvent(
        id: 'ib_tok',
        title: 'TOK 展示',
        body: 'Theory of Knowledge exhibition／essay 影響核心加分。',
        choices: [
          EventChoice(
            label: '認真準備 presentation',
            apply: (pl) {
              BirthGacha.applyStudyGain(pl, base: 3);
              pl.network = (pl.network + 2).clamp(0, 100);
              pl.unlockedFlags.add('ib_tok_strong');
            },
          ),
          EventChoice(
            label: '臨場發揮算',
            apply: (pl) {
              pl.san = (pl.san + 2).clamp(0, pl.maxSan);
            },
          ),
        ],
      ));
    }

    if (p.age >= 17 &&
        p.completedExams.contains('ib_diploma') &&
        !p.completedExams.contains('ib_university') &&
        _chance(80)) {
      final choices = IbPathway.pathChoices(p);
      events.add(StoryEvent(
        id: 'ib_uni_choice',
        title: 'IB 放榜後 · 選大學',
        body:
            '你 IB ${p.ibScore}/45（${p.ibTier.label}）。\n'
            '${IbCurriculum.subjectsLabel(p)}\n'
            '海外升學暫時未開放；其餘路線可以揀。',
        choices: [
          for (final c in choices)
            EventChoice(
              label: c.label,
              enabled: c.enabled,
              apply: (pl) {
                if (!c.enabled) return;
                IbPathway.applyUniversityChoice(pl, c.path);
              },
            ),
        ],
      ));
    }

    return events;
  }

  StoryEvent _ibDailyEvent(Player p) {
    final pool = <StoryEvent Function(Player)>[
      (pl) => StoryEvent(
            id: 'ib_daily_ia_${pl.year}_${pl.quarter.name}',
            title: 'IB · IA / HL',
            body: pl.ibSubjectSlots.isNotEmpty
                ? 'DP：${IbCurriculum.subjectsLabel(pl)}\n赶 IA 截止日。'
                : '准备入 DP，要拣 6 科。',
            choices: [
              EventChoice(
                label: '赶 IA／温 HL 科',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 4);
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.san = (x.san - 4).clamp(0, x.maxSan);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '做 CAS 义工',
                apply: (x) {
                  x.network = (x.network + 3).clamp(0, 100);
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                  x.unlockedFlags.add('ib_cas_strong');
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'ib_daily_tok_${pl.year}_${pl.quarter.name}',
            title: 'TOK 讨论',
            body: 'Theory of Knowledge 课堂讨论「知识係咪绝对」。',
            choices: [
              EventChoice(
                label: '积极发言',
                apply: (x) {
                  x.smarts = (x.smarts + 2).clamp(0, 100);
                  x.reputation = (x.reputation + 2).clamp(0, 100);
                },
              ),
              EventChoice(
                label: 'hea hea 过关',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.discipline = (x.discipline - 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'ib_daily_beach_${pl.year}_${pl.quarter.name}',
            title: '国际学校生活',
            body: '同学约去海滩／party，英文环境比课堂更真实。',
            choices: [
              EventChoice(
                label: '去，练英文',
                apply: (x) {
                  x.network = (x.network + 4).clamp(0, 100);
                  x.smarts = (x.smarts + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '留喺度温书',
                apply: (x) {
                  BirthGacha.applyStudyGain(x, base: 3);
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'ib_daily_counsel_${pl.year}_${pl.quarter.name}',
            title: '升学顾问',
            body: '升学顾问讲 UCAS / 本地 Non-JUPAS 路线。',
            choices: [
              EventChoice(
                label: '认真规划',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '迟啲先谀',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                },
              ),
            ],
          ),
    ];
    final idx = (_next + p.age * 5 + p.year) % pool.length;
    return pool[idx](p);
  }

  StoryEvent _ibDpSelectionEvent(Player p) {
    final packs = IbCurriculum.packages.toList()
      ..sort((a, b) {
        final am = a.affinity == p.streamAffinity ? 0 : 1;
        final bm = b.affinity == p.streamAffinity ? 0 : 1;
        return am.compareTo(bm);
      });

    return StoryEvent(
      id: 'ib_dp_pick',
      title: 'IB DP 選科（6 科 · 3HL+3SL）',
      body: 'Diploma Programme 要選 6 科，通常 3 科 HL、3 科 SL，\n'
          '覆蓋 Group 1–5，Group 6 可用第二科學／人文代替。\n'
          '傾向：${p.streamAffinity.label} — 對口套餐較易獲批。',
      choices: [
        for (final pack in packs.take(5))
          EventChoice(
            label: pack.name,
            apply: (pl) => IbCurriculum.tryApplyPackage(pl, pack),
          ),
        EventChoice(
          label: '稍後再選',
          apply: (_) {},
        ),
      ],
    );
  }

  String _bandFlavor(Player p) => switch (p.schoolBand) {
        SchoolBand.band1 => '名校競爭好激烈，排名表貼喺告示板，壓力好大。',
        SchoolBand.band2 => '學校功課唔少，但仲算 manageable。',
        SchoolBand.band3 => '課堂有時比較鬆散，同學講緊邊度有好玩。',
        SchoolBand.none => '中學生活開始喇。',
      };

  // ── 18+ Adult ──

  List<StoryEvent> _adultEvents(Player p) {
    final events = <StoryEvent>[];

    events.addAll(UniversityLife.systemCards(p));

    if (!UniversityPathway.isStudyingBachelor(p)) {
      events.add(_adultDailyEvent(p));
      final adultMilestone = _adultMilestoneEvent(p);
      if (adultMilestone != null) events.add(adultMilestone);
    }

    // DSE 放榜後：交志願／Asso 兩手準備；等 Main Round 時仍可交留位費
    // defer 後：下屆 Q4 正式／Q1 逾期窗必彈；Q3＝Asso 夏天收生必彈
    if (JupasPathway.isLocalTrack(p) &&
        JupasPathway.shouldShowPostResultsPlanner(p)) {
      if (JupasPathway.isAwaitingDecision(p) ||
          JupasPathway.isAwaitingMainRound(p) ||
          JupasPathway.isDeferredReapplySeason(p) ||
          (p.quarter == Quarter.q3 &&
              (JupasPathway.canApplyAsso(p) ||
                  JupasPathway.canPayAssoDeposit(p)))) {
        events.add(_dsePostResultsEvent(p));
      } else if (JupasPathway.canEditJupasChoices(p) && _chance(25)) {
        events.add(_dsePostResultsEvent(p));
      } else if (JupasPathway.canApplyAsso(p) && _chance(20)) {
        events.add(_dsePostResultsEvent(p));
      }
    }

    final careerEv = CareerEvents.quarterlyEvent(
      p,
      Random(_seed ^ p.year ^ p.age),
    );
    if (careerEv != null) {
      events.add(careerEv);
    }
    final layoff = CareerEmployment.layoffEvent(
      p,
      Random(_seed ^ (p.year * 13) ^ p.jobPerformance),
    );
    if (layoff != null) {
      events.insert(0, layoff);
    }
    if (p.isEmployed && _chance(28)) {
      events.add(_officeOtEvent());
    }
    if (p.age >= HousingMarket.minAge &&
        !p.ownsFlat &&
        p.age >= 28 &&
        p.age < 65 &&
        _chance(22)) {
      events.add(_propertyEvent(p));
    }
    if (p.age >= 60) {
      events.add(_retirementEvent(p));
    }

    return events;
  }

  StoryEvent _adultDailyEvent(Player p) {
    final pool = <StoryEvent Function(Player)>[
      (pl) => StoryEvent(
            id: 'adult_mtr_${pl.year}_${pl.quarter.name}',
            title: '塞车 / 迫 MTR',
            body: '返工返学逼到贴门，迟到被老板／导师点名。',
            choices: [
              EventChoice(
                label: '道歉，之后早啲出门',
                apply: (x) {
                  x.discipline = (x.discipline + 2).clamp(0, 100);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '话系交通问题',
                apply: (x) {
                  x.san = (x.san - 1).clamp(0, x.maxSan);
                  x.reputation = (x.reputation - 1).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'adult_rent_${pl.year}_${pl.quarter.name}',
            title: '加租 / 租务',
            body: pl.renting && !pl.ownsFlat
                ? '业主话要加租，或者要交维修费。'
                : '屋企讨论水电煤同生活开支。',
            choices: [
              EventChoice(
                label: '节衣缩食',
                apply: (x) {
                  if (x.renting && x.wealth >= 2000) x.wealth -= 2000;
                  x.stress = (x.stress + 4).clamp(0, 100);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '同家人商量',
                apply: (x) {
                  x.network = (x.network + 2).clamp(0, 100);
                  if (FamilyAssets.requestFromFamily(x, 3000, reason: '生活开支')) {
                    x.stress = (x.stress + 2).clamp(0, 100);
                  }
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'adult_family_${pl.year}_${pl.quarter.name}',
            title: '家庭饭聚',
            body: '周末同家人食饭，长辈问「有冇对象」「几时升职」。',
            choices: [
              EventChoice(
                label: '耐心应付',
                apply: (x) {
                  x.network = (x.network + 2).clamp(0, 100);
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                  x.stress = (x.stress + 3).clamp(0, 100);
                },
              ),
              EventChoice(
                label: '早啲走',
                apply: (x) {
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                  x.stress = (x.stress + 2).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'adult_health_${pl.year}_${pl.quarter.name}',
            title: '身体检查',
            body: '成日OT／压力，开始腰酸背痛或者失眠。',
            choices: [
              EventChoice(
                label: '睇医生 / 做运动',
                apply: (x) {
                  if (x.wealth >= 800) x.wealth -= 800;
                  x.hp = (x.hp + 4).clamp(0, x.maxHp);
                  x.san = (x.san + 2).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '捱住先',
                apply: (x) {
                  x.hp = (x.hp - 3).clamp(0, x.maxHp);
                  x.stress = (x.stress + 4).clamp(0, 100);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'adult_colleague_${pl.year}_${pl.quarter.name}',
            title: '同事 / 朋友约饭',
            body: pl.isEmployed
                ? '同事约 Happy Hour，倾项目同办公室政治。'
                : '朋友约你出街，话介绍工作机会。',
            choices: [
              EventChoice(
                label: '去，扩展人脉',
                apply: (x) {
                  x.network = (x.network + 4).clamp(0, 100);
                  if (x.wealth >= 400) x.wealth -= 400;
                  x.san = (x.san + 3).clamp(0, x.maxSan);
                },
              ),
              EventChoice(
                label: '拒绝，休息',
                apply: (x) {
                  x.san = (x.san + 4).clamp(0, x.maxSan);
                },
              ),
            ],
          ),
      (pl) => StoryEvent(
            id: 'adult_side_${pl.year}_${pl.quarter.name}',
            title: '副业 / 进修诱惑',
            body: '有人介绍副业、考证或者再读书，'
                '要花时间同金钱。',
            choices: [
              EventChoice(
                label: '报名进修',
                apply: (x) {
                  if (x.wealth >= 5000) {
                    x.wealth -= 5000;
                    BirthGacha.applyStudyGain(x, base: 4);
                    x.network = (x.network + 2).clamp(0, 100);
                  }
                },
              ),
              EventChoice(
                label: '专注而家',
                apply: (x) {
                  x.discipline = (x.discipline + 1).clamp(0, 100);
                },
              ),
            ],
          ),
    ];
    final idx = (_next + p.age * 3 + p.year + (p.isEmployed ? 1 : 0)) % pool.length;
    return pool[idx](p);
  }

  StoryEvent? _adultMilestoneEvent(Player p) {
    if (p.isEmployed &&
        p.unlockedFlags.contains('career_just_hired') &&
        !p.unlockedFlags.contains('adult_first_job_seen')) {
      return StoryEvent(
        id: 'adult_first_job',
        title: '第一份工作',
        body: '正式入职场：${p.jobTitle}。\n'
            '试用期、KPI、同同事磨合一齐嚟。',
        choices: [
          EventChoice(
            label: '勤力做，留好印象',
            apply: (pl) {
              pl.unlockedFlags.add('adult_first_job_seen');
              pl.unlockedFlags.remove('career_just_hired');
              pl.jobPerformance = (pl.jobPerformance + 8).clamp(0, 100);
              pl.stress = (pl.stress + 4).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '观察环境先',
            apply: (pl) {
              pl.unlockedFlags.add('adult_first_job_seen');
              pl.unlockedFlags.remove('career_just_hired');
              pl.network = (pl.network + 3).clamp(0, 100);
            },
          ),
        ],
      );
    }

    if (p.age == 25 && !p.unlockedFlags.contains('adult_age_25')) {
      return StoryEvent(
        id: 'adult_age_25',
        title: '25 岁关口',
        body: '朋友陆续结婚、上车；你开始谂 career 同生活方向。',
        choices: [
          EventChoice(
            label: '设定目标，搏事业',
            apply: (pl) {
              pl.unlockedFlags.add('adult_age_25');
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
              pl.stress = (pl.stress + 4).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '享受当下',
            apply: (pl) {
              pl.unlockedFlags.add('adult_age_25');
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
            },
          ),
        ],
      );
    }

    return null;
  }

  StoryEvent dsePostResultsEventPublic(Player p) => _dsePostResultsEvent(p);

  StoryEvent _dsePostResultsEvent(Player p) {
    final grades = DseGradeGenerator.summaryLabel(p.dseGrades);
    final sitInfo = p.dseSittingCount > 1
        ? '已應考 ${p.dseSittingCount} 次；合計取各科最佳。\n'
            '神科課程對多次應考或略為不利。'
        : '首次放榜。成績無有效期；聯招會攞晒所有 sitting。';
    return StoryEvent(
      id: 'dse_jupas_choice',
      title: JupasPathway.isAwaitingMainRound(p)
          ? '等 Main Round · 兩手準備'
          : 'DSE 放榜 · 報 JUPAS／Asso',
      body:
          'Best5 合計：${p.dseBestScore}（${p.dseTier.label}）\n'
          '$grades\n'
          '$sitInfo\n'
          'JUPAS 志願：\n${JupasPathway.choicesLabel(p)}\n'
          '${p.assoHoldCode.isNotEmpty ? "Asso／HD：${p.assoHoldCode}${p.assoDepositPaid ? "（已交留位費）" : "（未交留位費）"}\n" : ""}'
          '報 JUPAS = 交志願；Q3 提交下季出結果，其餘等到下一個 Q3（夏天）；'
          'Asso 交留位只鎖位，出結果時再揀去向。'
          '系統唔會自動派位。',
      choices: JupasPathway.postResultsEventChoices(p),
    );
  }

  StoryEvent _officeOtEvent() => StoryEvent(
        id: 'office_ot',
        title: 'OT 文化',
        body: '老細話「今次 project 好重要，大家 OT 頂一頂」。',
        choices: [
          EventChoice(
            label: '留低 OT',
            apply: (pl) {
              pl.jobWorkedThisQuarter = true;
              pl.jobPerformance = (pl.jobPerformance + 6).clamp(0, 100);
              pl.hp = (pl.hp - 5).clamp(0, pl.maxHp);
              pl.san = (pl.san - 4).clamp(0, pl.maxSan);
              pl.discipline = (pl.discipline + 4).clamp(0, 100);
              pl.stress = (pl.stress + 6).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '蛇王，準時走佬',
            apply: (pl) {
              pl.san = (pl.san + 5).clamp(0, pl.maxSan);
              pl.jobPerformance = (pl.jobPerformance - 2).clamp(0, 100);
            },
          ),
        ],
      );

  StoryEvent _propertyEvent(Player p) => StoryEvent(
        id: 'property_decision',
        title: '上車機會',
        body: '經紀話有個細單位（屯門／荃灣一帶），'
            '首期＋印花要一筆；按揭要過 DSR。滿 ${HousingMarket.minAge} 歲先可以成交。',
        choices: [
          EventChoice(
            label: '搏一搏，睇細單位上車',
            apply: (pl) {
              if (pl.age < HousingMarket.minAge) {
                pl.eventLog.add(
                  '${pl.year}年：未滿 ${HousingMarket.minAge} 歲唔可以買樓。',
                );
                return;
              }
              final msg = HousingMarket.purchase(pl, 'tm_old');
              pl.eventLog.add('${pl.year}年：$msg');
            },
          ),
          EventChoice(
            label: '繼續租屋／住屋企',
            apply: (pl) {
              pl.san = (pl.san + 3).clamp(0, pl.maxSan);
            },
          ),
        ],
      );

  StoryEvent _retirementEvent(Player p) => StoryEvent(
        id: 'retirement',
        title: '退休抉擇',
        body: '你已經 ${p.age} 歲，身體話你知「唔好再咁搏」。',
        choices: [
          EventChoice(
            label: '再捱多幾年',
            apply: (pl) {
              pl.hp = (pl.hp - 10).clamp(0, pl.maxHp);
            },
          ),
          EventChoice(
            label: '退休享樂',
            apply: (pl) {
              pl.phase = GamePhase.retired;
              pl.san = (pl.san + 15).clamp(0, pl.maxSan);
            },
          ),
        ],
      );

  StoryEvent _investigationEvent(Player p) => StoryEvent(
        id: 'investigation',
        title: '調查來襲',
        body: switch (p.investigation) {
          InvestigationStatus.police => '差佬上門話要同你「傾吓計」。',
          InvestigationStatus.icac => 'ICAC 話想請你「飲杯咖啡」。',
          InvestigationStatus.court => '你收到傳票，要出庭應訊。',
          InvestigationStatus.convicted => '判決已下。',
          InvestigationStatus.none => '',
        },
        choices: [
          EventChoice(
            label: '配合調查',
            apply: (pl) {
              pl.san = (pl.san - 15).clamp(0, pl.maxSan);
              if (pl.investigation == InvestigationStatus.court &&
                  _chance(40)) {
                _enterPrison(pl);
              }
            },
          ),
          EventChoice(
            label: '搵律師',
            apply: (pl) {
              pl.wealth -= 50000;
              pl.san = (pl.san - 8).clamp(0, pl.maxSan);
            },
          ),
        ],
        isSystem: true,
      );

  StoryEvent _prisonEvent(Player p) => StoryEvent(
        id: 'prison_life',
        title: '監獄日常',
        body: '赤柱嘅日子一日似一日。',
        choices: [
          EventChoice(
            label: '喺監獄進修',
            apply: (pl) {
              BirthGacha.applyStudyGain(pl, base: 2);
              pl.discipline = (pl.discipline + 3).clamp(0, 100);
            },
          ),
          EventChoice(
            label: '同倉友混熟',
            apply: (pl) {
              pl.network = (pl.network + 2).clamp(0, 100);
            },
          ),
        ],
        isSystem: true,
      );

  void _enterPrison(Player player) {
    player.inPrison = true;
    player.phase = GamePhase.prison;
    player.prisonQuartersLeft = 8;
    player.hasCriminalRecord = true;
    player.investigation = InvestigationStatus.convicted;
    player.currentSector = CareerSector.none;
    player.jobTitle = '在囚';
  }

  StoryEvent? goAstrayEvent(Player player) {
    if (player.hasCriminalRecord || player.isChildhood) return null;
    if (player.schoolBand == SchoolBand.band3) {
      if (!_chance(20)) return null;
    } else {
      if (!_chance(10)) return null;
    }

    return StoryEvent(
      id: 'go_astray',
      title: '捷徑誘惑',
      body: '有人話有條「快錢路」，唔使咁辛苦。',
      choices: [
        EventChoice(
          label: '搏一搏，走捷徑',
          apply: (p) {
            p.wealth += 200000;
            p.investigation = _chance(60)
                ? InvestigationStatus.icac
                : InvestigationStatus.police;
            p.unlockedFlags.add('went_astray');
          },
        ),
        EventChoice(
          label: '拒絕，行正道',
          apply: (p) {
            p.reputation = (p.reputation + 5).clamp(0, 100);
            p.discipline = (p.discipline + 5).clamp(0, 100);
          },
        ),
      ],
    );
  }

  List<ChecklistExam> allExams(Player player) {
    final exams = <ChecklistExam>[
      ChecklistExam(
        id: 'ssr_secondary_path',
        title: '升中路線：國際 vs 本地',
        description:
            'SSR 專屬：了解升中選項。請於本季事件卡揀「國際（IB）」或「轉本地（SSA＋DSE）」。',
        requirements: [
          RequirementItem(
            label: '國際學校背景',
            check: (p) => p.unlockedFlags.contains('international_school'),
          ),
          RequirementItem(
            label: 'Age 10 或 11',
            check: (p) => p.age == 10 || p.age == 11,
          ),
          RequirementItem(
            label: '小學階段',
            check: (p) => p.lifeStage == LifeStage.primary,
          ),
          RequirementItem(
            label: '未決定路線',
            check: (p) =>
                !p.unlockedFlags.contains('ssa_stay_international') &&
                !p.unlockedFlags.contains('ssa_force_local'),
          ),
          RequirementItem(
            label: '未讀過簡介',
            check: (p) => !p.completedExams.contains('ssr_secondary_path_briefing'),
          ),
        ],
        onPass: (p) {
          p.completedExams.add('ssr_secondary_path_briefing');
          p.eventLog.add(
            '${p.year}年：已了解升中路線選項；'
            '請於事件卡揀國際（IB）或轉本地（SSA＋DSE）。',
          );
        },
        onFail: (p) {
          p.eventLog.add('${p.year}年：升中路線簡介未完成。');
        },
      ),
      ChecklistExam(
        id: 'ssa_discretionary',
        title: '自行分配學位申請',
        description:
            '小六上學期：向最多兩間中學申請自行分配（約三成學位）。'
            '可搏一條龍／聯繫，或面試名校。失敗則轉統一派位。',
        requirements: [
          RequirementItem(
            label: 'Age 11',
            check: (p) => p.age == 11,
          ),
          RequirementItem(
            label: '小學階段',
            check: (p) => p.lifeStage == LifeStage.primary,
          ),
          RequirementItem(
            label: 'Q1 或 Q2（自行分配季）',
            check: (p) => p.quarter == Quarter.q1 || p.quarter == Quarter.q2,
          ),
          RequirementItem(
            label: '未做過自行分配',
            check: (p) => !p.completedExams.contains('ssa_discretionary'),
          ),
          RequirementItem(
            label: '非國際繞過路線',
            check: (p) =>
                !p.unlockedFlags.contains('ssa_stay_international') &&
                (!p.unlockedFlags.contains('international_school') ||
                    p.unlockedFlags.contains('ssa_force_local')),
          ),
        ],
        onPass: (p) {
          final primary = HkSchoolData.getPrimaryById(p.primarySchoolId);
          final msg = SsaFlow.completeDiscretionary(
            p,
            tryThroughTrain: primary?.hasFeederLink ?? false,
          );
          p.eventLog.add('${p.year}年：自行分配結算 — $msg');
        },
        onFail: (p) {
          final msg = SsaFlow.completeDiscretionary(p, skip: true);
          p.eventLog.add('${p.year}年：$msg');
        },
      ),
      ChecklistExam(
        id: 'primary_stream_test',
        title: '統一派位放榜（SSA）',
        description:
            '呈分試折算 → Band 1／2／3 組別 → '
            '甲部跨網志願 → 乙部本網抽籤。'
            '若已獲自行分配／一條龍／國際路線，本輪只作確認。',
        requirements: [
          RequirementItem(
            label: 'Age 11',
            check: (p) => p.age == 11,
          ),
          RequirementItem(
            label: '小學階段',
            check: (p) => p.lifeStage == LifeStage.primary,
          ),
          RequirementItem(
            label: 'Q4（統派放榜季）',
            check: (p) => p.quarter == Quarter.q4,
          ),
          RequirementItem(
            label: '未完成統派',
            check: (p) => !p.completedExams.contains('primary_stream_test'),
          ),
        ],
        onPass: (p) {
          p.primaryScore += p.smarts ~/ 10;
          final msg = SsaFlow.completeAllocation(p);
          p.eventLog.add('${p.year}年：升中分配完成 — $msg');
        },
        onFail: (p) {
          p.primaryScore += p.smarts ~/ 20;
          final msg = SsaFlow.completeAllocation(p, missedExam: true);
          p.eventLog.add('${p.year}年：呈分欠佳／缺考 — $msg');
        },
      ),
      ChecklistExam(
        id: 'f4_electives',
        title: '中四選科確定',
        description:
            '按能力選 1–3 科選修。Band 愈高開科愈齊；'
            '理／文傾向提高對口科目取錄率。通過則按傾向自動配科。',
        requirements: [
          RequirementItem(
            label: 'Age 15（中四）',
            check: (p) => p.age == 15,
          ),
          RequirementItem(
            label: '本地中學路線',
            check: (p) => !IbPathway.isOnTrack(p),
          ),
          RequirementItem(
            label: '中學階段',
            check: (p) => p.lifeStage == LifeStage.secondary,
          ),
          RequirementItem(
            label: '未完成選科',
            check: (p) => !p.completedExams.contains('f4_electives'),
          ),
        ],
        onPass: (p) {
          if (p.streamAffinity == StreamAffinity.none) {
            // 未定傾向：按智慧偏向
            p.streamAffinity =
                p.smarts >= 55 ? StreamAffinity.science : StreamAffinity.arts;
          }
          ElectiveData.autoSelectPackage(p);
        },
        onFail: (p) {
          ElectiveData.finalize(p, forceMinimum: true);
        },
      ),
      ChecklistExam(
        id: 'dse_exam',
        title: 'DSE 公開考試',
        description:
            '香港中學文憑試。校內中六／重讀免費應考；'
            '出社會後自修生報考每季需 \$${JupasPathway.privateCandidateFee}。'
            '成績永久有效；聯招院校可見所有 sitting。',
        requirements: [
          RequirementItem(
            label: '考試窗口（Q3/Q4 · 校內或自修生）',
            check: (p) => JupasPathway.canSitDse(p),
          ),
          RequirementItem(
            label: '自修生須有報名費 \$${JupasPathway.privateCandidateFee}',
            check: (p) {
              if (!JupasPathway.canSitAsPrivateCandidate(p) ||
                  JupasPathway.isSchoolSitting(p)) {
                return true;
              }
              return p.wealth >= JupasPathway.privateCandidateFee;
            },
          ),
        ],
        onPass: (p) => JupasPathway.applySitting(p),
        onFail: (p) {
          JupasPathway.applySitting(p, missed: true);
          p.san = (p.san - 10).clamp(0, p.maxSan);
        },
      ),
      ChecklistExam(
        id: 'ib_dp_subjects',
        title: 'IB DP 選科確認（6 科）',
        description:
            '確認 Diploma Programme：6 科、通常 3HL+3SL。'
            '按理／文傾向自動配對口套餐。',
        requirements: [
          RequirementItem(
            label: '國際／IB 路線',
            check: (p) => IbPathway.isOnTrack(p),
          ),
          RequirementItem(
            label: 'Age 16（DP Year 1）',
            check: (p) => p.age == 16,
          ),
          RequirementItem(
            label: '未完成 DP 選科',
            check: (p) => !p.completedExams.contains('ib_dp_subjects'),
          ),
        ],
        onPass: (p) {
          if (p.streamAffinity == StreamAffinity.none) {
            p.streamAffinity =
                p.smarts >= 60 ? StreamAffinity.science : StreamAffinity.arts;
          }
          IbCurriculum.autoSelectPackage(p);
        },
        onFail: (p) {
          IbCurriculum.autoSelectPackage(p);
        },
      ),
      ChecklistExam(
        id: 'ib_diploma',
        title: 'IB Diploma 考試',
        description:
            '六科各 1–7 分 + TOK/EE 核心加分（最多 +3）= 滿分 45。'
            'Diploma 要求約 ≥24、HL 合計足夠、無 1 分。',
        requirements: [
          RequirementItem(
            label: '國際／IB 路線',
            check: (p) => IbPathway.isOnTrack(p),
          ),
          RequirementItem(
            label: 'Age 17 or 18',
            check: (p) => p.age == 17 || p.age == 18,
          ),
          RequirementItem(
            label: 'Q2–Q4（IB 放榜季）',
            check: (p) =>
                p.quarter == Quarter.q2 ||
                p.quarter == Quarter.q3 ||
                p.quarter == Quarter.q4,
          ),
          RequirementItem(
            label: '未考過 IB',
            check: (p) => !p.completedExams.contains('ib_diploma'),
          ),
        ],
        onPass: (p) {
          IbPathway.applyDiplomaResult(p);
        },
        onFail: (p) {
          IbPathway.applyDiplomaResult(p, missed: true);
          p.san = (p.san - 8).clamp(0, p.maxSan);
        },
      ),
      ChecklistExam(
        id: 'ib_university',
        title: 'IB 升學申請（非聯招／海外）',
        description:
            '用 IB 成績申請本地非聯招／Foundation／就業。'
            '海外升學暫時未開放。',
        requirements: [
          RequirementItem(
            label: '已考 IB Diploma',
            check: (p) => p.completedExams.contains('ib_diploma'),
          ),
          RequirementItem(
            label: '未選定升學',
            check: (p) => !p.completedExams.contains('ib_university'),
          ),
          RequirementItem(
            label: 'Age >= 17',
            check: (p) => p.age >= 17,
          ),
        ],
        onPass: (p) {
          final path = p.ibTier == IbTier.fail
              ? IbUniPath.foundation
              : IbUniPath.localNonJupas;
          IbPathway.applyUniversityChoice(p, path);
        },
        onFail: (p) {
          IbPathway.applyUniversityChoice(p, IbUniPath.work);
        },
      ),
      ChecklistExam(
        id: 'jre_exam',
        title: 'JRE 聯合招聘考試',
        description: '公務員 JRE，秋季舉行。',
        requirements: [
          RequirementItem(
            label: '大學已畢業',
            check: (p) => p.unlockedFlags.contains('bachelor_graduated'),
          ),
          RequirementItem(
            label: 'Smarts >= 60',
            check: (p) => p.smarts >= 60,
          ),
          RequirementItem(
            label: 'No criminal record',
            check: (p) => !p.hasCriminalRecord,
          ),
          RequirementItem(
            label: 'Autumn (Q3)',
            check: (p) => p.quarter == Quarter.q3,
          ),
          RequirementItem(
            label: 'Age >= 21',
            check: (p) => p.age >= 21,
          ),
        ],
        onPass: (p) {
          p.completedExams.add('jre_exam');
          p.unlockedFlags.add('jre_passed');
          p.eventLog.add('${p.year}年：JRE 合格。');
        },
        onFail: (p) {
          p.san = (p.san - 8).clamp(0, p.maxSan);
          p.eventLog.add('${p.year}年：JRE 不合格。');
        },
      ),
      ChecklistExam(
        id: 'pcee_exam',
        title: 'CRE 綜合招聘考試',
        description: '公務員 CRE，學歷要求較低。',
        requirements: [
          RequirementItem(
            label: 'F5 or above',
            check: (p) => p.education.index >= EducationLevel.f5.index,
          ),
          RequirementItem(
            label: 'Smarts >= 45',
            check: (p) => p.smarts >= 45,
          ),
          RequirementItem(
            label: 'No criminal record',
            check: (p) => !p.hasCriminalRecord,
          ),
          RequirementItem(
            label: 'Age >= 18',
            check: (p) => p.age >= 18,
          ),
        ],
        onPass: (p) {
          p.completedExams.add('pcee_exam');
          p.unlockedFlags.add('cre_passed');
          p.eventLog.add('${p.year}年：CRE 合格。');
        },
      ),
      ChecklistExam(
        id: 'pupillage',
        title: '大律師 Pupillage',
        description: '法律系畢業生必經之路。',
        requirements: [
          RequirementItem(
            label: 'Law degree flag',
            check: (p) => p.unlockedFlags.contains('law_degree'),
          ),
          RequirementItem(
            label: 'Smarts（辯論學會舊生 ≥65，否則 ≥70）',
            check: (p) =>
                p.smarts >= UniversitySocieties.pupillageSmartsNeed(p),
          ),
          RequirementItem(
            label: 'No criminal record',
            check: (p) => !p.hasCriminalRecord,
          ),
        ],
        onPass: (p) {
          p.completedExams.add('pupillage');
          p.unlockedFlags.add('pupillage_passed');
          p.eventLog.add('${p.year}年：取得 Pupillage。');
        },
      ),
      ChecklistExam(
        id: 'ha_intern',
        title: 'HA 實習醫生招聘',
        description: '醫管局公開招聘。',
        requirements: [
          RequirementItem(
            label: 'Medical degree flag',
            check: (p) => p.unlockedFlags.contains('med_degree'),
          ),
          RequirementItem(
            label: 'Smarts >= 75',
            check: (p) => p.smarts >= 75,
          ),
          RequirementItem(
            label: 'No criminal record',
            check: (p) => !p.hasCriminalRecord,
          ),
        ],
        onPass: (p) {
          p.completedExams.add('ha_intern');
          p.unlockedFlags.add('ha_intern_passed');
          p.eventLog.add('${p.year}年：HA 取錄。');
        },
      ),
      ChecklistExam(
        id: 'tvb_audition',
        title: 'TVB 訓練班試鏡',
        description: '秋季 audition。',
        requirements: [
          RequirementItem(
            label: 'Age <= 30',
            check: (p) => p.age <= 30,
          ),
          RequirementItem(
            label: 'Autumn (Q3)',
            check: (p) => p.quarter == Quarter.q3,
          ),
          RequirementItem(
            label: 'Network（編輯會／門檻見學會）',
            check: (p) =>
                p.network >= UniversitySocieties.tvbNetworkNeed(p),
          ),
          RequirementItem(
            label: '名望／面子',
            check: (p) =>
                p.reputation >= UniversitySocieties.tvbReputationNeed(p),
          ),
        ],
        onPass: (p) {
          p.completedExams.add('tvb_audition');
          p.unlockedFlags.add('tvb_passed');
          p.eventLog.add('${p.year}年：TVB 取錄。');
        },
      ),
      ChecklistExam(
        id: 'taxi_license',
        title: '的士駕駛執照',
        description: '運輸署筆試及路試。',
        requirements: [
          RequirementItem(
            label: 'Age >= 21',
            check: (p) => p.age >= 21,
          ),
          RequirementItem(
            label: 'Wealth >= 5000',
            check: (p) => p.wealth >= 5000,
          ),
        ],
        onPass: (p) {
          p.completedExams.add('taxi_license');
          p.unlockedFlags.add('taxi_license');
          p.wealth -= 5000;
          p.eventLog.add('${p.year}年：取得的士牌。');
        },
      ),
      ChecklistExam(
        id: 'legco_election',
        title: '立法會選舉',
        description: '參選立法會議員。',
        requirements: [
          RequirementItem(
            label: 'Age >= 21',
            check: (p) => p.age >= 21,
          ),
          RequirementItem(
            label: 'No criminal record',
            check: (p) => !p.hasCriminalRecord,
          ),
          RequirementItem(
            label: 'Network >= 50',
            check: (p) => p.network >= 50,
          ),
          RequirementItem(
            label: 'Wealth >= 100000',
            check: (p) => p.wealth >= 100000,
          ),
          RequirementItem(
            label: 'Q4',
            check: (p) => p.quarter == Quarter.q4,
          ),
        ],
        onPass: (p) {
          p.completedExams.add('legco_election');
          p.wealth -= 100000;
          p.reputation = (p.reputation + 15).clamp(0, 100);
          CareerData.enterCareer(p, CareerSector.politics, rank: 2);
          p.eventLog.add('${p.year}年：當選立法會議員！');
        },
        onFail: (p) {
          p.wealth -= 100000;
          p.reputation = (p.reputation - 10).clamp(0, 100);
        },
      ),
    ];

    exams.addAll(CareerExams.all());

    return exams;
  }

  /// Only show when ALL requirements fully met.
  List<ChecklistExam> eligibleExams(Player player) {
    return allExams(player).where((exam) {
      // 童年唔顯示職業牌照試（護士／IIQE 等）
      if (CareerExams.isCareerExam(exam.id) &&
          (player.age < 18 || player.isChildhood)) {
        return false;
      }
      // DSE 可多次應考（校內重讀／出社會自修生），唔因舊紀錄永久隱藏
      if (player.completedExams.contains(exam.id)) {
        if (exam.id == 'dse_exam' && JupasPathway.canSitDse(player)) {
          // allow
        } else {
          return false;
        }
      }
      return exam.evaluate(player).every((r) => r);
    }).toList();
  }
}
