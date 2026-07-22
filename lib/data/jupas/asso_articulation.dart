import 'dart:math';

import '../../models/enums.dart';
import '../../models/game_event.dart';
import '../../models/player.dart';
import '../career_data.dart';
import '../university_life.dart';
import 'jupas_catalogue.dart';
import 'jupas_matcher.dart';
import 'jupas_models.dart';

/// 副學士／HD → 大學 Non-JUPAS（Year 1 或 Year 2 銜接）
///
/// 真實簡化依據：
/// - CityU 等：通常 CGPA ≥ 3.0 先有競爭力；個別課程更高
/// - HKU senior year：文／理／工／社科／護理等有位；醫／牙／法／商多數唔喺 senior list
/// - Year 1 AD 學生：一般只可申請 Non-JUPAS Year 1，唔入 senior year
/// - 對口學科 GPA 要求可略降
abstract final class AssoArticulation {
  static const int appFee = 600;
  static const int maxChoicesShown = 10;

  static bool isOnAssoTrack(Player p) =>
      p.education == EducationLevel.associate &&
      (p.isStudying || p.unlockedFlags.contains('asso_graduated'));

  static bool canApplyYear1(Player p) =>
      p.education == EducationLevel.associate &&
      p.isStudying &&
      p.assoYear == 1 &&
      p.assoGpa > 0 &&
      !p.unlockedFlags.contains('artic_pending');

  /// Year 2 讀緊（final year）或已畢業
  static bool canApplyYear2(Player p) =>
      p.education == EducationLevel.associate &&
      p.assoGpa > 0 &&
      !p.unlockedFlags.contains('artic_pending') &&
      (p.unlockedFlags.contains('asso_graduated') ||
          (p.isStudying && p.assoYear >= 2));

  static JupasProgramme? currentAsso(Player p) {
    if (p.jupasCode.isEmpty) return null;
    final prog = JupasCatalogue.byCode(p.jupasCode);
    if (prog == null) return null;
    if (prog.award == JupasAward.associate ||
        prog.award == JupasAward.higherDiploma) {
      return prog;
    }
    return null;
  }

  /// 對口 Asso → 學士：GPA 門檻 −0.2
  static bool isRelated(Player p, JupasProgramme bach) {
    final asso = currentAsso(p);
    if (asso == null) return false;
    if (asso.tags.contains('artic_social_work') &&
        JupasMatcher.isSocialWorkProgramme(bach)) {
      return true;
    }
    const fields = [
      'social',
      'business',
      'stem',
      'engineering',
      'arts',
      'education',
      'nursing',
      'health',
      'law',
    ];
    for (final f in fields) {
      if (asso.tags.contains(f) && bach.tags.contains(f)) return true;
    }
    for (final t in asso.tags) {
      if (t.startsWith('feed_') &&
          bach.institution == t.substring('feed_'.length)) {
        // 同校 + 任一共同學科 tag
        if (fields.any((f) => asso.tags.contains(f) && bach.tags.contains(f))) {
          return true;
        }
      }
    }
    return false;
  }

  static double gpaRequired(Player p, JupasProgramme bach) {
    var min = bach.nonJupasGpaMin;
    if (isRelated(p, bach)) min -= 0.2;
    return double.parse(min.clamp(2.5, 4.0).toStringAsFixed(1));
  }

  static List<JupasMatch> eligibleForEntry(Player p, {required int entryYear}) {
    final list = <JupasMatch>[];
    for (final prog in JupasCatalogue.all) {
      if (prog.award != JupasAward.bachelor) continue;
      if (entryYear == 1 && !prog.acceptsNonJupasYear1) continue;
      if (entryYear == 2 && !prog.acceptsNonJupasYear2) continue;
      final need = gpaRequired(p, prog);
      if (p.assoGpa + 0.15 < need) continue; // 差太遠唔顯示
      final score = ((p.assoGpa - need) * 10).round() +
          JupasMatcher.articulationBoost(p, prog);
      list.add(JupasMatch(
        programme: prog,
        score: score,
        meetsExpected: p.assoGpa >= need,
      ));
    }
    list.sort((a, b) {
      final ar = isRelated(p, a.programme) ? 1 : 0;
      final br = isRelated(p, b.programme) ? 1 : 0;
      if (ar != br) return br.compareTo(ar);
      if (a.meetsExpected != b.meetsExpected) {
        return (b.meetsExpected ? 1 : 0).compareTo(a.meetsExpected ? 1 : 0);
      }
      return b.score.compareTo(a.score);
    });
    return list;
  }

