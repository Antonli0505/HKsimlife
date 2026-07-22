import 'dart:convert';

import '../data/elective_subjects.dart';
import '../data/hk_school_data.dart';
import '../data/ib_pathway.dart';
import '../data/market_engine.dart';
import '../data/social_circle.dart';
import 'enums.dart';
import 'stat_baseline.dart';

class DormantCareerRecord {
  final CareerSector sector;
  final String jobTitle;
  final Map<String, dynamic> attributes;
  final int endedYear;
  final int endedAge;

  const DormantCareerRecord({
    required this.sector,
    required this.jobTitle,
    required this.attributes,
    required this.endedYear,
    required this.endedAge,
  });

  Map<String, dynamic> toJson() => {
        'sector': sector.name,
        'jobTitle': jobTitle,
        'attributes': attributes,
        'endedYear': endedYear,
        'endedAge': endedAge,
      };

  factory DormantCareerRecord.fromJson(Map<String, dynamic> json) =>
      DormantCareerRecord(
        sector: CareerSector.values.byName(json['sector'] as String),
        jobTitle: json['jobTitle'] as String,
        attributes: Map<String, dynamic>.from(json['attributes'] as Map),
        endedYear: json['endedYear'] as int,
        endedAge: json['endedAge'] as int,
      );
}

class Player {
  String name;
  int age;
  int year;
  Quarter quarter;
  int actionPoints;
  int maxActionPoints;

  // Birth & life stage
  BirthTier birthTier;
  LifeStage lifeStage;
  SchoolBand schoolBand;
  SchoolBand primaryBand;
  String primarySchoolId;
  String primarySchoolName;
  String secondarySchoolId;
  String secondarySchoolName;
  HousingType housingType;
  HkDistrict homeDistrict;
  int primaryScore;
  int placementScore;
  SsaBandGroup ssaBandGroup;
  SsaPathway ssaPathway;
  String ssaDpChoices;
  DseTier dseTier;
  /// 歷屆合計最佳 raw（各次取高）
  int dseBestScore;
  /// 應考次數（最多 2：正考 + 重考一年）
  int dseSittingCount;
  DseRetakeMode dseRetakeMode;
  JupasPath jupasPath;
  /// 分科等級：chin/eng/math/csd/選修 id → 1–7（csd：1=Attained）
  Map<String, int> dseGrades;
  /// 入讀聯招／副學位課程 code，例如 JS6456
  String jupasCode;
  /// JUPAS 已確認志願（由高至低，最多 [JupasPathway.maxChoices]）
  List<String> jupasChoices;
  /// Asso／HD conditional offer 課程 code（未交留位費前只係 offer）
  String assoHoldCode;
  /// 已交 Asso／HD 留位費
  bool assoDepositPaid;
  /// 副學士讀緊第幾年（1–2）；0＝唔適用
  int assoYear;
  /// 副學士本學年已過幾季（0–3）
  int assoQuarters;
  /// 大學本學年已過幾季（0–3）
  int bachelorQuarters;
  /// 副學士累積 GPA（4.0 制）
  double assoGpa;
  /// Foundation 本學年已過幾季（0–3）；滿 4＝Pass
  int foundationQuarters;
  /// 經 Non-JUPAS 入大學後讀緊第幾年（1–2+）
  int bachelorYear;

  /// 大學 GPA（4.3 制；0＝未有首次考試成績）
  double uniGpa;
  /// 學業投入度
  UniStudyLoad uniStudyLoad;
  /// 本學年溫書次數（影響考試）
  int uniStudySessions;
  bool inHall;
  int hallPoints;
  bool uniProbation;
  /// 延遲畢業年數（0–2）
  int uniDelayYears;
  /// 畢業荣誉（空＝未畢業／未評）
  String uniHonours;
  /// 學生貸款尚欠（要還）
  int studentLoanDebt;

  /// 已加入嘅大學學會 id
  List<String> uniSocietyIds;
  /// 本年已佔用嘅「每年限一」名額（學生會／編輯會）
  String uniExclusiveSocietyId;
  /// 本年上莊學會 id（每年最多一個）
  String uniCadreSocietyId;
  /// 同莊員關係（0–100；影響踢會）
  int uniSocietyStanding;

  /// 社交朋友／拍拖
  List<SocialFriend> friends;

  int ibScore;
  IbTier ibTier;
  IbUniPath ibUniPath;
  StreamAffinity streamAffinity;
  List<String> electiveIds;
  /// IB DP 選科，格式 subjectId:hl|sl ，應為 6 科
  List<String> ibSubjectSlots;

