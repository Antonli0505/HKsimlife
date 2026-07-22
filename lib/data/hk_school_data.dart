import 'dart:math';

import '../models/enums.dart';
import '../models/player.dart';

// ─── 學校類型 / 地區 / 校網 ─────────────────────────────────

enum SchoolType { gov, aided, dss, private, international }

extension SchoolTypeExt on SchoolType {
  String get label => switch (this) {
        SchoolType.gov => '官立',
        SchoolType.aided => '資助',
        SchoolType.dss => '直資',
        SchoolType.private => '私立',
        SchoolType.international => '國際',
      };
}

/// 居住／校網地區（影響統派乙部）
enum HkDistrict {
  centralWestern,
  wanChai,
  eastern,
  southern,
  kowloonCity,
  kwunTong,
  shamShuiPo,
  yauTsimMong,
  wongTaiSin,
  shaTin,
  saiKung,
  taiPo,
  north,
  tuenMun,
  yuenLong,
  tsuenWan,
  kwaiTsing,
}

extension HkDistrictExt on HkDistrict {
  String get label => switch (this) {
        HkDistrict.centralWestern => '中西區',
        HkDistrict.wanChai => '灣仔',
        HkDistrict.eastern => '東區',
        HkDistrict.southern => '南區',
        HkDistrict.kowloonCity => '九龍城',
        HkDistrict.kwunTong => '觀塘',
        HkDistrict.shamShuiPo => '深水埗',
        HkDistrict.yauTsimMong => '油尖旺',
        HkDistrict.wongTaiSin => '黃大仙',
        HkDistrict.shaTin => '沙田',
        HkDistrict.saiKung => '西貢',
        HkDistrict.taiPo => '大埔',
        HkDistrict.north => '北區',
        HkDistrict.tuenMun => '屯門',
        HkDistrict.yuenLong => '元朗',
        HkDistrict.tsuenWan => '荃灣',
        HkDistrict.kwaiTsing => '葵青',
      };

  /// 中學學位分配校網名稱（簡化）
  String get schoolNet => switch (this) {
        HkDistrict.centralWestern ||
        HkDistrict.wanChai ||
        HkDistrict.southern =>
          '港島西',
        HkDistrict.eastern => '港島東',
        HkDistrict.kowloonCity || HkDistrict.yauTsimMong => '九龍城',
        HkDistrict.kwunTong => '觀塘',
        HkDistrict.shamShuiPo => '深水埗',
        HkDistrict.wongTaiSin => '黃大仙',
        HkDistrict.shaTin => '沙田',
        HkDistrict.saiKung => '西貢',
        HkDistrict.taiPo => '大埔',
        HkDistrict.north => '北區',
        HkDistrict.tuenMun => '屯門',
        HkDistrict.yuenLong => '元朗',
        HkDistrict.tsuenWan || HkDistrict.kwaiTsing => '荃灣',
      };
}

/// 自行分配 / 一條龍 / 統派甲部 / 統派乙部
enum SsaPathway {
  none,
  throughTrain,
  discretionary,
  centralPartA,
  centralPartB,
}

extension SsaPathwayExt on SsaPathway {
  String get label => switch (this) {
        SsaPathway.none => '未分配',
        SsaPathway.throughTrain => '一條龍／聯繫升中',
        SsaPathway.discretionary => '自行分配學位',
        SsaPathway.centralPartA => '統一派位 · 甲部（跨網）',
        SsaPathway.centralPartB => '統一派位 · 乙部（本網）',
      };
}

/// 呈分組別 — 對應 Band 1／2／3（唔再用甲一乙二等舊叫法）
enum SsaBandGroup { none, a1, a2, b1, b2, c1, c2 }

extension SsaBandGroupExt on SsaBandGroup {
  String get label => switch (this) {
        SsaBandGroup.none => '未定',
        SsaBandGroup.a1 => 'Band 1（頂）',
        SsaBandGroup.a2 => 'Band 1',
        SsaBandGroup.b1 => 'Band 2（上）',
        SsaBandGroup.b2 => 'Band 2',
        SsaBandGroup.c1 => 'Band 3（上）',
        SsaBandGroup.c2 => 'Band 3',
      };

  SchoolBand get schoolBand => switch (this) {
        SsaBandGroup.a1 || SsaBandGroup.a2 => SchoolBand.band1,
        SsaBandGroup.b1 || SsaBandGroup.b2 => SchoolBand.band2,
        SsaBandGroup.c1 || SsaBandGroup.c2 => SchoolBand.band3,
        SsaBandGroup.none => SchoolBand.none,
      };

  /// 統派優先序（數字愈細愈先派）
  int get priority => switch (this) {
        SsaBandGroup.a1 => 1,
        SsaBandGroup.a2 => 2,
        SsaBandGroup.b1 => 3,
        SsaBandGroup.b2 => 4,
        SsaBandGroup.c1 => 5,
        SsaBandGroup.c2 => 6,
        SsaBandGroup.none => 99,
      };
}

// ─── 學校資料模型 ───────────────────────────────────────────

class HkSecondarySchool {
  final String id;
  final String name;
  final SchoolBand band;
  final HkDistrict district;
  final SchoolType type;
  final String language; // EMI / CMI / 兩文三語
  final List<String> tags;
  final List<String> feederPrimaryIds;
  final bool acceptsDp;
  final int prestige; // 1–100，自行分配面試難度
  final bool boysOnly;
  final bool girlsOnly;

  const HkSecondarySchool({
    required this.id,
    required this.name,
    required this.band,
    required this.district,
    required this.type,
    required this.language,
    this.tags = const [],
    this.feederPrimaryIds = const [],
    this.acceptsDp = true,
    this.prestige = 50,
    this.boysOnly = false,
    this.girlsOnly = false,
  });

  String get schoolNet => district.schoolNet;

  String get profileLine =>
      '${type.label} · ${district.label} · $language · ${band.secondaryLabel}';

  String get shortMeta =>
      '${district.schoolNet} · ${type.label} · $language';
}

class HkPrimarySchool {
  final String id;
  final String name;
  final SchoolBand band;
  final HkDistrict district;
  final SchoolType type;
  final bool isThroughTrain;
  final String? linkedSecondaryId;
  final List<String> feederSecondaryIds;

  const HkPrimarySchool({
    required this.id,
    required this.name,
    required this.band,
    required this.district,
    required this.type,
    this.isThroughTrain = false,
    this.linkedSecondaryId,
    this.feederSecondaryIds = const [],
  });

  bool get hasFeederLink =>
      isThroughTrain ||
      linkedSecondaryId != null ||
      feederSecondaryIds.isNotEmpty;
}

class SsaAllocationResult {
  final HkSecondarySchool school;
  final SsaPathway pathway;
  final SsaBandGroup bandGroup;
  final int placementScore;
  final List<String> steps;

  const SsaAllocationResult({
    required this.school,
    required this.pathway,
    required this.bandGroup,
    required this.placementScore,
    required this.steps,
  });

  String get summary =>
      '呈分 $placementScore · ${bandGroup.label}（${school.band.secondaryLabel}）\n'
      '${pathway.label}\n'
      '派位：${school.name}（${school.profileLine}）';
}

// ─── 校庫 ───────────────────────────────────────────────────

