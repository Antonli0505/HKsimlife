import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'elective_subjects.dart';
import 'social_circle.dart';
import 'university_pathway.dart';

enum UniSocietyKind {
  /// 每年只可加入其中一個（學生會／編輯委員會）
  exclusive,
  /// 住 Hall 先可加入
  hall,
  /// 普通興趣屬會
  open,
}

class UniSociety {
  final String id;
  final String nameZh;
  final UniSocietyKind kind;
  final String blurb;
  /// 學期活動簡稱（顯示用）
  final String activityLabel;

  const UniSociety({
    required this.id,
    required this.nameZh,
    required this.kind,
    required this.blurb,
    required this.activityLabel,
  });
}

/// 港大／中大常見類型簡化
///
/// 設計：
/// - 全部學會每學期要參加／搞活動（唔係虛設）
/// - 會員易入；上莊難、加成大、代價大；每年最多上一個莊
/// - Hall 會：住 Hall 先有；可上 Hall 莊
/// - 職業：舊生 flag 降低相關入行門檻／加成
abstract final class UniversitySocieties {
  static const List<UniSociety> all = [
    UniSociety(
      id: 'su',
      nameZh: '學生會',
      kind: UniSocietyKind.exclusive,
      blurb: '幹事會路線；會員易啲，上莊好難。',
      activityLabel: '校園活動／福利週',
    ),
    UniSociety(
      id: 'editorial',
      nameZh: '編輯委員會',
      kind: UniSocietyKind.exclusive,
      blurb: '校園刊物；文科較易入編委。',
      activityLabel: '出刊／採訪',
    ),
    UniSociety(
      id: 'hall',
      nameZh: 'Hall 會',
      kind: UniSocietyKind.hall,
      blurb: '宿生會；住 Hall 先可加入，可上 Hall 莊。',
      activityLabel: 'Hall 夜／樓層活動',
    ),
    UniSociety(
      id: 'astro',
      nameZh: '天文學會',
      kind: UniSocietyKind.open,
      blurb: '觀星／科普講座。',
      activityLabel: '觀星夜／講座',
    ),
    UniSociety(
      id: 'photo',
      nameZh: '攝影學會',
      kind: UniSocietyKind.open,
      blurb: '影迎新、活動記錄。',
      activityLabel: '拍攝活動',
    ),
    UniSociety(
      id: 'drama',
      nameZh: '話劇社',
      kind: UniSocietyKind.open,
      blurb: '排練同公演。',
      activityLabel: '排練／公演',
    ),
    UniSociety(
      id: 'debate',
      nameZh: '辯論學會',
      kind: UniSocietyKind.open,
      blurb: '粵語／英語辯論。',
      activityLabel: '訓練／出賽',
    ),
    UniSociety(
      id: 'choir',
      nameZh: '合唱團',
      kind: UniSocietyKind.open,
      blurb: '練唱同音樂會。',
      activityLabel: '練唱／音樂會',
    ),
    UniSociety(
      id: 'volunteer',
      nameZh: '社會服務團',
      kind: UniSocietyKind.open,
      blurb: '義工、社區服務。',
      activityLabel: '義工服務',
    ),
    UniSociety(
      id: 'christian',
      nameZh: '基督徒團契',
      kind: UniSocietyKind.open,
      blurb: '團契生活。',
      activityLabel: '團契聚會',
    ),
    UniSociety(
      id: 'business',
      nameZh: '投資學會',
      kind: UniSocietyKind.open,
      blurb: '投資比賽、財經講座。',
      activityLabel: '講座／模擬投資',
    ),
    UniSociety(
      id: 'sports',
      nameZh: '球類學會',
      kind: UniSocietyKind.open,
      blurb: '足球／籃球等康體。',
      activityLabel: '訓練／比賽',
    ),
  ];

  static UniSociety? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static bool isMember(Player p, String id) => p.uniSocietyIds.contains(id);

  static bool isCadre(Player p, String id) => p.uniCadreSocietyId == id;

  static String dutyFlag(Player p, String societyId) {
    final sem = (p.quarter == Quarter.q4 || p.quarter == Quarter.q1) ? 1 : 2;
    return 'duty_${societyId}_y${p.bachelorYear}_s$sem';
  }

