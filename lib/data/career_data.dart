import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_abilities.dart';
import 'career_busy_seasons.dart';
import 'career_employment.dart';
import 'career_gov.dart';
import 'career_tax.dart';
import 'luck_modifiers.dart';
import 'social_circle.dart';
import 'university_societies.dart';

class CareerRank {
  final String title;
  final int minRank;
  final int salary;
  final String employer;
  final Map<String, dynamic> attributes;
  final int promoteMinQuarters;
  final int promoteMinPerformance;
  final int promoteMinDiscipline;
  final int promoteMinSmarts;

  const CareerRank({
    required this.title,
    required this.minRank,
    required this.salary,
    this.employer = '',
    this.attributes = const {},
    this.promoteMinQuarters = 4,
    this.promoteMinPerformance = 45,
    this.promoteMinDiscipline = 40,
    this.promoteMinSmarts = 0,
  });

  String get displayTitle =>
      employer.isEmpty ? title : '$employer · $title';
}

class CareerTrack {
  final CareerSector sector;
  final String name;
  final List<CareerRank> ranks;
  final List<String> requiredFlags;
  final bool blockedByCriminalRecord;
  final int minAge;
  final EducationLevel minEducation;
  final int minSmarts;
  final int minNetwork;
  final int minReputation;

  const CareerTrack({
    required this.sector,
    required this.name,
    required this.ranks,
    this.requiredFlags = const [],
    this.blockedByCriminalRecord = true,
    this.minAge = 18,
    this.minEducation = EducationLevel.none,
    this.minSmarts = 0,
    this.minNetwork = 0,
    this.minReputation = 0,
  });

  CareerRank rankFor(int jobRank) {
    var result = ranks.first;
    for (final r in ranks) {
      if (jobRank >= r.minRank) result = r;
    }
    return result;
  }
}