  // Gacha baseline tracking (Base vs Added)
  StatBaselines baselines;

  // Core stats
  int hp;
  int maxHp;
  int san;
  int maxSan;
  int smarts;
  int network;
  int wealth;
  int reputation;

  // Hidden attributes
  int luck;
  int discipline;
  int stress;
  bool hasCriminalRecord;
  InvestigationStatus investigation;

  // Career / school
  CareerSector currentSector;
  String jobTitle;
  int jobRank;
  EducationLevel education;
  bool isStudying;
  String studyProgram;
  Map<String, dynamic> careerAttributes;
  /// 全職表現（升職用）
  int jobPerformance;
  int jobQuartersInRank;
  /// 試用期剩餘季數（0＝已過／無試用）
  int jobProbationQuartersLeft;
  /// 現職累計季數（花紅／年資）
  int jobQuartersEmployed;
  /// 呢個 Q 有冇返工（用嚟決定有冇出糧）
  bool jobWorkedThisQuarter;
  /// 公務員／紀律部隊：累計評核 A（升職用；升完重置）
  int jobAppraisalAs;
  /// 公職：本職級增薪點（跳 point）
  int jobGovMpsPoint;
  /// 公職：累計划一薪酬調整（10000＝100%，10200＝+2%）
  int jobGovPayScaleBps;
  /// 公職：凍增薪點剩餘季數（拉 Curve／表現差）
  int jobGovPointFreezeQuarters;
  /// 體能（紀律部隊入職／在職）
  int fitness;
  /// 強積金結餘
  int mpfBalance;
  /// 本評稅年度累計入息（舊欄；＝全職＋兼職）
  int taxYearIncome;
  /// 全職／花紅等（僱主 IR56 類預填）
  int taxYearFtIncome;
  /// 兼職入息（不論多少都要報）
  int taxYearPtIncome;
  /// 上一次薪俸稅應繳（含罰款）
  int lastTaxPaid;
  /// 上一次申報入息
  int lastTaxDeclared;
  /// 名企／僱主顯示用（可空）
  String employerId;

  /// 搵工面試／Offer 暫存
  String jobHuntSector;
  String jobHuntEmployer;
  bool jobHuntPrestige;

  /// 兼職（可與讀書並存；每 4 季至少返一次）
  String partTimeJobId;
  int partTimeQuartersIdle;
  int partTimeShiftsTotal;

  /// 大學暑期／短期實習
  String activeInternId;
  String internEmployer;
  int internQuartersLeft;
  int internPerformance;

  // Housing & assets (personal)
  bool ownsFlat;
  bool renting;
  int flatValue;
  int mortgagePrincipal;
  double mortgageRateAnnual;
  int mortgageQuartersLeft;
  int mortgageMissedQuarters;
  int monthlyRent;
  String estateNameZh;
  String housingListingId;
  bool hosPremiumPaid;
  int publicHousingWaitQuarters;
  int hosBallotFails;
  bool everOwnedResidential;

  /// 投資組合
  List<AssetHolding> holdings;
  Map<String, double> assetPrices;
  Map<String, List<double>> assetPriceHistory;
  int marketSeed;
  double hkPropertyIndex;

  // Family assets (不可直接动用，影响零用钱 & 事件)
  int familyWealth;
  int familyPropertyValue;
  bool familyOwnsHome;
  int baseAllowance;
  bool livesWithFamily;

  // Flags
  bool inPrison;
  int prisonQuartersLeft;
  GamePhase phase;
  List<DormantCareerRecord> dormantHistory;
  List<String> eventLog;
  Set<String> completedExams;
  Set<String> unlockedFlags;

  /// 教會：主日出席、洗禮、推薦信（神學 JS4111）
  bool churchMember;
  int churchLoyalty;
  bool isBaptized;
  bool hasChurchReferenceLetter;

