enum Quarter { q1, q2, q3, q4 }

extension QuarterExt on Quarter {
  String get label => switch (this) {
        Quarter.q1 => '第一季',
        Quarter.q2 => '第二季',
        Quarter.q3 => '第三季',
        Quarter.q4 => '第四季',
      };

  int get quarterIndex => Quarter.values.indexOf(this);
  Quarter get next => Quarter.values[(quarterIndex + 1) % 4];
}

enum BirthTier { ssr, sr, r }

extension BirthTierExt on BirthTier {
  String get label => switch (this) {
        BirthTier.ssr => 'SSR · 嘉道理/淺水灣豪門',
        BirthTier.sr => 'SR · 太古城/第一城中產',
        BirthTier.r => 'R · 公屋草根',
      };

  String get shortLabel => switch (this) {
        BirthTier.ssr => 'SSR',
        BirthTier.sr => 'SR',
        BirthTier.r => 'R',
      };

  String get description => switch (this) {
        BirthTier.ssr =>
          '屋企\$2000萬信託+豪宅（唔可以掂）· 豐厚零用錢 · 國際名校',
        BirthTier.sr =>
          '屋企\$50萬積蓄 · 智慧50 · 每週零用錢 · JUPAS 精英路',
        BirthTier.r =>
          '公屋 · 兒童綜援（18歲以下每季\$1000）· 升學靠 Grant／Loan',
      };

  String get locationTag => switch (this) {
        BirthTier.ssr => 'Kadoorie Hill / Repulse Bay',
        BirthTier.sr => 'Taikoo Shing / First City',
        BirthTier.r => 'Subsidized Public Housing',
      };
}

enum LifeStage { infant, primary, secondary, adult }

extension LifeStageExt on LifeStage {
  String get label => switch (this) {
        LifeStage.infant => '幼兒期 (0-5)',
        LifeStage.primary => '小學 (6-11)',
        LifeStage.secondary => '中學 (12-17)',
        LifeStage.adult => '成年 (18+)',
      };
}

enum SchoolBand { none, band1, band2, band3 }

extension SchoolBandExt on SchoolBand {
  String get label => switch (this) {
        SchoolBand.none => '未分配',
        SchoolBand.band1 => 'Band 1 名校',
        SchoolBand.band2 => 'Band 2',
        SchoolBand.band3 => 'Band 3',
      };

  /// 小學階段顯示用
  String get primaryLabel => switch (this) {
        SchoolBand.none => '未分配',
        SchoolBand.band1 => '小學 Band 1（名校）',
        SchoolBand.band2 => '小學 Band 2',
        SchoolBand.band3 => '小學 Band 3（區內）',
      };

  /// 中學階段顯示用
  String get secondaryLabel => switch (this) {
        SchoolBand.none => '未分配',
        SchoolBand.band1 => '中學 Band 1 名校',
        SchoolBand.band2 => '中學 Band 2',
        SchoolBand.band3 => '中學 Band 3',
      };
}

enum HousingType {
  luxury,
  privateRental,
  publicHousing,
  hos,
  ownedPrivate,
}

extension HousingTypeExt on HousingType {
  String get label => switch (this) {
        HousingType.luxury => '豪宅/半山',
        HousingType.privateRental => '私樓/租賃',
        HousingType.publicHousing => '公屋',
        HousingType.hos => '居屋',
        HousingType.ownedPrivate => '私樓自住',
      };
}

enum CareerSector {
  none,
  medical,
  pharmacy,
  legalSolicitor,
  legalBarrister,
  civilService,
  taxi,
  insurance,
  flightAttendant,
  politics,
  entertainment,
  labour,
  student,
  socialWork,
  teaching,
  nursing,
  banking,
  accounting,
  it,
  media,
  realEstate,
  engineering,
  disciplinary,
  catering,
}

extension CareerSectorExt on CareerSector {
  String get label => switch (this) {
        CareerSector.none => '待業',
        CareerSector.medical => '醫療',
        CareerSector.pharmacy => '藥劑',
        CareerSector.legalSolicitor => '事務律師',
        CareerSector.legalBarrister => '大律師',
        CareerSector.civilService => '公務員（AO／EO）',
        CareerSector.taxi => '的士',
        CareerSector.insurance => '保險',
        CareerSector.flightAttendant => '空服員',
        CareerSector.politics => '政治',
        CareerSector.entertainment => '娛樂/KOL',
        CareerSector.labour => '藍領／服務業',
        CareerSector.student => '學生',
        CareerSector.socialWork => '社福',
        CareerSector.teaching => '教學',
        CareerSector.nursing => '護理',
        CareerSector.banking => '金融銀行',
        CareerSector.accounting => '會計審計',
        CareerSector.it => 'IT／科網',
        CareerSector.media => '傳媒',
        CareerSector.realEstate => '地產',
        CareerSector.engineering => '工程',
        CareerSector.disciplinary => '紀律部隊／ICAC',
        CareerSector.catering => '餐飲管理',
      };
}

enum EducationLevel {
  none,
  f5,
  f6,
  associate,
  bachelor,
  master,
  phd,
}

extension EducationLevelExt on EducationLevel {
  String get label => switch (this) {
        EducationLevel.none => '未受正規教育',
        EducationLevel.f5 => '中五',
        EducationLevel.f6 => '中六/DSE',
        EducationLevel.associate => '副學士',
        EducationLevel.bachelor => '學士',
        EducationLevel.master => '碩士',
        EducationLevel.phd => '博士',
      };
}

enum ActionTab { career, assets, lifestyle, job }

enum GamePhase { playing, prison, dead, retired, gacha }

enum InvestigationStatus { none, police, icac, court, convicted }

enum DseTier { none, blueCollar, associate, university, godTier }

extension DseTierExt on DseTier {
  String get label => switch (this) {
        DseTier.none => '未考 DSE',
        DseTier.blueCollar => '藍領/技術路線',
        DseTier.associate => '副學士/高級文憑',
        DseTier.university => '大學學士',
        DseTier.godTier => '神科 (醫/法)',
      };
}

/// DSE 重考一年方式
enum DseRetakeMode {
  none,
  selfStudy,
  originalSchool,
  transferSchool,
}

extension DseRetakeModeExt on DseRetakeMode {
  String get label => switch (this) {
        DseRetakeMode.none => '無',
        DseRetakeMode.selfStudy => '自修生重考',
        DseRetakeMode.originalSchool => '原校重讀一年',
        DseRetakeMode.transferSchool => '轉校重讀一年',
      };
}

/// JUPAS／放榜後去向
enum JupasPath {
  none,
  deferred,
  /// 已交志願，等下一季 Main Round 結果
  awaitingOffer,
  bachelor,
  associate,
  work,
}

extension JupasPathExt on JupasPath {
  String get label => switch (this) {
        JupasPath.none => '未決定',
        JupasPath.deferred => '下屆 Q4／Q1 再報聯招',
        JupasPath.awaitingOffer => '已報聯招 · 等 Main Round',
        JupasPath.bachelor => '聯招學士',
        JupasPath.associate => '副學士／高級文憑',
        JupasPath.work => '直接就業',
      };
}

/// 大學學業投入度（影響 GPA）
enum UniStudyLoad {
  none,
  light,
  balanced,
  hard,
}

extension UniStudyLoadExt on UniStudyLoad {
  String get label => switch (this) {
        UniStudyLoad.none => '未定',
        UniStudyLoad.light => '輕鬆（社交優先）',
        UniStudyLoad.balanced => '均衡',
        UniStudyLoad.hard => '硬食（GPA 優先）',
      };
}
