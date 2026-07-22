import '../../models/enums.dart';
import '../../models/player.dart';
import '../career_data.dart';
import 'jupas_matcher.dart';
import 'jupas_requirements.dart';

/// 基礎專上教育文憑（Foundation）：
/// 未達 Asso／HD 一般入學 **22222** 時讀一年；Pass 後視同有 Asso 入場資格。
/// （唔取代各課程科目要求；亦唔等於公務員「五科二級」。）
abstract final class FoundationPathway {
  static const fee = 28000;

  static bool isStudying(Player p) =>
      p.unlockedFlags.contains('foundation_studying');

  static bool hasPassed(Player p) =>
      p.unlockedFlags.contains('foundation_pass');

  static bool canEnroll(Player p) {
    if (isStudying(p) || hasPassed(p)) return false;
    if (p.education == EducationLevel.bachelor ||
        p.education == EducationLevel.associate) {
      return false;
    }
    if (p.isStudying && !isStudying(p)) return false;
    // DSE：未達 22222
    if (p.dseSittingCount >= 1) {
      final grades = JupasMatcher.gradesOf(p);
      if (JupasRequirements.meetsAssoGer(grades)) return false;
      return true;
    }
    // IB Fail：無 Diploma
    if (p.unlockedFlags.contains('ib_fail')) return true;
    return false;
  }

  static String enroll(Player p, {String source = 'Foundation'}) {
    if (!canEnroll(p)) {
      if (hasPassed(p)) return '已有 Foundation Pass，可直接報 Asso／HD。';
      if (isStudying(p)) return '已讀緊 Foundation。';
      if (p.dseSittingCount >= 1 &&
          JupasRequirements.meetsAssoGer(JupasMatcher.gradesOf(p))) {
        return '已達 22222，可直接報 Asso／HD，唔使讀 Foundation。';
      }
      return '而家唔可以報 Foundation。';
    }
    if (p.wealth < fee) {
      return '學費不足：Foundation 約 \$$fee／年';
    }
    p.wealth -= fee;
    CareerData.onStartStudying(p);
    p.unlockedFlags.add('foundation_studying');
    p.unlockedFlags.remove('foundation_pass');
    p.foundationQuarters = 0;
    p.isStudying = true;
    p.currentSector = CareerSector.student;
    p.lifeStage = LifeStage.adult;
    p.jobTitle = 'Foundation／基礎專上文憑 · 讀緊';
    p.studyProgram = 'Diploma in Foundation Studies';
    p.eventLog.add(
      '${p.year}年：入讀 Foundation（$source · 學費 \$$fee）。'
      '讀一年 Pass 後視同達 Asso／HD 一般入學（22222），先可報副學位。',
    );
    return '已入讀 Foundation（一年）\n'
        '學費 \$$fee\n'
        'Pass 後先有資格報 Asso／HD（課程科目要求仍要睇）。';
  }

  /// 每季推進；滿 4 季＝Pass
  static String? tickQuarter(Player p) {
    if (!isStudying(p) || !p.isStudying) return null;
    p.foundationQuarters += 1;
    if (p.foundationQuarters < 4) {
      p.jobTitle =
          'Foundation · 第 ${p.foundationQuarters}/4 季';
      return null;
    }
    p.foundationQuarters = 0;
    p.unlockedFlags.remove('foundation_studying');
    p.unlockedFlags.add('foundation_pass');
    p.isStudying = false;
    p.currentSector = CareerSector.none;
    p.jobTitle = 'Foundation Pass · 可報 Asso／HD';
    p.studyProgram = '';
    p.eventLog.add(
      '${p.year}年：Foundation Pass。'
      '視同達副學位一般入學（22222）；可申請 Asso／HD'
      '（仍要符合個別課程科目要求）。',
    );
    return 'Foundation Pass\n可視同 22222，可報 Asso／HD';
  }

  static String studyAction(Player p) {
    if (!isStudying(p)) return '而家唔係讀緊 Foundation。';
    p.smarts = (p.smarts + 3).clamp(0, 100);
    p.discipline = (p.discipline + 2).clamp(0, 100);
    p.san = (p.san - 2).clamp(0, p.maxSan);
    return 'Foundation 溫書中（${p.foundationQuarters}/4 季）';
  }

  static void dropOut(Player p) {
    if (!isStudying(p)) return;
    p.unlockedFlags.remove('foundation_studying');
    p.foundationQuarters = 0;
    p.isStudying = false;
    p.currentSector = CareerSector.none;
    p.jobTitle = '待業（Foundation 輟學）';
    p.studyProgram = '';
    p.eventLog.add('${p.year}年：輟學 Foundation，未獲 Pass。');
  }
}
