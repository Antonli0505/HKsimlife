import 'dart:math';

import '../models/enums.dart';
import '../models/game_event.dart';
import '../models/player.dart';
import 'career_data.dart';
import 'luck_modifiers.dart';

/// 專業資格／牌照考試（只限成年；條件齊＝入場，交卷要骰過關）
abstract final class CareerExams {
  static const Set<String> ids = {
    'iiqe_exam',
    'eaa_license',
    'hkicpa_qp',
    'cfa_l1',
    'teacher_reg',
    'nursing_license',
    'pharm_reg',
  };

  static bool isCareerExam(String id) => ids.contains(id);

  /// base：剛剛達入場智慧時大約勝算%；每高 1 智慧約 +1.2%
  static bool _rollPass(
    Player p, {
    required int baseChance,
    required int smartsFloor,
    int disciplineBonusAt = 55,
  }) {
    var chance = baseChance + ((p.smarts - smartsFloor) * 1.2).round();
    chance += p.luck ~/ 15;
    if (p.discipline >= disciplineBonusAt) chance += 6;
    if (p.discipline >= 70) chance += 4;
    chance = chance.clamp(18, 82);
    return LuckModifiers.roll(
      p,
      chance / 100.0,
      Random(p.year * 53 + p.smarts * 7 + p.age + baseChance),
    );
  }

  static void _charge(Player p, int fee) {
    p.wealth = (p.wealth - fee).clamp(0, 999999999);
  }

  static const _feeIiqe = 1200;
  static const _feeEaa = 1500;
  static const _feeHkicpa = 18000;
  static const _feeCfa = 12000;
  static const _feeTeacher = 800;
  static const _feeNursing = 2000;
  static const _feePharm = 8000;