  /// 入讀 Asso 時初始化
  static void onEnrollAsso(Player p) {
    p.assoYear = 1;
    p.assoQuarters = 0;
    p.assoGpa = _seedGpa(p);
    p.bachelorYear = 0;
    p.unlockedFlags.remove('asso_graduated');
    p.unlockedFlags.remove('artic_pending');
  }

  static double _seedGpa(Player p) {
    final base = 2.2 + (p.smarts / 100) * 1.4 + (p.discipline / 100) * 0.4;
    return double.parse(base.clamp(2.0, 3.6).toStringAsFixed(2));
  }

  /// 每季推進；滿 4 季＝讀完一年
  static String? tickQuarter(Player p, {Random? random}) {
    if (!p.isStudying || p.education != EducationLevel.associate) {
      return null;
    }
    if (p.assoYear < 1) p.assoYear = 1;
    p.assoQuarters += 1;
    // 勤力／智慧微調 GPA
    final delta = ((p.smarts - 50) + (p.discipline - 50)) / 800.0;
    p.assoGpa = double.parse(
      (p.assoGpa + delta * 0.25).clamp(1.5, 4.0).toStringAsFixed(2),
    );

    if (p.assoQuarters < 4) return null;

    // 學年結束
    p.assoQuarters = 0;
    final rng = random ?? Random(p.year * 31 + p.assoYear * 7);
    final yearDelta = (rng.nextDouble() - 0.35) * 0.35;
    p.assoGpa = double.parse(
      (p.assoGpa + yearDelta).clamp(1.7, 4.0).toStringAsFixed(2),
    );

    if (p.assoYear == 1) {
      p.assoYear = 2;
      p.jobTitle =
          '${currentAsso(p)?.institution ?? "社區院校"} · Year 2 · GPA ${p.assoGpa}';
      p.eventLog.add(
        '${p.year}年：副學士升上 Year 2 · 累積 GPA ${p.assoGpa}。'
        '而家可申請 Non-JUPAS Year 2 銜接（或繼續讀完）。',
      );
      return '副學士升 Year 2\nGPA ${p.assoGpa}\n可申請 Non-JUPAS Year 2 銜接';
    }

    // Year 2 完 → 畢業
    p.isStudying = false;
    p.currentSector = CareerSector.none;
    p.unlockedFlags.add('asso_graduated');
    final asso = currentAsso(p);
    if (asso != null &&
        (asso.tags.contains('artic_social_work') ||
            asso.tags.contains('social') ||
            asso.tags.contains('social_work'))) {
      p.unlockedFlags.add('asso_social');
    }
    p.jobTitle = '副學士畢業 · GPA ${p.assoGpa} · 可銜接';
    p.eventLog.add(
      '${p.year}年：完成副學士／HD（GPA ${p.assoGpa}）。'
      '可申請 Non-JUPAS Year 2 銜接升大學。',
    );
    return '副學士畢業\nGPA ${p.assoGpa}\n可申請 Non-JUPAS Year 2 銜接';
  }

  static String studyAction(Player p) {
    if (!p.isStudying || p.education != EducationLevel.associate) {
      return '而家唔係讀緊副學士。';
    }
    p.smarts = (p.smarts + 3).clamp(0, 100);
    p.discipline = (p.discipline + 2).clamp(0, 100);
    p.san = (p.san - 2).clamp(0, p.maxSan);
    p.assoGpa = double.parse(
      (p.assoGpa + 0.04).clamp(1.5, 4.0).toStringAsFixed(2),
    );
    return '溫書中 · GPA 現 ${p.assoGpa}（Year ${p.assoYear}）';
  }

  static String applyTo(
    Player p,
    String code, {
    required int entryYear,
    Random? random,
  }) {
    if (entryYear == 1 && !canApplyYear1(p)) {
      return 'Year 1 銜接：只限讀緊副學士 Year 1。';
    }
    if (entryYear == 2 && !canApplyYear2(p)) {
      return 'Year 2 銜接：要 Year 2／已畢業。';
    }
    final prog = JupasCatalogue.byCode(code);
    if (prog == null || prog.award != JupasAward.bachelor) {
      return '課程唔存在。';
    }
    if (entryYear == 1 && !prog.acceptsNonJupasYear1) {
      return '${prog.code} 唔收 Non-JUPAS Year 1。';
    }
    if (entryYear == 2 && !prog.acceptsNonJupasYear2) {
      return '${prog.code} 唔收 Non-JUPAS senior year（神科／例外）。';
    }
    if (p.wealth < appFee) {
      return '申請費不足：需要 \$$appFee';
    }

    p.wealth -= appFee;
    final need = gpaRequired(p, prog);
    final related = isRelated(p, prog);
    final rng = random ?? Random(p.year * 17 + code.hashCode);
    final gpa = p.assoGpa;

    var chance = 0.0;
    if (gpa >= need + 0.3) {
      chance = 0.85;
    } else if (gpa >= need) {
      chance = 0.55;
    } else if (gpa >= need - 0.15) {
      chance = 0.25;
    } else {
      chance = 0.05;
    }
    if (related) chance = (chance + 0.12).clamp(0.0, 0.95);
    chance += JupasMatcher.articulationBoost(p, prog) * 0.01;

    final ok = rng.nextDouble() < chance;
    final note = related ? '（對口 Asso，GPA 門檻已略降）' : '';

    if (!ok) {
      p.eventLog.add(
        '${p.year}年：Non-JUPAS ${prog.code} Year $entryYear 失敗'
        '（GPA $gpa／要求 $need$note）。',
      );
      return '未取錄：${prog.shortLabel}\n'
          '你嘅 GPA $gpa · 要求 ≥$need$note\n'
          '可繼續讀／再申請其他科。';
    }

    return _enrollBachelor(p, prog, entryYear: entryYear, note: note);
  }

