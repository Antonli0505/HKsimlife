import 'dart:math';

import '../models/enums.dart';
import '../models/player.dart';
import 'career_data.dart';
import 'elective_subjects.dart';
import 'ib_curriculum.dart';
import 'jupas/asso_articulation.dart';
import 'jupas/foundation_pathway.dart';
import 'jupas/jupas_catalogue.dart';
import 'jupas/jupas_models.dart';
import 'university_life.dart';

/// IB Diploma 成績階梯（唔行 DSE／JUPAS）
enum IbTier {
  none,
  fail, // <24 或無 diploma
  diploma, // 24–29
  competitive, // 30–38
  outstanding, // 39–42
  perfect, // 43–45
}

extension IbTierExt on IbTier {
  String get label => switch (this) {
        IbTier.none => '未考 IB',
        IbTier.fail => '未獲 Diploma',
        IbTier.diploma => 'IB Diploma（24–29）',
        IbTier.competitive => 'IB 競爭力（30–38）',
        IbTier.outstanding => 'IB 優秀（39–42）',
        IbTier.perfect => 'IB 頂尖（43–45）',
      };

  String get shortLabel => switch (this) {
        IbTier.none => '—',
        IbTier.fail => 'Fail',
        IbTier.diploma => '24–29',
        IbTier.competitive => '30–38',
        IbTier.outstanding => '39–42',
        IbTier.perfect => '43–45',
      };
}

/// 升學去向（IB 專用，非 JUPAS）
enum IbUniPath {
  none,
  overseasElite, // Oxbridge / Ivy / 頂尖
  overseas, // 一般海外
  localNonJupas, // 港大／中大等非聯招
  foundation, // 一年 Foundation（未達副學位資格）
  associate, // 有 Diploma → 直接社區 Asso／HD
  work, // 直接打工
}

extension IbUniPathExt on IbUniPath {
  String get label => switch (this) {
        IbUniPath.none => '未決定',
        IbUniPath.overseasElite => '海外頂尖大學',
        IbUniPath.overseas => '海外大學',
        IbUniPath.localNonJupas => '本地大學（非聯招）',
        IbUniPath.foundation => 'Foundation（基礎專上文憑）',
        IbUniPath.associate => '社區 Asso／HD',
        IbUniPath.work => '直接就業',
      };
}

class IbPathway {
  static bool isOnTrack(Player p) =>
      p.unlockedFlags.contains('bypass_dse') &&
      (p.unlockedFlags.contains('ssa_international') ||
          p.unlockedFlags.contains('ssa_stay_international'));

  /// 預測／最終 IB 分（滿分 45）— 按 6 科 HL/SL + TOK/EE core
  static int calculateScore(Player p, {bool missed = false}) {
    return IbCurriculum.calculateDiploma(p, missed: missed).total;
  }

  static IbTier tierFromScore(int score, {bool diplomaOk = true}) {
    if (!diplomaOk && score < 28) return IbTier.fail;
    if (score >= 43) return IbTier.perfect;
    if (score >= 39) return IbTier.outstanding;
    if (score >= 30) return IbTier.competitive;
    if (score >= 24 && diplomaOk) return IbTier.diploma;
    if (score >= 24 && !diplomaOk) return IbTier.fail; // 有 1 分／HL 不足等
    return IbTier.fail;
  }

  /// 考完 IB Diploma
  static String applyDiplomaResult(Player p, {bool missed = false}) {
    if (!p.completedExams.contains('ib_dp_subjects') ||
        p.ibSubjectSlots.length != 6) {
      IbCurriculum.autoSelectPackage(p);
    }

    final result = IbCurriculum.calculateDiploma(p, missed: missed);
    final score = result.total;
    final tier = tierFromScore(score, diplomaOk: result.diplomaOk);
    p.ibScore = score;
    p.ibTier = tier;
    p.completedExams.add('ib_diploma');
    p.education = EducationLevel.f6;
    p.isStudying = true;
    p.lifeStage = LifeStage.adult;
    p.currentSector = CareerSector.student;
    p.studyProgram = 'IB Diploma · $score/45';

    // 放榜清舊職業 flag；med/law 學位要大學畢業先解鎖（同 JUPAS）
    p.unlockedFlags.removeAll([
      'med_degree',
      'law_degree',
      'studying_medicine',
      'studying_law',
      'studying_pharmacy',
      'pharm_degree',
    ]);

    for (final line in result.breakdown) {
      p.eventLog.add('${p.year}年 IB：$line');
    }

    switch (tier) {
      case IbTier.perfect:
        p.unlockedFlags.addAll([
          'ib_diploma',
          'ib_elite',
          'local_non_jupas_ready',
        ]);
        p.jobTitle = 'IB $score 分 · 放榜待選校';
        p.eventLog.add('${p.year}年：IB Diploma $score 分（頂尖）。');
      case IbTier.outstanding:
        p.unlockedFlags.addAll([
          'ib_diploma',
          'ib_high',
          'local_non_jupas_ready',
        ]);
        p.jobTitle = 'IB $score 分 · 放榜待選校';
        p.eventLog.add('${p.year}年：IB Diploma $score 分（優秀）。');
      case IbTier.competitive:
        p.unlockedFlags.addAll([
          'ib_diploma',
          'local_non_jupas_ready',
        ]);
        p.jobTitle = 'IB $score 分 · 放榜待選校';
        p.eventLog.add('${p.year}年：IB Diploma $score 分。');
      case IbTier.diploma:
        p.unlockedFlags.addAll(['ib_diploma', 'local_non_jupas_ready']);
        p.jobTitle = 'IB $score 分 · 待選校';
        p.eventLog.add('${p.year}年：IB Diploma $score 分（剛過）。');
      case IbTier.fail:
        p.unlockedFlags.add('ib_fail');
        p.jobTitle = 'IB 未獲 Diploma（$score）';
        p.isStudying = false;
        p.currentSector = CareerSector.none;
        p.eventLog.add(
          '${p.year}年：IB $score 分，未獲 Diploma'
          '${result.diplomaOk ? "" : "（HL／核心條件未達）"}。',
        );
      case IbTier.none:
        break;
    }

    return 'IB Diploma：$score / 45 · ${tier.label}\n'
        '${IbCurriculum.subjectsLabel(p)}';
  }