  static List<ChecklistExam> all() => [
        ChecklistExam(
          id: 'iiqe_exam',
          title: '保險中介人資格考試（IIQE）',
          description:
              '保險代理牌。條件齊先可以入場；交卷後睇發揮（唔保證過）。'
              '考牌費 \$$_feeIiqe。',
          requirements: [
            RequirementItem(label: '滿 18 歲', check: (p) => p.age >= 18),
            RequirementItem(
              label: '已出社會（非在學童年）',
              check: (p) => !p.isChildhood,
            ),
            RequirementItem(
              label: '智慧 ≥ 52',
              check: (p) => p.smarts >= 52,
            ),
            RequirementItem(
              label: '紀律 ≥ 35',
              check: (p) => p.discipline >= 35,
            ),
            RequirementItem(
              label: '現金 ≥ \$$_feeIiqe',
              check: (p) => p.wealth >= _feeIiqe,
            ),
            RequirementItem(
              label: '未持牌',
              check: (p) => !p.unlockedFlags.contains('iiqe_passed'),
            ),
          ],
          onPass: (p) {
            _charge(p, _feeIiqe);
            if (_rollPass(p, baseChance: 42, smartsFloor: 52)) {
              p.completedExams.add('iiqe_exam');
              p.unlockedFlags.add('iiqe_passed');
              p.eventLog.add('${p.year}年：IIQE 合格，可入保險行。');
            } else {
              p.stress = (p.stress + 5).clamp(0, 100);
              p.eventLog.add('${p.year}年：IIQE 不合格，再温書考多次。');
            }
          },
        ),
        ChecklistExam(
          id: 'eaa_license',
          title: '地產代理資格考試（EAA）',
          description: '地產代理牌。入場後要骰過關。考牌費 \$$_feeEaa。',
          requirements: [
            RequirementItem(label: '滿 18 歲', check: (p) => p.age >= 18),
            RequirementItem(
              label: '已出社會（非在學童年）',
              check: (p) => !p.isChildhood,
            ),
            RequirementItem(
              label: '智慧 ≥ 52',
              check: (p) => p.smarts >= 52,
            ),
            RequirementItem(
              label: '紀律 ≥ 35',
              check: (p) => p.discipline >= 35,
            ),
            RequirementItem(
              label: '現金 ≥ \$$_feeEaa',
              check: (p) => p.wealth >= _feeEaa,
            ),
            RequirementItem(
              label: '未持牌',
              check: (p) => !p.unlockedFlags.contains('eaa_license'),
            ),
          ],
          onPass: (p) {
            _charge(p, _feeEaa);
            if (_rollPass(p, baseChance: 40, smartsFloor: 52)) {
              p.completedExams.add('eaa_license');
              p.unlockedFlags.add('eaa_license');
              p.eventLog.add('${p.year}年：取得地產代理牌。');
            } else {
              p.stress = (p.stress + 5).clamp(0, 100);
              p.eventLog.add('${p.year}年：地產牌試不合格。');
            }
          },
        ),
        ChecklistExam(
          id: 'hkicpa_qp',
          title: 'HKICPA 專業資格（QP 簡化）',
          description:
              '會計師公會資格簡化版。過關先好升 Manager。'
              '學費 \$$_feeHkicpa；考掛只退一半。',
          requirements: [
            RequirementItem(label: '滿 21 歲', check: (p) => p.age >= 21),
            RequirementItem(
              label: '會計／審計相關工作或學位',
              check: (p) =>
                  p.currentSector == CareerSector.accounting ||
                  p.unlockedFlags.contains('bachelor_graduated') ||
                  p.partTimeJobId == 'audit_pt',
            ),
            RequirementItem(
              label: '智慧 ≥ 68',
              check: (p) => p.smarts >= 68,
            ),
            RequirementItem(
              label: '紀律 ≥ 55',
              check: (p) => p.discipline >= 55,
            ),
            RequirementItem(
              label: '現金 ≥ \$$_feeHkicpa',
              check: (p) => p.wealth >= _feeHkicpa,
            ),
            RequirementItem(
              label: '未過 QP',
              check: (p) => !p.unlockedFlags.contains('hkicpa_passed'),
            ),
          ],
          onPass: (p) {
            if (_rollPass(
              p,
              baseChance: 32,
              smartsFloor: 68,
              disciplineBonusAt: 60,
            )) {
              _charge(p, _feeHkicpa);
              p.completedExams.add('hkicpa_qp');
              p.unlockedFlags.add('hkicpa_passed');
              p.reputation = (p.reputation + 4).clamp(0, 100);
              p.eventLog.add('${p.year}年：HKICPA QP 合格。');
            } else {
              _charge(p, _feeHkicpa ~/ 2);
              p.stress = (p.stress + 8).clamp(0, 100);
              p.eventLog.add('${p.year}年：QP 不合格，半費打水漂。');
            }
          },
        ),
        ChecklistExam(
          id: 'cfa_l1',
          title: 'CFA Level I',
          description:
              '金融分析師一級。有助銀行升 RM／私銀。'
              '報名費 \$$_feeCfa；出名難——入場都好易考掛。',
          requirements: [
            RequirementItem(label: '滿 21 歲', check: (p) => p.age >= 21),
            RequirementItem(
              label: '智慧 ≥ 72',
              check: (p) => p.smarts >= 72,
            ),
            RequirementItem(
              label: '紀律 ≥ 55',
              check: (p) => p.discipline >= 55,
            ),
            RequirementItem(
              label: '現金 ≥ \$$_feeCfa',
              check: (p) => p.wealth >= _feeCfa,
            ),
            RequirementItem(
              label: '未過 CFA L1',
              check: (p) => !p.unlockedFlags.contains('cfa_l1'),
            ),
          ],
          onPass: (p) {
            _charge(p, _feeCfa);
            if (_rollPass(
              p,
              baseChance: 28,
              smartsFloor: 72,
              disciplineBonusAt: 60,
            )) {
              p.completedExams.add('cfa_l1');
              p.unlockedFlags.add('cfa_l1');
              p.reputation = (p.reputation + 3).clamp(0, 100);
              p.eventLog.add('${p.year}年：CFA Level I 合格。');
            } else {
              p.stress = (p.stress + 7).clamp(0, 100);
              p.eventLog.add('${p.year}年：CFA L1 不合格。');
            }
          },
        ),
        ChecklistExam(
          id: 'teacher_reg',
          title: '教師註冊（TRB 簡化）',
          description:
              '教育局教師註冊。有教育學位／師資係優勢，但仍要申請；'
              '未註冊唔算正式學位教師。行政費 \$$_feeTeacher。',
          requirements: [
            RequirementItem(label: '滿 21 歲', check: (p) => p.age >= 21),
            RequirementItem(
              label: '教育學位，或教學業＋表現',
              check: (p) =>
                  CareerData.hasEducationDegreePublic(p) ||
                  (p.currentSector == CareerSector.teaching &&
                      p.jobQuartersEmployed >= 4 &&
                      p.jobPerformance >= 45),
            ),
            RequirementItem(
              label: '無刑事紀錄',
              check: (p) => !p.hasCriminalRecord,
            ),
            RequirementItem(
              label: '現金 ≥ \$$_feeTeacher',
              check: (p) => p.wealth >= _feeTeacher,
            ),
            RequirementItem(
              label: '未註冊',
              check: (p) => !p.unlockedFlags.contains('teacher_registered'),
            ),
          ],
          onPass: (p) {
            _charge(p, _feeTeacher);
            final base = CareerData.hasEducationDegreePublic(p) ? 78 : 62;
            if (_rollPass(p, baseChance: base, smartsFloor: 45)) {
              p.completedExams.add('teacher_reg');
              p.unlockedFlags.add('teacher_registered');
              p.eventLog.add(
                '${p.year}年：取得教師註冊。'
                '${p.currentSector == CareerSector.teaching ? "可以爭取升正式教師。" : ""}',
              );
            } else {
              p.eventLog.add('${p.year}年：教師註冊申請被拒，再補文件再申請。');
            }
          },
        ),
        ChecklistExam(
          id: 'nursing_license',
          title: '護士管理局執業考試（簡化）',
          description:
              '主要畀非本地／未認可課程路線。'
              '本地認可護理學士畢業通常可直接申請註冊，唔使再考呢科。'
              '考試費 \$$_feeNursing。',
          requirements: [
            RequirementItem(label: '滿 21 歲', check: (p) => p.age >= 21),
            RequirementItem(
              label: '已出社會（非中小學）',
              check: (p) => !p.isChildhood,
            ),
            RequirementItem(
              label: '護理相關學歷／在讀護理',
              check: (p) =>
                  p.unlockedFlags.contains('nursing_degree') ||
                  p.unlockedFlags.contains('studying_nursing') ||
                  p.unlockedFlags.contains('grad_nursing') ||
                  (p.currentSector == CareerSector.nursing),
            ),
            RequirementItem(
              label: '未有註冊資格',
              check: (p) => !p.unlockedFlags.contains('nursing_license'),
            ),
            RequirementItem(
              label: '智慧 ≥ 62',
              check: (p) => p.smarts >= 62,
            ),
            RequirementItem(
              label: '紀律 ≥ 45',
              check: (p) => p.discipline >= 45,
            ),
            RequirementItem(
              label: '現金 ≥ \$$_feeNursing',
              check: (p) => p.wealth >= _feeNursing,
            ),
          ],
          onPass: (p) {
            _charge(p, _feeNursing);
            if (_rollPass(p, baseChance: 38, smartsFloor: 62)) {
              p.completedExams.add('nursing_license');
              p.unlockedFlags.add('nursing_license');
              p.eventLog.add('${p.year}年：護士執業試合格。');
            } else {
              p.stress = (p.stress + 7).clamp(0, 100);
              p.eventLog.add('${p.year}年：護士執業試不合格。');
            }
          },
        ),
        ChecklistExam(
          id: 'pharm_reg',
          title: '藥劑師註冊考試（簡化）',
          description:
              '主要畀非本地藥劑學歷：要過管理局三科筆試。'
              '本地港大／中大藥劑學位通常豁免筆試，改做約一年認可實習。'
              '考試費 \$$_feePharm。',
          requirements: [
            RequirementItem(label: '滿 21 歲', check: (p) => p.age >= 21),
            RequirementItem(
              label: '藥劑學位（或同等）',
              check: (p) =>
                  p.unlockedFlags.contains('pharm_degree') ||
                  p.unlockedFlags.contains('grad_pharmacy'),
            ),
            RequirementItem(
              label: '未註冊完成',
              check: (p) => !p.unlockedFlags.contains('pharm_reg_passed'),
            ),
            RequirementItem(
              label: '智慧 ≥ 68',
              check: (p) => p.smarts >= 68,
            ),
            RequirementItem(
              label: '紀律 ≥ 50',
              check: (p) => p.discipline >= 50,
            ),
            RequirementItem(
              label: '現金 ≥ \$$_feePharm',
              check: (p) => p.wealth >= _feePharm,
            ),
          ],
          onPass: (p) {
            _charge(p, _feePharm);
            if (_rollPass(
              p,
              baseChance: 30,
              smartsFloor: 68,
              disciplineBonusAt: 60,
            )) {
              p.completedExams.add('pharm_reg');
              p.unlockedFlags.add('pharm_reg_passed');
              p.eventLog.add('${p.year}年：藥劑師註冊試合格。');
            } else {
              p.stress = (p.stress + 8).clamp(0, 100);
              p.eventLog.add('${p.year}年：藥劑師註冊試不合格。');
            }
          },
        ),
      ];
}