class HkSchoolData {
  /// 各校網均有 Band 1／2／3；Band 為遊戲用家長觀感分組，非官方標籤。
  static const secondarySchools = <HkSecondarySchool>[
    // ═══════════════ Band 1 ═══════════════
    // 港島西
    HkSecondarySchool(
      id: 'qes',
      name: '皇仁書院',
      band: SchoolBand.band1,
      district: HkDistrict.wanChai,
      type: SchoolType.gov,
      language: 'EMI',
      tags: ['傳統名校', '男校'],
      prestige: 95,
      boysOnly: true,
    ),
    HkSecondarySchool(
      id: 'wah_yan_hk',
      name: '香港華仁書院',
      band: SchoolBand.band1,
      district: HkDistrict.wanChai,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['男校', '耶穌會'],
      prestige: 91,
      boysOnly: true,
    ),
    HkSecondarySchool(
      id: 'spss',
      name: '聖保祿學校',
      band: SchoolBand.band1,
      district: HkDistrict.wanChai,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['女校'],
      prestige: 89,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'spcc',
      name: '聖保羅男女中學',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['直資名校', '一條龍'],
      prestige: 94,
      feederPrimaryIds: ['spcps'],
    ),
    HkSecondarySchool(
      id: 'st_paul_coed',
      name: '聖保羅書院',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['傳統名校', '男校'],
      prestige: 90,
      boysOnly: true,
    ),
    HkSecondarySchool(
      id: 'st_stephen_girls',
      name: '聖士提反女子中學',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['女校'],
      prestige: 88,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'ying_wa_girls',
      name: '英華女學校',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['女校'],
      prestige: 86,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'island_school',
      name: '港島中學',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['英基'],
      prestige: 90,
    ),
    HkSecondarySchool(
      id: 'st_joseph',
      name: '聖若瑟書院',
      band: SchoolBand.band1,
      district: HkDistrict.wanChai,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['男校'],
      prestige: 87,
      boysOnly: true,
    ),
    HkSecondarySchool(
      id: 'sacred_heart_canossian',
      name: '嘉諾撒聖心書院',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['女校'],
      prestige: 85,
      girlsOnly: true,
    ),
    // 港島東／南
    HkSecondarySchool(
      id: 'chinese_foundation',
      name: '中華基金中學',
      band: SchoolBand.band1,
      district: HkDistrict.eastern,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['直資'],
      prestige: 84,
    ),
    HkSecondarySchool(
      id: 'clementi',
      name: '金文泰中學',
      band: SchoolBand.band1,
      district: HkDistrict.eastern,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 80,
    ),
    HkSecondarySchool(
      id: 'shau_kei_wan_gov',
      name: '筲箕灣官立中學',
      band: SchoolBand.band1,
      district: HkDistrict.eastern,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 79,
    ),
    HkSecondarySchool(
      id: 'st_mark',
      name: '聖馬可中學',
      band: SchoolBand.band1,
      district: HkDistrict.eastern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 81,
    ),
    HkSecondarySchool(
      id: 'st_stephen',
      name: '聖士提反書院',
      band: SchoolBand.band1,
      district: HkDistrict.southern,
      type: SchoolType.aided,
      language: 'EMI',
      prestige: 83,
    ),
    HkSecondarySchool(
      id: 'aberdeen_baptist',
      name: '香港仔浸信會呂明才書院',
      band: SchoolBand.band1,
      district: HkDistrict.southern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 77,
    ),
    // 九龍城／油尖旺
    HkSecondarySchool(
      id: 'dbs',
      name: '拔萃男書院',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['傳統名校', '男校'],
      prestige: 96,
      boysOnly: true,
      feederPrimaryIds: ['dbps'],
    ),
    HkSecondarySchool(
      id: 'dgs',
      name: '拔萃女書院',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['傳統名校', '女校'],
      prestige: 96,
      girlsOnly: true,
      feederPrimaryIds: ['psps'],
    ),
    HkSecondarySchool(
      id: 'lasalle',
      name: '喇沙書院',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['傳統名校', '男校'],
      prestige: 93,
      boysOnly: true,
      feederPrimaryIds: ['lasalle_ps'],
    ),
    HkSecondarySchool(
      id: 'heep_yunn',
      name: '協恩中學',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['女校'],
      prestige: 88,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'maryknoll_convent',
      name: '瑪利諾修院學校（中學部）',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['女校'],
      prestige: 87,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'wah_yan_kln',
      name: '九龍華仁書院',
      band: SchoolBand.band1,
      district: HkDistrict.yauTsimMong,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['男校', '耶穌會'],
      prestige: 90,
      boysOnly: true,
    ),
    HkSecondarySchool(
      id: 'true_light_kln',
      name: '九龍真光中學',
      band: SchoolBand.band1,
      district: HkDistrict.yauTsimMong,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['女校'],
      prestige: 85,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'munsang',
      name: '民生書院',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'EMI',
      prestige: 84,
    ),
    HkSecondarySchool(
      id: 'pui_ching',
      name: '培正中學',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 86,
    ),
    // 觀塘／黃大仙／深水埗
    HkSecondarySchool(
      id: 'carmel',
      name: '迦密中學',
      band: SchoolBand.band1,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 78,
    ),
    HkSecondarySchool(
      id: 'ng_wah',
      name: '天主教伍華中學',
      band: SchoolBand.band1,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 76,
    ),
    HkSecondarySchool(
      id: 'good_hope',
      name: '德望學校',
      band: SchoolBand.band1,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['女校', '直資'],
      prestige: 88,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'st_francis_xavier',
      name: '聖芳濟書院',
      band: SchoolBand.band1,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'EMI',
      tags: ['男校'],
      prestige: 82,
      boysOnly: true,
    ),
    HkSecondarySchool(
      id: 'lai_chack',
      name: '禮查中學',
      band: SchoolBand.band1,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 75,
    ),
    HkSecondarySchool(
      id: 'cheung_sha_wan_catholic',
      name: '長沙灣天主教英文中學',
      band: SchoolBand.band1,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'EMI',
      prestige: 80,
    ),
    // 沙田／西貢
    HkSecondarySchool(
      id: 'shatin_college',
      name: '沙田學院',
      band: SchoolBand.band1,
      district: HkDistrict.shaTin,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['英基', '直資'],
      prestige: 92,
    ),
    HkSecondarySchool(
      id: 'chinese_foundation_sha_tin',
      name: '浸信會呂明才中學',
      band: SchoolBand.band1,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 81,
    ),
    HkSecondarySchool(
      id: 'sha_tin_gov',
      name: '沙田官立中學',
      band: SchoolBand.band1,
      district: HkDistrict.shaTin,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 79,
    ),
    HkSecondarySchool(
      id: 'chinese_ymca',
      name: '中華基督教青年會中學',
      band: SchoolBand.band1,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 77,
    ),
    HkSecondarySchool(
      id: 'stfa_ykp',
      name: '順德聯誼總會翁祐中學',
      band: SchoolBand.band1,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 82,
    ),
    HkSecondarySchool(
      id: 'po_leung_kuk_laws_foundation',
      name: '保良局羅氏基金中學',
      band: SchoolBand.band1,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 80,
    ),
    // 大埔／北區／屯門／元朗／荃灣葵青
    HkSecondarySchool(
      id: 'tai_po_sam_yuk',
      name: '大埔三育中學',
      band: SchoolBand.band1,
      district: HkDistrict.taiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 76,
    ),
    HkSecondarySchool(
      id: 'hong_kong_teachers',
      name: '香港教師會李興貴中學',
      band: SchoolBand.band1,
      district: HkDistrict.taiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 74,
    ),
    HkSecondarySchool(
      id: 'fanling_lutheran',
      name: '粉嶺禮賢會中學',
      band: SchoolBand.band1,
      district: HkDistrict.north,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 75,
    ),
    HkSecondarySchool(
      id: 'elegantia',
      name: '風采中學（教育評議會主辦）',
      band: SchoolBand.band1,
      district: HkDistrict.north,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 78,
    ),
    HkSecondarySchool(
      id: 'plk_no1',
      name: '保良局第一張永慶中學',
      band: SchoolBand.band1,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 80,
    ),
    HkSecondarySchool(
      id: 'carmel_bunnan',
      name: '迦密唐賓南紀念中學',
      band: SchoolBand.band1,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 77,
    ),
    HkSecondarySchool(
      id: 'yfcm_tang_hin',
      name: '元朗公立中學校友會鄧兆棠中學',
      band: SchoolBand.band1,
      district: HkDistrict.yuenLong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 76,
    ),
    HkSecondarySchool(
      id: 'chiu_lut_sau',
      name: '趙聿修紀念中學',
      band: SchoolBand.band1,
      district: HkDistrict.yuenLong,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 74,
    ),
    HkSecondarySchool(
      id: 'st_bonaventure',
      name: '聖文德書院',
      band: SchoolBand.band1,
      district: HkDistrict.tsuenWan,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 78,
    ),
    HkSecondarySchool(
      id: 'plk_tang_yuk_tien',
      name: '保良局董玉娣中學',
      band: SchoolBand.band1,
      district: HkDistrict.tsuenWan,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 76,
    ),
    HkSecondarySchool(
      id: 'buddhist_sin_tak',
      name: '佛教善德中學',
      band: SchoolBand.band1,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 75,
    ),
    HkSecondarySchool(
      id: 'kwai_chung_methodist',
      name: '循道衛理聯合教會李惠利中學',
      band: SchoolBand.band1,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 74,
    ),

    // ═══════════════ Band 2 ═══════════════
    // 港島
    HkSecondarySchool(
      id: 'tang_shui_kin',
      name: '鄧肇堅維多利亞官立中學',
      band: SchoolBand.band2,
      district: HkDistrict.wanChai,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 62,
    ),
    HkSecondarySchool(
      id: 'hotung',
      name: '何東中學',
      band: SchoolBand.band2,
      district: HkDistrict.wanChai,
      type: SchoolType.gov,
      language: 'CMI',
      tags: ['女校'],
      prestige: 60,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'st_joan_arc',
      name: '聖貞德中學',
      band: SchoolBand.band2,
      district: HkDistrict.centralWestern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 63,
    ),
    HkSecondarySchool(
      id: 'yu_chun_keung',
      name: '余振強紀念中學',
      band: SchoolBand.band2,
      district: HkDistrict.southern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 58,
    ),
    HkSecondarySchool(
      id: 'pui_kiu',
      name: '培僑中學',
      band: SchoolBand.band2,
      district: HkDistrict.eastern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 65,
    ),
    HkSecondarySchool(
      id: 'cognitio_college_hk',
      name: '文理書院（香港）',
      band: SchoolBand.band2,
      district: HkDistrict.eastern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 64,
    ),
    HkSecondarySchool(
      id: 'lingnan_hang_yee',
      name: '嶺南衡怡紀念中學',
      band: SchoolBand.band2,
      district: HkDistrict.eastern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 61,
    ),
    // 九龍
    HkSecondarySchool(
      id: 'pooi_to',
      name: '培道中學',
      band: SchoolBand.band2,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'CMI',
      tags: ['女校'],
      prestige: 65,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'newman',
      name: '天主教新民書院',
      band: SchoolBand.band2,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 63,
    ),
    HkSecondarySchool(
      id: 'homantin_gov',
      name: '何文田官立中學',
      band: SchoolBand.band2,
      district: HkDistrict.kowloonCity,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 60,
    ),
    HkSecondarySchool(
      id: 'queen_elizabeth',
      name: '伊利沙伯中學',
      band: SchoolBand.band2,
      district: HkDistrict.yauTsimMong,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 68,
    ),
    HkSecondarySchool(
      id: 'king_george_v',
      name: '英皇佐治五世學校',
      band: SchoolBand.band2,
      district: HkDistrict.kowloonCity,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['英基'],
      prestige: 70,
    ),
    HkSecondarySchool(
      id: 'stfa_lkc',
      name: '順德聯誼總會梁銶琚中學',
      band: SchoolBand.band2,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 62,
    ),
    HkSecondarySchool(
      id: 'twgh_whn',
      name: '東華三院黃笏南中學',
      band: SchoolBand.band2,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 60,
    ),
    HkSecondarySchool(
      id: 'ning_po_no2',
      name: '寧波公學',
      band: SchoolBand.band2,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 64,
    ),
    HkSecondarySchool(
      id: 'kwun_tong_gov',
      name: '觀塘官立中學',
      band: SchoolBand.band2,
      district: HkDistrict.kwunTong,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 59,
    ),
    HkSecondarySchool(
      id: 'wong_tai_sin_catholic',
      name: '天主教彩雲第一中學',
      band: SchoolBand.band2,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 55,
    ),
    HkSecondarySchool(
      id: 'ccc_keilun',
      name: '中華基督教會基朗中學',
      band: SchoolBand.band2,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 58,
    ),
    HkSecondarySchool(
      id: 'our_lady_good_counsel',
      name: '聖母書院',
      band: SchoolBand.band2,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.aided,
      language: 'CMI',
      tags: ['女校'],
      prestige: 61,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'ccc_ming_yin',
      name: '中華基督教會銘賢書院',
      band: SchoolBand.band2,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 61,
    ),
    HkSecondarySchool(
      id: 'delia_memorial_broadway',
      name: '地利亞修女紀念學校（百老匯）',
      band: SchoolBand.band2,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 56,
    ),
    HkSecondarySchool(
      id: 'nam_wah',
      name: '南華中學',
      band: SchoolBand.band2,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 57,
    ),
    // 新界東
    HkSecondarySchool(
      id: 'cognitio',
      name: '啟思中學',
      band: SchoolBand.band2,
      district: HkDistrict.shaTin,
      type: SchoolType.dss,
      language: 'EMI',
      prestige: 68,
    ),
    HkSecondarySchool(
      id: 'immanuel_lutheran',
      name: '基督教香港信義會心誠中學',
      band: SchoolBand.band2,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 63,
    ),
    HkSecondarySchool(
      id: 'lock_tao',
      name: '樂道中學',
      band: SchoolBand.band2,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 58,
    ),
    HkSecondarySchool(
      id: 'king_ling',
      name: '景嶺書院',
      band: SchoolBand.band2,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 66,
    ),
    HkSecondarySchool(
      id: 'tko_methodist',
      name: '將軍澳循道衛理中學',
      band: SchoolBand.band2,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 60,
    ),
    HkSecondarySchool(
      id: 'cheng_chek_chee',
      name: '鄭植之中學',
      band: SchoolBand.band2,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 59,
    ),
    HkSecondarySchool(
      id: 'wong_shiu_chi',
      name: '王肇枝中學',
      band: SchoolBand.band2,
      district: HkDistrict.taiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 64,
    ),
    HkSecondarySchool(
      id: 'tai_po_gov',
      name: '大埔官立中學',
      band: SchoolBand.band2,
      district: HkDistrict.taiPo,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 60,
    ),
    HkSecondarySchool(
      id: 'carolyn',
      name: '迦密聖道中學',
      band: SchoolBand.band2,
      district: HkDistrict.taiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 61,
    ),
    HkSecondarySchool(
      id: 'fanling_gov',
      name: '粉嶺官立中學',
      band: SchoolBand.band2,
      district: HkDistrict.north,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 58,
    ),
    HkSecondarySchool(
      id: 'sheung_shui_gov',
      name: '上水官立中學',
      band: SchoolBand.band2,
      district: HkDistrict.north,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 57,
    ),
    HkSecondarySchool(
      id: 'christian_alliance_swayne',
      name: '宣道中學',
      band: SchoolBand.band2,
      district: HkDistrict.north,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 62,
    ),
    // 新界西
    HkSecondarySchool(
      id: 'mkss',
      name: '馬可賓紀念中學',
      band: SchoolBand.band2,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 58,
    ),
    HkSecondarySchool(
      id: 'plk_laws',
      name: '保良局羅傑承（一九八三）中學',
      band: SchoolBand.band2,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 64,
    ),
    HkSecondarySchool(
      id: 'cma_choi_cheung_kok',
      name: '廠商會蔡章閣中學',
      band: SchoolBand.band2,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 56,
    ),
    HkSecondarySchool(
      id: 'nt_heung_yee_kuk',
      name: '新界鄉議局元朗區中學',
      band: SchoolBand.band2,
      district: HkDistrict.yuenLong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 57,
    ),
    HkSecondarySchool(
      id: 'yfcm_tin_ka_ping',
      name: '元朗公立中學校友會鄧英業中學',
      band: SchoolBand.band2,
      district: HkDistrict.yuenLong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 59,
    ),
    HkSecondarySchool(
      id: 'pak_kau',
      name: '博愛醫院歷屆總理聯誼會梁省德中學',
      band: SchoolBand.band2,
      district: HkDistrict.yuenLong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 55,
    ),
    HkSecondarySchool(
      id: 'buddhist_fat_ho',
      name: '佛教筏可紀念中學',
      band: SchoolBand.band2,
      district: HkDistrict.tsuenWan,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 55,
    ),
    HkSecondarySchool(
      id: 'liu_po_shan',
      name: '廖寶珊紀念書院',
      band: SchoolBand.band2,
      district: HkDistrict.tsuenWan,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 58,
    ),
    HkSecondarySchool(
      id: 'hkma_david_li',
      name: '香港管理專業協會李國寶中學',
      band: SchoolBand.band2,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 59,
    ),
    HkSecondarySchool(
      id: 'buddhist_sin_tak_b2',
      name: '棉紡會中學',
      band: SchoolBand.band2,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 54,
    ),
    HkSecondarySchool(
      id: 'salesian_yip_hon',
      name: '天主教母佑會蕭明中學',
      band: SchoolBand.band2,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 56,
    ),

    // ═══════════════ Band 3 ═══════════════
    // 港島
    HkSecondarySchool(
      id: 'cfss',
      name: '明愛莊月明中學',
      band: SchoolBand.band3,
      district: HkDistrict.eastern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 35,
    ),
    HkSecondarySchool(
      id: 'caritas_chong_yuet_ming',
      name: '明愛柴灣馬登基金中學',
      band: SchoolBand.band3,
      district: HkDistrict.eastern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 33,
    ),
    HkSecondarySchool(
      id: 'henrietta',
      name: '顯理中學',
      band: SchoolBand.band3,
      district: HkDistrict.eastern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 38,
    ),
    HkSecondarySchool(
      id: 'tang_king_po',
      name: '鄧鏡波學校',
      band: SchoolBand.band3,
      district: HkDistrict.wanChai,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 36,
    ),
    HkSecondarySchool(
      id: 'cognitio_kowloon',
      name: '文理書院（九龍）',
      band: SchoolBand.band3,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 37,
    ),
    HkSecondarySchool(
      id: 'methodist_college',
      name: '循道中學',
      band: SchoolBand.band3,
      district: HkDistrict.wanChai,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 40,
    ),
    HkSecondarySchool(
      id: 'st_louis',
      name: '聖類斯中學',
      band: SchoolBand.band3,
      district: HkDistrict.centralWestern,
      type: SchoolType.aided,
      language: 'CMI',
      tags: ['男校'],
      prestige: 42,
      boysOnly: true,
    ),
    HkSecondarySchool(
      id: 'hk_sea_school',
      name: '香港航海學校',
      band: SchoolBand.band3,
      district: HkDistrict.southern,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 34,
    ),
    HkSecondarySchool(
      id: 'south_island',
      name: '南島中學',
      band: SchoolBand.band3,
      district: HkDistrict.southern,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['英基'],
      prestige: 45,
    ),
    // 九龍
    HkSecondarySchool(
      id: 'delia_memorial',
      name: '地利亞修女紀念學校（協和）',
      band: SchoolBand.band3,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 33,
    ),
    HkSecondarySchool(
      id: 'kwun_tong_maryknoll',
      name: '觀塘瑪利諾書院',
      band: SchoolBand.band3,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 39,
    ),
    HkSecondarySchool(
      id: 'leung_shek_chee',
      name: '梁式芝書院',
      band: SchoolBand.band3,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 35,
    ),
    HkSecondarySchool(
      id: 'ko_lui',
      name: '高雷中學',
      band: SchoolBand.band3,
      district: HkDistrict.kwunTong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 32,
    ),
    HkSecondarySchool(
      id: 'christian_alliance_sw',
      name: '宣道會陳瑞芝紀念中學',
      band: SchoolBand.band3,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 37,
    ),
    HkSecondarySchool(
      id: 'our_lady_of_the_rosary',
      name: '聖母玫瑰書院',
      band: SchoolBand.band3,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'CMI',
      tags: ['女校'],
      prestige: 40,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'ccc_ming_kei',
      name: '中華基督教會銘基書院',
      band: SchoolBand.band3,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 38,
    ),
    HkSecondarySchool(
      id: 'lung_cheung',
      name: '龍翔官立中學',
      band: SchoolBand.band3,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 36,
    ),
    HkSecondarySchool(
      id: 'buddhist_hung_sean',
      name: '佛教孔仙洲紀念中學',
      band: SchoolBand.band3,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 34,
    ),
    HkSecondarySchool(
      id: 'stevenson',
      name: '聖公會聖本德中學',
      band: SchoolBand.band3,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 41,
    ),
    HkSecondarySchool(
      id: 'holy_trinity',
      name: '聖三一堂中學',
      band: SchoolBand.band3,
      district: HkDistrict.yauTsimMong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 37,
    ),
    HkSecondarySchool(
      id: 'true_light_middle',
      name: '真光女書院',
      band: SchoolBand.band3,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'CMI',
      tags: ['女校'],
      prestige: 43,
      girlsOnly: true,
    ),
    HkSecondarySchool(
      id: 'raimondi',
      name: '高主教書院',
      band: SchoolBand.band3,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 44,
    ),
    // 新界東
    HkSecondarySchool(
      id: 'nthy',
      name: '新界鄉議局大埔區中學',
      band: SchoolBand.band3,
      district: HkDistrict.taiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 38,
    ),
    HkSecondarySchool(
      id: 'tai_po_sam_yuk_b3',
      name: '香港紅卍字會大埔卍慈中學',
      band: SchoolBand.band3,
      district: HkDistrict.taiPo,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 33,
    ),
    HkSecondarySchool(
      id: 'north_district',
      name: '鳳溪第一中學',
      band: SchoolBand.band3,
      district: HkDistrict.north,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 34,
    ),
    HkSecondarySchool(
      id: 'hhckla_buddhist',
      name: '香海正覺蓮社佛教梁植偉中學',
      band: SchoolBand.band3,
      district: HkDistrict.north,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 35,
    ),
    HkSecondarySchool(
      id: 'sha_tin_methodist',
      name: '沙田循道衛理中學',
      band: SchoolBand.band3,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 40,
    ),
    HkSecondarySchool(
      id: 'kuen_ngai',
      name: '基督書院',
      band: SchoolBand.band3,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 37,
    ),
    HkSecondarySchool(
      id: 'buddhist_tai_hung',
      name: '佛教大光中學',
      band: SchoolBand.band3,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 34,
    ),
    HkSecondarySchool(
      id: 'tko_catholic',
      name: '天主教鳴遠中學',
      band: SchoolBand.band3,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 36,
    ),
    HkSecondarySchool(
      id: 'po_leung_kuk_ho_yuk',
      name: '保良局何慶棠中學',
      band: SchoolBand.band3,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 38,
    ),
    // 新界西
    HkSecondarySchool(
      id: 'tmss',
      name: '屯門官立中學',
      band: SchoolBand.band3,
      district: HkDistrict.tuenMun,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 40,
    ),
    HkSecondarySchool(
      id: 'csbs_mrs_aw_shu',
      name: '中華傳道會劉永生中學',
      band: SchoolBand.band3,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 35,
    ),
    HkSecondarySchool(
      id: 'semple',
      name: '基督教香港信義會元朗信義中學',
      band: SchoolBand.band3,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 33,
    ),
    HkSecondarySchool(
      id: 'ylss',
      name: '元朗信義中學',
      band: SchoolBand.band3,
      district: HkDistrict.yuenLong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 36,
      feederPrimaryIds: ['ylgps'],
    ),
    HkSecondarySchool(
      id: 'caritas_yuen_long',
      name: '明愛元朗陳震夏中學',
      band: SchoolBand.band3,
      district: HkDistrict.yuenLong,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 32,
    ),
    HkSecondarySchool(
      id: 'tin_shui_wai_gov',
      name: '天水圍官立中學',
      band: SchoolBand.band3,
      district: HkDistrict.yuenLong,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 34,
    ),
    HkSecondarySchool(
      id: 'twss',
      name: '荃灣官立中學',
      band: SchoolBand.band3,
      district: HkDistrict.tsuenWan,
      type: SchoolType.gov,
      language: 'CMI',
      prestige: 42,
    ),
    HkSecondarySchool(
      id: 'ad_and_fd_of_pok_oi',
      name: '博愛醫院陳國威中學',
      band: SchoolBand.band3,
      district: HkDistrict.tsuenWan,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 35,
    ),
    HkSecondarySchool(
      id: 'kwai_chung_methodist_b3',
      name: '葵涌循道中學',
      band: SchoolBand.band3,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 36,
    ),
    HkSecondarySchool(
      id: 'ling_liang_church',
      name: '靈糧堂怡愛中學',
      band: SchoolBand.band3,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 33,
    ),
    HkSecondarySchool(
      id: 'buddhist_yip_kei',
      name: '佛教葉紀南紀念中學',
      band: SchoolBand.band3,
      district: HkDistrict.kwaiTsing,
      type: SchoolType.aided,
      language: 'CMI',
      prestige: 34,
    ),
    // ── 國際學校（SSR 可揀；唔入本地 SSA 統派／自行分配池）──
    HkSecondarySchool(
      id: 'cis',
      name: '漢基國際學校',
      band: SchoolBand.band1,
      district: HkDistrict.wanChai,
      type: SchoolType.international,
      language: 'EMI',
      tags: ['IB', '國際'],
      prestige: 94,
      acceptsDp: false,
    ),
    HkSecondarySchool(
      id: 'hkis',
      name: '香港國際學校',
      band: SchoolBand.band1,
      district: HkDistrict.southern,
      type: SchoolType.international,
      language: 'EMI',
      tags: ['IB', '國際', '美式'],
      prestige: 94,
      acceptsDp: false,
    ),
    HkSecondarySchool(
      id: 'gsis',
      name: '德國瑞士國際學校',
      band: SchoolBand.band1,
      district: HkDistrict.southern,
      type: SchoolType.international,
      language: 'EMI',
      tags: ['IB', '國際'],
      prestige: 93,
      acceptsDp: false,
    ),
    HkSecondarySchool(
      id: 'cdnis',
      name: '加拿大國際學校',
      band: SchoolBand.band1,
      district: HkDistrict.southern,
      type: SchoolType.international,
      language: 'EMI',
      tags: ['IB', '國際'],
      prestige: 91,
      acceptsDp: false,
    ),
    HkSecondarySchool(
      id: 'kellet',
      name: '啓新書院',
      band: SchoolBand.band1,
      district: HkDistrict.saiKung,
      type: SchoolType.international,
      language: 'EMI',
      tags: ['IB', '國際', '英式'],
      prestige: 90,
      acceptsDp: false,
    ),
    HkSecondarySchool(
      id: 'harrow_hk',
      name: '香港哈羅國際學校',
      band: SchoolBand.band1,
      district: HkDistrict.tuenMun,
      type: SchoolType.international,
      language: 'EMI',
      tags: ['IB', '國際', '英式'],
      prestige: 92,
      acceptsDp: false,
    ),
    HkSecondarySchool(
      id: 'vsa',
      name: '弘立書院',
      band: SchoolBand.band1,
      district: HkDistrict.shaTin,
      type: SchoolType.international,
      language: 'EMI',
      tags: ['IB', '國際'],
      prestige: 91,
      acceptsDp: false,
    ),
    HkSecondarySchool(
      id: 'island_school_intl',
      name: '港島中學（英基）',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.dss,
      language: 'EMI',
      tags: ['英基', 'IB'],
      prestige: 90,
      acceptsDp: false,
    ),
  ];

