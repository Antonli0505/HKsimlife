import '../models/enums.dart';
import '../models/player.dart';
import 'jupas/jupas_catalogue.dart';
import 'university_life.dart';
import 'university_societies.dart';

/// 大學學士進度：每季 tick，畢業先解鎖學位 flag
abstract final class UniversityPathway {
  static int degreeDuration(Player p) {
    if (p.unlockedFlags.contains('studying_medicine')) return 6;
    return 4;
  }

  static bool isStudyingBachelor(Player p) =>
      p.isStudying &&
      p.education == EducationLevel.bachelor &&
      p.bachelorYear > 0;

  /// 每季推進；滿 4 季升一年或畢業（含 GPA／開支）
  static String? tickQuarter(Player p) {
    if (!isStudyingBachelor(p)) {
      final interest = UniversityLife.accrueStudentLoanInterest(p);
      final repay = UniversityLife.repayStudentLoan(p);
      final parts = [interest, repay].whereType<String>().toList();
      return parts.isEmpty ? null : parts.join('\n');
    }

    final msgs = <String>[];

    UniversitySocieties.syncHallMembership(p);

    final cost = UniversityLife.applyQuarterlyCosts(p);
    if (cost != null && cost.isNotEmpty) msgs.add(cost);

    final interest = UniversityLife.accrueStudentLoanInterest(p);
    if (interest != null) msgs.add(interest);

    if (p.quarter == Quarter.q1) {
      final exam = UniversityLife.settleExamGpa(p);
      if (exam != null && exam.isNotEmpty) msgs.add(exam);
    }

    final duty = UniversitySocieties.settleDutyNeglect(p);
    if (duty != null && duty.isNotEmpty) msgs.add(duty);

    p.bachelorQuarters++;
    if (p.bachelorQuarters < 4) {
      return msgs.isEmpty ? null : msgs.join('\n');
    }

    p.bachelorQuarters = 0;
    final yearEnd = UniversityLife.resolveAcademicYear(p);
    if (yearEnd.isNotEmpty) msgs.add(yearEnd);

    return msgs.isEmpty ? null : msgs.join('\n');
  }

  static String graduate(Player p) {
    final programme = p.studyProgram;
    final honours = UniversityLife.honoursForGpa(p.uniGpa);
    final honoursZh = UniversityLife.honoursLabelZh(honours);
    p.uniHonours = honours;

    UniversitySocieties.markAlumniOnGraduate(p);

    // Honours／Hall／學會 → 出社會起步加成（面子＝reputation）
    if (honours.startsWith('First Class')) {
      p.reputation = (p.reputation + 12).clamp(0, 100);
      p.network = (p.network + 6).clamp(0, 100);
    } else if (honours.contains('Division I')) {
      p.reputation = (p.reputation + 7).clamp(0, 100);
      p.network = (p.network + 3).clamp(0, 100);
    } else if (honours.contains('Division II')) {
      p.reputation = (p.reputation + 3).clamp(0, 100);
    }
    if (p.inHall && p.hallPoints >= 20) {
      p.network = (p.network + 5).clamp(0, 100);
    }
    if (UniversitySocieties.wasInSu(p)) {
      p.network = (p.network + 8).clamp(0, 100);
      p.reputation = (p.reputation + 5).clamp(0, 100);
    }
    if (UniversitySocieties.wasInEditorial(p)) {
      p.reputation = (p.reputation + 6).clamp(0, 100);
    }
    if (UniversitySocieties.wasHallCadre(p)) {
      p.network = (p.network + 6).clamp(0, 100);
      p.hallPoints = (p.hallPoints + 5).clamp(0, 100);
    }
    if (UniversitySocieties.wasInVolunteer(p)) {
      p.reputation = (p.reputation + 4).clamp(0, 100);
    }

    p.isStudying = false;
    p.currentSector = CareerSector.none;
    p.bachelorQuarters = 0;
    p.inHall = false;
    p.jobTitle = '大學畢業 · $honoursZh';
    p.unlockedFlags.add('bachelor_graduated');
    p.jupasPath = JupasPath.none;
    p.jupasChoices = [];
    p.completedExams.remove('jupas');

    if (p.unlockedFlags.contains('studying_medicine')) {
      p.unlockedFlags
        ..add('med_degree')
        ..remove('studying_medicine');
    }
    if (p.unlockedFlags.contains('studying_law')) {
      p.unlockedFlags
        ..add('law_degree')
        ..remove('studying_law');
    }
    if (p.unlockedFlags.contains('studying_pharmacy')) {
      p.unlockedFlags
        ..add('pharm_degree')
        ..add('pharm_local_grad')
        ..remove('studying_pharmacy');
    }
    if (p.unlockedFlags.contains('studying_nursing')) {
      p.unlockedFlags
        ..add('nursing_degree')
        ..add('nursing_license') // 本地認可課程：畢業可申請註冊
        ..remove('studying_nursing');
    }
    if (p.unlockedFlags.contains('studying_social')) {
      p.unlockedFlags
        ..add('social_degree')
        ..remove('studying_social');
    }
    if (p.unlockedFlags.contains('studying_education')) {
      p.unlockedFlags
        ..add('education_degree')
        ..remove('studying_education');
    }

    final prog = p.jupasCode.isNotEmpty
        ? JupasCatalogue.byCode(p.jupasCode)
        : null;
    if (prog != null) {
      if (prog.tags.contains('pharmacy')) {
        p.unlockedFlags
          ..add('pharm_degree')
          ..add('pharm_local_grad');
      }
      if (prog.tags.contains('nursing')) {
        p.unlockedFlags
          ..add('nursing_degree')
          ..add('nursing_license');
      }
      if (prog.tags.contains('social') ||
          prog.tags.contains('social_work')) {
        p.unlockedFlags.add('social_degree');
      }
      if (prog.tags.contains('education')) {
        p.unlockedFlags.add('education_degree');
      }
    }

    final loanNote = p.studentLoanDebt > 0
        ? '\n尚欠學生貸款 \$${p.studentLoanDebt}（之後每季自動還）'
        : '';
    final clubNote = p.uniSocietyIds.isEmpty
        ? ''
        : '\n學會經歷：${p.uniSocietyIds.map((id) => UniversitySocieties.byId(id)?.nameZh ?? id).join("、")}';
    p.eventLog.add(
      '${p.year}年：$programme 畢業 · $honoursZh'
      '（GPA ${p.uniGpa.toStringAsFixed(2)}）。',
    );
    return '恭喜畢業！$programme\n'
        '$honoursZh（$honours）\n'
        'GPA ${p.uniGpa.toStringAsFixed(2)}'
        '$clubNote'
        '$loanNote\n'
        '而家可以考專業試／搵全職。';
  }
}
