import '../models/enums.dart';
import '../models/player.dart';

/// R 階級兒童綜援（遊戲簡化）：
/// - **未滿 18** 先可以攞
/// - 生效中每季自動入帳 **\$1000**
/// - **每 2 年**要手動續期，否則停發／取消
/// - 個人現金 **> \$20000** 自動取消
abstract final class CssaWelfare {
  static const quarterlyAmount = 1000;
  static const assetLimit = 20000;
  static const renewYears = 2;

  static const _active = 'cssa_active';
  static const _renewPrefix = 'cssa_renew_y';
  static const _eligible = 'cssa_welfare';

  static bool isEligibleTier(Player p) =>
      p.unlockedFlags.contains(_eligible) ||
      p.unlockedFlags.contains('welfare_network') ||
      p.birthTier == BirthTier.r;

  static bool isActive(Player p) => p.unlockedFlags.contains(_active);

  static int? lastRenewYear(Player p) {
    for (final f in p.unlockedFlags) {
      if (f.startsWith(_renewPrefix)) {
        return int.tryParse(f.substring(_renewPrefix.length));
      }
    }
    return null;
  }

  static void _setRenewYear(Player p, int year) {
    p.unlockedFlags.removeWhere((f) => f.startsWith(_renewPrefix));
    p.unlockedFlags.add('$_renewPrefix$year');
  }

  static int? yearsUntilRenewDue(Player p) {
    final last = lastRenewYear(p);
    if (last == null || !isActive(p)) return null;
    final due = last + renewYears;
    return due - p.year;
  }

  static bool isRenewOverdue(Player p) {
    final left = yearsUntilRenewDue(p);
    return left != null && left <= 0;
  }

  static bool needsRenewSoon(Player p) {
    final left = yearsUntilRenewDue(p);
    return left != null && left <= 1;
  }

  /// 出世 R：自動開綜援，續期基準＝出世年
  static void activateAtBirth(Player p) {
    if (!isEligibleTier(p)) return;
    p.unlockedFlags.add(_eligible);
    p.unlockedFlags.add(_active);
    _setRenewYear(p, p.year);
  }

  static void cancel(Player p, {required String reason}) {
    if (!isActive(p)) return;
    p.unlockedFlags.remove(_active);
    p.eventLog.add('${p.year}年：綜援已取消——$reason');
  }

  /// 申請／重新開通（未滿 18、資產唔超限）
  static String apply(Player p) {
    if (!isEligibleTier(p)) return '你唔符合綜援資格（非公屋草根路線）。';
    if (p.age >= 18) return '綜援只限 18 歲以下；你已成年，唔可以再申請。';
    if (p.wealth > assetLimit) {
      return '個人現金超過 \$$assetLimit，唔可以申請綜援。';
    }
    p.unlockedFlags.add(_active);
    _setRenewYear(p, p.year);
    p.eventLog.add(
      '${p.year}年：綜援申請獲批。'
      '每季 \$$quarterlyAmount；每 $renewYears 年要手動續期；'
      '現金超過 \$$assetLimit 會自動取消。',
    );
    return '綜援已開通\n'
        '每季自動入帳 \$$quarterlyAmount\n'
        '下次續期：${p.year + renewYears} 年\n'
        '現金超過 \$$assetLimit 會自動取消';
  }

  /// 手動續期（未過期可提早續；過期後續期＝重新啟動）
  static String renew(Player p) {
    if (!isEligibleTier(p)) return '唔符合綜援資格。';
    if (p.age >= 18) {
      cancel(p, reason: '已滿 18 歲');
      return '已滿 18 歲，綜援取消，唔可以續期。';
    }
    if (p.wealth > assetLimit) {
      cancel(p, reason: '個人現金超過 \$$assetLimit');
      return '現金超過 \$$assetLimit，綜援已取消，唔可以續期。';
    }
    final wasActive = isActive(p);
    p.unlockedFlags.add(_active);
    _setRenewYear(p, p.year);
    p.eventLog.add(
      '${p.year}年：綜援續期成功。下次要喺 ${p.year + renewYears} 年前再開續期。',
    );
    return wasActive
        ? '綜援續期成功\n下次續期期限：${p.year + renewYears} 年'
        : '綜援已重新開通並續期\n下次續期期限：${p.year + renewYears} 年';
  }

  /// 每季結算：檢查取消條件 → 發放／逾期停發
  /// 回傳要彈窗嘅提示（可多則用 \n\n 合併）
  static String? tickQuarter(Player p) {
    if (!isEligibleTier(p)) return null;

    final msgs = <String>[];

    if (isActive(p)) {
      if (p.age >= 18) {
        cancel(p, reason: '已滿 18 歲（兒童綜援終止）');
        msgs.add('綜援取消：已滿 18 歲，兒童綜援終止。');
        return msgs.join('\n\n');
      }
      if (p.wealth > assetLimit) {
        cancel(p, reason: '個人現金超過 \$$assetLimit');
        msgs.add(
          '綜援取消：個人現金 \$${p.wealth} 超過上限 \$$assetLimit。',
        );
        return msgs.join('\n\n');
      }
      if (isRenewOverdue(p)) {
        cancel(p, reason: '超過 $renewYears 年未手動續期');
        msgs.add(
          '綜援取消：已超過 $renewYears 年未續期。'
          '未滿 18 且現金 ≤ \$$assetLimit 可再申請／續期。',
        );
        return msgs.join('\n\n');
      }

      p.wealth += quarterlyAmount;
      p.eventLog.add(
        '${p.year}年：綜援入帳 \$$quarterlyAmount'
        '（現金 \$${p.wealth}／上限 \$$assetLimit）',
      );
      msgs.add('綜援入帳 \$$quarterlyAmount');

      if (p.wealth > assetLimit) {
        cancel(p, reason: '個人現金超過 \$$assetLimit');
        msgs.add(
          '綜援取消：入帳後現金 \$${p.wealth} 超過上限 \$$assetLimit。',
        );
        return msgs.join('\n\n');
      }

      final left = yearsUntilRenewDue(p);
      if (left != null && left <= 1) {
        msgs.add(
          left <= 0
              ? '⚠ 綜援續期已到期——請立即去「資產」手動續期！'
              : '⚠ 綜援將於明年到期——請盡快去「資產」手動續期（每 $renewYears 年一次）。',
        );
      }
      return msgs.join('\n\n');
    }

    // 未生效：資產超限就唔提醒；未滿18可申請
    return null;
  }

  static String statusLabel(Player p) {
    if (!isEligibleTier(p)) return '不符合';
    if (p.age >= 18) return '已成年（不可再領）';
    if (!isActive(p)) {
      if (p.wealth > assetLimit) return '停用（現金超過 \$$assetLimit）';
      return '未生效（可申請）';
    }
    final last = lastRenewYear(p) ?? p.year;
    final due = last + renewYears;
    final left = due - p.year;
    if (left <= 0) return '生效中 · ⚠ 續期已逾期';
    if (left <= 1) return '生效中 · ⚠ $due 年前要續期';
    return '生效中 · 下次續期 $due 年（每季 \$$quarterlyAmount）';
  }
}