  Player({
    this.name = '新移民',
    this.age = 0,
    this.year = 2008,
    this.quarter = Quarter.q1,
    this.actionPoints = 3,
    this.maxActionPoints = 3,
    this.birthTier = BirthTier.sr,
    this.lifeStage = LifeStage.infant,
    this.schoolBand = SchoolBand.none,
    this.primaryBand = SchoolBand.none,
    this.primarySchoolId = '',
    this.primarySchoolName = '',
    this.secondarySchoolId = '',
    this.secondarySchoolName = '',
    this.housingType = HousingType.privateRental,
    this.homeDistrict = HkDistrict.shaTin,
    this.primaryScore = 0,
    this.placementScore = 0,
    this.ssaBandGroup = SsaBandGroup.none,
    this.ssaPathway = SsaPathway.none,
    this.ssaDpChoices = '',
    this.dseTier = DseTier.none,
    this.dseBestScore = 0,
    this.dseSittingCount = 0,
    this.dseRetakeMode = DseRetakeMode.none,
    this.jupasPath = JupasPath.none,
    Map<String, int>? dseGrades,
    this.jupasCode = '',
    List<String>? jupasChoices,
    this.assoHoldCode = '',
    this.assoDepositPaid = false,
    this.assoYear = 0,
    this.assoQuarters = 0,
    this.bachelorQuarters = 0,
    this.assoGpa = 0,
    this.foundationQuarters = 0,
    this.bachelorYear = 0,
    this.uniGpa = 0,
    this.uniStudyLoad = UniStudyLoad.none,
    this.uniStudySessions = 0,
    this.inHall = false,
    this.hallPoints = 0,
    this.uniProbation = false,
    this.uniDelayYears = 0,
    this.uniHonours = '',
    this.studentLoanDebt = 0,
    List<String>? uniSocietyIds,
    this.uniExclusiveSocietyId = '',
    this.uniCadreSocietyId = '',
    this.uniSocietyStanding = 50,
    List<SocialFriend>? friends,
    this.ibScore = 0,
    this.ibTier = IbTier.none,
    this.ibUniPath = IbUniPath.none,
    this.streamAffinity = StreamAffinity.none,
    List<String>? electiveIds,
    List<String>? ibSubjectSlots,
    StatBaselines? baselines,
    this.hp = 80,
    this.maxHp = 100,
    this.san = 70,
    this.maxSan = 100,
    this.smarts = 50,
    this.network = 30,
    this.wealth = 0,
    this.reputation = 50,
    this.luck = 50,
    this.discipline = 50,
    this.stress = 20,
    this.hasCriminalRecord = false,
    this.investigation = InvestigationStatus.none,
    this.currentSector = CareerSector.none,
    this.jobTitle = '嬰兒',
    this.jobRank = 0,
    this.education = EducationLevel.none,
    this.isStudying = false,
    this.studyProgram = '',
    this.careerAttributes = const {},
    this.jobPerformance = 0,
    this.jobQuartersInRank = 0,
    this.jobProbationQuartersLeft = 0,
    this.jobQuartersEmployed = 0,
    this.jobWorkedThisQuarter = false,
    this.jobAppraisalAs = 0,
    this.jobGovMpsPoint = 0,
    this.jobGovPayScaleBps = 10000,
    this.jobGovPointFreezeQuarters = 0,
    this.fitness = 40,
    this.mpfBalance = 0,
    this.taxYearIncome = 0,
    this.taxYearFtIncome = 0,
    this.taxYearPtIncome = 0,
    this.lastTaxPaid = 0,
    this.lastTaxDeclared = 0,
    this.employerId = '',
    this.jobHuntSector = '',
    this.jobHuntEmployer = '',
    this.jobHuntPrestige = false,
    this.partTimeJobId = '',
    this.partTimeQuartersIdle = 0,
    this.partTimeShiftsTotal = 0,
    this.activeInternId = '',
    this.internEmployer = '',
    this.internQuartersLeft = 0,
    this.internPerformance = 0,
    this.ownsFlat = false,
    this.renting = false,
    this.flatValue = 0,
    this.mortgagePrincipal = 0,
    this.mortgageRateAnnual = 0.035,
    this.mortgageQuartersLeft = 0,
    this.mortgageMissedQuarters = 0,
    this.monthlyRent = 0,
    this.estateNameZh = '',
    this.housingListingId = '',
    this.hosPremiumPaid = true,
    this.publicHousingWaitQuarters = 0,
    this.hosBallotFails = 0,
    this.everOwnedResidential = false,
    List<AssetHolding>? holdings,
    Map<String, double>? assetPrices,
    Map<String, List<double>>? assetPriceHistory,
    this.marketSeed = 0,
    this.hkPropertyIndex = 1.0,
    this.familyWealth = 0,
    this.familyPropertyValue = 0,
    this.familyOwnsHome = false,
    this.baseAllowance = 0,
    this.livesWithFamily = true,
    this.inPrison = false,
    this.prisonQuartersLeft = 0,
    this.phase = GamePhase.gacha,
    List<DormantCareerRecord>? dormantHistory,
    List<String>? eventLog,
    Set<String>? completedExams,
    Set<String>? unlockedFlags,
    this.churchMember = false,
    this.churchLoyalty = 0,
    this.isBaptized = false,
    this.hasChurchReferenceLetter = false,
  })  : dormantHistory = dormantHistory ?? [],
        eventLog = eventLog ?? [],
        completedExams = completedExams ?? {},
        unlockedFlags = unlockedFlags ?? {},
        electiveIds = electiveIds ?? [],
        ibSubjectSlots = ibSubjectSlots ?? [],
        dseGrades = dseGrades ?? {},
        jupasChoices = jupasChoices ?? [],
        uniSocietyIds = uniSocietyIds ?? [],
        friends = friends ?? [],
        holdings = holdings ?? [],
        assetPrices = assetPrices ?? {},
        assetPriceHistory = assetPriceHistory ?? {},
        baselines = baselines ?? StatBaselines();

