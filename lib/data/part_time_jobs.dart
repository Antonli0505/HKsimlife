import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_tax.dart';

/// 香港常見兼職（時薪跟 2025–26 招聘／市場取合理整數；最低工資 \$43.1 只係底線）
class PartTimeJob {
  final String id;
  final String titleZh;
  final String employer;
  final int hourlyPay;
  final int hoursPerShift;
  final int minAge;
  final int stressGain;
  final int networkGain;
  final int minSmarts;
  final bool requireStudyingOrGrad;
  final bool requireStrongAcademics;

  const PartTimeJob({
    required this.id,
    required this.titleZh,
    required this.employer,
    required this.hourlyPay,
    this.hoursPerShift = 6,
    this.minAge = 16,
    this.stressGain = 4,
    this.networkGain = 0,
    this.minSmarts = 0,
    this.requireStudyingOrGrad = false,
    this.requireStrongAcademics = false,
  });

  int get shiftPay => hourlyPay * hoursPerShift;

  String get label =>
      employer.isEmpty ? titleZh : '$employer · $titleZh';

  String get payLabel => '\$$hourlyPay/時 · 每次約 \$$shiftPay';
}

abstract final class PartTimeJobs {
  static const int idleFireQuarters = 4;

  static const List<PartTimeJob> all = [
    PartTimeJob(
      id: '7eleven',
      titleZh: '便利店店員',
      employer: '7-Eleven',
      hourlyPay: 50,
      hoursPerShift: 6,
      stressGain: 5,
    ),
    PartTimeJob(
      id: 'ok_store',
      titleZh: '便利店店員',
      employer: 'OK便利店',
      hourlyPay: 50,
      hoursPerShift: 6,
      stressGain: 5,
    ),
    PartTimeJob(
      id: 'kfc',
      titleZh: '快餐店務員',
      employer: 'KFC',
      hourlyPay: 55,
      hoursPerShift: 6,
      stressGain: 6,
    ),
    PartTimeJob(
      id: 'mcd',
      titleZh: '快餐店務員',
      employer: '麥當勞',
      hourlyPay: 55,
      hoursPerShift: 6,
      stressGain: 6,
    ),
    PartTimeJob(
      id: 'restaurant',
      titleZh: '餐廳／酒樓侍應',
      employer: '',
      hourlyPay: 65,
      hoursPerShift: 7,
      stressGain: 7,
      networkGain: 1,
    ),
    PartTimeJob(
      id: 'barista',
      titleZh: '咖啡師',
      employer: 'Starbucks',
      hourlyPay: 55,
      hoursPerShift: 6,
      stressGain: 5,
    ),
    PartTimeJob(
      id: 'event',
      titleZh: '活動／展覽助理',
      employer: '',
      hourlyPay: 75,
      hoursPerShift: 8,
      stressGain: 6,
      networkGain: 2,
    ),
    PartTimeJob(
      id: 'promo',
      titleZh: '推廣員',
      employer: '',
      hourlyPay: 70,
      hoursPerShift: 6,
      stressGain: 5,
      networkGain: 2,
    ),
    PartTimeJob(
      id: 'warehouse',
      titleZh: '包裝／倉務',
      employer: '',
      hourlyPay: 60,
      hoursPerShift: 8,
      stressGain: 7,
    ),
    PartTimeJob(
      id: 'clerk',
      titleZh: '文職兼職',
      employer: '',
      hourlyPay: 65,
      hoursPerShift: 6,
      stressGain: 3,
      minSmarts: 35,
    ),
    PartTimeJob(
      id: 'security',
      titleZh: '保安',
      employer: '',
      hourlyPay: 70,
      hoursPerShift: 8,
      stressGain: 4,
      minAge: 18,
    ),
    PartTimeJob(
      id: 'tutor_basic',
      titleZh: '家教／補習（入門）',
      employer: '',
      hourlyPay: 180,
      hoursPerShift: 2,
      stressGain: 3,
      networkGain: 1,
      minSmarts: 55,
      requireStudyingOrGrad: true,
    ),
    PartTimeJob(
      id: 'tutor_dse',
      titleZh: 'DSE 科補習',
      employer: '',
      hourlyPay: 280,
      hoursPerShift: 2,
      stressGain: 4,
      networkGain: 2,
      minSmarts: 70,
      requireStudyingOrGrad: true,
      requireStrongAcademics: true,
    ),
    // ─── 專業路徑兼職（轉正對應行業）────────────────
    PartTimeJob(
      id: 'bank_pt',
      titleZh: '銀行櫃枱／見習',
      employer: '中銀香港',
      hourlyPay: 80,
      hoursPerShift: 6,
      stressGain: 4,
      networkGain: 1,
      minSmarts: 45,
      minAge: 18,
    ),
    PartTimeJob(
      id: 'audit_pt',
      titleZh: '審計／會計助理',
      employer: '中小行',
      hourlyPay: 85,
      hoursPerShift: 7,
      stressGain: 5,
      minSmarts: 55,
      minAge: 18,
      requireStudyingOrGrad: true,
    ),
    PartTimeJob(
      id: 'helpdesk_pt',
      titleZh: 'IT Helpdesk',
      employer: '',
      hourlyPay: 90,
      hoursPerShift: 7,
      stressGain: 5,
      minSmarts: 60,
      minAge: 18,
    ),
    PartTimeJob(
      id: 'news_pt',
      titleZh: '新聞／採訪助理',
      employer: '報館',
      hourlyPay: 70,
      hoursPerShift: 6,
      stressGain: 5,
      networkGain: 2,
      minSmarts: 45,
    ),
    PartTimeJob(
      id: 'estate_pt',
      titleZh: '地產見習',
      employer: '中原',
      hourlyPay: 65,
      hoursPerShift: 8,
      stressGain: 6,
      networkGain: 2,
      minAge: 18,
    ),
    PartTimeJob(
      id: 'insurance_pt',
      titleZh: '保險見習／行政',
      employer: 'AIA',
      hourlyPay: 70,
      hoursPerShift: 6,
      stressGain: 4,
      networkGain: 2,
      minAge: 18,
    ),
    PartTimeJob(
      id: 'clinic_pt',
      titleZh: '診所／病房助理',
      employer: '診所',
      hourlyPay: 75,
      hoursPerShift: 7,
      stressGain: 6,
      minAge: 18,
    ),
    PartTimeJob(
      id: 'pharm_pt',
      titleZh: '藥房助理',
      employer: '藥房',
      hourlyPay: 70,
      hoursPerShift: 6,
      stressGain: 4,
      minSmarts: 40,
      minAge: 18,
    ),
    PartTimeJob(
      id: 'social_pt',
      titleZh: '社福中心助理',
      employer: 'NGO',
      hourlyPay: 65,
      hoursPerShift: 6,
      stressGain: 5,
      networkGain: 2,
      minAge: 18,
    ),
  ];