  static const primarySchools = <HkPrimarySchool>[
    HkPrimarySchool(
      id: 'spcps',
      name: '聖保羅男女中學附屬小學',
      band: SchoolBand.band1,
      district: HkDistrict.centralWestern,
      type: SchoolType.dss,
      isThroughTrain: true,
      linkedSecondaryId: 'spcc',
    ),
    HkPrimarySchool(
      id: 'psps',
      name: '拔萃女小學',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      feederSecondaryIds: ['dgs'],
    ),
    HkPrimarySchool(
      id: 'dbps',
      name: '拔萃男書院附屬小學',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      feederSecondaryIds: ['dbs'],
    ),
    HkPrimarySchool(
      id: 'lasalle_ps',
      name: '喇沙小學',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      feederSecondaryIds: ['lasalle'],
    ),
    HkPrimarySchool(
      id: 'kgps',
      name: '九龍塘學校（小學部）',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
    ),
    HkPrimarySchool(
      id: 'marymount_ps',
      name: '瑪利曼小學',
      band: SchoolBand.band1,
      district: HkDistrict.wanChai,
      type: SchoolType.aided,
    ),
    HkPrimarySchool(
      id: 'plkps',
      name: '保良局陳守仁小學',
      band: SchoolBand.band2,
      district: HkDistrict.tuenMun,
      type: SchoolType.aided,
    ),
    HkPrimarySchool(
      id: 'twgps',
      name: '荃灣官立小學',
      band: SchoolBand.band2,
      district: HkDistrict.tsuenWan,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'stfa_ps',
      name: '順德聯誼總會胡少渠紀念小學',
      band: SchoolBand.band2,
      district: HkDistrict.saiKung,
      type: SchoolType.aided,
    ),
    HkPrimarySchool(
      id: 'sha_tin_gov_ps',
      name: '沙田官立小學',
      band: SchoolBand.band2,
      district: HkDistrict.shaTin,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'tpgps',
      name: '大埔官立小學',
      band: SchoolBand.band3,
      district: HkDistrict.taiPo,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'ylgps',
      name: '元朗公立中學校友會小學',
      band: SchoolBand.band3,
      district: HkDistrict.yuenLong,
      type: SchoolType.aided,
      feederSecondaryIds: ['ylss'],
    ),
    HkPrimarySchool(
      id: 'tin_shui_wai_ps',
      name: '天水圍官立小學',
      band: SchoolBand.band3,
      district: HkDistrict.yuenLong,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'north_ps',
      name: '上水惠州公立學校',
      band: SchoolBand.band3,
      district: HkDistrict.north,
      type: SchoolType.aided,
    ),
    HkPrimarySchool(
      id: 'st_joseph_ps',
      name: '聖若瑟小學',
      band: SchoolBand.band1,
      district: HkDistrict.wanChai,
      type: SchoolType.aided,
      feederSecondaryIds: ['st_joseph'],
    ),
    HkPrimarySchool(
      id: 'pui_ching_ps',
      name: '培正小學',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      feederSecondaryIds: ['pui_ching'],
    ),
    HkPrimarySchool(
      id: 'munsang_ps',
      name: '民生書院小學',
      band: SchoolBand.band1,
      district: HkDistrict.kowloonCity,
      type: SchoolType.aided,
      feederSecondaryIds: ['munsang'],
    ),
    HkPrimarySchool(
      id: 'good_hope_ps',
      name: '德望小學暨幼稚園',
      band: SchoolBand.band1,
      district: HkDistrict.wongTaiSin,
      type: SchoolType.dss,
      isThroughTrain: true,
      linkedSecondaryId: 'good_hope',
    ),
    HkPrimarySchool(
      id: 'clementi_ps',
      name: '北角官立小學（雲景道）',
      band: SchoolBand.band2,
      district: HkDistrict.eastern,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'ma_on_shan_ps',
      name: '馬鞍山聖若瑟小學',
      band: SchoolBand.band2,
      district: HkDistrict.shaTin,
      type: SchoolType.aided,
    ),
    HkPrimarySchool(
      id: 'tko_ps',
      name: '將軍澳官立小學',
      band: SchoolBand.band2,
      district: HkDistrict.saiKung,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'tuen_mun_ps',
      name: '屯門官立小學',
      band: SchoolBand.band2,
      district: HkDistrict.tuenMun,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'kwun_tong_ps',
      name: '觀塘官立小學',
      band: SchoolBand.band3,
      district: HkDistrict.kwunTong,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'sham_shui_po_ps',
      name: '深水埗官立小學',
      band: SchoolBand.band3,
      district: HkDistrict.shamShuiPo,
      type: SchoolType.gov,
    ),
    HkPrimarySchool(
      id: 'intl_ps',
      name: '國際名校小學部',
      band: SchoolBand.band1,
      district: HkDistrict.southern,
      type: SchoolType.international,
      isThroughTrain: true,
      linkedSecondaryId: 'hkis',
    ),
  ];