  static bool dutyDoneThisSem(Player p, String societyId) =>
      p.unlockedFlags.contains(dutyFlag(p, societyId));

  static List<String> pendingDutyIds(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return const [];
    if (p.quarter != Quarter.q4 && p.quarter != Quarter.q2) return const [];
    return p.uniSocietyIds
        .where(
          (id) =>
              !dutyDoneThisSem(p, id) &&
              !p.unlockedFlags.contains('${dutyFlag(p, id)}_skipped'),
        )
        .toList();
  }

  static bool needsDutyPrompt(Player p) => pendingDutyIds(p).isNotEmpty;

  /// 學期尾未搞 → 每個未完成學會罰一次
  static String? settleDutyNeglect(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return null;
    if (p.quarter != Quarter.q1 && p.quarter != Quarter.q3) return null;

    final msgs = <String>[];
    for (final id in List<String>.from(p.uniSocietyIds)) {
      if (dutyDoneThisSem(p, id)) continue;
      final s = byId(id);
      if (s == null) continue;

      final cadre = isCadre(p, id);
      final standHit = cadre ? 22 : 14;
      final netHit = cadre ? 7 : 4;
      final faceHit = cadre ? 6 : 3;

      p.uniSocietyStanding = (p.uniSocietyStanding - standHit).clamp(0, 100);
      p.network = (p.network - netHit).clamp(0, 100);
      p.reputation = (p.reputation - faceHit).clamp(0, 100);
      p.eventLog.add(
        '${p.year}年：${s.nameZh}${cadre ? "（上莊）" : ""}'
        '未搞掂「${s.activityLabel}」，莊友唔滿意。',
      );

      final kickChance = cadre
          ? (p.uniSocietyStanding < 40 ? 0.65 : 0.3)
          : (p.uniSocietyStanding < 35
              ? 0.45
              : (p.uniSocietyStanding < 50 ? 0.2 : 0.06));
      if (Random(p.year * 17 + id.hashCode + p.uniSocietyStanding)
              .nextDouble() <
          kickChance) {
        final k = _kick(
          p,
          id,
          reason: '成日唔參與${s.nameZh}活動，俾人踢走',
        );
        if (k != null) msgs.add(k);
      } else {
        msgs.add('${s.nameZh}：呢學期冇搞／參加活動，關係同面子↓');
      }
    }
    return msgs.isEmpty ? null : msgs.join('\n');
  }

  static String? _kick(Player p, String id, {required String reason}) {
    p.uniSocietyIds.remove(id);
    if (p.uniExclusiveSocietyId == id) p.uniExclusiveSocietyId = '';
    if (p.uniCadreSocietyId == id) p.uniCadreSocietyId = '';
    p.uniSocietyStanding = (p.uniSocietyStanding - 10).clamp(0, 100);
    p.reputation = (p.reputation - 8).clamp(0, 100);
    p.network = (p.network - 6).clamp(0, 100);
    p.stress = (p.stress + 5).clamp(0, 100);
    p.unlockedFlags.add('uni_society_kicked_$id');
    p.eventLog.add('${p.year}年：$reason（面子／人脈都損咗）。');
    return reason;
  }

  static double joinChance(Player p, UniSociety s, {required bool asCadre}) {
    var c = switch (s.id) {
      'su' => 0.35 + (p.smarts - 55) * 0.01 + (p.network - 40) * 0.008,
      'editorial' => 0.4 +
          (p.smarts - 50) * 0.008 +
          (p.streamAffinity == StreamAffinity.arts ? 0.25 : 0) -
          (p.streamAffinity == StreamAffinity.science ? 0.1 : 0),
      'hall' => 0.75 + (p.hallPoints - 10) * 0.01,
      'debate' => 0.6 + (p.smarts - 50) * 0.01,
      'christian' => p.churchMember ? 0.92 : 0.55,
      _ => 0.88,
    };
    if (asCadre) {
      c *= 0.45;
      c += (p.network - 45) * 0.006 + (p.reputation - 50) * 0.005;
      if (p.smarts < 60) c -= 0.15;
    }
    if (s.id == 'su' && p.smarts < 62 && asCadre) c -= 0.2;
    return c.clamp(0.05, 0.95);
  }

