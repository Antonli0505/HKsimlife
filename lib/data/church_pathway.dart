import 'dart:math';

import '../models/player.dart';

/// 教會／洗禮／推薦信（神學 JS4111 等）
abstract final class ChurchPathway {
  static const minAttendanceAge = 6;
  static const minReferenceAge = 16;
  static const guaranteedLoyalty = 80;

  static const flagMember = 'church_member';
  static const flagBaptized = 'church_baptized';
  static const flagReference = 'church_ref_letter';

  static void _syncFlags(Player p) {
    if (p.churchMember) p.unlockedFlags.add(flagMember);
    if (p.isBaptized) p.unlockedFlags.add(flagBaptized);
    if (p.hasChurchReferenceLetter) p.unlockedFlags.add(flagReference);
  }

  static bool canAttend(Player p) =>
      p.age >= minAttendanceAge && !p.inPrison;

  static bool canBaptize(Player p) =>
      p.churchMember && !p.isBaptized && canAttend(p);

  static bool canApplyReference(Player p) =>
      p.age >= minReferenceAge &&
      p.churchMember &&
      p.isBaptized &&
      !p.hasChurchReferenceLetter &&
      canAttend(p);

  /// 忠誠度 ≥80 必定發出；以下按比例（40→50%）
  static double referenceProbability(Player p) {
    final l = p.churchLoyalty.clamp(0, 100);
    if (l >= guaranteedLoyalty) return 1.0;
    return l / guaranteedLoyalty;
  }

  static String loyaltyLabel(Player p) {
    if (!p.churchMember) return '未入教會';
    final parts = <String>['忠誠 ${p.churchLoyalty}%'];
    if (p.isBaptized) parts.add('受咗洗');
    if (p.hasChurchReferenceLetter) parts.add('有推薦信');
    return parts.join(' · ');
  }

  /// 參加主日／團契；首次自動成為教會友
  static String attendWorship(Player p) {
    if (!canAttend(p)) return '而家唔適合去教會。';
    final first = !p.churchMember;
    p.churchMember = true;
    p.churchLoyalty = (p.churchLoyalty + 6).clamp(0, 100);
    p.san = (p.san + 4).clamp(0, p.maxSan);
    p.stress = (p.stress - 2).clamp(0, 100);
    _syncFlags(p);
    if (first) {
      return '你開始固定返教會。忠誠度 +6（而家 ${p.churchLoyalty}%）。';
    }
    return '主日崇拜／團契。忠誠度 +6（而家 ${p.churchLoyalty}%）。';
  }

  /// 受洗：無額外條件（已入教會即可）
  static String baptize(Player p) {
    if (!p.churchMember) return '要先返教會做教友。';
    if (p.isBaptized) return '你已經受洗。';
    p.isBaptized = true;
    p.churchLoyalty = (p.churchLoyalty + 20).clamp(0, 100);
    p.reputation = (p.reputation + 2).clamp(0, 100);
    _syncFlags(p);
    return '受洗禮搞掂。忠誠度 +20（而家 ${p.churchLoyalty}%），'
        '之後可以向牧師申請教會推薦信。';
  }

  /// 教會服事（青少年／成人）；加快累積忠誠度
  static String serve(Player p) {
    if (!p.churchMember) return '要先返教會。';
    if (p.age < 14) return '年紀太細，暫時未可以固定服事。';
    p.churchLoyalty = (p.churchLoyalty + 10).clamp(0, 100);
    p.network = (p.network + 2).clamp(0, 100);
    p.discipline = (p.discipline + 2).clamp(0, 100);
    _syncFlags(p);
    return '教會服事（詩班／主日學／探訪等）。忠誠度 +10（而家 ${p.churchLoyalty}%）。';
  }

  /// 向牧師申請推薦信（16 歲後；機率視忠誠度）
  static String applyReferenceLetter(Player p, Random rng) {
    if (p.age < minReferenceAge) {
      return '教會推薦信要 $minReferenceAge 歲後先可以申請。';
    }
    if (!p.churchMember) return '要先做教會友。';
    if (!p.isBaptized) return '要先受洗，牧師先會考慮出推薦信。';
    if (p.hasChurchReferenceLetter) return '你已經有教會推薦信。';

    final prob = referenceProbability(p);
    final pct = (prob * 100).round();
    if (rng.nextDouble() < prob) {
      p.hasChurchReferenceLetter = true;
      _syncFlags(p);
      p.eventLog.add('${p.year}年（${p.age}歲）：教會出咗推薦信。');
      return '牧師同意出推薦信（忠誠度 ${p.churchLoyalty}%，'
          '今次機率 $pct%）。可以用嚟報讀要教會推薦嘅大學課程。';
    }
    p.churchLoyalty = (p.churchLoyalty + 3).clamp(0, 100);
    return '牧師覺得你信仰生活未夠穩，暫時唔出推薦信（機率 $pct%）。'
        '多返教會、服事，下季可以再申請。忠誠度 +3。';
  }

  static bool hasReferenceForJupas(Player p) =>
      p.hasChurchReferenceLetter ||
      p.unlockedFlags.contains(flagReference);

  static String referenceFailReason(Player p) {
    if (hasReferenceForJupas(p)) return '';
    if (!p.isBaptized) return '要受洗';
    if (p.age < minReferenceAge) return '推薦信要 $minReferenceAge 歲後申請';
    return '未有教會推薦信（向牧師申請；忠誠度越高越易）';
  }
}