  static PartTimeJob? byId(String id) {
    for (final j in all) {
      if (j.id == id) return j;
    }
    return null;
  }

  static bool hasJob(Player p) => p.partTimeJobId.isNotEmpty;

  static PartTimeJob? current(Player p) =>
      hasJob(p) ? byId(p.partTimeJobId) : null;

  static String displayLabel(Player p) {
    final j = current(p);
    if (j == null) return '無兼職';
    return '${j.label}（${j.payLabel}）';
  }

  static String? blockReason(Player p, PartTimeJob job) {
    if (p.age < job.minAge) return '要滿 ${job.minAge} 歲先做得';
    if (p.smarts < job.minSmarts) return '智慧唔夠（要 ${job.minSmarts}+）';
    if (job.requireStudyingOrGrad) {
      final ok = p.isStudying ||
          p.unlockedFlags.contains('bachelor_graduated') ||
          p.education.index >= EducationLevel.associate.index;
      if (!ok) return '要讀緊專上／讀過書先請你教';
    }
    if (job.requireStrongAcademics) {
      final ok = p.dseBestScore >= 22 ||
          p.uniGpa >= 3.0 ||
          p.ibScore >= 36 ||
          p.smarts >= 80;
      if (!ok) return '成績／智慧未夠教 DSE';
    }
    return null;
  }

  static List<PartTimeJob> availableFor(Player p) =>
      all.where((j) => blockReason(p, j) == null).toList();

  static String hire(Player p, String id) {
    final job = byId(id);
    if (job == null) return '搵唔到呢份工。';
    final block = blockReason(p, job);
    if (block != null) return block;
    p.partTimeJobId = job.id;
    p.partTimeQuartersIdle = 0;
    p.eventLog.add('${p.year}年：入咗兼職 — ${job.label}（${job.payLabel}）');
    return '入咗兼職：${job.label}\n每次返工約賺 \$${job.shiftPay}';
  }