  int get addedHp => hp - baselines.baseHp;
  int get addedSan => san - baselines.baseSan;
  int get addedSmarts => smarts - baselines.baseSmarts;
  int get addedNetwork => network - baselines.baseNetwork;
  int get addedWealth => wealth - baselines.baseWealth;
  int get addedReputation => reputation - baselines.baseReputation;
  int get addedLuck => luck - baselines.baseLuck;
  int get addedDiscipline => discipline - baselines.baseDiscipline;

  String get quarterLabel => quarter.label;

  bool get isEmployed =>
      !isStudying &&
      lifeStage == LifeStage.adult &&
      currentSector != CareerSector.none &&
      currentSector != CareerSector.student;

  bool get hasPartTime => partTimeJobId.isNotEmpty;

  bool get isInSchool =>
      lifeStage == LifeStage.primary || lifeStage == LifeStage.secondary;

  bool get isChildhood => lifeStage != LifeStage.adult;

  /// 按年齡顯示年級（唔用錯誤嘅「升中＝中五」）
  String get schoolFormLabel {
    if (lifeStage == LifeStage.infant) return '幼兒';
    if (lifeStage == LifeStage.primary) {
      final form = (age - 5).clamp(1, 6);
      return '小$form';
    }
    if (lifeStage == LifeStage.secondary) {
      return switch (age) {
        12 => '中一',
        13 => '中二',
        14 => '中三',
        15 => '中四',
        16 => '中五',
        17 => '中六',
        _ => age < 12 ? '中學' : (age >= 18 ? '中六+' : '中學'),
      };
    }
    return education.label;
  }

  String get statusLabel {
    if (inPrison) return '在囚';
    if (isInSchool) return jobTitle;
    if (isEmployed) return jobTitle;
    if (lifeStage == LifeStage.infant) return '幼兒';
    return jobTitle;
  }

  /// AP：童年 2；成年／DSE 重讀 3（刻意唔夠「樣樣都做」）
  /// 若上季揀咗職業危機卡「認真」選項 → 本季少 1 AP
  static const nextApPenaltyFlag = 'career_next_ap_minus_2';

  void refreshActionPoints() {
    final retakeAdult =
        age >= 18 && unlockedFlags.contains('dse_retaking');
    maxActionPoints = (isChildhood && !retakeAdult) ? 2 : 3;
    actionPoints = maxActionPoints;
    if (unlockedFlags.remove(nextApPenaltyFlag)) {
      actionPoints = (actionPoints - 1).clamp(0, maxActionPoints);
    }
  }