  static String? joinBlockReason(
    Player p,
    UniSociety s, {
    required bool asCadre,
  }) {
    if (!UniversityPathway.isStudyingBachelor(p)) return '未讀緊學士';
    if (asCadre) {
      if (!isMember(p, s.id)) return '要先做${s.nameZh}會員先可以上莊';
      if (p.uniCadreSocietyId.isNotEmpty) {
        final cur = byId(p.uniCadreSocietyId)?.nameZh ?? '另一個';
        return '今年已上$cur 莊；每年最多上一個莊';
      }
      if (isCadre(p, s.id)) return '你已經係${s.nameZh}上莊';
      if (s.id == 'su' && p.smarts < 62) {
        return '學生會上莊：Smarts 建議 ≥ 62';
      }
      if (s.id == 'editorial' &&
          p.smarts < 55 &&
          p.streamAffinity != StreamAffinity.arts) {
        return '編輯委員會上莊：能力／文傾向未夠';
      }
      if (s.id == 'hall' && p.hallPoints < 12) {
        return 'Hall 莊：Hall 點數建議 ≥ 12（而家 ${p.hallPoints}）';
      }
      return null;
    }

    if (isMember(p, s.id)) return '你已經喺${s.nameZh}';
    if (s.kind == UniSocietyKind.hall && !p.inHall) {
      return '要住 Hall 先可以加入 Hall 會';
    }
    if (s.kind == UniSocietyKind.exclusive) {
      if (p.uniExclusiveSocietyId.isNotEmpty) {
        final cur = byId(p.uniExclusiveSocietyId)?.nameZh ?? '另一個';
        return '今年已加入$cur；每年只可入一個學生會／編輯委員會';
      }
      if (s.id == 'su' && p.smarts < 55) {
        return '學生會會員：Smarts 建議 ≥ 55';
      }
    }
    return null;
  }

  static String tryJoin(Player p, String id, {bool asCadre = false}) {
    final s = byId(id);
    if (s == null) return '無呢個學會';
    final block = joinBlockReason(p, s, asCadre: asCadre);
    if (block != null) {
      p.eventLog.add('${p.year}年：${asCadre ? "上莊" : "入會"}失敗 — $block');
      return block;
    }

    final chance = joinChance(p, s, asCadre: asCadre);
    final roll =
        Random(p.year * 41 + id.hashCode + p.smarts + (asCadre ? 9 : 0))
            .nextDouble();
    if (roll > chance) {
      p.reputation = (p.reputation - (asCadre ? 4 : 2)).clamp(0, 100);
      return '${asCadre ? "上莊" : "申請"}${s.nameZh}唔成'
          '（約 ${(chance * 100).round()}%）。面子少少損。';
    }

    if (!asCadre) {
      p.uniSocietyIds.add(id);
      if (s.kind == UniSocietyKind.exclusive) {
        p.uniExclusiveSocietyId = id;
      }
      p.uniSocietyStanding =
          (p.uniSocietyStanding <= 0 ? 50 : p.uniSocietyStanding + 4)
              .clamp(0, 100);
      p.network = (p.network + 3).clamp(0, 100);
      p.eventLog.add('${p.year}年：入咗${s.nameZh}（會員）。');
      return '入到${s.nameZh}（會員）啦！每學期都要參加「${s.activityLabel}」。';
    }

    p.uniCadreSocietyId = id;
    p.uniSocietyStanding = (p.uniSocietyStanding + 10).clamp(0, 100);
    p.network = (p.network + 6).clamp(0, 100);
    p.reputation = (p.reputation + 4).clamp(0, 100);
    p.stress = (p.stress + 3).clamp(0, 100);
    p.eventLog.add('${p.year}年：做咗${s.nameZh}上莊／幹事。');
    return '上到${s.nameZh}莊啦！義務更重，人脈／面子加成更大。';
  }