  static String workShift(Player p) {
    final job = current(p);
    if (job == null) return '你而家冇兼職，去搵先啦。';
    p.wealth += job.shiftPay;
    p.stress = (p.stress + job.stressGain).clamp(0, 100);
    p.san = (p.san - 1).clamp(0, p.maxSan);
    if (job.networkGain > 0) {
      p.network = (p.network + job.networkGain).clamp(0, 100);
    }
    p.partTimeQuartersIdle = 0;
    p.partTimeShiftsTotal++;
    // 兼職入息不論多少都要報稅（現實僱主 IR56 亦要報兼職）
    CareerTax.addPartTimeIncome(p, job.shiftPay);
    CareerTax.syncLegacyTotal(p);
    // 讀大學時兼職可能食溫書時間
    if (p.isStudying &&
        p.uniStudySessions > 0 &&
        Random(p.year + p.wealth + p.partTimeShiftsTotal).nextBool()) {
      p.uniStudySessions--;
    }
    p.eventLog.add(
      '${p.year}年：返兼職 ${job.label}，賺 \$${job.shiftPay}',
    );
    return '返咗 ${job.label}\n今次入帳 \$${job.shiftPay}';
  }

  static String quit(Player p) {
    final job = current(p);
    if (job == null) return '冇兼職可辭。';
    p.partTimeJobId = '';
    p.partTimeQuartersIdle = 0;
    p.eventLog.add('${p.year}年：辭咗兼職 ${job.label}');
    return '辭咗兼職：${job.label}';
  }

  /// 每季：有兼職就 idle++；滿 4 季唔返 → 炒
  static String? tickQuarter(Player p) {
    if (!hasJob(p)) return null;
    p.partTimeQuartersIdle++;
    if (p.partTimeQuartersIdle < idleFireQuarters) return null;
    final job = current(p);
    final label = job?.label ?? p.partTimeJobId;
    p.partTimeJobId = '';
    p.partTimeQuartersIdle = 0;
    p.eventLog.add('${p.year}年：因為成日唔返，兼職畀人炒咗（$label）');
    return '兼職畀人炒咗：$label（連續 $idleFireQuarters 季冇返）';
  }

  static StoryEvent hireEvent(Player p) {
    final pool = availableFor(p);
    if (pool.isEmpty) {
      return StoryEvent(
        id: 'pt_hire_none',
        title: '搵兼職',
        body: '暫時冇啱你條件嘅兼職（年紀／智慧／學歷）。',
        choices: [
          EventChoice(label: '算啦', apply: (_) {}),
        ],
      );
    }
    final picks = List<PartTimeJob>.from(pool)..shuffle(Random(p.year + p.age));
    final shown = picks.take(4).toList();
    return StoryEvent(
      id: 'pt_hire',
      title: '搵兼職',
      body: p.partTimeJobId.isEmpty
          ? '16 歲起可以炒散。每 4 季至少要返一次，唔係會畀人炒。'
          : '轉工會辭咗而家份：${displayLabel(p)}',
      choices: [
        ...shown.map(
          (j) => EventChoice(
            label: '${j.label}（${j.payLabel}）',
            apply: (pl) {
              if (hasJob(pl)) quit(pl);
              hire(pl, j.id);
            },
          ),
        ),
        EventChoice(label: '唔搵啦', apply: (_) {}),
      ],
    );
  }

  static List<ActionButton> lifestyleActions(Player p) {
    if (p.age < 16) return const [];
    final buttons = <ActionButton>[
      ActionButton(
        label: hasJob(p) ? '轉／再搵兼職' : '搵兼職',
        apCost: 1,
        onExecute: (pl) {
          pl.unlockedFlags.add('pt_hire_pending');
        },
      ),
    ];
    if (hasJob(p)) {
      final job = current(p)!;
      buttons.add(ActionButton(
        label: '返兼職（約 \$${job.shiftPay}）',
        apCost: 1,
        onExecute: (pl) {
          pl.eventLog.add(workShift(pl));
        },
      ));
      buttons.add(ActionButton(
        label: '辭兼職',
        apCost: 0,
        onExecute: (pl) {
          pl.eventLog.add(quit(pl));
        },
      ));
    }
    return buttons;
  }
}
