import '../../models/player.dart';
import '../elective_subjects.dart';
import 'dse_grade_generator.dart';
import 'jupas_catalogue.dart';
import 'jupas_models.dart';
import 'jupas_requirements.dart';

class JupasMatch {
  final JupasProgramme programme;
  final int score;
  final bool meetsExpected;

  const JupasMatch({
    required this.programme,
    required this.score,
    required this.meetsExpected,
  });
}

/// 按分科成績配對可入課程（模組化核心）
abstract final class JupasMatcher {
  static Map<String, int> gradesOf(Player p) {
    if (p.dseGrades.isNotEmpty) return p.dseGrades;
    // 舊存檔／未生成：即時估
    return DseGradeGenerator.generate(p);
  }

  static bool isSocialWorkProgramme(JupasProgramme prog) {
    final n = '${prog.nameZh} ${prog.nameEn}'.toLowerCase();
    return n.contains('social work') ||
        n.contains('社工') ||
        prog.tags.contains('social_work');
  }

  /// Asso 背景／留位課程 → 升學士優勢（社工、對口院校等）
  static int articulationBoost(Player p, JupasProgramme prog) {
    final tags = <String>{
      ...p.unlockedFlags.where(
        (f) => f.startsWith('artic_') || f.startsWith('feed_'),
      ),
    };
    final hold = p.assoHoldCode.isEmpty
        ? null
        : JupasCatalogue.byCode(p.assoHoldCode);
    if (hold != null) {
      tags.addAll(
        hold.tags.where((t) => t.startsWith('artic_') || t.startsWith('feed_')),
      );
    }
    if (tags.isEmpty) return 0;

    var b = 0;
    if (tags.contains('artic_social_work') && isSocialWorkProgramme(prog)) {
      b += 5;
    }
    if (tags.contains('artic_social') && prog.tags.contains('social')) {
      b += 2;
    }
    if (tags.contains('artic_business') && prog.tags.contains('business')) {
      b += 3;
    }
    if (tags.contains('artic_stem') &&
        (prog.tags.contains('stem') || prog.tags.contains('engineering'))) {
      b += 3;
    }
    if (tags.contains('artic_engineering') &&
        prog.tags.contains('engineering')) {
      b += 3;
    }
    if (tags.contains('artic_arts') && prog.tags.contains('arts')) {
      b += 3;
    }
    if (tags.contains('artic_education') &&
        prog.tags.contains('education')) {
      b += 3;
    }
    if (tags.contains('artic_nursing') && prog.tags.contains('nursing')) {
      b += 3;
    }
    if (tags.contains('artic_health') &&
        (prog.tags.contains('health') ||
            prog.tags.contains('nursing') ||
            prog.tags.contains('pharmacy'))) {
      b += 3;
    }
    if (tags.contains('artic_law') && prog.tags.contains('law')) {
      b += 4;
    }
    for (final t in tags) {
      if (t.startsWith('feed_')) {
        final uni = t.substring('feed_'.length);
        if (prog.institution == uni) b += 2;
      }
    }
    return b;
  }

  static List<JupasMatch> eligibleMatches(
    Player p, {
    JupasAward? award,
  }) {
    final grades = gradesOf(p);
    final list = <JupasMatch>[];
    final hasAsso = JupasRequirements.hasAssoEntrance(p, grades);
    final hasDegree = JupasRequirements.hasDegreeEntrance(p, grades);
    final foundationPass = p.unlockedFlags.contains('foundation_pass');

    for (final prog in JupasCatalogue.all) {
      if (award != null && prog.award != award) continue;

      final isAsso = prog.award == JupasAward.associate ||
          prog.award == JupasAward.higherDiploma;
      final isDegree = prog.award == JupasAward.bachelor;

      // GER：入場資格（課程 PER 另計）
      if (isAsso && !hasAsso) continue;
      if (isDegree && !prog.tags.contains('community') && !hasDegree) {
        continue;
      }

      // Foundation Pass：視同 22222，社區 Asso／HD 可豁免 DSE 科目檢查
      final programmeOk = foundationPass &&
              isAsso &&
              prog.tags.contains('community')
          ? true
          : JupasRequirements.meetsAll(p, prog, grades);
      if (!programmeOk) continue;

      var adj = JupasRequirements.admissionScore(prog, grades);
      if (p.dseSittingCount > 1 && prog.tags.contains('elite')) {
        adj -= 2;
      }
      adj += articulationBoost(p, prog);
      list.add(JupasMatch(
        programme: prog,
        score: adj,
        meetsExpected: adj >= prog.expectedScore - 2,
      ));
    }
    list.sort((a, b) {
      final ae = a.meetsExpected ? 1 : 0;
      final be = b.meetsExpected ? 1 : 0;
      if (ae != be) return be.compareTo(ae);
      if (a.score != b.score) return b.score.compareTo(a.score);
      return b.programme.expectedScore.compareTo(a.programme.expectedScore);
    });
    return list;
  }

  /// 按傾向／選修／Asso 銜接加權排序
  static List<JupasMatch> rankedForPlayer(Player p, {int limit = 8}) {
    final matches = eligibleMatches(p);
    if (matches.isEmpty) return [];

    int affinityBoost(JupasProgramme prog) {
      var b = 0;
      final tags = prog.tags;
      switch (p.streamAffinity) {
        case StreamAffinity.science:
          if (tags.contains('stem') ||
              tags.contains('engineering') ||
              tags.contains('med') ||
              tags.contains('pharmacy')) {
            b += 3;
          }
        case StreamAffinity.arts:
          if (tags.contains('arts') ||
              tags.contains('social') ||
              tags.contains('law') ||
              tags.contains('education')) {
            b += 3;
          }
        case StreamAffinity.none:
          break;
      }
      for (final id in p.electiveIds) {
        if (id == 'bio' || id == 'chem') {
          if (tags.contains('med') || tags.contains('pharmacy')) b += 2;
        }
        if (id == 'econ' || id == 'bafs') {
          if (tags.contains('business')) b += 2;
        }
        if (id == 'ict' && tags.contains('stem')) b += 1;
      }
      if (p.unlockedFlags.contains('jupas_elite_track') &&
          tags.contains('elite')) {
        b += 2;
      }
      return b;
    }

    final scored = matches.map((m) {
      final weight = m.score + affinityBoost(m.programme);
      return (m: m, w: weight);
    }).toList()
      ..sort((a, b) => b.w.compareTo(a.w));

    return scored.take(limit).map((e) => e.m).toList();
  }
}
