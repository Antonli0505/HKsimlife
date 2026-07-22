import '../jupas_models.dart';

/// 各大學對應社區院校：按主要學院／學系方向各配 **1 個 Asso／HD**。
///
/// tags：`feed_港大` 等對口院校；`artic_*` 升讀對應學士有優勢。
List<JupasProgramme> communityProgrammes() => [
      // ════════ 港大 SPACE CC → 港大 ════════
      ..._uni(
        feed: '港大',
        school: '港大 SPACE CC',
        prefix: 'SPACE',
        sections: const [
          _Sec('ARTS', '人文學副學士', 'AD in Arts', 'arts', ['artic_arts']),
          _Sec('SOC', '社會科學副學士', 'AD in Social Sciences', 'social',
              ['artic_social', 'artic_social_work']),
          _Sec('BIZ', '商業學副學士', 'AD in Business', 'business',
              ['artic_business']),
          _Sec('SCI', '理學副學士', 'AD in Science', 'stem', ['artic_stem']),
          _Sec('ENG', '工程學副學士', 'AD in Engineering', 'engineering',
              ['artic_engineering', 'artic_stem']),
          _Sec('NUR', '護理學高級文憑', 'HD in Nursing Studies', 'nursing',
              ['artic_nursing', 'artic_health'],
              hd: true),
          _Sec('LAW', '法律學副學士', 'AD in Legal Studies', 'law',
              ['artic_law']),
        ],
      ),

      // ════════ 中大 CUSCS → 中大 ════════
      ..._uni(
        feed: '中大',
        school: '中大 CUSCS',
        prefix: 'CUSCS',
        sections: const [
          _Sec('ARTS', '中國語文及文化副學士', 'AD in Chinese Studies', 'arts',
              ['artic_arts']),
          _Sec('SOC', '社會科學副學士', 'AD in Social Sciences', 'social',
              ['artic_social', 'artic_social_work']),
          _Sec('BIZ', '商學副學士', 'AD in Business Administration', 'business',
              ['artic_business']),
          _Sec('SCI', '理學副學士', 'AD in Science', 'stem', ['artic_stem']),
          _Sec('ENG', '工程學副學士', 'AD in Engineering', 'engineering',
              ['artic_engineering', 'artic_stem']),
          _Sec('EDU', '教育學副學士', 'AD in Education Studies', 'education',
              ['artic_education']),
          _Sec('NUR', '健康護理高級文憑', 'HD in Health Care', 'health',
              ['artic_health', 'artic_nursing'],
              hd: true),
        ],
      ),

      // ════════ 科大銜接向 → 科大 ════════
      ..._uni(
        feed: '科大',
        school: '社區銜接（科大向）',
        prefix: 'UST',
        sections: const [
          _Sec('SCI', '應用科學副學士', 'AD in Applied Science', 'stem',
              ['artic_stem']),
          _Sec('ENG', '工程學副學士', 'AD in Engineering', 'engineering',
              ['artic_engineering', 'artic_stem']),
          _Sec('BIZ', '商學及管理副學士', 'AD in Business & Management', 'business',
              ['artic_business']),
          _Sec('DATA', '數據科學副學士', 'AD in Data Science', 'stem',
              ['artic_stem']),
          _Sec('SOC', '社會科學副學士', 'AD in Social Sciences', 'social',
              ['artic_social']),
        ],
      ),

      // ════════ 城大 SCOPE → 城大 ════════
      ..._uni(
        feed: '城大',
        school: '城大 SCOPE',
        prefix: 'SCOPE',
        sections: const [
          _Sec('ARTS', '創意媒體副學士', 'AD in Creative Media', 'arts',
              ['artic_arts']),
          _Sec('SOC', '應用社會科學副學士', 'AD in Applied Social Sciences', 'social',
              ['artic_social', 'artic_social_work']),
          _Sec('BIZ', '工商管理副學士', 'AD in Business Management', 'business',
              ['artic_business']),
          _Sec('SCI', '應用科學副學士', 'AD in Applied Science', 'stem',
              ['artic_stem']),
          _Sec('ENG', '工程學副學士', 'AD in Engineering', 'engineering',
              ['artic_engineering', 'artic_stem']),
          _Sec('LAW', '法律學副學士', 'AD in Legal Studies', 'law',
              ['artic_law']),
        ],
      ),

      // ════════ 理大 HKCC → 理大 ════════
      ..._uni(
        feed: '理大',
        school: '理大 HKCC',
        prefix: 'HKCC',
        sections: const [
          _Sec('BIZ', '工商業副學士', 'AD in Business', 'business',
              ['artic_business']),
          _Sec('ENG', '工程副學士', 'AD in Engineering', 'engineering',
              ['artic_engineering', 'artic_stem']),
          _Sec('SCI', '應用科學副學士', 'AD in Applied Science', 'stem',
              ['artic_stem']),
          _Sec('SOC', '社會科學副學士', 'AD in Social Sciences', 'social',
              ['artic_social', 'artic_social_work']),
          _Sec('NUR', '健康科學高級文憑', 'HD in Health Sciences', 'health',
              ['artic_health', 'artic_nursing'],
              hd: true),
          _Sec('DES', '設計副學士', 'AD in Design', 'arts', ['artic_arts']),
          _Sec('HTM', '酒店及旅遊副學士', 'AD in Hotel & Tourism', 'business',
              ['artic_business']),
        ],
      ),

      // ════════ 浸大 CIE → 浸大 ════════
      ..._uni(
        feed: '浸大',
        school: '浸大 CIE',
        prefix: 'BU',
        sections: const [
          _Sec('COM', '傳理副學士', 'AD in Communication', 'arts',
              ['artic_arts']),
          _Sec('SOC', '社會工作副學士', 'AD in Social Work', 'social',
              ['artic_social', 'artic_social_work']),
          _Sec('BIZ', '商學副學士', 'AD in Business', 'business',
              ['artic_business']),
          _Sec('SCI', '理學副學士', 'AD in Science', 'stem', ['artic_stem']),
          _Sec('ARTS', '人文及語文副學士', 'AD in Arts & Languages', 'arts',
              ['artic_arts']),
          _Sec('CMED', '中醫藥學高級文憑', 'HD in Chinese Medicine Studies', 'health',
              ['artic_health'],
              hd: true),
        ],
      ),

      // ════════ 嶺大 LIFE → 嶺大 ════════
      ..._uni(
        feed: '嶺大',
        school: '嶺大 LIFE',
        prefix: 'LIFE',
        sections: const [
          _Sec('ARTS', '人文學副學士', 'AD in Humanities', 'arts',
              ['artic_arts']),
          _Sec('SOC', '社會科學副學士', 'AD in Social Sciences', 'social',
              ['artic_social', 'artic_social_work']),
          _Sec('BIZ', '商學副學士', 'AD in Business Studies', 'business',
              ['artic_business']),
          _Sec('SCI', '數據及資訊副學士', 'AD in Data & Information Studies', 'stem',
              ['artic_stem']),
        ],
      ),

      // ════════ 教大 → 教大 ════════
      ..._uni(
        feed: '教大',
        school: '教大',
        prefix: 'EDU',
        sections: const [
          _Sec('ECE', '幼兒教育副學士', 'AD in Early Childhood Education',
              'education', ['artic_education']),
          _Sec('EDU', '教育學副學士', 'AD in Education', 'education',
              ['artic_education']),
          _Sec('ARTS', '人文及語言教育副學士', 'AD in Liberal Arts Education', 'arts',
              ['artic_education', 'artic_arts']),
          _Sec('SOC', '社會科學教育副學士', 'AD in Social Sciences Education',
              'social', ['artic_education', 'artic_social']),
          _Sec('SCI', '科學教育副學士', 'AD in Science Education', 'stem',
              ['artic_education', 'artic_stem']),
          _Sec('PE', '體育教育高級文憑', 'HD in Physical Education', 'education',
              ['artic_education'],
              hd: true),
        ],
      ),
    ];

class _Sec {
  final String id;
  final String nameZh;
  final String nameEn;
  final String fieldTag;
  final List<String> artic;
  final bool hd;
  const _Sec(
    this.id,
    this.nameZh,
    this.nameEn,
    this.fieldTag,
    this.artic, {
    this.hd = false,
  });
}

List<JupasProgramme> _uni({
  required String feed,
  required String school,
  required String prefix,
  required List<_Sec> sections,
}) {
  return [
    for (final s in sections)
      JupasProgramme(
        code: '${s.hd ? "HD" : "AD"}-$prefix-${s.id}',
        nameZh: s.nameZh,
        nameEn: s.nameEn,
        institution: school,
        award: s.hd ? JupasAward.higherDiploma : JupasAward.associate,
        chinMin: 2,
        engMin: 2,
        mathMin: 2,
        requireCsdAttained: false,
        // 課程 PER（喺 22222 GER 之上）；唔取代一般入學
        electiveRequirements: const [ElectiveRequirement.anyOneAt2],
        expectedScore: s.hd ? 11 : 12,
        tags: [
          s.hd ? 'hd' : 'associate',
          'community',
          s.fieldTag,
          'feed_$feed',
          ...s.artic,
        ],
      ),
  ];
}
