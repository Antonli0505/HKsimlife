import 'catalogue/cityu.dart';
import 'catalogue/community.dart';
import 'catalogue/cuhk.dart';
import 'catalogue/eduhk.dart';
import 'catalogue/hkbu.dart';
import 'catalogue/hku.dart';
import 'catalogue/hkmu.dart';
import 'catalogue/hkust.dart';
import 'catalogue/lingnan.dart';
import 'catalogue/polyu.dart';
import 'catalogue/sssdp.dart';
import 'jupas_models.dart';
import 'official_score_overlay.dart';

/// 全庫入口：UGC 八大 + 都會 + SSSDP + 八大對應社區 Asso／HD（按學院方向）
///
/// 學士收生公式／median：優先套用 [OfficialScoreOverlay]（JUPAS 2025 官方 PDF），
/// 唔再靠標題估 Best5／Best6／加權。
abstract final class JupasCatalogue {
  static final List<JupasProgramme> all = _build();

  static List<JupasProgramme> _build() {
    final raw = [
      ...hkuProgrammes(),
      ...cuhkProgrammes(),
      ...hkustProgrammes(),
      ...cityuProgrammes(),
      ...polyuProgrammes(),
      ...hkbuProgrammes(),
      ...lingnanProgrammes(),
      ...eduhkProgrammes(),
      ...hkmuProgrammes(),
      ...sssdpProgrammes(),
      ...communityProgrammes(),
    ];
    return [
      for (final p in raw) _applyOfficialScore(p),
    ];
  }

  static JupasProgramme _applyOfficialScore(JupasProgramme p) {
    final spec = OfficialScoreOverlay.of(p.code);
    if (spec == null) return p;
    return p.copyWith(
      formula: spec.formula,
      expectedScore: spec.expectedScore,
      subjectWeights: spec.subjectWeights,
      legacyScale: spec.legacyScale,
      tags: {
        ...p.tags,
        'official_score_2025',
      }.toList(),
    );
  }

  static JupasProgramme? byCode(String code) {
    for (final p in all) {
      if (p.code == code) return p;
    }
    return null;
  }

  static List<JupasProgramme> byInstitution(String institution) =>
      all.where((p) => p.institution == institution).toList();

  static List<JupasProgramme> byAward(JupasAward award) =>
      all.where((p) => p.award == award).toList();

  static int get count => all.length;

  static int get officialScoreCoverage =>
      all.where((p) => p.tags.contains('official_score_2025')).length;
}