class CareerData {
  static const tracks = <CareerTrack>[
    CareerTrack(
      sector: CareerSector.medical,
      name: '醫療',
      requiredFlags: ['ha_intern_passed'],
      minEducation: EducationLevel.bachelor,
      ranks: [
        CareerRank(
          title: '實習醫生',
          employer: 'HA',
          minRank: 0,
          salary: 55000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 50,
        ),
        CareerRank(
          title: '駐院醫生',
          employer: 'HA',
          minRank: 1,
          salary: 90000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 55,
          promoteMinDiscipline: 50,
        ),
        CareerRank(
          title: '專科醫生',
          employer: 'HA',
          minRank: 2,
          salary: 160000,
          promoteMinQuarters: 12,
          promoteMinPerformance: 65,
        ),
        CareerRank(
          title: '私家專科',
          minRank: 3,
          salary: 280000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.pharmacy,
      name: '藥劑',
      minEducation: EducationLevel.f6,
      ranks: [
        CareerRank(
          title: '藥劑師助理',
          employer: 'Watsons',
          minRank: 0,
          salary: 18000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: '註冊藥劑師',
          employer: 'Mannings',
          minRank: 1,
          salary: 38000,
          promoteMinQuarters: 6,
          promoteMinPerformance: 50,
        ),
        CareerRank(
          title: '藥房經理',
          minRank: 2,
          salary: 55000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.legalSolicitor,
      name: '事務律師',
      requiredFlags: ['law_degree'],
      minEducation: EducationLevel.bachelor,
      ranks: [
        CareerRank(
          title: 'Trainee Solicitor',
          employer: 'Deacons',
          minRank: 0,
          salary: 28000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
          promoteMinSmarts: 60,
        ),
        CareerRank(
          title: 'Associate',
          employer: 'Clifford Chance',
          minRank: 1,
          salary: 55000,
          promoteMinQuarters: 12,
          promoteMinPerformance: 60,
        ),
        CareerRank(
          title: 'Partner',
          minRank: 2,
          salary: 150000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.legalBarrister,
      name: '大律師',
      requiredFlags: ['pupillage_passed'],
      ranks: [
        CareerRank(
          title: 'Pupillage',
          minRank: 0,
          salary: 20000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 45,
          promoteMinSmarts: 65,
        ),
        CareerRank(
          title: 'Junior Counsel',
          minRank: 1,
          salary: 80000,
          promoteMinQuarters: 12,
          promoteMinPerformance: 60,
        ),
        CareerRank(
          title: 'Senior Counsel',
          minRank: 2,
          salary: 250000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.civilService,
      name: '公務員',
      ranks: [
        CareerRank(
          title: '文職／EO',
          employer: '政府',
          minRank: 0,
          salary: 35000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
          promoteMinDiscipline: 55,
        ),
        CareerRank(
          title: 'Executive Officer',
          employer: '政府',
          minRank: 1,
          salary: 45000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: 'AO／高級主任',
          employer: '政府',
          minRank: 2,
          salary: 62000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.taxi,
      name: '的士',
      requiredFlags: ['taxi_license'],
      blockedByCriminalRecord: false,
      ranks: [
        CareerRank(
          title: '租車司機',
          minRank: 0,
          salary: 16000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 35,
          promoteMinDiscipline: 30,
        ),
        CareerRank(
          title: '擁牌司機',
          minRank: 1,
          salary: 26000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 45,
        ),
        CareerRank(
          title: '車行老闆',
          minRank: 2,
          salary: 60000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.insurance,
      name: '保險',
      minEducation: EducationLevel.f6,
      ranks: [
        CareerRank(
          title: 'Insurance Agent',
          employer: 'AIA',
          minRank: 0,
          salary: 14000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: 'Unit Manager',
          employer: '保誠',
          minRank: 1,
          salary: 35000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: 'MDRT 頂尖',
          minRank: 2,
          salary: 85000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.flightAttendant,
      name: '空服員',
      minNetwork: 20,
      ranks: [
        CareerRank(
          title: 'Cabin Crew',
          employer: '國泰 Cathay',
          minRank: 0,
          salary: 22000,
          promoteMinQuarters: 6,
          promoteMinPerformance: 45,
        ),
        CareerRank(
          title: 'Senior Crew',
          employer: '國泰 Cathay',
          minRank: 1,
          salary: 35000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: 'Purser',
          employer: '國泰 Cathay',
          minRank: 2,
          salary: 50000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.politics,
      name: '政治',
      minNetwork: 25,
      minReputation: 25,
      ranks: [
        CareerRank(
          title: '區議員助理',
          minRank: 0,
          salary: 20000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
        ),
        CareerRank(
          title: '區議員',
          minRank: 1,
          salary: 42000,
          promoteMinQuarters: 12,
          promoteMinPerformance: 60,
        ),
        CareerRank(
          title: '立法會議員',
          minRank: 2,
          salary: 100000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.entertainment,
      name: '娛樂/KOL',
      requiredFlags: ['tvb_passed'],
      blockedByCriminalRecord: false,
      ranks: [
        CareerRank(
          title: '訓練班學員',
          employer: 'TVB',
          minRank: 0,
          salary: 10000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: '藝人',
          employer: 'TVB',
          minRank: 1,
          salary: 32000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: '頂流 KOL',
          minRank: 2,
          salary: 180000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.labour,
      name: '藍領／服務業',
      minEducation: EducationLevel.f5,
      blockedByCriminalRecord: false,
      ranks: [
        CareerRank(
          title: '餐廳／零售員工',
          employer: '美心',
          minRank: 0,
          salary: 13000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 35,
          promoteMinDiscipline: 30,
        ),
        CareerRank(
          title: '技工／師傅',
          minRank: 1,
          salary: 20000,
          promoteMinQuarters: 6,
          promoteMinPerformance: 45,
        ),
        CareerRank(
          title: '工頭／店長',
          minRank: 2,
          salary: 30000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.student,
      name: '學生',
      blockedByCriminalRecord: false,
      ranks: [
        CareerRank(title: '全日制學生', minRank: 0, salary: 0),
      ],
    ),
    CareerTrack(
      sector: CareerSector.socialWork,
      name: '社福',
      minEducation: EducationLevel.associate,
      ranks: [
        CareerRank(
          title: '社會工作助理 SWA',
          employer: '東華三院',
          minRank: 0,
          salary: 25100,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
        ),
        CareerRank(
          title: '助理社工主任 ASWO',
          employer: '社署 SWD',
          minRank: 1,
          salary: 36850,
          promoteMinQuarters: 12,
          promoteMinPerformance: 55,
          promoteMinSmarts: 50,
        ),
        CareerRank(
          title: '社工主任 SWO',
          employer: '社署 SWD',
          minRank: 2,
          salary: 82300,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.teaching,
      name: '教學',
      minEducation: EducationLevel.f6,
      ranks: [
        CareerRank(
          title: '教學助理',
          minRank: 0,
          salary: 15000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: '文憑／學位教師',
          employer: '資助中學',
          minRank: 1,
          salary: 32000,
          promoteMinQuarters: 12,
          promoteMinPerformance: 55,
          promoteMinDiscipline: 50,
        ),
        CareerRank(
          title: '主任／PSM',
          minRank: 2,
          salary: 55000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.nursing,
      name: '護理',
      requiredFlags: ['nursing_degree'],
      minEducation: EducationLevel.bachelor,
      ranks: [
        CareerRank(
          title: '登記護士',
          employer: 'HA',
          minRank: 0,
          salary: 21000,
          promoteMinQuarters: 6,
          promoteMinPerformance: 45,
        ),
        CareerRank(
          title: '註冊護士',
          employer: 'HA',
          minRank: 1,
          salary: 32000,
          promoteMinQuarters: 10,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: '護士長',
          employer: 'HA',
          minRank: 2,
          salary: 48000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.banking,
      name: '金融銀行',
      minEducation: EducationLevel.bachelor,
      minSmarts: 45,
      ranks: [
        CareerRank(
          title: '櫃員／客戶服務',
          employer: '中銀香港',
          minRank: 0,
          salary: 16000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: '客戶經理',
          employer: '滙豐 HSBC',
          minRank: 1,
          salary: 28000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: '高級 RM／私銀',
          employer: '渣打',
          minRank: 2,
          salary: 55000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.accounting,
      name: '會計審計',
      minEducation: EducationLevel.bachelor,
      minSmarts: 55,
      ranks: [
        CareerRank(
          title: 'Audit Associate',
          employer: 'PwC',
          minRank: 0,
          salary: 20000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
          promoteMinDiscipline: 50,
          promoteMinSmarts: 55,
        ),
        CareerRank(
          title: 'Senior Associate',
          employer: 'Deloitte',
          minRank: 1,
          salary: 32000,
          promoteMinQuarters: 10,
          promoteMinPerformance: 60,
        ),
        CareerRank(
          title: 'Manager',
          employer: 'EY',
          minRank: 2,
          salary: 55000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.it,
      name: 'IT／科網',
      minSmarts: 55,
      ranks: [
        CareerRank(
          title: 'Junior Developer',
          employer: '本地初創',
          minRank: 0,
          salary: 22000,
          promoteMinQuarters: 6,
          promoteMinPerformance: 45,
          promoteMinSmarts: 55,
        ),
        CareerRank(
          title: 'Software Engineer',
          employer: 'Microsoft HK',
          minRank: 1,
          salary: 38000,
          promoteMinQuarters: 10,
          promoteMinPerformance: 55,
          promoteMinSmarts: 65,
        ),
        CareerRank(
          title: 'Tech Lead',
          employer: 'Google',
          minRank: 2,
          salary: 60000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.media,
      name: '傳媒',
      minEducation: EducationLevel.f6,
      minSmarts: 40,
      ranks: [
        CareerRank(
          title: '編輯助理／記者見習',
          employer: '報館',
          minRank: 0,
          salary: 16000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: '記者',
          employer: 'TVB 新聞',
          minRank: 1,
          salary: 25000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
        ),
        CareerRank(
          title: '高級記者／主編',
          minRank: 2,
          salary: 45000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.realEstate,
      name: '地產',
      minAge: 18,
      blockedByCriminalRecord: false,
      ranks: [
        CareerRank(
          title: '地產代理',
          employer: '中原',
          minRank: 0,
          salary: 14000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: '分行經理',
          employer: '美聯',
          minRank: 1,
          salary: 35000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: '代理行老闆',
          minRank: 2,
          salary: 65000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.engineering,
      name: '工程',
      minEducation: EducationLevel.bachelor,
      minSmarts: 55,
      ranks: [
        CareerRank(
          title: 'Graduate Engineer',
          employer: 'AECOM',
          minRank: 0,
          salary: 22000,
          promoteMinQuarters: 6,
          promoteMinPerformance: 45,
          promoteMinSmarts: 55,
        ),
        CareerRank(
          title: 'Engineer',
          employer: 'MTR',
          minRank: 1,
          salary: 38000,
          promoteMinQuarters: 10,
          promoteMinPerformance: 55,
        ),
        CareerRank(
          title: 'Senior Engineer／項目經理',
          minRank: 2,
          salary: 58000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.disciplinary,
      name: '紀律部隊／執法',
      minAge: 18,
      minEducation: EducationLevel.f5,
      blockedByCriminalRecord: true,
      ranks: [
        CareerRank(
          title: '見習／學員',
          employer: '紀律部隊',
          minRank: 0,
          salary: 24000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
          promoteMinDiscipline: 50,
        ),
        CareerRank(
          title: '隊員／關員／調查員',
          employer: '紀律部隊',
          minRank: 1,
          salary: 32000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
          promoteMinDiscipline: 55,
        ),
        CareerRank(
          title: '警長／主任／高級調查',
          minRank: 2,
          salary: 48000,
        ),
      ],
    ),
    CareerTrack(
      sector: CareerSector.catering,
      name: '餐飲管理',
      minAge: 18,
      ranks: [
        CareerRank(
          title: '見習／副經理',
          employer: '美心',
          minRank: 0,
          salary: 16000,
          promoteMinQuarters: 4,
          promoteMinPerformance: 40,
        ),
        CareerRank(
          title: '分店經理',
          employer: '大家樂',
          minRank: 1,
          salary: 28000,
          promoteMinQuarters: 8,
          promoteMinPerformance: 50,
        ),
        CareerRank(
          title: '區域經理',
          minRank: 2,
          salary: 45000,
        ),
      ],
    ),
  ];

  static CareerTrack? trackFor(CareerSector sector) {
    try {
      return tracks.firstWhere((t) => t.sector == sector);
    } catch (_) {
      return null;
    }
  }

  static String jobDisplay(Player p) {
    if (p.currentSector == CareerSector.none ||
        p.currentSector == CareerSector.student) {
      return p.jobTitle;
    }
    final track = trackFor(p.currentSector);
    if (track == null) return p.jobTitle;
    final r = track.rankFor(p.jobRank);
    if (p.employerId.isNotEmpty) {
      return '${p.employerId} · ${r.title}';
    }
    return r.displayTitle;
  }

  /// 入學時清全職（兼職可留）
  static void onStartStudying(Player p) {
    if (p.currentSector == CareerSector.none ||
        p.currentSector == CareerSector.student) {
      return;
    }
    final title = p.jobTitle;
    quitJob(p, reason: '入學要辭全職');
    p.eventLog.add(
      '${p.year}年：讀緊書唔可以做全職，已辭：$title（兼職可繼續）',
    );
  }

  static String? entryBlockReason(Player p, CareerSector sector) {
    if (p.isStudying) return '讀緊書唔可以做全職，最多兼職';
    final track = trackFor(sector);
    if (track == null) return '無呢條職涯';
    if (track.blockedByCriminalRecord && p.hasCriminalRecord) {
      return '有案底入唔到呢行';
    }
    if (p.age < track.minAge) return '要滿 ${track.minAge} 歲';
    if (p.education.index < track.minEducation.index) {
      return '學歷唔夠（要 ${track.minEducation.label}+）';
    }
    if (p.smarts < track.minSmarts) return '智慧唔夠（要 ${track.minSmarts}+）';
    if (p.network < track.minNetwork) {
      return '人脈唔夠（要 ${track.minNetwork}+）';
    }
    if (p.reputation < track.minReputation) {
      return '名望唔夠（要 ${track.minReputation}+）';
    }
    for (final f in track.requiredFlags) {
      if (!p.unlockedFlags.contains(f) && !_softFlagOk(p, sector, f)) {
        return '未過入職門檻';
      }
    }
    switch (sector) {
      case CareerSector.socialWork:
        if (!_hasSocialDiplomaPath(p)) {
          return '要認可社工／社福學歷（副學士社工或社工學士）'
              '${UniversitySocieties.wasInVolunteer(p) ? "；淨係社服學會唔夠" : ""}';
        }
      case CareerSector.teaching:
        if (!_canEnterTeaching(p)) {
          return '教學助理要 F.6+；正式教師要教育學位';
        }
      case CareerSector.pharmacy:
        // 無學位只可以做助理；註冊藥劑師要藥劑學位（enter 時跳 rank）
        break;
      case CareerSector.nursing:
        if (!p.unlockedFlags.contains('nursing_degree') &&
            !_tagGrad(p, 'nursing')) {
          return '要護理學歷';
        }
      case CareerSector.civilService:
        // 部門職位（社署／民政／房屋／AO／EO）各有門檻；見 CareerGov
        break;
      case CareerSector.disciplinary:
        if (p.discipline < 40) return '紀律部隊要紀律 40+';
        if (p.hp < 45) return '體能／HP 唔夠（要 45+）';
      case CareerSector.flightAttendant:
        if (p.network < UniversitySocieties.flightNetworkNeed(p)) {
          return '人脈未夠應徵空服';
        }
      case CareerSector.politics:
        if (p.network < UniversitySocieties.politicsNetworkNeed(p) ||
            p.reputation < UniversitySocieties.politicsReputationNeed(p)) {
          return '人脈／名望未夠從政';
        }
      case CareerSector.insurance:
        if (!p.unlockedFlags.contains('iiqe_passed')) {
          return '入保險要過 IIQE 資格試';
        }
      case CareerSector.realEstate:
        if (!p.unlockedFlags.contains('eaa_license')) {
          return '做地產代理要過 EAA 資格試';
        }
      case CareerSector.accounting:
        if (p.smarts < 55 && p.uniGpa < 2.8) {
          return '四大／審計要智慧或 GPA';
        }
      case CareerSector.it:
        if (p.education.index < EducationLevel.bachelor.index &&
            p.smarts < 70) {
          return 'IT 要學位或好高智慧';
        }
      case CareerSector.banking:
        if (p.education.index < EducationLevel.bachelor.index) {
          return '銀行要學士學位';
        }
      case CareerSector.media:
        if (!_hasMediaPath(p)) {
          return '傳媒要：編輯委員會背景／相關學士，'
              '或者人脈≥${_mediaNetworkNeed(p)}＋名望≥${_mediaReputationNeed(p)}';
        }
      case CareerSector.engineering:
        if (p.education.index < EducationLevel.bachelor.index &&
            p.smarts < 70) {
          return '工程要學位或好高智慧';
        }
      case CareerSector.catering:
        break;
      default:
        break;
    }
    return null;
  }

  /// 紀律部隊分支（警／消／海關／ICAC）額外門檻
  /// [branch]：police／fire／customs／icac
  static String? disciplinaryBranchBlock(Player p, String branch) {
    final base = entryBlockReason(p, CareerSector.disciplinary);
    if (base != null) return base;
    switch (branch) {
      case 'icac':
        if (p.education.index < EducationLevel.bachelor.index) {
          return 'ICAC 調查員線通常要學位';
        }
        if (p.smarts < 58) return 'ICAC 要智慧 58+';
        if (p.discipline < 55) return 'ICAC 要紀律 55+';
        if (p.reputation < 35) return 'ICAC 要體面／名望 35+';
      case 'police':
        if (p.discipline < 50) return '警隊要紀律 50+';
      case 'fire':
        if (p.hp < 55) return '消防體能要求更高（HP 55+）';
      case 'customs':
        if (p.smarts < 42) return '海關要智慧 42+';
    }
    return null;
  }

  static String disciplinaryEmployer(String branch) => switch (branch) {
        'police' => '香港警務處',
        'fire' => '消防處',
        'customs' => '香港海關',
        'icac' => '廉政公署 ICAC',
        _ => '紀律部隊',
      };

  static String disciplinaryTitleFor(String branch, int rank) {
    final titles = switch (branch) {
      'police' => ['學員', '警員', '警長'],
      'fire' => ['學員', '消防員', '隊目'],
      'customs' => ['見習關員', '關員', '高級關員'],
      'icac' => ['見習調查員', '調查員', '高級調查員'],
      _ => ['見習／學員', '隊員', '主任級'],
    };
    final i = rank.clamp(0, titles.length - 1);
    return titles[i];
  }

  static String? disciplinaryBranchOf(Player p) {
    return _branchFromEmployer(p.employerId);
  }

  static String? _branchFromEmployer(String e) {
    if (e.contains('警')) return 'police';
    if (e.contains('消防')) return 'fire';
    if (e.contains('海關')) return 'customs';
    if (e.contains('ICAC') || e.contains('廉政')) return 'icac';
    return null;
  }

  static bool _softFlagOk(Player p, CareerSector sector, String flag) {
    if (sector == CareerSector.civilService &&
        (flag == 'jre_passed' || flag == 'cre_passed')) {
      return p.unlockedFlags.contains('jre_passed') ||
          p.unlockedFlags.contains('cre_passed');
    }
    if (flag == 'nursing_degree') return _tagGrad(p, 'nursing');
    if (flag == 'pharm_degree') {
      return p.unlockedFlags.contains('pharm_degree') ||
          _tagGrad(p, 'pharmacy');
    }
    return false;
  }

  static bool _tagGrad(Player p, String tag) =>
      p.unlockedFlags.contains('${tag}_degree') ||
      p.unlockedFlags.contains('grad_$tag');

  /// 社工學位（ASWO 起跳）
  static bool _hasSocialDegree(Player p) =>
      p.unlockedFlags.contains('social_degree') ||
      p.unlockedFlags.contains('grad_social') ||
      (p.unlockedFlags.contains('bachelor_graduated') &&
          _programLooksSocial(p));

  /// SWA：副學士社工／社工學士（唔接受淨學會）
  static bool _hasSocialDiplomaPath(Player p) =>
      _hasSocialDegree(p) || p.unlockedFlags.contains('asso_social');

  static bool _programLooksSocial(Player p) {
    final s = p.studyProgram.toLowerCase();
    return s.contains('social') ||
        s.contains('社工') ||
        s.contains('社會工作');
  }

  /// 教育學位先算正式教師資格
  static bool _hasEducationDegree(Player p) =>
      p.unlockedFlags.contains('education_degree') ||
      p.unlockedFlags.contains('grad_education') ||
      (p.unlockedFlags.contains('bachelor_graduated') &&
          _programLooksEducation(p));

  /// 畀考試／外部模組用
  static bool hasEducationDegreePublic(Player p) => _hasEducationDegree(p);

  static bool _programLooksEducation(Player p) {
    final s = p.studyProgram.toLowerCase();
    return s.contains('education') ||
        s.contains('教育') ||
        s.contains('教學') ||
        s.contains('b.ed') ||
        s.contains('bed');
  }

  static bool _canEnterTeaching(Player p) {
    if (_hasEducationDegree(p)) return true;
    // 淨 TA：F.6+，但唔係任何學士都當教師
    return p.education.index >= EducationLevel.f6.index;
  }

  static int _mediaNetworkNeed(Player p) =>
      UniversitySocieties.wasInEditorial(p) ? 12 : 30;

  static int _mediaReputationNeed(Player p) =>
      UniversitySocieties.wasInEditorial(p) ? 20 : 35;

  static bool _hasMediaPath(Player p) {
    if (UniversitySocieties.wasInEditorial(p)) return true;
    if (p.unlockedFlags.contains('bachelor_graduated') &&
        (p.studyProgram.toLowerCase().contains('journal') ||
            p.studyProgram.toLowerCase().contains('media') ||
            p.studyProgram.toLowerCase().contains('通信') ||
            p.studyProgram.toLowerCase().contains('新聞') ||
            p.studyProgram.toLowerCase().contains('傳播') ||
            p.studyProgram.toLowerCase().contains('english') ||
            p.studyProgram.toLowerCase().contains('中文'))) {
      return p.network >= 18;
    }
    // 無對口背景：人脈＋名望要夠
    return p.network >= _mediaNetworkNeed(p) &&
        p.reputation >= _mediaReputationNeed(p) &&
        p.smarts >= 45;
  }

  static bool canEnter(Player p, CareerSector sector) =>
      entryBlockReason(p, sector) == null;

  static String socialEntryLabel(Player p) =>
      _hasSocialDegree(p) ? '入職社福（ASWO · 社工學位）' : '入職社福（SWA）';

  static String teachingEntryLabel(Player p) {
    if (p.unlockedFlags.contains('teacher_registered')) {
      return '入職學位教師（已註冊）';
    }
    if (_hasEducationDegree(p)) {
      return '入職準教師／合約（未註冊）';
    }
    return '入職教學助理（TA）';
  }

  static String pharmacyEntryLabel(Player p) {
    final hasPharm = p.unlockedFlags.contains('pharm_degree') ||
        _tagGrad(p, 'pharmacy');
    return hasPharm ? '藥劑實習入行（學位）' : '藥劑師助理入行';
  }

  /// 本地藥劑學位：完成約一年實習後可註冊（豁免註冊試）
  static bool _pharmacyInternDone(Player p) =>
      p.unlockedFlags.contains('pharm_local_grad') &&
      p.currentSector == CareerSector.pharmacy &&
      p.jobQuartersInRank >= 4;

  /// Offer／UI 預覽用：同 enterCareer 一致嘅起跳 rank
  static int previewStartRank(Player player, CareerSector sector) {
    final track = trackFor(sector);
    if (track == null) return 0;
    var startRank = 0;
    if (sector == CareerSector.socialWork && _hasSocialDegree(player)) {
      startRank = 1;
    }
    if (sector == CareerSector.teaching) {
      startRank =
          player.unlockedFlags.contains('teacher_registered') ? 1 : 0;
    }
    if (sector == CareerSector.pharmacy) {
      startRank = 0; // 學位都要先實習／註冊
    }
    if (sector == CareerSector.civilService) {
      if (player.unlockedFlags.contains('jre_passed')) {
        startRank = 2;
      } else if (player.unlockedFlags.contains('cre_passed')) {
        startRank = 0;
      }
    }
    return startRank;
  }

  static const provisionalTeacherTitle = '準教師／合約（未註冊）';

  static String previewHireTitle(Player player, CareerSector sector) {
    final track = trackFor(sector);
    if (track == null) return sector.label;
    final startRank = previewStartRank(player, sector);
    final title = track.rankFor(startRank).title;
    if (sector == CareerSector.teaching &&
        startRank == 0 &&
        _hasEducationDegree(player) &&
        !player.unlockedFlags.contains('teacher_registered')) {
      return provisionalTeacherTitle;
    }
    if (sector == CareerSector.pharmacy &&
        (player.unlockedFlags.contains('pharm_degree') ||
            _tagGrad(player, 'pharmacy'))) {
      return '藥劑實習員';
    }
    return title;
  }

  static bool enterCareer(
    Player player,
    CareerSector sector, {
    int rank = 0,
    String? employerOverride,
  }) {
    var resolvedEmployer = employerOverride;
    var govPost = resolvedEmployer != null
        ? CareerGov.fromEmployer(resolvedEmployer)
        : null;
    // 公職／紀律：未帶 #postId 就綁預設職位，避免月薪顯示 $0
    if (govPost == null && CareerGov.isGovSector(sector)) {
      govPost = CareerGov.defaultPostFor(sector, player);
      if (govPost != null) {
        resolvedEmployer = CareerGov.taggedEmployer(govPost);
      }
    }
    if (govPost != null) {
      final gb = CareerGov.blockReason(player, govPost);
      if (gb != null) {
        player.eventLog.add('${player.year}年：入職失敗 — $gb');
        return false;
      }
    } else {
      final block = entryBlockReason(player, sector);
      if (block != null) {
        player.eventLog.add('${player.year}年：入職失敗 — $block');
        return false;
      }
    }
    final track = trackFor(sector);
    if (track == null) return false;

    var startRank = rank;
    if (govPost != null) {
      startRank = 0; // 公職職位由該 post 職級線起
    } else if (sector == CareerSector.socialWork &&
        _hasSocialDegree(player) &&
        rank == 0) {
      startRank = 1; // 社工學士 → ASWO
    }
    if (sector == CareerSector.teaching) {
      // 現實：有教育學位仍要申請教師註冊；未註冊唔當正式學位教師
      if (player.unlockedFlags.contains('teacher_registered') &&
          rank == 0) {
        startRank = 1;
      } else {
        startRank = 0;
      }
    }
    if (sector == CareerSector.pharmacy) {
      // 現實：本地藥劑學位 ≠ 自動註冊；要先做認可實習（通常一年）
      if (rank == 0) startRank = 0;
      if (player.unlockedFlags.contains('pharm_degree') ||
          _tagGrad(player, 'pharmacy')) {
        player.unlockedFlags.add('pharm_local_grad');
      }
    }
    if (sector == CareerSector.nursing) {
      // 本地認可護理學士：畢業後可申請註冊（唔使再考執業試）
      if (player.unlockedFlags.contains('nursing_degree') ||
          _tagGrad(player, 'nursing')) {
        player.unlockedFlags.add('nursing_license');
      }
    }
    if (govPost == null && sector == CareerSector.civilService) {
      if (player.unlockedFlags.contains('jre_passed') && rank == 0) {
        startRank = 2;
      } else if (player.unlockedFlags.contains('cre_passed') && rank == 0) {
        startRank = 0;
      }
    }

    player.currentSector = sector;
    player.jobRank = startRank;
    player.jobWorkedThisQuarter = false;
    final r = track.rankFor(startRank);
    player.employerId = resolvedEmployer ?? r.employer;
    player.jobTitle = jobDisplay(player);
    if (sector == CareerSector.teaching &&
        startRank == 0 &&
        _hasEducationDegree(player) &&
        !player.unlockedFlags.contains('teacher_registered')) {
      player.jobTitle = player.employerId.isNotEmpty
          ? '${player.employerId} · $provisionalTeacherTitle'
          : provisionalTeacherTitle;
    }
    if (sector == CareerSector.pharmacy &&
        player.unlockedFlags.contains('pharm_local_grad') &&
        startRank == 0) {
      player.jobTitle = player.employerId.isNotEmpty
          ? '${player.employerId} · 藥劑實習員'
          : '藥劑實習員';
    }
    if (govPost != null) {
      CareerGov.onHireGov(player, govPost);
    } else if (CareerGov.usesGovRules(player)) {
      CareerGov.initPayScale(player);
      CareerGov.applyTitle(player);
    }
    player.jobPerformance = 20;
    player.jobQuartersInRank = 0;
    if (govPost == null) {
      player.careerAttributes = Map<String, dynamic>.from(r.attributes);
    }
    CareerAbilities.seedOnHire(player);
    _seedKpiBaseline(player);
    final salary = govPost != null
        ? CareerGov.monthlySalary(player)
        : (CareerGov.usesGovRules(player)
            ? CareerGov.monthlySalary(player)
            : r.salary);
    player.eventLog.add(
      '${player.year}年：入職 ${player.jobTitle}（月薪約 \$$salary）',
    );
    CareerEmployment.onHire(player, sector);
    player.unlockedFlags.add('career_just_hired');
    if (govPost != null) {
      // 三年試用＋職稱以公職為準（onHire 後再蓋）
      player.jobProbationQuartersLeft = CareerGov.probationQuarters;
      CareerGov.applyTitle(player);
      CareerGov.setAppraisalAs(player, 0);
    }
    return true;
  }

  static void quitJob(Player player, {String reason = '辭工'}) {
    if (player.currentSector == CareerSector.none ||
        player.currentSector == CareerSector.student) {
      return;
    }
    player.dormantHistory.add(DormantCareerRecord(
      sector: player.currentSector,
      jobTitle: player.jobTitle,
      attributes: Map<String, dynamic>.from(player.careerAttributes),
      endedYear: player.year,
      endedAge: player.age,
    ));
    player.currentSector = CareerSector.none;
    player.jobTitle = '待業';
    player.jobRank = 0;
    player.jobPerformance = 0;
    player.jobQuartersInRank = 0;
    player.jobProbationQuartersLeft = 0;
    player.jobQuartersEmployed = 0;
    player.jobWorkedThisQuarter = false;
    player.employerId = '';
    player.careerAttributes = {};
    player.jobAppraisalAs = 0;
    player.jobGovMpsPoint = 0;
    player.jobGovPayScaleBps = 10000;
    player.jobGovPointFreezeQuarters = 0;
    player.unlockedFlags.removeWhere((f) => f.startsWith(_kpiFlagPrefix));
    player.eventLog.add('${player.year}年：$reason');
  }

  static String? promoteBlockReason(Player player) {
    final track = trackFor(player.currentSector);
    if (track == null) return '無職涯';
    if (CareerEmployment.onProbation(player)) {
      return '試用期未完，唔可以升職';
    }
    if (player.jobRank >= track.ranks.last.minRank) {
      return '已經係最高職級';
    }
    final govBlock = CareerGov.promoteBlock(player);
    if (govBlock != null) return govBlock;
    final current = track.rankFor(player.jobRank);
    // 公職以 A 為主；其他行業維持本級年資
    if (!CareerGov.usesGovRules(player) &&
        player.jobQuartersInRank < current.promoteMinQuarters) {
      return '呢個位未做夠（要 ${current.promoteMinQuarters} 季，而家 ${player.jobQuartersInRank}）';
    }
    if (CareerGov.usesGovRules(player) &&
        player.jobQuartersInRank < 4) {
      return '本級至少做滿 1 年（4 季）先可以搏升';
    }
    // 表現唔鎖死——太差照樣畀搏，結果多數係老細嘲諷
    if (player.discipline < current.promoteMinDiscipline) {
      return '紀律唔夠（要 ${current.promoteMinDiscipline}+）';
    }
    if (player.smarts < current.promoteMinSmarts) {
      return '智慧唔夠升呢級';
    }
    final nextRank = player.jobRank + 1;
    if (player.currentSector == CareerSector.teaching &&
        nextRank >= 1) {
      if (!player.unlockedFlags.contains('teacher_registered')) {
        return '升正式教師要先完成教師註冊（TRB）';
      }
      if (!_hasEducationDegree(player) &&
          player.jobQuartersEmployed < 4) {
        return '未有教育學位：要有足夠教學年資先升';
      }
      final parentSat =
          CareerAbilities.get(player, '家長滿意', 50);
      if (parentSat < 45) {
        return '家長滿意太低（要 45+；而家 $parentSat）——多啲備課改簿／處理投訴';
      }
    }
    if (player.currentSector == CareerSector.pharmacy &&
        nextRank >= 1) {
      if (!player.unlockedFlags.contains('pharm_degree') &&
          !_tagGrad(player, 'pharmacy')) {
        return '升註冊藥劑師要藥劑學位';
      }
      // 本地學位：一年實習（4 季）可註冊；否則要過註冊試（非本地路線）
      if (!player.unlockedFlags.contains('pharm_reg_passed') &&
          !_pharmacyInternDone(player)) {
        if (player.unlockedFlags.contains('pharm_local_grad')) {
          return '升註冊藥劑師要完成約一年實習'
              '（而家 ${player.jobQuartersInRank}/4 季），'
              '或者考藥劑師註冊試';
        }
        return '升註冊藥劑師要過藥劑師註冊試';
      }
    }
    if (player.currentSector == CareerSector.taxi && nextRank >= 1) {
      // 入職已要 taxi_license（駕駛執照）；擁牌＝湊夠錢買／頂牌
      const plateCost = 180000;
      if (player.wealth < plateCost) {
        return '升擁牌司機要湊夠約 \$$plateCost 買／頂牌（而家 \$${player.wealth}）';
      }
    }
    if (player.currentSector == CareerSector.taxi && nextRank >= 2) {
      const fleetCost = 450000;
      if (player.wealth < fleetCost) {
        return '升車行老闆要資金約 \$$fleetCost（而家 \$${player.wealth}）';
      }
    }
    if (player.currentSector == CareerSector.nursing &&
        nextRank >= 1 &&
        !player.unlockedFlags.contains('nursing_license')) {
      return '升註冊護士要護士註冊資格（本地學位畢業可申請；否則考執業試）';
    }
    if (player.currentSector == CareerSector.socialWork &&
        nextRank >= 1 &&
        !_hasSocialDegree(player)) {
      return '升 ASWO 要社工學士學位';
    }
    if (player.currentSector == CareerSector.accounting &&
        nextRank >= 2 &&
        !player.unlockedFlags.contains('hkicpa_passed')) {
      return '升 Manager 要過 HKICPA QP';
    }
    if (player.currentSector == CareerSector.banking &&
        nextRank >= 2 &&
        !player.unlockedFlags.contains('cfa_l1') &&
        player.smarts < 75) {
      return '升高級 RM 要 CFA L1 或智慧 75+';
    }
    return null;
  }

  /// 升職成功率（內部用，唔直接顯示數字畀玩家）
  static int promoteSuccessChance(Player player) {
    final track = trackFor(player.currentSector);
    if (track == null) return 0;
    final need = track.rankFor(player.jobRank).promoteMinPerformance;
    final perf = player.jobPerformance;
    // 剛好達標約 48%；每高／低 1 分 ±2%；幸運微調
    var chance = 48 + (perf - need) * 2;
    chance += player.luck ~/ 12;
    if (player.discipline >= 70) chance += 4;
    if (player.unlockedFlags.contains('cfa_l1') &&
        player.currentSector == CareerSector.banking) {
      chance += 8;
    }
    if (player.unlockedFlags.contains('hkicpa_passed') &&
        player.currentSector == CareerSector.accounting) {
      chance += 8;
    }
    if (player.unlockedFlags.contains('teacher_registered') &&
        player.currentSector == CareerSector.teaching) {
      chance += 5;
    }
    chance += CareerGov.promoteChanceBonus(player);
    chance += CareerAbilities.promoteChanceModifier(player);
    // 表現太差可以低到近乎 0，唔設硬下限鎖死
    return chance.clamp(0, 90);
  }

  /// 畀玩家睇嘅模糊手感（唔爆 %）
  static String promoteOddsHint(Player player) {
    final perf = player.jobPerformance;
    if (perf < 20) return '咪玩啦，你自己知自己事';
    final c = promoteSuccessChance(player);
    if (c >= 75) return '老細近期對你睇好';
    if (c >= 60) return '氣氛幾正面';
    if (c >= 45) return '五五波，睇你表現';
    if (c >= 30) return '機會一般，要搏';
    if (c >= 15) return '希望唔大，但總好過唔試';
    return '好似係去乞笑';
  }

  static String _bossRoastPromote(Player player) {
    final lines = <String>[
      '老細當面笑出聲：「你都夠膽講升職？你近期做嘅野，我阿媽都唔敢。」',
      '老細撳住太陽穴：「升職？不如你先證明自己識返工。」',
      '老細望住你：「同事見你加班都當睇戲，你仲想升？」',
      '老細冷笑：「你表現成咁，我同 HR 提你個名，佢哋會以為我痴線。」',
      '老細拍拍你膊頭：「勇敢係好事——但勇敢同厚臉皮有時好似。」',
      '老細：『升職申請我收到啦。垃圾桶都收到。』',
    ];
    final i = Random(
      player.year * 17 + player.age + player.jobPerformance * 3,
    ).nextInt(lines.length);
    return lines[i];
  }

  static bool canPromote(Player player) =>
      promoteBlockReason(player) == null;

  static String promote(Player player) {
    final block = promoteBlockReason(player);
    if (block != null) {
      player.stress = (player.stress + 3).clamp(0, 100);
      return '升職失敗：$block';
    }

    // 表現太差：照畀講，但升唔到，淨係換老細一餐屌／嘲諷
    if (player.jobPerformance < 20) {
      player.stress = (player.stress + 10).clamp(0, 100);
      player.reputation = (player.reputation - 2).clamp(0, 100);
      player.jobPerformance =
          (player.jobPerformance - 1).clamp(0, 100);
      final roast = _bossRoastPromote(player);
      player.eventLog.add('${player.year}年：講升職被老細嘲諷');
      return '你開口講升職……\n$roast\n（聲望 −2，壓力飆高）';
    }

    final chance = promoteSuccessChance(player);
    final hint = promoteOddsHint(player);
    final ok = LuckModifiers.roll(
      player,
      chance / 100.0,
      Random(player.year * 41 + player.jobPerformance + player.jobRank),
    );
    if (!ok) {
      player.stress = (player.stress + 5).clamp(0, 100);
      player.jobPerformance =
          (player.jobPerformance - 2).clamp(0, 100);
      player.eventLog.add('${player.year}年：爭取升職失敗');
      if (chance < 25) {
        return '升職失敗。${_bossRoastPromote(player)}\n'
            '（你估今次「$hint」——估得唔錯。）';
      }
      return '升職失敗。老細話再觀察下——你估今次係「$hint」，果然唔穩。'
          '繼續做好本份／OT 再搏啦。';
    }
    final track = trackFor(player.currentSector);
    if (track == null) return '升職失敗';
    final fromRank = player.jobRank;
    player.jobRank++;
    var taxiCostNote = '';
    if (player.currentSector == CareerSector.taxi) {
      if (fromRank == 0) {
        player.wealth -= 180000;
        taxiCostNote = '\n頂牌開支 \$180000';
      } else if (fromRank == 1) {
        player.wealth -= 450000;
        taxiCostNote = '\n開車行資金 \$450000';
      }
    }
    final r = track.rankFor(player.jobRank);
    // 紀律部隊／公職分支要保留原機構，唔好升職洗返通用名
    if (r.employer.isNotEmpty && !CareerGov.usesGovRules(player)) {
      player.employerId = r.employer;
    }
    if (CareerGov.usesGovRules(player)) {
      CareerGov.onPromoteResetAs(player);
    } else {
      player.jobTitle = jobDisplay(player);
    }
    player.jobPerformance = (player.jobPerformance - 15).clamp(10, 100);
    player.jobQuartersInRank = 0;
    player.reputation = (player.reputation + 5).clamp(0, 100);
    final salary = CareerGov.currentPost(player) != null
        ? CareerGov.monthlySalary(player)
        : r.salary;
    player.eventLog.add('${player.year}年：升職成功 → ${player.jobTitle}');
    return '升職成功：${player.jobTitle}\n月薪約 \$$salary'
        '$taxiCostNote'
        '${CareerGov.usesGovRules(player) ? "\n評核 A 已重置，重新累積。" : ""}';
  }

  static void tickQuarter(Player p) {
    if (p.isStudying) {
      onStartStudying(p);
      return;
    }
    if (!p.isEmployed) return;
    p.jobQuartersInRank++;
    _applyQuarterlyKpi(p);
  }

  static const String _kpiFlagPrefix = 'kpi_last_';

  static ({String metric, String label, int target})? _kpiSpecFor(
    CareerSector sector,
  ) {
    return switch (sector) {
      CareerSector.socialWork => (metric: '個案數', label: '個案', target: 2),
      CareerSector.teaching => (metric: '改簿量', label: '改簿量', target: 2),
      CareerSector.nursing || CareerSector.medical => (
        metric: '值班時數',
        label: '值班',
        target: 2,
      ),
      CareerSector.banking => (metric: '客戶數', label: '客戶', target: 2),
      CareerSector.accounting => (
        metric: 'Busy Season',
        label: '審計工作量',
        target: 1,
      ),
      CareerSector.it => (metric: 'Project 數', label: 'Project', target: 1),
      CareerSector.media => (metric: '稿件數', label: '稿件', target: 2),
      CareerSector.realEstate => (metric: '成交單', label: '成交單', target: 1),
      CareerSector.insurance => (metric: '保單數', label: '保單', target: 1),
      CareerSector.flightAttendant => (
        metric: '飛行時數',
        label: '飛行時數',
        target: 20,
      ),
      CareerSector.engineering => (metric: '工程進度', label: '工程進度', target: 1),
      CareerSector.disciplinary => (metric: '執勤次數', label: '執勤次數', target: 2),
      CareerSector.catering => (metric: '排更班次', label: '排更班次', target: 2),
      CareerSector.pharmacy => (metric: '處方覆核', label: '處方覆核', target: 2),
      CareerSector.legalSolicitor => (metric: '檔案數', label: '檔案', target: 2),
      CareerSector.legalBarrister => (
        metric: '上庭次數',
        label: '上庭',
        target: 1,
      ),
      CareerSector.civilService => (
        metric: '公文完成量',
        label: '公文',
        target: 2,
      ),
      CareerSector.taxi => (metric: '載客量', label: '載客', target: 2),
      CareerSector.politics => (metric: '曝光度', label: '曝光', target: 2),
      CareerSector.entertainment => (
        metric: '內容產出',
        label: '內容',
        target: 2,
      ),
      CareerSector.labour => (metric: '工時', label: '工時', target: 2),
      CareerSector.none || CareerSector.student => null,
    };
  }

  static int _kpiLastFor(Player p, CareerSector sector) {
    final prefix = '$_kpiFlagPrefix${sector.name}_';
    for (final f in p.unlockedFlags) {
      if (f.startsWith(prefix)) {
        return int.tryParse(f.substring(prefix.length)) ?? 0;
      }
    }
    return 0;
  }

  static void _setKpiLastFor(Player p, CareerSector sector, int total) {
    final prefix = '$_kpiFlagPrefix${sector.name}_';
    p.unlockedFlags.removeWhere((f) => f.startsWith(prefix));
    p.unlockedFlags.add('$prefix$total');
  }

  static void _seedKpiBaseline(Player p) {
    final spec = _kpiSpecFor(p.currentSector);
    if (spec == null) return;
    final total = (p.careerAttributes[spec.metric] as int?) ?? 0;
    _setKpiLastFor(p, p.currentSector, total);
  }

  static Quarter _previousQuarter(Quarter q) =>
      Quarter.values[(q.quarterIndex + 3) % 4];

  static int _kpiBaseTarget(CareerSector sector) {
    final spec = _kpiSpecFor(sector);
    return spec?.target ?? 0;
  }

  /// 本季（或指定季）KPI 目標；旺季 +1。
  static int kpiTargetFor(Player p, {Quarter? quarter}) {
    final base = _kpiBaseTarget(p.currentSector);
    if (base <= 0) return 0;
    final q = quarter ?? p.quarter;
    final busy = CareerBusySeasons.isBusy(p.currentSector, q);
    return base + (busy ? CareerBusySeasons.kpiBonus : 0);
  }

  static void _applyQuarterlyKpi(Player p) {
    final spec = _kpiSpecFor(p.currentSector);
    if (spec == null) return;
    final evalQuarter = _previousQuarter(p.quarter);
    final target = kpiTargetFor(p, quarter: evalQuarter);
    final total = (p.careerAttributes[spec.metric] as int?) ?? 0;
    final last = _kpiLastFor(p, p.currentSector);
    final delta = (total - last).clamp(0, 9999);
    final busyNote = CareerBusySeasons.isBusy(p.currentSector, evalQuarter)
        ? '（旺季目標 +1）'
        : '';
    if (delta < target) {
      p.jobPerformance = (p.jobPerformance - 4).clamp(0, 100);
      p.stress = (p.stress + 3).clamp(0, 100);
      final special = CareerAbilities.applyKpiFailPenalty(p);
      final specialNote = special.isEmpty ? '' : '；$special';
      p.eventLog.add(
        'KPI 未達標（${spec.label} $delta/$target$busyNote）：'
        '表現 -4、壓力 +3$specialNote',
      );
    } else {
      p.jobPerformance = (p.jobPerformance + 2).clamp(0, 100);
      p.eventLog.add(
        'KPI 達標（${spec.label} $delta/$target$busyNote）：表現 +2',
      );
    }
    _setKpiLastFor(p, p.currentSector, total);
  }

  /// 本季 KPI 進度（供 UI 顯示）；無 KPI 嘅行業回傳 null。
  static ({String label, int current, int target, bool busy})? kpiProgress(
    Player p,
  ) {
    if (!p.isEmployed) return null;
    final spec = _kpiSpecFor(p.currentSector);
    if (spec == null) return null;
    final total = (p.careerAttributes[spec.metric] as int?) ?? 0;
    final last = _kpiLastFor(p, p.currentSector);
    final current = (total - last).clamp(0, 9999);
    final target = kpiTargetFor(p);
    final busy = CareerBusySeasons.isBusy(p.currentSector, p.quarter);
    return (label: spec.label, current: current, target: target, busy: busy);
  }

  static String? kpiProgressLabel(Player p) {
    final progress = kpiProgress(p);
    if (progress == null) return null;
    final busyTag = progress.busy ? ' · 旺季' : '';
    return '${progress.label} ${progress.current}/${progress.target}$busyTag';
  }

  static String? kpiBusySeasonHint(Player p) =>
      CareerBusySeasons.busyHint(p.currentSector, p.quarter);

  /// 呢份工係咪有專屬行業行動（唔係「做好本份（加強）」fallback）。
  static bool hasDedicatedSectorAction(Player p) =>
      _kpiSpecFor(p.currentSector) != null;

  static String doCoreWork(Player p) {
    if (!p.isEmployed) return '你冇全職。';
    p.jobWorkedThisQuarter = true;
    p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
    p.stress = (p.stress + 4).clamp(0, 100);
    p.discipline = (p.discipline + 1).clamp(0, 100);
    // 空服「留基地／休息日」可消時差
    if (p.currentSector == CareerSector.flightAttendant) {
      CareerAbilities.add(p, '時差影響', -4, min: 0);
      return '做好本份（基地休息），表現 +8，時差↓（而家 ${p.jobPerformance}）';
    }
    return '做好本份，表現 +8（而家 ${p.jobPerformance}）';
  }

  static String doOvertime(Player p) {
    if (!p.isEmployed) return '你冇全職。';
    p.jobWorkedThisQuarter = true;
    p.jobPerformance = (p.jobPerformance + 14).clamp(0, 100);
    p.stress = (p.stress + 10).clamp(0, 100);
    p.san = (p.san - 4).clamp(0, p.maxSan);
    final bonus = CareerEmployment.effectiveMonthlySalary(p) ~/ 40;
    CareerTax.grantTaxablePay(p, bonus);
    final meet = SocialCircle.tryMeet(p, FriendSource.work, baseChance: 0.18);
    final meetNote = meet != null ? '；$meet' : '';
    return 'OT 搏命，表現 +14，額外 \$$bonus$meetNote';
  }

  static bool _luckRoll(Player p) =>
      Random(p.year * 31 + p.age + p.jobPerformance).nextInt(100) <
      (25 + p.luck ~/ 5);

  /// 行業行動最少壓力代價（高過「做好本份」+4）。
  static const int _sectorMinStress = 5;

  static void _sectorStress(Player p, int amount) {
    p.stress = (p.stress + amount.clamp(_sectorMinStress, 20)).clamp(0, 100);
  }

  static String doSectorAction(Player p) {
    if (!p.isEmployed) return '你冇全職。';
    if (p.currentSector == CareerSector.none ||
        p.currentSector == CareerSector.student) {
      return '你冇全職。';
    }
    p.jobWorkedThisQuarter = true;
    CareerAbilities.onSectorActionSuccess(p);
    SocialCircle.tryMeet(p, FriendSource.work, baseChance: 0.22);
    switch (p.currentSector) {
      case CareerSector.socialWork:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        p.reputation = (p.reputation + 2).clamp(0, 100);
        p.stress = (p.stress + 6).clamp(0, 100);
        p.careerAttributes['個案數'] =
            ((p.careerAttributes['個案數'] as int?) ?? 0) + 1;
        return '跟進個案，表現 +8';
      case CareerSector.teaching:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.careerAttributes['改簿量'] =
            ((p.careerAttributes['改簿量'] as int?) ?? 0) + 1;
        return '備課改簿，表現 +8';
      case CareerSector.nursing:
      case CareerSector.medical:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        p.stress = (p.stress + 8).clamp(0, 100);
        p.hp = (p.hp - 2).clamp(0, p.maxHp);
        p.careerAttributes['值班時數'] =
            ((p.careerAttributes['值班時數'] as int?) ?? 0) + 1;
        return '值班，表現 +8';
      case CareerSector.banking:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.network = (p.network + 2).clamp(0, 100);
        p.careerAttributes['客戶數'] =
            ((p.careerAttributes['客戶數'] as int?) ?? 0) + 1;
        return '搵客／開戶，表現 +8';
      case CareerSector.accounting:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        p.stress = (p.stress + 12).clamp(0, 100);
        p.careerAttributes['Busy Season'] =
            ((p.careerAttributes['Busy Season'] as int?) ?? 0) + 1;
        return 'Busy season 核數，表現 +8';
      case CareerSector.it:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.smarts = (p.smarts + 1).clamp(0, 100);
        p.careerAttributes['Project 數'] =
            ((p.careerAttributes['Project 數'] as int?) ?? 0) + 1;
        return '交 project，表現 +8';
      case CareerSector.media:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.reputation = (p.reputation + 2).clamp(0, 100);
        p.careerAttributes['稿件數'] =
            ((p.careerAttributes['稿件數'] as int?) ?? 0) + 1;
        return '交稿／採訪，表現 +8';
      case CareerSector.realEstate:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        if (_luckRoll(p)) {
          CareerTax.grantTaxablePay(p, 8000);
          p.careerAttributes['成交單'] =
              ((p.careerAttributes['成交單'] as int?) ?? 0) + 1;
          return '開到單！佣金 \$8000，表現 +8（壓力 +5）';
        }
        p.stress = (p.stress + 3).clamp(0, 100);
        return '帶客睇樓，未成交；表現 +8（壓力 +8）';
      case CareerSector.insurance:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.network = (p.network + 2).clamp(0, 100);
        p.careerAttributes['保單數'] =
            ((p.careerAttributes['保單數'] as int?) ?? 0) + 1;
        return '推保險，表現 +8';
      case CareerSector.flightAttendant:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.hp = (p.hp - 1).clamp(0, p.maxHp);
        p.careerAttributes['飛行時數'] =
            ((p.careerAttributes['飛行時數'] as int?) ?? 0) + 10;
        return '飛長途，表現 +8（壓力 +5、HP -1）';
      case CareerSector.engineering:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        p.smarts = (p.smarts + 1).clamp(0, 100);
        p.stress = (p.stress + 6).clamp(0, 100);
        p.careerAttributes['工程進度'] =
            ((p.careerAttributes['工程進度'] as int?) ?? 0) + 1;
        return '地盤／圖則跟進，表現 +8';
      case CareerSector.disciplinary:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.discipline = (p.discipline + 2).clamp(0, 100);
        p.hp = (p.hp - 2).clamp(0, p.maxHp);
        p.careerAttributes['執勤次數'] =
            ((p.careerAttributes['執勤次數'] as int?) ?? 0) + 1;
        final branch = disciplinaryBranchOf(p);
        return switch (branch) {
          'icac' => '調查／外勤取證，表現 +8',
          'fire' => '操練／救援勤務，表現 +8',
          'customs' => '清關／巡查，表現 +8',
          'police' => '巡邏／執勤，表現 +8',
          _ => '操練／巡邏，表現 +8',
        };
      case CareerSector.catering:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        p.stress = (p.stress + 7).clamp(0, 100);
        p.network = (p.network + 1).clamp(0, 100);
        p.careerAttributes['排更班次'] =
            ((p.careerAttributes['排更班次'] as int?) ?? 0) + 1;
        return '睇舖／排更，表現 +8';
      case CareerSector.pharmacy:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.smarts = (p.smarts + 1).clamp(0, 100);
        p.careerAttributes['處方覆核'] =
            ((p.careerAttributes['處方覆核'] as int?) ?? 0) + 1;
        return '覆核處方／配藥，表現 +8';
      case CareerSector.legalSolicitor:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.smarts = (p.smarts + 1).clamp(0, 100);
        p.careerAttributes['檔案數'] =
            ((p.careerAttributes['檔案數'] as int?) ?? 0) + 1;
        return '跟進檔案／草擬文件，表現 +8';
      case CareerSector.legalBarrister:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        p.stress = (p.stress + 8).clamp(0, 100);
        p.san = (p.san - 2).clamp(0, p.maxSan);
        p.reputation = (p.reputation + 2).clamp(0, 100);
        p.careerAttributes['上庭次數'] =
            ((p.careerAttributes['上庭次數'] as int?) ?? 0) + 1;
        return '上庭辯論，表現 +8';
      case CareerSector.civilService:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.discipline = (p.discipline + 2).clamp(0, 100);
        p.careerAttributes['公文完成量'] =
            ((p.careerAttributes['公文完成量'] as int?) ?? 0) + 1;
        return '跟進公文／政策文件，表現 +8';
      case CareerSector.taxi:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.careerAttributes['載客量'] =
            ((p.careerAttributes['載客量'] as int?) ?? 0) + 1;
        if (_luckRoll(p)) {
          CareerTax.grantTaxablePay(p, 1200);
          return '旺場載客，額外 \$1200，表現 +8';
        }
        return '出車載客，表現 +8';
      case CareerSector.politics:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.network = (p.network + 2).clamp(0, 100);
        p.careerAttributes['曝光度'] =
            ((p.careerAttributes['曝光度'] as int?) ?? 0) + 1;
        // 每次落區都累積票倉；運程好再多 1
        p.careerAttributes['票倉'] =
            ((p.careerAttributes['票倉'] as int?) ?? 0) + 1;
        if (_luckRoll(p)) {
          p.careerAttributes['票倉'] =
              ((p.careerAttributes['票倉'] as int?) ?? 0) + 1;
          return '落區拉票成功，票倉 +2，表現 +8';
        }
        return '落區見街坊，票倉 +1，表現 +8';
      case CareerSector.entertainment:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        _sectorStress(p, 5);
        p.san = (p.san - 1).clamp(0, p.maxSan);
        p.careerAttributes['內容產出'] =
            ((p.careerAttributes['內容產出'] as int?) ?? 0) + 1;
        return '拍片／開 Live，表現 +8（Views／粉絲有機會升）';
      case CareerSector.labour:
        p.jobPerformance = (p.jobPerformance + 8).clamp(0, 100);
        p.stress = (p.stress + 6).clamp(0, 100);
        p.hp = (p.hp - 2).clamp(0, p.maxHp);
        p.careerAttributes['工時'] =
            ((p.careerAttributes['工時'] as int?) ?? 0) + 1;
        return '做枱／搬貨，表現 +8';
      case CareerSector.none:
      case CareerSector.student:
        return '你冇全職。';
    }
  }

  static String sectorActionLabel(Player p) => switch (p.currentSector) {
        CareerSector.socialWork => '做個案',
        CareerSector.teaching => '備課改簿',
        CareerSector.nursing || CareerSector.medical => '值班',
        CareerSector.banking => '搵客／開戶',
        CareerSector.accounting => 'Busy season',
        CareerSector.it => '交 project',
        CareerSector.media => '交稿採訪',
        CareerSector.realEstate => '帶客睇樓／開單',
        CareerSector.insurance => '推保單',
        CareerSector.flightAttendant => '執勤飛行',
        CareerSector.engineering => '跟進項目',
        CareerSector.disciplinary => switch (disciplinaryBranchOf(p)) {
            'icac' => '調查外勤',
            'fire' => '救援勤務',
            'customs' => '清關巡查',
            _ => '操練／巡邏',
          },
        CareerSector.catering => '睇舖排更',
        CareerSector.pharmacy => '覆核處方',
        CareerSector.legalSolicitor => '跟進檔案',
        CareerSector.legalBarrister => '上庭辯論',
        CareerSector.civilService => '跟進公文',
        CareerSector.taxi => '出車載客',
        CareerSector.politics => '落區拉票',
        CareerSector.entertainment => '拍片／開 Live',
        CareerSector.labour => '做枱搬貨',
        CareerSector.none || CareerSector.student => '—',
      };

  static String tryPrestigeHire(Player p, CareerSector sector) {
    if (p.isStudying) return '讀緊書唔可以做全職';
    final block = entryBlockReason(p, sector);
    if (block != null) return block;
    final chance =
        (20 + p.smarts ~/ 4 + p.uniGpa.round() * 5 + p.luck ~/ 5)
            .clamp(10, 75);
    final ok = Random(p.year + p.smarts).nextInt(100) < chance;
    if (!ok) {
      p.stress = (p.stress + 5).clamp(0, 100);
      return '名企面試唔過（約 $chance%），再練吓啦';
    }
    final employer = switch (sector) {
      CareerSector.banking => '滙豐 HSBC',
      CareerSector.accounting =>
        ['PwC', 'Deloitte', 'EY', 'KPMG'][Random(p.year).nextInt(4)],
      CareerSector.it =>
        Random(p.age).nextBool() ? 'Google' : 'Microsoft HK',
      CareerSector.flightAttendant => '國泰 Cathay',
      CareerSector.media => 'TVB 新聞',
      _ => '',
    };
    enterCareer(
      p,
      sector,
      employerOverride: employer.isEmpty ? null : employer,
    );
    p.reputation = (p.reputation + 8).clamp(0, 100);
    p.jobPerformance = 30;
    return '入到名企：${p.jobTitle}！';
  }

  static List<ActionButton> employedActions(Player p) {
    if (!p.isEmployed) return const [];
    final promoLabel = canPromote(p)
        ? '爭取升職 · ${promoteOddsHint(p)}'
        : '爭取升職';
    return [
      ActionButton(
        label: '做好本份',
        apCost: 1,
        onExecute: (pl) => pl.eventLog.add(doCoreWork(pl)),
      ),
      ActionButton(
        label: '加班／OT',
        apCost: 2,
        onExecute: (pl) => pl.eventLog.add(doOvertime(pl)),
      ),
      ActionButton(
        label: sectorActionLabel(p),
        apCost: 1,
        onExecute: (pl) => pl.eventLog.add(doSectorAction(pl)),
      ),
      ActionButton(
        label: promoLabel,
        apCost: 2,
        onExecute: (pl) => pl.eventLog.add(promote(pl)),
      ),
    ];
  }
}