  /// 參加／搞今學期活動（上莊＝搞，會員＝參加）
  static String runDuty(Player p, String id) {
    final s = byId(id);
    if (s == null || !isMember(p, id)) return '你唔喺呢個學會';
    if (dutyDoneThisSem(p, id)) return '今學期已經搞掂${s.nameZh}活動';

    final cadre = isCadre(p, id);
    p.unlockedFlags.add(dutyFlag(p, id));

    if (cadre) {
      p.network = (p.network + 10).clamp(0, 100);
      p.stress = (p.stress + 9).clamp(0, 100);
      p.uniSocietyStanding = (p.uniSocietyStanding + 14).clamp(0, 100);
      p.reputation = (p.reputation + 5).clamp(0, 100);
      if (id == 'hall') p.hallPoints = (p.hallPoints + 4).clamp(0, 100);
      // 上莊佔兩次溫書
      p.uniStudySessions = (p.uniStudySessions - 2).clamp(0, 99);
    } else {
      p.network = (p.network + 5).clamp(0, 100);
      p.stress = (p.stress + 4).clamp(0, 100);
      p.uniSocietyStanding = (p.uniSocietyStanding + 7).clamp(0, 100);
      p.reputation = (p.reputation + 2).clamp(0, 100);
      if (id == 'hall') p.hallPoints = (p.hallPoints + 2).clamp(0, 100);
      if (p.uniStudySessions > 0) {
        p.uniStudySessions--;
      } else {
        p.stress = (p.stress + 2).clamp(0, 100);
      }
    }

    p.eventLog.add(
      '${p.year}年：${cadre ? "搞咗" : "參加咗"}${s.nameZh}「${s.activityLabel}」。',
    );
    SocialCircle.tryMeet(p, FriendSource.uni, baseChance: 0.4);
    return '${cadre ? "搞" : "參加"}咗${s.nameZh}活動：'
        '人脈／關係＋、壓力＋、溫書↓（GPA 潛力↓）。';
  }

  static String skipDuty(Player p, String id) {
    final s = byId(id);
    if (s == null || !isMember(p, id)) return '你唔喺呢個學會';

    final cadre = isCadre(p, id);
    p.unlockedFlags.add('${dutyFlag(p, id)}_skipped');
    p.uniSocietyStanding =
        (p.uniSocietyStanding - (cadre ? 16 : 10)).clamp(0, 100);
    p.network = (p.network - (cadre ? 6 : 3)).clamp(0, 100);
    p.reputation = (p.reputation - (cadre ? 5 : 3)).clamp(0, 100);
    p.eventLog.add(
      '${p.year}年：呢學期唔${cadre ? "搞" : "參加"}${s.nameZh}活動。',
    );

    final kickThresh = cadre ? 32 : 28;
    final kickP = cadre ? 0.5 : 0.35;
    if (p.uniSocietyStanding < kickThresh &&
        Random(p.year + p.uniSocietyStanding + id.hashCode).nextDouble() <
            kickP) {
      return _kick(
            p,
            id,
            reason: '唔肯${cadre ? "搞" : "參加"}活動，踢出${s.nameZh}',
          ) ??
          '俾人踢出學會';
    }
    return '唔參加：莊友關係差、人脈同面子↓'
        '${cadre ? "（上莊缺席更嚴重）" : ""}。';
  }

  static StoryEvent? dutyEvent(Player p) {
    final pending = pendingDutyIds(p);
    if (pending.isEmpty) return null;

    // 一次處理一個，避免選項爆炸；下季／再生成再下一個
    final id = pending.first;
    final s = byId(id)!;
    final cadre = isCadre(p, id);

    return StoryEvent(
      id: 'uni_duty_$id',
      title: '${s.nameZh} · 呢學期「${s.activityLabel}」',
      body: '每個學會每學期都要${cadre ? "搞" : "參加"}活動，唔係掛名㗎。\n'
          '${cadre ? "你係上莊：搞活動加成大，缺席後果好嚴重。" : "你係會員：要出席／幫手。"}\n'
          '搞／參加 → 人脈、關係、面子＋；壓力＋、溫書↓\n'
          '唔搞 → 關係／面子↓，有機會俾人踢會。\n'
          '莊友關係：${p.uniSocietyStanding}'
          '${pending.length > 1 ? "\n（仲有 ${pending.length - 1} 個學會等處理）" : ""}',
      isSystem: true,
      choices: [
        EventChoice(
          label: cadre ? '搞活動（壓力大、溫書↓↓）' : '參加活動（壓力＋、溫書↓）',
          apply: (pl) => runDuty(pl, id),
        ),
        EventChoice(
          label: '呢學期唔搞／唔參加',
          apply: (pl) => skipDuty(pl, id),
        ),
      ],
    );
  }