  static String _enrollBachelor(
    Player p,
    JupasProgramme prog, {
    required int entryYear,
    required String note,
  }) {
    CareerData.onStartStudying(p);
    p.jupasCode = prog.code;
    p.jupasPath = JupasPath.bachelor;
    p.education = EducationLevel.bachelor;
    p.isStudying = true;
    p.currentSector = CareerSector.student;
    p.bachelorYear = entryYear;
    p.bachelorQuarters = 0;
    UniversityLife.resetOnEnroll(p);
    p.unlockedFlags.add('local_uni');
    p.unlockedFlags.add('dse_university');
    p.unlockedFlags.remove('asso_graduated');
    p.unlockedFlags.remove('dse_associate');
    if (prog.tags.contains('elite')) {
      p.unlockedFlags.add('elite_uni');
    }
    if (prog.tags.contains('med')) {
      p.unlockedFlags.add('studying_medicine');
    } else if (prog.tags.contains('law')) {
      p.unlockedFlags.add('studying_law');
    } else if (prog.tags.contains('pharmacy')) {
      p.unlockedFlags.add('studying_pharmacy');
    } else if (prog.tags.contains('nursing')) {
      p.unlockedFlags.add('studying_nursing');
    } else if (prog.tags.contains('social') ||
        prog.tags.contains('social_work')) {
      p.unlockedFlags.add('studying_social');
    } else if (prog.tags.contains('education')) {
      p.unlockedFlags.add('studying_education');
    }
    p.jobTitle =
        '${prog.institution} · Year $entryYear · ${prog.nameZh}';
    p.studyProgram = '${prog.displayName}（Non-JUPAS Year $entryYear）';
    p.dseTier = DseTier.university;
    p.eventLog.add(
      '${p.year}年：Non-JUPAS 取錄 ${prog.displayName}'
      '（入 Year $entryYear · GPA ${p.assoGpa}$note）。',
    );
    return 'Non-JUPAS 取錄\n${prog.displayName}\n'
        '入讀大學 Year $entryYear\nGPA ${p.assoGpa}$note';
  }

  static StoryEvent applicationEvent(Player p, {required int entryYear}) {
    final matches = eligibleForEntry(p, entryYear: entryYear)
        .take(maxChoicesShown)
        .toList();
    final choices = <EventChoice>[
      for (final m in matches)
        EventChoice(
          label: _choiceLabel(p, m.programme, entryYear),
          apply: (pl) => applyTo(pl, m.programme.code, entryYear: entryYear),
        ),
      EventChoice(
        label: '暫時唔申請',
        apply: (_) {},
      ),
    ];
    return StoryEvent(
      id: 'asso_artic_y$entryYear',
      title: 'Non-JUPAS · 申請大學 Year $entryYear',
      body:
          '而家：副學士 Year ${p.assoYear}'
          '${p.unlockedFlags.contains("asso_graduated") ? "（已畢業）" : ""}\n'
          '累積 GPA：${p.assoGpa}（4.0 制）\n'
          '申請費 \$$appFee · 主要睇 GPA，唔係 JUPAS 計分。\n'
          '神科（醫／牙／法／藥等）基本上唔收。'
          '對口 Asso GPA 要求可降 0.2。\n'
          '顯示合資格／接近嘅課程：',
      choices: choices,
      isSystem: true,
    );
  }

  static String _choiceLabel(Player p, JupasProgramme prog, int entryYear) {
    final need = gpaRequired(p, prog);
    final rel = isRelated(p, prog) ? ' · 對口−0.2' : '';
    final block = prog.blocksNonJupas ? ' · 唔收' : '';
    return '${prog.code} ${prog.nameEn}（${prog.institution} · '
        'GPA≥$need$rel · 入Y$entryYear$block）';
  }
}