  /// 升學決定（考完 IB 之後）
  /// 海外路線目前未開放 — 會提示並改派本地非聯招（若誤呼叫）。
  static String applyUniversityChoice(Player p, IbUniPath path, {Random? random}) {
    final rng = random ?? Random(p.year * 41 + p.ibScore);

    // 海外未開發：唔俾選，誤呼叫則轉本地
    if (path == IbUniPath.overseasElite || path == IbUniPath.overseas) {
      path = IbUniPath.localNonJupas;
    }

    p.ibUniPath = path;
    p.completedExams.add('ib_university');
    p.lifeStage = LifeStage.adult;

    switch (path) {
      case IbUniPath.overseasElite:
      case IbUniPath.overseas:
        return applyUniversityChoice(p, IbUniPath.localNonJupas, random: rng);

      case IbUniPath.localNonJupas:
        if (p.ibTier == IbTier.fail) {
          return applyUniversityChoice(p, IbUniPath.foundation, random: rng);
        }
        String school;
        if (p.ibTier.index >= IbTier.outstanding.index) {
          school = rng.nextBool() ? '港大（非聯招）' : '中大（非聯招）';
          p.unlockedFlags.addAll(['elite_uni', 'local_uni']);
          if (p.streamAffinity == StreamAffinity.science && p.smarts >= 75) {
            p.unlockedFlags.add('studying_medicine');
          } else if (p.streamAffinity == StreamAffinity.arts && p.smarts >= 70) {
            p.unlockedFlags.add('studying_law');
          }
        } else if (p.ibTier.index >= IbTier.competitive.index) {
          final opts = ['港大（非聯招）', '中大（非聯招）', '科大（非聯招）', '城大（非聯招）'];
          school = opts[rng.nextInt(opts.length)];
          p.unlockedFlags.add('local_uni');
        } else {
          final opts = ['城大（非聯招）', '理大（非聯招）', '浸大（非聯招）'];
          school = opts[rng.nextInt(opts.length)];
          p.unlockedFlags.add('local_uni');
        }
        p.education = EducationLevel.bachelor;
        CareerData.onStartStudying(p);
        p.isStudying = true;
        p.currentSector = CareerSector.student;
        p.bachelorYear = 1;
        p.bachelorQuarters = 0;
        UniversityLife.resetOnEnroll(p);
        p.jobTitle = school;
        p.studyProgram = 'Local Non-JUPAS';
        p.eventLog.add('${p.year}年：以 IB 成績經非聯招入讀$school。');
        return '本地非聯招：$school';

      case IbUniPath.foundation:
        return _enrollFoundationYear(p);

      case IbUniPath.associate:
        return _enrollAssoDirect(p);

      case IbUniPath.work:
        p.isStudying = false;
        p.currentSector = CareerSector.none;
        p.jobTitle = '待業（IB 後直接就業）';
        p.unlockedFlags.add('ib_work');
        p.eventLog.add('${p.year}年：唔讀大學，直接搵工。');
        return '直接就業';

      case IbUniPath.none:
        return '未選擇升學去向';
    }
  }

  /// 實際可選路徑（海外除外）
  static List<IbUniPath> availablePaths(Player p) {
    if (p.ibTier == IbTier.none) return [];
    if (p.ibTier == IbTier.fail) {
      return [IbUniPath.foundation, IbUniPath.work];
    }
    final paths = <IbUniPath>[IbUniPath.localNonJupas];
    // Diploma＝視同有副學位一般入學；可直接 Asso（唔使 Foundation）
    if (p.ibTier.index >= IbTier.diploma.index) {
      paths.add(IbUniPath.associate);
    }
    paths.add(IbUniPath.work);
    return paths;
  }

