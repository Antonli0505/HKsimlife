import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'luck_modifiers.dart';

enum FriendSource {
  classmate,
  neighbour,
  club,
  church,
  uni,
  work,
  bar,
  random,
}

extension FriendSourceExt on FriendSource {
  String get label => switch (this) {
        FriendSource.classmate => '同學',
        FriendSource.neighbour => '鄰居',
        FriendSource.club => '社團',
        FriendSource.church => '教會',
        FriendSource.uni => '大學',
        FriendSource.work => '職場',
        FriendSource.bar => '社交場合',
        FriendSource.random => '偶遇',
      };
}

class SocialFriend {
  final String id;
  String nameZh;
  FriendSource source;
  int affinity;
  int metAge;
  int metYear;
  bool isPartner;

  SocialFriend({
    required this.id,
    required this.nameZh,
    required this.source,
    this.affinity = 15,
    required this.metAge,
    required this.metYear,
    this.isPartner = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameZh': nameZh,
        'source': source.name,
        'affinity': affinity,
        'metAge': metAge,
        'metYear': metYear,
        'isPartner': isPartner,
      };

  factory SocialFriend.fromJson(Map<String, dynamic> json) => SocialFriend(
        id: json['id'] as String? ?? 'f0',
        nameZh: json['nameZh'] as String? ?? '朋友',
        source: FriendSource.values.byName(
          json['source'] as String? ?? 'random',
        ),
        affinity: (json['affinity'] as int?) ?? 15,
        metAge: (json['metAge'] as int?) ?? 0,
        metYear: (json['metYear'] as int?) ?? 2008,
        isPartner: json['isPartner'] as bool? ?? false,
      );

  String get affinityBand {
    if (affinity >= 80) return '非常親密';
    if (affinity >= 60) return '可表白／親密';
    if (affinity >= 30) return '好友';
    return '認識';
  }
}

/// 朋友好感度／拍拖系統
abstract final class SocialCircle {
  static const maxFriends = 6;
  static const confessMinAffinity = 60;
  static const datingMinAge = 15;
  static const datingSmartsPenalty = 3;

  static const _meetFlagPrefix = 'social_met_q_';
  static const _datedFlag = 'social_dated_this_q';
  static const _harshFlag = 'social_harsh_study_q';
  static const _idlePrefix = 'partner_idle_';

  static SocialFriend? partnerOf(Player p) {
    for (final f in p.friends) {
      if (f.isPartner) return f;
    }
    return null;
  }

  static bool isDating(Player p) => partnerOf(p) != null;

  static SocialFriend? byId(Player p, String id) {
    for (final f in p.friends) {
      if (f.id == id) return f;
    }
    return null;
  }

  static void clearPartners(Player p) {
    for (final f in p.friends) {
      f.isPartner = false;
    }
  }

  static int _idleQuarters(Player p) {
    for (final f in p.unlockedFlags) {
      if (f.startsWith(_idlePrefix)) {
        return int.tryParse(f.substring(_idlePrefix.length)) ?? 0;
      }
    }
    return 0;
  }

  static void _setIdleQuarters(Player p, int n) {
    p.unlockedFlags.removeWhere((f) => f.startsWith(_idlePrefix));
    p.unlockedFlags.add('$_idlePrefix$n');
  }

  static void markDatedThisQuarter(Player p) {
    p.unlockedFlags.add(_datedFlag);
    _setIdleQuarters(p, 0);
  }

  static void markHarshStudy(Player p) {
    if (isDating(p)) p.unlockedFlags.add(_harshFlag);
  }

  static bool _alreadyMetThisQuarter(Player p) =>
      p.unlockedFlags.contains('$_meetFlagPrefix${p.year}_${p.quarter.name}');

  static void _markMetThisQuarter(Player p) {
    p.unlockedFlags
        .removeWhere((f) => f.startsWith(_meetFlagPrefix));
    p.unlockedFlags.add('$_meetFlagPrefix${p.year}_${p.quarter.name}');
  }

  static Random _rng(Player p, [int salt = 0]) =>
      Random(p.year * 97 + p.age * 13 + p.friends.length * 7 + salt);

  // ── Names ──────────────────────────────────────────────

  static const _namesR = [
    '阿傑', '小雯', '志明', '嘉欣', '偉豪', '詠珊', '家輝', '美玲',
    '志強', '慧敏', '國榮', '麗萍', '文傑', '曉彤', '俊傑', '詩詩',
  ];
  static const _namesSr = [
    'Jason', 'Cindy', 'Ryan', 'Amy', 'Kelvin', 'Joyce', 'Brian', 'Yvonne',
    'Eric', 'Michelle', 'Chris', 'Natalie', 'Derek', 'Cherry', 'Sam', 'Iris',
  ];
  static const _namesSsr = [
    'Adrian', 'Chloe', 'Sebastian', 'Isabelle', 'Nathan', 'Olivia',
    'Marcus', 'Sophia', 'Julian', 'Emma', 'Lucas', 'Ava',
  ];