  /// 每季 50%：學會八卦／內訌／聯校等（要至少加入一個學會）
  static StoryEvent? gossipEvent(Player p) {
    if (!UniversityPathway.isStudyingBachelor(p)) return null;
    if (p.uniSocietyIds.isEmpty) return null;

    final flag = 'uni_gossip_y${p.year}_q${p.quarter.name}';
    if (p.unlockedFlags.contains(flag)) return null;

    final rng = Random(p.year * 997 + p.quarter.index * 131 + p.age * 17);
    if (rng.nextDouble() >= 0.5) {
      p.unlockedFlags.add(flag); // 今季已 roll 過唔中，唔再重複 roll
      return null;
    }
    p.unlockedFlags.add(flag);

    final id = p.uniSocietyIds[rng.nextInt(p.uniSocietyIds.length)];
    final s = byId(id) ?? all.first;
    final cadre = isCadre(p, id);
    final type = rng.nextInt(5);

    return switch (type) {
      0 => StoryEvent(
          id: 'uni_gossip_budget',
          title: '${s.nameZh} · 搶預算',
          body: '評議會／幹事會為活動撥款嘈緊交。有人叫你企邊。\n'
              '莊友關係而家：${p.uniSocietyStanding}',
          isSystem: true,
          choices: [
            EventChoice(
              label: '幫莊爭預算',
              apply: (pl) {
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding + 8).clamp(0, 100);
                pl.network = (pl.network + 3).clamp(0, 100);
                pl.stress = (pl.stress + 4).clamp(0, 100);
                pl.reputation = (pl.reputation + 2).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：${s.nameZh}搶預算幫咗莊。');
              },
            ),
            EventChoice(
              label: '扮唔知',
              apply: (pl) {
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding - 3).clamp(0, 100);
                pl.san = (pl.san + 2).clamp(0, pl.maxSan);
                pl.eventLog.add('${pl.year}年：${s.nameZh}預算戰扮唔知。');
              },
            ),
            EventChoice(
              label: '一齊傳謠',
              apply: (pl) {
                pl.network = (pl.network + 2).clamp(0, 100);
                pl.reputation = (pl.reputation - 8).clamp(0, 100);
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding - 10).clamp(0, 100);
                pl.stress = (pl.stress + 5).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：${s.nameZh}預算戰一齊傳謠。');
              },
            ),
          ],
        ),
      1 => StoryEvent(
          id: 'uni_gossip_drama',
          title: '${s.nameZh} · 內訌八卦',
          body: 'WhatsApp 傳開莊內有人篤灰。同學問你知唔知內幕。\n'
              '${cadre ? "你係上莊，更加敏感。" : ""}',
          isSystem: true,
          choices: [
            EventChoice(
              label: '幫莊澄清',
              apply: (pl) {
                pl.network = (pl.network + 5).clamp(0, 100);
                pl.reputation = (pl.reputation + 3).clamp(0, 100);
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding + 5).clamp(0, 100);
                pl.stress = (pl.stress + 5).clamp(0, 100);
                if (pl.uniStudySessions > 0) pl.uniStudySessions--;
                pl.eventLog.add('${pl.year}年：${s.nameZh}內訌幫莊澄清。');
              },
            ),
            EventChoice(
              label: '扮唔知',
              apply: (pl) {
                pl.discipline = (pl.discipline + 2).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：${s.nameZh}八卦扮唔知。');
              },
            ),
            EventChoice(
              label: '一齊傳謠',
              apply: (pl) {
                pl.network = (pl.network + 2).clamp(0, 100);
                pl.reputation = (pl.reputation - 8).clamp(0, 100);
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding - 8).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：傳${s.nameZh}八卦造謠，面子插水。');
              },
            ),
          ],
        ),
      2 => StoryEvent(
          id: 'uni_gossip_intervarsity',
          title: '${s.nameZh} · 聯校交流',
          body: '有聯校活動名額。去就識到人，但好辛苦，又影響溫書。',
          isSystem: true,
          choices: [
            EventChoice(
              label: '去聯校（人脈＋＋）',
              apply: (pl) {
                pl.network = (pl.network + 10).clamp(0, 100);
                pl.stress = (pl.stress + 6).clamp(0, 100);
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding + 6).clamp(0, 100);
                pl.uniStudySessions =
                    (pl.uniStudySessions - (cadre ? 2 : 1)).clamp(0, 99);
                if (id == 'hall') {
                  pl.hallPoints = (pl.hallPoints + 3).clamp(0, 100);
                }
                pl.eventLog.add('${pl.year}年：去咗${s.nameZh}聯校。');
              },
            ),
            EventChoice(
              label: '唔去啦，溫書先',
              apply: (pl) {
                pl.uniStudySessions++;
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding - 4).clamp(0, 100);
                pl.eventLog.add('${pl.year}年：推${s.nameZh}聯校，溫書。');
              },
            ),
          ],
        ),
      3 => StoryEvent(
          id: 'uni_gossip_recruit',
          title: '${s.nameZh} · 招新拉人',
          body: '迎新／招新，叫你喺校園設攤同拉人入會。',
          isSystem: true,
          choices: [
            EventChoice(
              label: '全日幫手（好累）',
              apply: (pl) {
                pl.network = (pl.network + 6).clamp(0, 100);
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding + 10).clamp(0, 100);
                pl.stress = (pl.stress + 7).clamp(0, 100);
                pl.san = (pl.san - 3).clamp(0, pl.maxSan);
                pl.eventLog.add('${pl.year}年：幫${s.nameZh}招新。');
              },
            ),
            EventChoice(
              label: '只幫手半日',
              apply: (pl) {
                pl.network = (pl.network + 3).clamp(0, 100);
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding + 4).clamp(0, 100);
                pl.stress = (pl.stress + 3).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '話自己有堂',
              apply: (pl) {
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding - 5).clamp(0, 100);
                pl.reputation = (pl.reputation - 1).clamp(0, 100);
              },
            ),
          ],
        ),
      _ => StoryEvent(
          id: 'uni_gossip_praise',
          title: '${s.nameZh} · 被人讚／被篤',
          body: rng.nextBool()
              ? '有人喺群組公開多謝你幫手，一時好有面。'
              : '有人喺群組話你唔夠心機，莊內氣氛好尷尬。',
          isSystem: true,
          choices: [
            EventChoice(
              label: '低調啲回',
              apply: (pl) {
                pl.reputation = (pl.reputation + 2).clamp(0, 100);
                pl.discipline = (pl.discipline + 1).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '借勢識多啲人',
              apply: (pl) {
                pl.network = (pl.network + 5).clamp(0, 100);
                pl.reputation = (pl.reputation + 3).clamp(0, 100);
                pl.stress = (pl.stress + 2).clamp(0, 100);
              },
            ),
            EventChoice(
              label: '對質／澄清（有壓力）',
              apply: (pl) {
                pl.uniSocietyStanding =
                    (pl.uniSocietyStanding + 3).clamp(0, 100);
                pl.stress = (pl.stress + 5).clamp(0, 100);
                pl.san = (pl.san - 2).clamp(0, pl.maxSan);
              },
            ),
          ],
        ),
    };
  }

  static StoryEvent joinEvent(Player p) {
    final choices = <EventChoice>[];

    for (final s in all) {
      if (s.kind == UniSocietyKind.hall && !p.inHall) {
        choices.add(EventChoice(
          label: '${s.nameZh}（要住 Hall）',
          enabled: false,
          apply: (_) {},
        ));
        continue;
      }

      if (!isMember(p, s.id)) {
        final block = joinBlockReason(p, s, asCadre: false);
        final pct = (joinChance(p, s, asCadre: false) * 100).round();
        if (block != null) {
          choices.add(EventChoice(
            label: '會員·${s.nameZh}（唔得）',
            enabled: false,
            apply: (_) {},
          ));
        } else {
          choices.add(EventChoice(
            label: '入${s.nameZh}做會員（約 $pct%）',
            apply: (pl) => tryJoin(pl, s.id),
          ));
        }
      } else if (!isCadre(p, s.id)) {
        final block = joinBlockReason(p, s, asCadre: true);
        final pct = (joinChance(p, s, asCadre: true) * 100).round();
        if (block != null) {
          choices.add(EventChoice(
            label: '上莊·${s.nameZh}（唔得）',
            enabled: false,
            apply: (_) {},
          ));
        } else {
          choices.add(EventChoice(
            label: '申請${s.nameZh}上莊（約 $pct%）',
            apply: (pl) => tryJoin(pl, s.id, asCadre: true),
          ));
        }
      }
    }
    choices.add(EventChoice(label: '暫時唔入', apply: (_) {}));

    final joined = p.uniSocietyIds.isEmpty
        ? '未入過任何學會'
        : '入咗：${p.uniSocietyIds.map((id) {
            final n = byId(id)?.nameZh ?? id;
            return isCadre(p, id) ? '$n（上莊）' : n;
          }).join("、")}';

    return StoryEvent(
      id: 'uni_society_join',
      title: '大學學會／上莊',
      body: '$joined\n'
          '· 全部學會每學期都要搞／參加活動\n'
          '· 學生會／編輯委員會：每年只可以入其中一個做會員\n'
          '· 上莊：每年最多一個；加成大、義務重\n'
          '· Hall 會：住 Hall 先有；可以上 Hall 莊',
      isSystem: true,
      choices: choices,
    );
  }

  static void resetOnEnroll(Player p) {
    p.uniSocietyIds = [];
    p.uniExclusiveSocietyId = '';
    p.uniCadreSocietyId = '';
    p.uniSocietyStanding = 50;
  }

  /// 搬出 Hall → 自動退 Hall 會
  static void syncHallMembership(Player p) {
    if (!p.inHall && isMember(p, 'hall')) {
      _kick(p, 'hall', reason: '搬出 Hall，自動退出 Hall 會');
    }
  }

  static void onAcademicYearAdvance(Player p) {
    p.uniExclusiveSocietyId = '';
    p.uniCadreSocietyId = ''; // 新學年要重新選舉上莊
  }

  static bool wasIn(Player p, String id) =>
      isMember(p, id) || p.unlockedFlags.contains('uni_society_alumni_$id');

  static bool wasCadreOf(Player p, String id) =>
      p.unlockedFlags.contains('uni_society_cadre_alumni_$id');

  static bool wasInSu(Player p) => wasIn(p, 'su');

  static bool wasInEditorial(Player p) => wasIn(p, 'editorial');

  static bool wasInInvestment(Player p) => wasIn(p, 'business');

  static bool wasInDebate(Player p) => wasIn(p, 'debate');

  static bool wasInVolunteer(Player p) => wasIn(p, 'volunteer');

  static bool wasHallCadre(Player p) =>
      wasCadreOf(p, 'hall') || isCadre(p, 'hall');

  static void markAlumniOnGraduate(Player p) {
    for (final id in p.uniSocietyIds) {
      p.unlockedFlags.add('uni_society_alumni_$id');
    }
    if (p.uniCadreSocietyId.isNotEmpty) {
      p.unlockedFlags.add('uni_society_cadre_alumni_${p.uniCadreSocietyId}');
    }
  }

  /// 職業門檻設計（畀 game_state／exam 用）
  /// 學生會 → 從政；編輯 → 傳媒；投資 → 保險；辯論 → 法律；Hall 莊 → 人脈
  static int politicsNetworkNeed(Player p) {
    if (wasCadreOf(p, 'su') || isCadre(p, 'su')) return 18;
    if (wasInSu(p)) return 22;
    return 30;
  }

  static int politicsReputationNeed(Player p) {
    if (wasCadreOf(p, 'su') || isCadre(p, 'su')) return 28;
    if (wasInSu(p)) return 32;
    return 40;
  }

  static int flightNetworkNeed(Player p) {
    if (wasInEditorial(p)) return 28;
    if (wasHallCadre(p)) return 30;
    return 35;
  }

  static int tvbNetworkNeed(Player p) => wasInEditorial(p) ? 15 : 20;

  static int tvbReputationNeed(Player p) => wasInEditorial(p) ? 28 : 35;

  static int pupillageSmartsNeed(Player p) => wasInDebate(p) ? 65 : 70;
}