  void clampStats() {
    hp = hp.clamp(0, maxHp);
    san = san.clamp(0, maxSan);
    smarts = smarts.clamp(0, 100);
    network = network.clamp(0, 100);
    reputation = reputation.clamp(0, 100);
    luck = luck.clamp(0, 100);
    discipline = discipline.clamp(0, 100);
    stress = stress.clamp(0, 100);
    wealth = wealth.clamp(-999999, 999999999);
    churchLoyalty = churchLoyalty.clamp(0, 100);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'year': year,
        'quarter': quarter.name,
        'actionPoints': actionPoints,
        'maxActionPoints': maxActionPoints,
        'birthTier': birthTier.name,
        'lifeStage': lifeStage.name,
        'schoolBand': schoolBand.name,
        'primaryBand': primaryBand.name,
        'primarySchoolId': primarySchoolId,
        'primarySchoolName': primarySchoolName,
        'secondarySchoolId': secondarySchoolId,
        'secondarySchoolName': secondarySchoolName,
        'housingType': housingType.name,
        'homeDistrict': homeDistrict.name,
        'primaryScore': primaryScore,
        'placementScore': placementScore,
        'ssaBandGroup': ssaBandGroup.name,
        'ssaPathway': ssaPathway.name,
        'ssaDpChoices': ssaDpChoices,
        'dseTier': dseTier.name,
        'dseBestScore': dseBestScore,
        'dseSittingCount': dseSittingCount,
        'dseRetakeMode': dseRetakeMode.name,
        'jupasPath': jupasPath.name,
        'dseGrades': dseGrades,
        'jupasCode': jupasCode,
        'jupasChoices': jupasChoices,
        'assoHoldCode': assoHoldCode,
        'assoDepositPaid': assoDepositPaid,
        'assoYear': assoYear,
        'assoQuarters': assoQuarters,
        'bachelorQuarters': bachelorQuarters,
        'assoGpa': assoGpa,
        'foundationQuarters': foundationQuarters,
        'bachelorYear': bachelorYear,
        'uniGpa': uniGpa,
        'uniStudyLoad': uniStudyLoad.name,
        'uniStudySessions': uniStudySessions,
        'inHall': inHall,
        'hallPoints': hallPoints,
        'uniProbation': uniProbation,
        'uniDelayYears': uniDelayYears,
        'uniHonours': uniHonours,
        'studentLoanDebt': studentLoanDebt,
        'uniSocietyIds': uniSocietyIds,
        'uniExclusiveSocietyId': uniExclusiveSocietyId,
        'uniCadreSocietyId': uniCadreSocietyId,
        'uniSocietyStanding': uniSocietyStanding,
        'friends': friends.map((e) => e.toJson()).toList(),
        'ibScore': ibScore,
        'ibTier': ibTier.name,
        'ibUniPath': ibUniPath.name,
        'streamAffinity': streamAffinity.name,
        'electiveIds': electiveIds,
        'ibSubjectSlots': ibSubjectSlots,
        'baselines': baselines.toJson(),
        'hp': hp,
        'maxHp': maxHp,
        'san': san,
        'maxSan': maxSan,
        'smarts': smarts,
        'network': network,
        'wealth': wealth,
        'reputation': reputation,
        'luck': luck,
        'discipline': discipline,
        'stress': stress,
        'hasCriminalRecord': hasCriminalRecord,
        'investigation': investigation.name,
        'currentSector': currentSector.name,
        'jobTitle': jobTitle,
        'jobRank': jobRank,
        'education': education.name,
        'isStudying': isStudying,
        'studyProgram': studyProgram,
        'careerAttributes': careerAttributes,
        'jobPerformance': jobPerformance,
        'jobQuartersInRank': jobQuartersInRank,
        'jobProbationQuartersLeft': jobProbationQuartersLeft,
        'jobQuartersEmployed': jobQuartersEmployed,
        'jobWorkedThisQuarter': jobWorkedThisQuarter,
        'jobAppraisalAs': jobAppraisalAs,
        'jobGovMpsPoint': jobGovMpsPoint,
        'jobGovPayScaleBps': jobGovPayScaleBps,
        'jobGovPointFreezeQuarters': jobGovPointFreezeQuarters,
        'fitness': fitness,
        'mpfBalance': mpfBalance,
        'taxYearIncome': taxYearIncome,
        'taxYearFtIncome': taxYearFtIncome,
        'taxYearPtIncome': taxYearPtIncome,
        'lastTaxPaid': lastTaxPaid,
        'lastTaxDeclared': lastTaxDeclared,
        'employerId': employerId,
        'jobHuntSector': jobHuntSector,
        'jobHuntEmployer': jobHuntEmployer,
        'jobHuntPrestige': jobHuntPrestige,
        'partTimeJobId': partTimeJobId,
        'partTimeQuartersIdle': partTimeQuartersIdle,
        'partTimeShiftsTotal': partTimeShiftsTotal,
        'activeInternId': activeInternId,
        'internEmployer': internEmployer,
        'internQuartersLeft': internQuartersLeft,
        'internPerformance': internPerformance,
        'ownsFlat': ownsFlat,
        'renting': renting,
        'flatValue': flatValue,
        'mortgagePrincipal': mortgagePrincipal,
        'mortgageRateAnnual': mortgageRateAnnual,
        'mortgageQuartersLeft': mortgageQuartersLeft,
        'mortgageMissedQuarters': mortgageMissedQuarters,
        'monthlyRent': monthlyRent,
        'estateNameZh': estateNameZh,
        'housingListingId': housingListingId,
        'hosPremiumPaid': hosPremiumPaid,
        'publicHousingWaitQuarters': publicHousingWaitQuarters,
        'hosBallotFails': hosBallotFails,
        'everOwnedResidential': everOwnedResidential,
        'holdings': holdings.map((e) => e.toJson()).toList(),
        'assetPrices': assetPrices,
        'assetPriceHistory': assetPriceHistory.map(
          (k, v) => MapEntry(k, v),
        ),
        'marketSeed': marketSeed,
        'hkPropertyIndex': hkPropertyIndex,
        'familyWealth': familyWealth,
        'familyPropertyValue': familyPropertyValue,
        'familyOwnsHome': familyOwnsHome,
        'baseAllowance': baseAllowance,
        'livesWithFamily': livesWithFamily,
        'inPrison': inPrison,
        'prisonQuartersLeft': prisonQuartersLeft,
        'phase': phase.name,
        'dormantHistory': dormantHistory.map((e) => e.toJson()).toList(),
        'eventLog': eventLog,
        'completedExams': completedExams.toList(),
        'unlockedFlags': unlockedFlags.toList(),
        'churchMember': churchMember,
        'churchLoyalty': churchLoyalty,
        'isBaptized': isBaptized,
        'hasChurchReferenceLetter': hasChurchReferenceLetter,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    final player = Player(
      name: json['name'] as String? ?? '新移民',
      age: json['age'] as int? ?? 0,
      year: json['year'] as int? ?? 2008,
      quarter: Quarter.values.byName(json['quarter'] as String? ?? 'q1'),
      actionPoints: json['actionPoints'] as int? ?? 3,
      maxActionPoints: json['maxActionPoints'] as int? ?? 3,
      birthTier: BirthTier.values.byName(json['birthTier'] as String? ?? 'sr'),
      lifeStage:
          LifeStage.values.byName(json['lifeStage'] as String? ?? 'infant'),
      schoolBand:
          SchoolBand.values.byName(json['schoolBand'] as String? ?? 'none'),
      primaryBand:
          SchoolBand.values.byName(json['primaryBand'] as String? ?? 'none'),
      primarySchoolId: json['primarySchoolId'] as String? ?? '',
      primarySchoolName: json['primarySchoolName'] as String? ?? '',
      secondarySchoolId: json['secondarySchoolId'] as String? ?? '',
      secondarySchoolName: json['secondarySchoolName'] as String? ?? '',
      housingType: () {
        final name = json['housingType'] as String? ?? 'privateRental';
        return HousingType.values.firstWhere(
          (e) => e.name == name,
          orElse: () => HousingType.privateRental,
        );
      }(),
      homeDistrict: HkDistrict.values.byName(
        json['homeDistrict'] as String? ?? 'shaTin',
      ),
      primaryScore: json['primaryScore'] as int? ?? 0,
      placementScore: json['placementScore'] as int? ?? 0,
      ssaBandGroup: SsaBandGroup.values.byName(
        json['ssaBandGroup'] as String? ?? 'none',
      ),
      ssaPathway: SsaPathway.values.byName(
        json['ssaPathway'] as String? ?? 'none',
      ),
      ssaDpChoices: json['ssaDpChoices'] as String? ?? '',
      dseTier: DseTier.values.byName(json['dseTier'] as String? ?? 'none'),
      dseBestScore: json['dseBestScore'] as int? ?? 0,
      dseSittingCount: json['dseSittingCount'] as int? ?? 0,
      dseRetakeMode: DseRetakeMode.values.byName(
        json['dseRetakeMode'] as String? ?? 'none',
      ),
      jupasPath: JupasPath.values.byName(
        json['jupasPath'] as String? ?? 'none',
      ),
      dseGrades: Map<String, int>.from(
        (json['dseGrades'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v as int),
        ),
      ),
      jupasCode: json['jupasCode'] as String? ?? '',
      jupasChoices: List<String>.from(json['jupasChoices'] as List? ?? []),
      assoHoldCode: json['assoHoldCode'] as String? ?? '',
      assoDepositPaid: json['assoDepositPaid'] as bool? ?? false,
      assoYear: json['assoYear'] as int? ?? 0,
      assoQuarters: json['assoQuarters'] as int? ?? 0,
      bachelorQuarters: json['bachelorQuarters'] as int? ?? 0,
      assoGpa: (json['assoGpa'] as num?)?.toDouble() ?? 0,
      foundationQuarters: json['foundationQuarters'] as int? ?? 0,
      bachelorYear: json['bachelorYear'] as int? ?? 0,
      uniGpa: (json['uniGpa'] as num?)?.toDouble() ?? 0,
      uniStudyLoad: UniStudyLoad.values.byName(
        json['uniStudyLoad'] as String? ?? 'none',
      ),
      uniStudySessions: json['uniStudySessions'] as int? ?? 0,
      inHall: json['inHall'] as bool? ?? false,
      hallPoints: json['hallPoints'] as int? ?? 0,
      uniProbation: json['uniProbation'] as bool? ?? false,
      uniDelayYears: json['uniDelayYears'] as int? ?? 0,
      uniHonours: json['uniHonours'] as String? ?? '',
      studentLoanDebt: json['studentLoanDebt'] as int? ?? 0,
      uniSocietyIds:
          List<String>.from(json['uniSocietyIds'] as List? ?? []),
      uniExclusiveSocietyId:
          json['uniExclusiveSocietyId'] as String? ?? '',
      uniCadreSocietyId: json['uniCadreSocietyId'] as String? ?? '',
      uniSocietyStanding: json['uniSocietyStanding'] as int? ?? 50,
      friends: (json['friends'] as List? ?? [])
          .map((e) => SocialFriend.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      ibScore: json['ibScore'] as int? ?? 0,
      ibTier: IbTier.values.byName(json['ibTier'] as String? ?? 'none'),
      ibUniPath:
          IbUniPath.values.byName(json['ibUniPath'] as String? ?? 'none'),
      streamAffinity: StreamAffinity.values.byName(
        json['streamAffinity'] as String? ?? 'none',
      ),
      electiveIds: List<String>.from(json['electiveIds'] as List? ?? []),
      ibSubjectSlots:
          List<String>.from(json['ibSubjectSlots'] as List? ?? []),
      baselines: json['baselines'] != null
          ? StatBaselines.fromJson(
              Map<String, dynamic>.from(json['baselines'] as Map),
            )
          : StatBaselines(
              baseHp: json['hp'] as int? ?? 80,
              baseSan: json['san'] as int? ?? 70,
              baseSmarts: json['smarts'] as int? ?? 50,
              baseNetwork: json['network'] as int? ?? 30,
              baseWealth: json['wealth'] as int? ?? 0,
              baseReputation: json['reputation'] as int? ?? 50,
              baseLuck: json['luck'] as int? ?? 50,
              baseDiscipline: json['discipline'] as int? ?? 50,
            ),
      hp: json['hp'] as int? ?? 80,
      maxHp: json['maxHp'] as int? ?? 100,
      san: json['san'] as int? ?? 70,
      maxSan: json['maxSan'] as int? ?? 100,
      smarts: json['smarts'] as int? ?? 50,
      network: json['network'] as int? ?? 30,
      wealth: json['wealth'] as int? ?? 0,
      reputation: json['reputation'] as int? ?? 50,
      luck: json['luck'] as int? ?? 50,
      discipline: json['discipline'] as int? ?? 50,
      stress: json['stress'] as int? ?? 20,
      hasCriminalRecord: json['hasCriminalRecord'] as bool? ?? false,
      investigation: InvestigationStatus.values
          .byName(json['investigation'] as String? ?? 'none'),
      currentSector: CareerSector.values
          .byName(json['currentSector'] as String? ?? 'none'),
      jobTitle: json['jobTitle'] as String? ?? '嬰兒',
      jobRank: json['jobRank'] as int? ?? 0,
      education:
          EducationLevel.values.byName(json['education'] as String? ?? 'none'),
      isStudying: json['isStudying'] as bool? ?? false,
      studyProgram: json['studyProgram'] as String? ?? '',
      careerAttributes: Map<String, dynamic>.from(
        json['careerAttributes'] as Map? ?? {},
      ),
      jobPerformance: json['jobPerformance'] as int? ?? 0,
      jobQuartersInRank: json['jobQuartersInRank'] as int? ?? 0,
      jobProbationQuartersLeft:
          json['jobProbationQuartersLeft'] as int? ?? 0,
      jobQuartersEmployed: json['jobQuartersEmployed'] as int? ?? 0,
      jobWorkedThisQuarter:
          json['jobWorkedThisQuarter'] as bool? ?? false,
      jobAppraisalAs: json['jobAppraisalAs'] as int? ?? 0,
      jobGovMpsPoint: json['jobGovMpsPoint'] as int? ?? 0,
      jobGovPayScaleBps: json['jobGovPayScaleBps'] as int? ?? 10000,
      jobGovPointFreezeQuarters:
          json['jobGovPointFreezeQuarters'] as int? ?? 0,
      fitness: json['fitness'] as int? ?? 40,
      mpfBalance: json['mpfBalance'] as int? ?? 0,
      taxYearIncome: json['taxYearIncome'] as int? ?? 0,
      taxYearFtIncome: json['taxYearFtIncome'] as int? ??
          ((json['taxYearPtIncome'] == null)
              ? (json['taxYearIncome'] as int? ?? 0)
              : 0),
      taxYearPtIncome: json['taxYearPtIncome'] as int? ?? 0,
      lastTaxPaid: json['lastTaxPaid'] as int? ?? 0,
      lastTaxDeclared: json['lastTaxDeclared'] as int? ?? 0,
      employerId: json['employerId'] as String? ?? '',
      jobHuntSector: json['jobHuntSector'] as String? ?? '',
      jobHuntEmployer: json['jobHuntEmployer'] as String? ?? '',
      jobHuntPrestige: json['jobHuntPrestige'] as bool? ?? false,
      partTimeJobId: json['partTimeJobId'] as String? ?? '',
      partTimeQuartersIdle: json['partTimeQuartersIdle'] as int? ?? 0,
      partTimeShiftsTotal: json['partTimeShiftsTotal'] as int? ?? 0,
      activeInternId: json['activeInternId'] as String? ?? '',
      internEmployer: json['internEmployer'] as String? ?? '',
      internQuartersLeft: json['internQuartersLeft'] as int? ?? 0,
      internPerformance: json['internPerformance'] as int? ?? 0,
      ownsFlat: json['ownsFlat'] as bool? ?? false,
      renting: json['renting'] as bool? ?? false,
      flatValue: json['flatValue'] as int? ?? 0,
      mortgagePrincipal: json['mortgagePrincipal'] as int? ?? 0,
      mortgageRateAnnual:
          (json['mortgageRateAnnual'] as num?)?.toDouble() ?? 0.035,
      mortgageQuartersLeft: json['mortgageQuartersLeft'] as int? ?? 0,
      mortgageMissedQuarters: json['mortgageMissedQuarters'] as int? ?? 0,
      monthlyRent: json['monthlyRent'] as int? ?? 0,
      estateNameZh: json['estateNameZh'] as String? ?? '',
      housingListingId: json['housingListingId'] as String? ?? '',
      hosPremiumPaid: json['hosPremiumPaid'] as bool? ?? true,
      publicHousingWaitQuarters:
          json['publicHousingWaitQuarters'] as int? ?? 0,
      hosBallotFails: json['hosBallotFails'] as int? ?? 0,
      everOwnedResidential: json['everOwnedResidential'] as bool? ?? false,
      holdings: (json['holdings'] as List? ?? [])
          .map((e) => AssetHolding.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      assetPrices: {
        for (final e
            in (json['assetPrices'] as Map? ?? {}).entries)
          e.key as String: (e.value as num).toDouble(),
      },
      assetPriceHistory: {
        for (final e
            in (json['assetPriceHistory'] as Map? ?? {}).entries)
          e.key as String: (e.value as List? ?? [])
              .map((x) => (x as num).toDouble())
              .toList(),
      },
      marketSeed: json['marketSeed'] as int? ?? 0,
      hkPropertyIndex:
          (json['hkPropertyIndex'] as num?)?.toDouble() ?? 1.0,
      familyWealth: json['familyWealth'] as int? ?? 0,
      familyPropertyValue: json['familyPropertyValue'] as int? ?? 0,
      familyOwnsHome: json['familyOwnsHome'] as bool? ?? false,
      baseAllowance: json['baseAllowance'] as int? ?? 0,
      livesWithFamily: json['livesWithFamily'] as bool? ?? true,
      inPrison: json['inPrison'] as bool? ?? false,
      prisonQuartersLeft: json['prisonQuartersLeft'] as int? ?? 0,
      phase: GamePhase.values.byName(json['phase'] as String? ?? 'gacha'),
      dormantHistory: (json['dormantHistory'] as List?)
              ?.map((e) => DormantCareerRecord.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList() ??
          [],
      eventLog: List<String>.from(json['eventLog'] as List? ?? []),
      completedExams: Set<String>.from(json['completedExams'] as List? ?? []),
      unlockedFlags: Set<String>.from(json['unlockedFlags'] as List? ?? []),
      churchMember: json['churchMember'] as bool? ?? false,
      churchLoyalty: json['churchLoyalty'] as int? ?? 0,
      isBaptized: json['isBaptized'] as bool? ??
          (json['unlockedFlags'] as List? ?? []).contains('church_baptized'),
      hasChurchReferenceLetter: json['hasChurchReferenceLetter'] as bool? ??
          (json['unlockedFlags'] as List? ?? []).contains('church_ref_letter'),
    );
    player.clampStats();
    if (player.taxYearFtIncome == 0 &&
        player.taxYearPtIncome == 0 &&
        player.taxYearIncome > 0) {
      player.taxYearFtIncome = player.taxYearIncome;
    }
    return player;
  }

  String encode() => jsonEncode(toJson());

  factory Player.decode(String source) =>
      Player.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