  static List<String> _namePool(Player p) => switch (p.birthTier) {
        BirthTier.ssr => _namesSsr,
        BirthTier.sr => [..._namesSr, ..._namesR.take(6)],
        BirthTier.r => _namesR,
      };

  static String _pickName(Player p, Random rng) {
    final used = p.friends.map((f) => f.nameZh).toSet();
    final pool = _namePool(p).where((n) => !used.contains(n)).toList();
    if (pool.isEmpty) {
      return '朋友${p.friends.length + 1}';
    }
    return pool[rng.nextInt(pool.length)];
  }

  // ── Meet ───────────────────────────────────────────────

  /// 嘗試識朋友；成功回傳訊息，否則 null
  static String? tryMeet(
    Player p,
    FriendSource source, {
    double baseChance = 0.35,
    bool ignoreQuarterCap = false,
    int? affinityOverride,
  }) {
    if (p.age < 6) return null;
    if (p.friends.length >= maxFriends) return null;
    if (!ignoreQuarterCap && _alreadyMetThisQuarter(p)) return null;

    var chance = baseChance;
    chance += (p.network - 40) * 0.004;
    chance += switch (p.birthTier) {
      BirthTier.ssr => 0.08,
      BirthTier.sr => 0.03,
      BirthTier.r => 0.0,
    };
    if (p.schoolBand == SchoolBand.band1) chance += 0.05;
    chance = chance.clamp(0.08, 0.75);

    final rng = _rng(p, source.index * 31);
    if (baseChance < 1.0 && !LuckModifiers.roll(p, chance, rng)) {
      return null;
    }

    var affinity = affinityOverride ?? (12 + rng.nextInt(10));
    if (affinityOverride == null) {
      affinity += switch (p.birthTier) {
        BirthTier.ssr => 5,
        BirthTier.sr => 2,
        BirthTier.r => 0,
      };
      if (source == FriendSource.classmate || source == FriendSource.club) {
        affinity += 3;
      }
      affinity = affinity.clamp(8, 35);
    } else {
      affinity = affinity.clamp(0, 100);
    }

    final friend = SocialFriend(
      id: 'f_${p.year}_${p.quarter.name}_${p.friends.length}_${rng.nextInt(9999)}',
      nameZh: _pickName(p, rng),
      source: source,
      affinity: affinity,
      metAge: p.age,
      metYear: p.year,
    );
    p.friends.add(friend);
    if (!ignoreQuarterCap) _markMetThisQuarter(p);
    p.network = (p.network + 1).clamp(0, 100);
    p.eventLog.add(
      '${p.year}年：識咗新朋友 ${friend.nameZh}（${friend.source.label}）'
      '· 好感 ${friend.affinity}',
    );
    return '識咗新朋友：${friend.nameZh}\n'
        '來源：${friend.source.label} · 好感 ${friend.affinity}';
  }

  // ── Interactions ───────────────────────────────────────

  static String hangOut(Player p, String friendId) {
    final f = byId(p, friendId);
    if (f == null) return '搵唔到呢個朋友。';

    final rng = _rng(p, friendId.hashCode);
    var gain = 6 + rng.nextInt(7);
    if (f.affinity >= 30) gain += 2;
    if (f.isPartner) gain += 1;

    f.affinity = (f.affinity + gain).clamp(0, 100);
    p.san = (p.san + 2 + rng.nextInt(4)).clamp(0, p.maxSan);
    p.stress = (p.stress - (1 + rng.nextInt(3))).clamp(0, 100);
    p.network = (p.network + (f.affinity >= 30 ? 2 : 1)).clamp(0, 100);

    final cost = p.lifeStage == LifeStage.adult
        ? 100 + rng.nextInt(400)
        : (p.age >= 15 ? 50 + rng.nextInt(150) : 0);
    if (cost > 0 && p.wealth >= cost) {
      p.wealth -= cost;
    } else if (cost > 0 && p.age < 18 && p.livesWithFamily) {
      // 童年：可能屋企代付，唔扣個人
    } else if (cost > 0 && p.wealth < cost) {
      p.san = (p.san - 1).clamp(0, p.maxSan);
    }

    if (f.isPartner) markDatedThisQuarter(p);

    final msg =
        '同 ${f.nameZh} 出街傾偈：好感 +$gain（而家 ${f.affinity}）'
        '${cost > 0 && p.lifeStage == LifeStage.adult ? " · 花咗 \$$cost" : ""}';
    p.eventLog.add('${p.year}年：$msg');
    return msg;
  }