  static HkPrimarySchool? getPrimaryById(String id) {
    try {
      return primarySchools.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static HkSecondarySchool? getById(String id) {
    try {
      return secondarySchools.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 出世／升小：按 Band + 家庭地區抽小學
  static HkPrimarySchool pickPrimarySchool(
    SchoolBand band,
    BirthTier tier,
    HkDistrict home,
    Random rng,
  ) {
    if (tier == BirthTier.ssr && band == SchoolBand.band1) {
      return primarySchools.firstWhere((s) => s.id == 'spcps');
    }
    final sameNet = primarySchools
        .where((s) => s.band == band && s.district.schoolNet == home.schoolNet)
        .toList();
    if (sameNet.isNotEmpty) return sameNet[rng.nextInt(sameNet.length)];

    final pool = primarySchools.where((s) => s.band == band).toList();
    if (pool.isEmpty) {
      return HkPrimarySchool(
        id: 'district_fallback',
        name: band == SchoolBand.band3 ? '區內小學' : '資助小學',
        band: band,
        district: home,
        type: SchoolType.aided,
      );
    }
    return pool[rng.nextInt(pool.length)];
  }

  /// 家庭居住地區（出世時決定，影響校網）
  static HkDistrict homeDistrictFor(BirthTier tier, [Random? random]) {
    final rng = random ?? Random();
    return switch (tier) {
      BirthTier.ssr => [
          HkDistrict.centralWestern,
          HkDistrict.southern,
          HkDistrict.wanChai,
        ][rng.nextInt(3)],
      BirthTier.sr => [
          HkDistrict.eastern,
          HkDistrict.shaTin,
          HkDistrict.kowloonCity,
          HkDistrict.saiKung,
        ][rng.nextInt(4)],
      BirthTier.r => [
          HkDistrict.tuenMun,
          HkDistrict.yuenLong,
          HkDistrict.kwunTong,
          HkDistrict.north,
          HkDistrict.shamShuiPo,
        ][rng.nextInt(5)],
    };
  }

  /// 呈分（P5–P6 校內評估簡化）：智慧 + 紀律 + 累積呈分 + 小學 Band
  static int placementScore(Player p, {bool missedExam = false}) {
    var score = p.smarts + (p.discipline ~/ 2) + p.primaryScore;
    switch (p.primaryBand) {
      case SchoolBand.band1:
        score += 12;
      case SchoolBand.band2:
        score += 5;
      case SchoolBand.band3:
        break;
      case SchoolBand.none:
        break;
    }
    // 補習／呈分試季努力
    if (p.unlockedFlags.contains('ssa_cram_boost')) score += 6;
    if (missedExam) score -= 18;
    return score.clamp(0, 200);
  }

  /// 呈分 → Band 1／2／3（門檻提高：淨係狂溫書唔會輕易 Band 1 頂）
  static SsaBandGroup bandGroupFromScore(int score) {
    if (score >= 125) return SsaBandGroup.a1;
    if (score >= 105) return SsaBandGroup.a2;
    if (score >= 85) return SsaBandGroup.b1;
    if (score >= 70) return SsaBandGroup.b2;
    if (score >= 55) return SsaBandGroup.c1;
    return SsaBandGroup.c2;
  }

  static List<HkSecondarySchool> get localSecondarySchools => secondarySchools
      .where((s) =>
          s.type != SchoolType.international && !s.tags.contains('英基'))
      .toList();

  static List<HkSecondarySchool> get internationalSchools => secondarySchools
      .where((s) =>
          s.type == SchoolType.international || s.tags.contains('英基'))
      .toList();

  static List<HkSecondarySchool> schoolsInNet(String net) =>
      localSecondarySchools.where((s) => s.schoolNet == net).toList();

  static List<HkSecondarySchool> dpCandidates(Player p) {
    final home = p.homeDistrict;
    return localSecondarySchools.where((s) {
      if (!s.acceptsDp) return false;
      if (s.band == SchoolBand.band3) return false;
      return s.district.schoolNet == home.schoolNet ||
          s.prestige >= 85 ||
          s.band == SchoolBand.band1;
    }).toList()
      ..sort((a, b) => b.prestige.compareTo(a.prestige));
  }
}

// ─── SSA 完整流程 ───────────────────────────────────────────

class SsaFlow {
  static Random _rng(Player p, [int salt = 0]) =>
      Random(p.year * 997 + p.age * 131 + p.name.hashCode + salt);

  /// 自行分配面試成功率（0–100）
  static int dpSuccessChance(Player p, HkSecondarySchool school) {
    var chance = 20;
    chance += (p.smarts - 50) ~/ 2;
    chance += (p.network - 30) ~/ 3;
    chance += (p.discipline - 40) ~/ 4;
    chance += p.luck ~/ 10;

    switch (p.primaryBand) {
      case SchoolBand.band1:
        chance += 12;
      case SchoolBand.band2:
        chance += 4;
      default:
        break;
    }

    // 聯繫／一條龍小學加分
    final primary = HkSchoolData.getPrimaryById(p.primarySchoolId);
    if (primary != null) {
      if (primary.linkedSecondaryId == school.id ||
          primary.feederSecondaryIds.contains(school.id) ||
          school.feederPrimaryIds.contains(p.primarySchoolId)) {
        chance += 28;
      }
    }

    // prestige 愈高愈難
    chance -= (school.prestige - 50) ~/ 2;

    if (p.birthTier == BirthTier.ssr) chance += 10;
    if (p.birthTier == BirthTier.r) chance -= 5;

    return chance.clamp(5, 92);
  }

  /// 嘗試一條龍／聯繫升中（自行分配階段可走）
  static HkSecondarySchool? tryThroughTrain(Player p, Random rng) {
    final primary = HkSchoolData.getPrimaryById(p.primarySchoolId);
    if (primary == null || !primary.hasFeederLink) return null;

    final score = HkSchoolData.placementScore(p);
    // 一條龍仍要基本成績
    if (score < 55) return null;

    String? targetId = primary.linkedSecondaryId;
    if (targetId == null && primary.feederSecondaryIds.isNotEmpty) {
      targetId = primary.feederSecondaryIds.first;
    }
    if (targetId == null) return null;

    final school = HkSchoolData.getById(targetId);
    if (school == null) return null;

    // 一條龍成功率較高，但仍有面試／內部篩選
    final chance = primary.isThroughTrain
        ? (70 + (score - 55) ~/ 2).clamp(55, 95)
        : dpSuccessChance(p, school);
    if (rng.nextInt(100) < chance) return school;
    return null;
  }

  /// 自行分配：申請最多兩間，回傳取錄學校（或 null）
  static HkSecondarySchool? runDiscretionary(
    Player p, {
    List<String>? preferredIds,
    Random? random,
  }) {
    final rng = random ?? _rng(p, 11);
    final steps = <String>[];

    // 先試一條龍
    if (p.unlockedFlags.contains('ssa_try_through_train') ||
        preferredIds == null) {
      final tt = tryThroughTrain(p, rng);
      if (tt != null) {
        _applySchool(p, tt, SsaPathway.throughTrain, steps);
        p.unlockedFlags.add('ssa_discretionary');
        p.unlockedFlags.add('ssa_through_train');
        p.completedExams.add('ssa_discretionary');
        p.eventLog.add('${p.year}年：一條龍／聯繫取錄 — ${tt.name}');
        return tt;
      }
    }

    final candidates = preferredIds != null && preferredIds.isNotEmpty
        ? preferredIds
            .map(HkSchoolData.getById)
            .whereType<HkSecondarySchool>()
            .take(2)
            .toList()
        : HkSchoolData.dpCandidates(p).take(2).toList();

    if (candidates.isEmpty) {
      p.completedExams.add('ssa_discretionary');
      p.unlockedFlags.add('ssa_dp_failed');
      return null;
    }

    for (final school in candidates) {
      final chance = dpSuccessChance(p, school);
      steps.add('申請 ${school.name}（面試勝算約 $chance%）');
      if (rng.nextInt(100) < chance) {
        _applySchool(p, school, SsaPathway.discretionary, steps);
        p.unlockedFlags.add('ssa_discretionary');
        p.completedExams.add('ssa_discretionary');
        p.ssaDpChoices = candidates.map((s) => s.name).join('、');
        p.eventLog.add(
          '${p.year}年：自行分配取錄 — ${school.name}（申請：${p.ssaDpChoices}）',
        );
        return school;
      }
    }

    p.ssaDpChoices = candidates.map((s) => s.name).join('、');
    p.completedExams.add('ssa_discretionary');
    p.unlockedFlags.add('ssa_dp_failed');
    p.eventLog.add(
      '${p.year}年：自行分配兩間都唔取 — ${p.ssaDpChoices}，轉入統派。',
    );
    return null;
  }

  /// 統一派位：甲部（跨網最多 3 志願）→ 乙部（本網）
  static SsaAllocationResult runCentralAllocation(
    Player p, {
    bool missedExam = false,
    Random? random,
  }) {
    final rng = random ?? _rng(p, 44);
    final steps = <String>[];
    final score = HkSchoolData.placementScore(p, missedExam: missedExam);
    final group = HkSchoolData.bandGroupFromScore(score);
    p.placementScore = score;
    p.ssaBandGroup = group;
    p.schoolBand = group.schoolBand;

    steps.add('校內呈分折算：$score → ${group.label}');
    steps.add('居住校網：${p.homeDistrict.schoolNet}（${p.homeDistrict.label}）');

    if (missedExam) {
      p.unlockedFlags.add('ssa_missed_exam');
      steps.add('缺考／呈分欠佳：分數已扣減');
    }

    // 若已有自行分配／一條龍，直接確認
    if (p.secondarySchoolId.isNotEmpty &&
        (p.ssaPathway == SsaPathway.discretionary ||
            p.ssaPathway == SsaPathway.throughTrain)) {
      final existing = HkSchoolData.getById(p.secondarySchoolId)!;
      steps.add('已獲${p.ssaPathway.label}，無需參與統派');
      p.completedExams.add('primary_stream_test');
      return SsaAllocationResult(
        school: existing,
        pathway: p.ssaPathway,
        bandGroup: group,
        placementScore: score,
        steps: steps,
      );
    }

    // ── 甲部：跨網選擇（甲一／甲二較易中）──
    final partAPrefs = _buildPartAPreferences(p, group);
    steps.add(
      '甲部志願：${partAPrefs.isEmpty ? "（跳過）" : partAPrefs.map((s) => s.name).join(" → ")}',
    );

    for (var i = 0; i < partAPrefs.length; i++) {
      final school = partAPrefs[i];
      final chance = _partAChance(group, school, i);
      if (rng.nextInt(100) < chance) {
        steps.add('甲部第${i + 1}志願命中：${school.name}（$chance%）');
        _applySchool(p, school, SsaPathway.centralPartA, steps);
        p.completedExams.add('primary_stream_test');
        return SsaAllocationResult(
          school: school,
          pathway: SsaPathway.centralPartA,
          bandGroup: group,
          placementScore: score,
          steps: steps,
        );
      }
      steps.add('甲部第${i + 1}志願未中：${school.name}');
    }

    // ── 乙部：本網，按 Band 組優先 + 隨機 ──
    final net = p.homeDistrict.schoolNet;
    var pool = HkSchoolData.schoolsInNet(net)
        .where((s) => s.band == group.schoolBand)
        .toList();
    if (pool.isEmpty) {
      pool = HkSchoolData.schoolsInNet(net).toList();
    }
    if (pool.isEmpty) {
      pool = HkSchoolData.localSecondarySchools
          .where((s) => s.band == group.schoolBand)
          .toList();
    }

    // 甲一優先派 prestige 較高；丙二相反
    pool.sort((a, b) {
      if (group.priority <= 2) return b.prestige.compareTo(a.prestige);
      if (group.priority >= 5) return a.prestige.compareTo(b.prestige);
      return 0;
    });

    // 隨機抽籤（同 Band 內）
    final pickIndex = group.priority <= 2
        ? rng.nextInt(min(3, pool.length))
        : rng.nextInt(pool.length);
    final school = pool[pickIndex];
    steps.add('乙部本網（$net）抽籤 → ${school.name}');
    _applySchool(p, school, SsaPathway.centralPartB, steps);
    p.completedExams.add('primary_stream_test');

    return SsaAllocationResult(
      school: school,
      pathway: SsaPathway.centralPartB,
      bandGroup: group,
      placementScore: score,
      steps: steps,
    );
  }

  static List<HkSecondarySchool> _buildPartAPreferences(
    Player p,
    SsaBandGroup group,
  ) {
    // 偏好乙部穩陣 → 跳過甲部
    if (p.unlockedFlags.contains('ssa_prefer_part_b') &&
        !p.unlockedFlags.contains('ssa_prefer_part_a')) {
      return [];
    }
    // 甲一／甲二先填跨網名校；乙以下較少搏甲部（除非玩家明確要搏）
    if (group.priority > 3 && !p.unlockedFlags.contains('ssa_prefer_part_a')) {
      return [];
    }

    final dream = HkSchoolData.localSecondarySchools
        .where((s) =>
            s.band == SchoolBand.band1 &&
            s.district.schoolNet != p.homeDistrict.schoolNet)
        .toList()
      ..sort((a, b) => b.prestige.compareTo(a.prestige));

    final localElite = HkSchoolData.schoolsInNet(p.homeDistrict.schoolNet)
        .where((s) => s.band == SchoolBand.band1)
        .toList()
      ..sort((a, b) => b.prestige.compareTo(a.prestige));

    final prefs = <HkSecondarySchool>[];
    if (dream.isNotEmpty) prefs.add(dream.first);
    if (localElite.isNotEmpty) prefs.add(localElite.first);
    if (dream.length > 1) prefs.add(dream[1]);
    return prefs.take(3).toList();
  }

  static int _partAChance(
    SsaBandGroup group,
    HkSecondarySchool school,
    int preferenceIndex,
  ) {
    var base = switch (group) {
      SsaBandGroup.a1 => 45,
      SsaBandGroup.a2 => 28,
      SsaBandGroup.b1 => 12,
      SsaBandGroup.b2 => 6,
      _ => 2,
    };
    base -= preferenceIndex * 8;
    base -= (school.prestige - 80).clamp(0, 20);
    return base.clamp(1, 55);
  }

  static void _applySchool(
    Player p,
    HkSecondarySchool school,
    SsaPathway pathway,
    List<String> steps,
  ) {
    p.secondarySchoolId = school.id;
    p.secondarySchoolName = school.name;
    p.schoolBand = school.band;
    p.ssaPathway = pathway;
    p.jobTitle = school.name;
    if (p.ssaBandGroup == SsaBandGroup.none) {
      p.ssaBandGroup = switch (school.band) {
        SchoolBand.band1 => SsaBandGroup.a2,
        SchoolBand.band2 => SsaBandGroup.b1,
        SchoolBand.band3 => SsaBandGroup.c1,
        SchoolBand.none => SsaBandGroup.none,
      };
    }
    steps.add('確認學位：${school.name} via ${pathway.label}');
  }

  /// SSR：繼續國際路線 → 派入具名國際學校，繞過本地 SSA
  static String chooseStayInternational(Player p, {Random? random}) {
    final rng = random ?? _rng(p, 88);
    final pool = HkSchoolData.internationalSchools;
    final school = pool.isEmpty
        ? HkSecondarySchool(
            id: 'intl_sec',
            name: '國際學校中學部',
            band: SchoolBand.band1,
            district: p.homeDistrict,
            type: SchoolType.international,
            language: 'EMI',
            tags: ['IB', '國際'],
            prestige: 90,
            acceptsDp: false,
          )
        : pool[rng.nextInt(pool.length)];

    p.unlockedFlags.add('ssa_stay_international');
    p.unlockedFlags.remove('ssa_force_local');
    p.unlockedFlags.add('bypass_dse');
    p.secondarySchoolId = school.id;
    p.secondarySchoolName = school.name;
    p.schoolBand = SchoolBand.band1;
    p.ssaPathway = SsaPathway.discretionary;
    p.ssaBandGroup = SsaBandGroup.a1;
    p.placementScore = HkSchoolData.placementScore(p);
    p.jobTitle = school.name;
    p.completedExams.add('ssr_secondary_path');
    p.completedExams.add('ssa_discretionary');
    p.completedExams.add('primary_stream_test');
    p.unlockedFlags.add('ssa_international');
    p.eventLog.add('${p.year}年：繼續國際路線 — ${school.name}（繞過本地 SSA）');
    return '繼續國際路線 — ${school.name}（${school.profileLine}）\n唔使參加呈分試／統派，之後行 IB。';
  }

  /// SSR：轉入本地教育 → 要走完整 SSA，之後考 DSE
  static String chooseForceLocal(Player p) {
    p.unlockedFlags.add('ssa_force_local');
    p.unlockedFlags.remove('ssa_stay_international');
    p.unlockedFlags.remove('bypass_dse');
    p.unlockedFlags.remove('ssa_international');
    // 清走可能已派嘅國際中學，等自行分配／統派
    if (p.secondarySchoolId.isNotEmpty) {
      final cur = HkSchoolData.getById(p.secondarySchoolId);
      if (cur != null &&
          (cur.type == SchoolType.international || cur.tags.contains('英基'))) {
        p.secondarySchoolId = '';
        p.secondarySchoolName = '';
        p.ssaPathway = SsaPathway.none;
        p.schoolBand = SchoolBand.none;
        p.ssaBandGroup = SsaBandGroup.none;
        p.completedExams.remove('ssa_discretionary');
        p.completedExams.remove('primary_stream_test');
      }
    }
    p.completedExams.add('ssr_secondary_path');
    p.eventLog.add('${p.year}年：轉入本地教育 — 將參加自行分配／統一派位，之後考 DSE。');
    return '已轉入本地升中路線。\n請於 Q1–Q2 做自行分配，Q4 做統一派位放榜。之後要考 DSE。';
  }

  /// 完整升中（統派放榜用）；若未做自行分配會先自動跑一次「不申請」路徑
  static String completeAllocation(Player p, {bool missedExam = false}) {
    final steps = <String>[];

    // SSR 已揀繼續國際 → 確認／補派國際學校
    if (p.unlockedFlags.contains('ssa_stay_international') ||
        (p.unlockedFlags.contains('international_school') &&
            p.unlockedFlags.contains('bypass_dse') &&
            !p.unlockedFlags.contains('ssa_force_local') &&
            !p.completedExams.contains('ssr_secondary_path'))) {
      // 未明確揀過 → 預設繼續國際（兼容舊流程）
      if (!p.unlockedFlags.contains('ssa_stay_international')) {
        return chooseStayInternational(p);
      }
      if (p.secondarySchoolName.isEmpty) {
        return chooseStayInternational(p);
      }
      p.completedExams.add('ssa_discretionary');
      p.completedExams.add('primary_stream_test');
      return '國際路線確認 — ${p.secondarySchoolName}（已繞過本地 SSA）';
    }

    if (!p.completedExams.contains('ssa_discretionary') &&
        p.secondarySchoolId.isEmpty) {
      steps.add('未申請自行分配／未獲取錄 → 直接統派');
      p.completedExams.add('ssa_discretionary');
    }

    final result = runCentralAllocation(p, missedExam: missedExam);
    for (final s in result.steps) {
      p.eventLog.add('${p.year}年 SSA：$s');
    }
    return result.summary;
  }

  /// 自行分配 checklist 通過時呼叫
  static String completeDiscretionary(
    Player p, {
    bool tryThroughTrain = false,
    bool skip = false,
  }) {
    if (skip) {
      p.completedExams.add('ssa_discretionary');
      p.unlockedFlags.add('ssa_dp_skipped');
      p.eventLog.add('${p.year}年：放棄自行分配，等統派。');
      return '已跳過自行分配，將於 Q4 參加統一派位。';
    }
    if (tryThroughTrain) {
      p.unlockedFlags.add('ssa_try_through_train');
    }
    final school = runDiscretionary(p);
    if (school != null) {
      return '${p.ssaPathway.label}取錄：${school.name}（${school.profileLine}）\n'
          'Q4 統派將確認學位，唔使再抽乙部。';
    }
    return '自行分配未取錄（申請：${p.ssaDpChoices.isEmpty ? "—" : p.ssaDpChoices}）。\n'
        '將於 Q4 參加統一派位（甲部＋乙部）。';
  }
}