  /// UI 用：海外顯示但灰色「未開放」；其餘可揀
  static List<({IbUniPath path, bool enabled, String label})> pathChoices(
    Player p,
  ) {
    if (p.ibTier == IbTier.none) return [];

    final locked = <({IbUniPath path, bool enabled, String label})>[
      (
        path: IbUniPath.overseasElite,
        enabled: false,
        label: '海外頂尖大學（未開放）',
      ),
      (
        path: IbUniPath.overseas,
        enabled: false,
        label: '海外大學（未開放）',
      ),
    ];

    if (p.ibTier == IbTier.fail) {
      return [
        ...locked,
        (
          path: IbUniPath.foundation,
          enabled: true,
          label: 'Foundation（一年 · Pass 後視同 22222 再報 Asso）',
        ),
        (
          path: IbUniPath.work,
          enabled: true,
          label: '直接就業',
        ),
      ];
    }

    final open = <({IbUniPath path, bool enabled, String label})>[
      (
        path: IbUniPath.localNonJupas,
        enabled: true,
        label: '本地大學（非聯招）',
      ),
      (
        path: IbUniPath.associate,
        enabled: true,
        label: '社區 Asso／HD（IB Diploma＝有副學位入場資格）',
      ),
      (
        path: IbUniPath.work,
        enabled: true,
        label: '直接就業',
      ),
    ];
    return [...locked, ...open];
  }

  /// IB Fail：讀一年 Foundation（同 DSE 未達 22222）
  static String _enrollFoundationYear(Player p) {
    p.unlockedFlags.add('ib_fail');
    final msg = FoundationPathway.enroll(p, source: 'IB 未獲 Diploma');
    if (!FoundationPathway.isStudying(p)) {
      // 學費不足等：撤回升學完成標記
      p.completedExams.remove('ib_university');
      p.ibUniPath = IbUniPath.none;
      return msg;
    }
    p.unlockedFlags.add('ib_foundation');
    return msg;
  }

  /// 有 IB Diploma：直接入社區 Asso（視同已有 22222）
  static String _enrollAssoDirect(Player p) {
    final prog = _pickFoundationProgramme(p);
    CareerData.onStartStudying(p);
    p.ibUniPath = IbUniPath.associate;
    p.jupasPath = JupasPath.associate;
    p.jupasCode = prog.code;
    p.education = EducationLevel.associate;
    p.isStudying = true;
    p.currentSector = CareerSector.student;
    p.bachelorYear = 0;
    p.unlockedFlags.add('ib_diploma');
    p.unlockedFlags.add('dse_associate');
    for (final t in prog.tags) {
      if (t.startsWith('artic_') || t.startsWith('feed_')) {
        p.unlockedFlags.add(t);
      }
    }
    AssoArticulation.onEnrollAsso(p);
    final fromIb = 2.5 + ((p.ibScore.clamp(24, 45) - 24) / 21) * 1.0;
    p.assoGpa = double.parse(fromIb.clamp(2.2, 3.6).toStringAsFixed(2));
    p.jobTitle =
        '${prog.institution} · Asso Year 1 · GPA ${p.assoGpa}';
    p.studyProgram = '${prog.displayName}（IB 直入）';
    p.eventLog.add(
      '${p.year}年：以 IB Diploma 直入 ${prog.displayName}。'
      '起步 GPA ${p.assoGpa}；之後可 Non-JUPAS 銜接。',
    );
    return '社區 Asso／HD\n${prog.displayName}\n'
        'Year 1 · GPA ${p.assoGpa}';
  }

  static JupasProgramme _pickFoundationProgramme(Player p) {
    final preferred = <String>[];
    if (p.streamAffinity == StreamAffinity.science) {
      preferred.addAll(['AD-UST-SCI', 'AD-HKCC-SCI', 'AD-SPACE-SCI']);
    } else if (p.streamAffinity == StreamAffinity.arts) {
      preferred.addAll(['AD-SPACE-ARTS', 'AD-BU-ARTS', 'AD-LIFE-ARTS']);
    }
    preferred.addAll([
      'AD-EDU-LIB',
      'AD-SCOPE-SOC',
      'AD-SPACE-SOC',
      'AD-HKCC-BIZ',
    ]);
    for (final code in preferred) {
      final prog = JupasCatalogue.byCode(code);
      if (prog != null) return prog;
    }
    return JupasCatalogue.all.firstWhere(
      (x) =>
          x.tags.contains('community') &&
          x.award == JupasAward.associate,
      orElse: () => JupasCatalogue.all.first,
    );
  }
}