  static String gift(Player p, String friendId) {
    final f = byId(p, friendId);
    if (f == null) return '搵唔到呢個朋友。';

    final cost = switch (p.birthTier) {
      BirthTier.ssr => 2000 + _rng(p).nextInt(1001),
      BirthTier.sr => 1000 + _rng(p).nextInt(801),
      BirthTier.r => 400 + _rng(p).nextInt(401),
    };
    if (p.wealth < cost) {
      return '現金唔夠請食飯／送禮（要約 \$$cost）。';
    }
    p.wealth -= cost;
    final gain = 10 + _rng(p, 3).nextInt(9);
    f.affinity = (f.affinity + gain).clamp(0, 100);
    p.san = (p.san + 1).clamp(0, p.maxSan);
    p.stress = (p.stress - 2).clamp(0, 100);
    p.network = (p.network + 1).clamp(0, 100);
    if (f.isPartner) markDatedThisQuarter(p);

    final msg =
        '請 ${f.nameZh} 食飯／送禮 \$$cost：好感 +$gain（而家 ${f.affinity}）';
    p.eventLog.add('${p.year}年：$msg');
    return msg;
  }

  static String confess(Player p, String friendId) {
    final f = byId(p, friendId);
    if (f == null) return '搵唔到呢個朋友。';
    if (p.age < datingMinAge) {
      return '未滿 $datingMinAge 歲，暫時唔開放拍拖。';
    }
    if (isDating(p)) return '你已經拍緊拖，唔可以同時多角。';
    if (f.affinity < confessMinAffinity) {
      return '好感未夠（要 ≥$confessMinAffinity，而家 ${f.affinity}）。';
    }

    var chance = 0.35 + (f.affinity - confessMinAffinity) * 0.012;
    chance += (p.network - 40) * 0.003;
    chance += (p.san - 50) * 0.002;
    chance = chance.clamp(0.2, 0.88);

    if (LuckModifiers.roll(p, chance, _rng(p, 17))) {
      clearPartners(p);
      f.isPartner = true;
      _setIdleQuarters(p, 0);
      p.network = (p.network + 3).clamp(0, 100);
      p.san = (p.san + 8).clamp(0, p.maxSan);
      p.stress = (p.stress - 5).clamp(0, 100);
      p.eventLog.add(
        '${p.year}年：同 ${f.nameZh} 拍拖成功！'
        '（每季智慧 −$datingSmartsPenalty）',
      );
      return '表白成功！\n你同 ${f.nameZh} 開始拍拖。\n'
          '注意：拍拖中每季智慧 −$datingSmartsPenalty。';
    }

    f.affinity = (f.affinity - 15).clamp(0, 100);
    p.san = (p.san - 8).clamp(0, p.maxSan);
    p.stress = (p.stress + 8).clamp(0, 100);
    p.eventLog.add(
      '${p.year}年：向 ${f.nameZh} 表白失敗（好感而家 ${f.affinity}）。',
    );
    return '表白失敗……\n${f.nameZh} 好感 −15（而家 ${f.affinity}）';
  }

  static String datePartner(Player p) {
    final f = partnerOf(p);
    if (f == null) return '你而家冇拍緊拖。';

    final fight = p.san <= 20 || p.stress >= 80;
    final cost = switch (p.birthTier) {
      BirthTier.ssr => 800 + _rng(p).nextInt(1200),
      BirthTier.sr => 400 + _rng(p).nextInt(600),
      BirthTier.r => 150 + _rng(p).nextInt(250),
    };

    if (fight && LuckModifiers.roll(p, 0.45, _rng(p, 9))) {
      f.affinity = (f.affinity - 8).clamp(0, 100);
      p.san = (p.san - 4).clamp(0, p.maxSan);
      p.stress = (p.stress + 5).clamp(0, 100);
      markDatedThisQuarter(p);
      final msg =
          '同 ${f.nameZh} 約會變咗吵交：好感 −8（而家 ${f.affinity}）';
      p.eventLog.add('${p.year}年：$msg');
      return msg;
    }

    if (p.wealth >= cost) p.wealth -= cost;
    var gain = 5 + _rng(p).nextInt(6);
    if (f.affinity >= 80) gain += 2;
    f.affinity = (f.affinity + gain).clamp(0, 100);
    p.san = (p.san + 4).clamp(0, p.maxSan);
    p.stress = (p.stress - 4).clamp(0, 100);
    p.network = (p.network + 1).clamp(0, 100);
    markDatedThisQuarter(p);

    final msg =
        '同 ${f.nameZh} 約會：好感 +$gain（而家 ${f.affinity}）· 花 \$$cost';
    p.eventLog.add('${p.year}年：$msg');
    return msg;
  }

  static String breakUp(Player p) {
    final f = partnerOf(p);
    if (f == null) return '你而家冇拍緊拖。';
    f.isPartner = false;
    final dropTo = f.affinity >= 80 ? 35 : 40;
    f.affinity = dropTo;
    p.san = (p.san - 10).clamp(0, p.maxSan);
    p.stress = (p.stress + 10).clamp(0, 100);
    p.network = (p.network - 2).clamp(0, 100);
    _setIdleQuarters(p, 0);
    p.unlockedFlags.remove(_datedFlag);
    p.eventLog.add('${p.year}年：同 ${f.nameZh} 分手（好感降至 ${f.affinity}）。');
    return '已同 ${f.nameZh} 分手。\n好感降至 ${f.affinity}';
  }

  // ── Events (pick friend) ───────────────────────────────

  static StoryEvent pickFriendEvent(
    Player p, {
    required String id,
    required String title,
    required String body,
    required String Function(Player, String friendId) onPick,
    bool Function(SocialFriend)? filter,
  }) {
    final list = p.friends.where(filter ?? (_) => true).toList();
    return StoryEvent(
      id: id,
      title: title,
      body: body,
      choices: [
        for (final f in list)
          EventChoice(
            label: '${f.isPartner ? "♥ " : ""}'
                '${f.nameZh}（${f.source.label} · 好感 ${f.affinity}）',
            apply: (pl) => onPick(pl, f.id),
          ),
        EventChoice(
          label: '取消',
          apply: (_) {},
        ),
      ],
    );
  }

  static StoryEvent hangOutPicker(Player p) => pickFriendEvent(
        p,
        id: 'social_hang_pick',
        title: '約邊個出街？',
        body: '揀一個朋友傾偈／出街（好感會上升）。',
        onPick: hangOut,
      );

  static StoryEvent giftPicker(Player p) => pickFriendEvent(
        p,
        id: 'social_gift_pick',
        title: '請邊個食飯／送禮？',
        body: '花費睇出身；好感升幅較大。',
        onPick: gift,
      );

  static StoryEvent confessPicker(Player p) => pickFriendEvent(
        p,
        id: 'social_confess_pick',
        title: '向邊個表白？',
        body: '好感要 ≥$confessMinAffinity，年齡 ≥$datingMinAge；'
            '同時只可以拍一個。拍拖後每季智慧 −$datingSmartsPenalty。',
        filter: (f) =>
            !f.isPartner && f.affinity >= confessMinAffinity,
        onPick: confess,
      );

  // ── Quarterly tick ─────────────────────────────────────

  static String? tickQuarter(Player p) {
    final msgs = <String>[];

    // Clear per-quarter meet spam across year boundary handled by key

    final partner = partnerOf(p);
    if (partner != null) {
      p.smarts = (p.smarts - datingSmartsPenalty).clamp(0, 100);
      p.san = (p.san + 2).clamp(0, p.maxSan);
      p.stress = (p.stress - 2).clamp(0, 100);
      msgs.add(
        '拍拖分心：智慧 −$datingSmartsPenalty'
        '（伴侶：${partner.nameZh}）· 神智 +2、壓力 −2',
      );
      p.eventLog.add(
        '${p.year}年：拍拖中智慧 −$datingSmartsPenalty（${partner.nameZh}）。',
      );

      if (p.unlockedFlags.contains(_harshFlag)) {
        partner.affinity = (partner.affinity - 3).clamp(0, 100);
        msgs.add('狂溫書冷落伴侶：${partner.nameZh} 好感 −3');
        p.unlockedFlags.remove(_harshFlag);
      }

      if (p.unlockedFlags.contains(_datedFlag)) {
        p.unlockedFlags.remove(_datedFlag);
        _setIdleQuarters(p, 0);
      } else {
        final idle = _idleQuarters(p) + 1;
        _setIdleQuarters(p, idle);
        if (idle >= 2) {
          partner.affinity = (partner.affinity - 5).clamp(0, 100);
          msgs.add(
            '疏離：連續 $idle 季冇約會／關心 → '
            '${partner.nameZh} 好感 −5（而家 ${partner.affinity}）',
          );
        }
      }
    } else {
      p.unlockedFlags.remove(_datedFlag);
      p.unlockedFlags.remove(_harshFlag);
      _setIdleQuarters(p, 0);
    }

    // Friends network drip
    final closeFriends =
        p.friends.where((f) => f.affinity >= 30 && !f.isPartner).length;
    if (closeFriends > 0 && p.network < 90) {
      p.network = (p.network + 1).clamp(0, 100);
    }

    return msgs.isEmpty ? null : msgs.join('\n\n');
  }

  static String statusSummary(Player p) {
    if (p.friends.isEmpty) return '未有朋友';
    final partner = partnerOf(p);
    final base = '朋友 ${p.friends.length}/$maxFriends';
    if (partner == null) return base;
    return '$base · 拍拖：${partner.nameZh}（每季智慧 −$datingSmartsPenalty）';
  }
}
