import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/career_abilities.dart';
import '../data/career_data.dart';
import '../data/career_employment.dart';
import '../data/career_gov.dart';
import '../data/career_internships.dart';
import '../data/church_pathway.dart';
import '../data/cssa_welfare.dart';
import '../data/elective_subjects.dart';
import '../data/family_assets.dart';
import '../data/hk_school_data.dart';
import '../data/ib_curriculum.dart';
import '../data/ib_pathway.dart';
import '../data/jupas/jupas.dart';
import '../data/jupas_pathway.dart';
import '../data/part_time_jobs.dart';
import '../data/social_circle.dart';
import '../data/housing_market.dart';
import '../data/market_engine.dart';
import '../data/university_life.dart';
import 'price_sparkline.dart';
import '../data/university_societies.dart';
import '../game_state.dart';
import '../models/enums.dart';
import '../models/player.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    if (!gs.profileOpen) return const SizedBox.shrink();

    final p = gs.player;
    final b = p.baselines;
    final width = MediaQuery.sizeOf(context).width.clamp(0, 420).toDouble();

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(onTap: gs.closeProfile),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: width < 380 ? width * 0.92 : 380,
              height: double.infinity,
              child: Material(
                color: const Color(0xFF0B0F14),
                elevation: 16,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHero(player: p, onClose: gs.closeProfile),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                          children: [
                            _StatGrid(player: p),
                            const SizedBox(height: 14),
                            _Card(
                              title: '基本資料',
                              children: [
                                _kv('年齡', '${p.age} 歲 · ${p.year} ${p.quarterLabel}'),
                                _kv('出身', p.birthTier.label),
                                _kv('標籤', p.birthTier.locationTag),
                                _kv('人生階段', p.lifeStage.label),
                                if (p.isInSchool)
                                  _kv('年級', p.schoolFormLabel)
                                else
                                  _kv('學歷', p.education.label),
                                _kv('而家', p.statusLabel),
                                _kv(
                                  '住邊',
                                  '${p.homeDistrict.label} · ${p.homeDistrict.schoolNet}校網',
                                ),
                                _kv('住房', p.housingType.label),
                              ],
                            ),
                            _schoolCard(p),
                            _socialCard(p),
                            _examCard(p),
                            if (p.isEmployed ||
                                p.hasPartTime ||
                                p.mpfBalance > 0)
                              _workCard(p),
                            _Card(
                              title: '錢同屋企',
                              children: [
                                _statBreakdown(
                                  '個人現金',
                                  b.baseWealth,
                                  p.addedWealth,
                                  p.wealth,
                                  isMoney: true,
                                ),
                                if (CssaWelfare.isEligibleTier(p))
                                  _kv('綜援', CssaWelfare.statusLabel(p)),
                                _kv(
                                  '屋企流動資金',
                                  FamilyAssets.familyWealthLabel(p),
                                ),
                                if (p.familyPropertyValue > 0)
                                  _kv(
                                    '屋企物業',
                                    '\$${p.familyPropertyValue}'
                                    '（${p.familyOwnsHome ? "自住" : "—"}）',
                                  ),
                                if (p.livesWithFamily) ...[
                                  _kv(
                                    '零用錢',
                                    FamilyAssets.allowanceStatusLabel(p),
                                  ),
                                  if (p.age < 18)
                                    _kv(
                                      '零用基準',
                                      '\$${p.baseAllowance}/季（唔一定派）',
                                    ),
                                  _kv(
                                    '新年利是',
                                    FamilyAssets.laiSeeRangeLabel(p),
                                  ),
                                ],
                                _kv('同住屋企', p.livesWithFamily ? '係' : '唔係'),
                              ],
                            ),
                            _housingCard(p),
                            _investCard(p),
                            _Card(
                              title: '核心屬性',
                              subtitle: '基礎 ＋ 加成 ＝ 合計',
                              children: [
                                _statBreakdown(
                                  '生命',
                                  b.baseHp,
                                  p.addedHp,
                                  p.hp,
                                  max: p.maxHp,
                                  color: const Color(0xFF3FB950),
                                ),
                                _statBreakdown(
                                  '神智',
                                  b.baseSan,
                                  p.addedSan,
                                  p.san,
                                  max: p.maxSan,
                                  color: const Color(0xFFBC8CFF),
                                ),
                                _statBreakdown(
                                  '智慧',
                                  b.baseSmarts,
                                  p.addedSmarts,
                                  p.smarts,
                                  color: const Color(0xFF79C0FF),
                                ),
                                _statBreakdown(
                                  '人脈',
                                  b.baseNetwork,
                                  p.addedNetwork,
                                  p.network,
                                  color: const Color(0xFFFFA657),
                                ),
                                _statBreakdown(
                                  '名望',
                                  b.baseReputation,
                                  p.addedReputation,
                                  p.reputation,
                                  color: const Color(0xFFE3B341),
                                ),
                              ],
                            ),
                            _Card(
                              title: '隱藏屬性',
                              children: [
                                _statBreakdown(
                                  '幸運',
                                  b.baseLuck,
                                  p.addedLuck,
                                  p.luck,
                                ),
                                _statBreakdown(
                                  '紀律',
                                  b.baseDiscipline,
                                  p.addedDiscipline,
                                  p.discipline,
                                ),
                                _kv('壓力', '${p.stress}'),
                              ],
                            ),
                            if (p.isEmployed &&
                                p.careerAttributes.isNotEmpty) ...[
                              if (CareerAbilities.abilityEntries(p)
                                  .isNotEmpty)
                                _Card(
                                  title: '行業能力',
                                  children: [
                                    ...CareerAbilities.abilityEntries(p).map(
                                          (e) => _kv(e.key, '${e.value}'),
                                        ),
                                  ],
                                ),
                              if (CareerAbilities.riskEntries(p).isNotEmpty)
                                _Card(
                                  title: '行業風險',
                                  children: [
                                    ...CareerAbilities.riskEntries(p).map(
                                          (e) => _kv(e.key, '${e.value}'),
                                        ),
                                  ],
                                ),
                            ],
                            if (p.dormantHistory.isNotEmpty)
                              _Card(
                                title: '過往履歷',
                                children: [
                                  ...p.dormantHistory.map(
                                    (d) => _kv(
                                      d.jobTitle,
                                      '${d.sector.label} · ${d.endedYear}年',
                                    ),
                                  ),
                                ],
                              ),
                            if (p.hasCriminalRecord)
                              _Card(
                                title: '紀錄',
                                accent: const Color(0xFFDA3633),
                                children: [
                                  _kv('刑事紀錄', '有'),
                                  if (p.investigation !=
                                      InvestigationStatus.none)
                                    _kv('調查狀態', p.investigation.name),
                                ],
                              ),
                            if (p.eventLog.isNotEmpty)
                              _Card(
                                title: '人生紀錄',
                                children: [
                                  ...p.eventLog.reversed.take(8).map(
                                        (e) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: Color(0xFF9DA7B3),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _housingCard(Player p) {
    final rows = <Widget>[
      _kv('現況', HousingMarket.housingStatusLabel(p)),
    ];
    if (p.age < HousingMarket.minAge) {
      rows.add(
        _kv('提示', '滿 ${HousingMarket.minAge} 歲先可以租樓／置業'),
      );
    } else {
      if (p.ownsFlat) {
        rows.add(_kv('估值', '\$${p.flatValue}'));
        if (p.mortgagePrincipal > 0) {
          rows.add(_kv('按揭欠款', '\$${p.mortgagePrincipal}'));
          rows.add(
            _kv(
              '利率／剩餘',
              '${(p.mortgageRateAnnual * 100).toStringAsFixed(2)}%'
              ' · 約 ${(p.mortgageQuartersLeft / 4).ceil()} 年',
            ),
          );
        }
        if (p.housingType == HousingType.hos) {
          rows.add(
            _kv('居屋補價', p.hosPremiumPaid ? '已補／豁免' : '未補（轉售受限）'),
          );
        }
      } else if (p.renting) {
        rows.add(_kv('月租', '\$${p.monthlyRent}'));
      }
      if (p.unlockedFlags.contains('prh_waiting')) {
        rows.add(
          _kv('公屋輪候', '已等 ${p.publicHousingWaitQuarters} 季'),
        );
      }
      rows.add(
        _kv(
          '樓價指數',
          p.hkPropertyIndex.toStringAsFixed(3),
        ),
      );
    }
    return _Card(title: '住屋', children: rows);
  }

  Widget _investCard(Player p) {
    MarketEngine.ensureInitialized(p);
    final rows = <Widget>[
      _kv('概況', MarketEngine.statusSummary(p)),
    ];
    if (p.age < MarketEngine.minAge) {
      rows.add(
        _kv('提示', '滿 ${MarketEngine.minAge} 歲先可以投資'),
      );
      return _Card(title: '投資', children: rows);
    }

    for (final a in MarketEngine.catalogue) {
      final hist = MarketEngine.historyOf(p, a.id);
      final px = MarketEngine.priceOf(p, a.id);
      final ch = MarketEngine.quarterChangePct(p, a.id);
      final sign = ch >= 0 ? '+' : '';
      final held = p.holdings
          .where((h) => h.assetId == a.id && h.units > 0)
          .toList();
      final holdNote = held.isEmpty
          ? ''
          : ' · 持 ${held.first.units.toStringAsFixed(3)}';
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.nameZh}（${a.id}）',
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${a.marketLabel} · \$${px.toStringAsFixed(2)} · '
                      '$sign${ch.toStringAsFixed(1)}%$holdNote',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PriceSparkline(prices: hist, width: 64, height: 26),
            ],
          ),
        ),
      );
    }
    return _Card(title: '投資（12 資產）', children: rows);
  }

  Widget _socialCard(Player p) {
    final rows = <Widget>[
      _kv('概況', SocialCircle.statusSummary(p)),
    ];
    if (p.friends.isEmpty) {
      rows.add(
        _kv('提示', '學校／社團／教會／蒲吧／大學聚會可識人'),
      );
    } else {
      for (final f in p.friends) {
        final tag = f.isPartner
            ? '♥ 拍拖中 · 每季智慧 −${SocialCircle.datingSmartsPenalty}'
            : f.affinityBand;
        rows.add(
          _kv(
            f.nameZh,
            '${f.source.label} · 好感 ${f.affinity}/100 · $tag',
          ),
        );
      }
    }
    return _Card(title: '社交', children: rows);
  }

  Widget _schoolCard(Player p) {
    final rows = <Widget>[];
    rows.add(_kv('小學 Band', p.primaryBand.primaryLabel));
    if (p.lifeStage == LifeStage.infant &&
        p.primaryBand != SchoolBand.none) {
      rows.add(_kv('升小', '6 歲派位（未入讀）'));
    } else if (p.primarySchoolName.isNotEmpty) {
      rows.add(_kv('小學', p.primarySchoolName));
    }
    if (p.unlockedFlags.contains('ssa_stay_international')) {
      rows.add(_kv('升中路線', '國際／IB（繞過 SSA）'));
    } else if (p.unlockedFlags.contains('ssa_force_local')) {
      rows.add(_kv('升中路線', '轉入本地 SSA'));
    }
    if (p.schoolBand != SchoolBand.none) {
      rows.add(_kv('中學 Band', p.schoolBand.secondaryLabel));
      if (p.ssaBandGroup != SsaBandGroup.none) {
        rows.add(_kv('呈分組別', p.ssaBandGroup.label));
      }
      if (p.ssaPathway != SsaPathway.none) {
        rows.add(_kv('升中途徑', p.ssaPathway.label));
      }
      if (p.placementScore > 0) {
        rows.add(_kv('呈分', '${p.placementScore}'));
      }
      if (p.secondarySchoolName.isNotEmpty) {
        rows.add(_kv('中學', p.secondarySchoolName));
      }
    }
    if (p.lifeStage == LifeStage.secondary || p.electiveIds.isNotEmpty) {
      rows.add(_kv('理文傾向', p.streamAffinity.label));
      if (p.electiveIds.isNotEmpty) {
        rows.add(_kv('選修科', ElectiveData.electivesLabel(p)));
      }
    }
    if (p.churchMember || p.isBaptized) {
      rows.add(_kv('教會', ChurchPathway.loyaltyLabel(p)));
    }
    if (rows.length <= 1) return const SizedBox.shrink();
    return _Card(title: '學校', children: rows);
  }

  Widget _examCard(Player p) {
    final rows = <Widget>[];

    if (p.lifeStage == LifeStage.secondary &&
        p.dseSittingCount <= 0 &&
        p.dseGrades.isEmpty &&
        !FoundationPathway.hasPassed(p)) {
      if (JupasPathway.isLocalTrack(p) && !IbPathway.isOnTrack(p)) {
        rows.add(
          _kv(
            'DSE',
            p.age >= 17 &&
                    (p.quarter == Quarter.q3 || p.quarter == Quarter.q4)
                ? '本季可考——去「溫書」㩒橙色【DSE】'
                : '17 歲 Q3／Q4 · 溫書 tab 㩒【DSE】睇條件',
          ),
        );
      } else if (IbPathway.isOnTrack(p)) {
        rows.add(_kv('公開試', 'IB Diploma（唔考 DSE）'));
      } else {
        rows.add(_kv('升學路線', '國際路線 · 唔走 DSE'));
      }
      rows.add(
        _kv('升學門檻', 'Asso／HD 22222 · 學士 33222（放榜後顯示）'),
      );
    }

    if (p.dseTier != DseTier.none || p.dseSittingCount > 0) {
      rows.add(
        _kv(
          'DSE Best5',
          '${p.dseBestScore}（${p.dseTier.label}）· ${p.dseSittingCount} 次',
        ),
      );
      if (p.dseGrades.isNotEmpty) {
        rows.add(
          _kv('分科', DseGradeGenerator.summaryLabel(p.dseGrades)),
        );
      }
      if (p.dseGrades.isNotEmpty ||
          p.dseSittingCount > 0 ||
          FoundationPathway.hasPassed(p)) {
        rows.add(_kv('一般入學', JupasRequirements.gerSummary(p)));
      }
      if (FoundationPathway.isStudying(p)) {
        rows.add(
          _kv('Foundation', '讀緊（${p.foundationQuarters}/4 季）'),
        );
      } else if (FoundationPathway.hasPassed(p)) {
        rows.add(_kv('Foundation', 'Pass · 可報 Asso／HD'));
      }
      if (p.dseRetakeMode != DseRetakeMode.none) {
        rows.add(_kv('重考', p.dseRetakeMode.label));
      }
      if (p.jupasPath != JupasPath.none) {
        rows.add(_kv('JUPAS', p.jupasPath.label));
      }
      if (p.jupasChoices.isNotEmpty) {
        rows.add(_kv('志願', JupasPathway.choicesLabel(p)));
      }
      if (p.assoHoldCode.isNotEmpty) {
        rows.add(
          _kv(
            'Asso／HD',
            '${p.assoHoldCode}'
            '${p.assoDepositPaid ? " · 已交留位費" : " · 未交留位費"}',
          ),
        );
      }
      if (p.education == EducationLevel.associate && p.assoGpa > 0) {
        rows.add(
          _kv(
            '副學士',
            'Year ${p.assoYear} · GPA ${p.assoGpa}'
            '${p.unlockedFlags.contains("asso_graduated") ? " · 已畢業" : ""}',
          ),
        );
      }
      if (p.bachelorYear > 0 && p.education == EducationLevel.bachelor) {
        rows.add(
          _kv(
            '大學年級',
            'Year ${p.bachelorYear}'
            '${p.uniDelayYears > 0 ? "（延遲 ${p.uniDelayYears}）" : ""}',
          ),
        );
        if (p.uniGpa > 0) {
          rows.add(
            _kv(
              '大學 GPA',
              p.uniGpa.toStringAsFixed(2) +
                  (p.uniProbation ? ' · 試讀中' : ''),
            ),
          );
        }
        if (p.uniHonours.isNotEmpty) {
          rows.add(
            _kv(
              '榮譽',
              '${UniversityLife.honoursLabelZh(p.uniHonours)}（${p.uniHonours}）',
            ),
          );
        }
        if (p.uniStudyLoad != UniStudyLoad.none) {
          rows.add(_kv('最近溫書', p.uniStudyLoad.label));
        }
        rows.add(
          _kv(
            '住宿',
            p.inHall
                ? 'Hall（點數 ${p.hallPoints}）'
                : (p.livesWithFamily ? '住屋企' : '外面'),
          ),
        );
        if (p.uniSocietyIds.isNotEmpty) {
          rows.add(
            _kv(
              '學會',
              p.uniSocietyIds.map((id) {
                final n = UniversitySocieties.byId(id)?.nameZh ?? id;
                return UniversitySocieties.isCadre(p, id) ? '$n（上莊）' : n;
              }).join('、'),
            ),
          );
          rows.add(_kv('莊員關係', '${p.uniSocietyStanding}'));
        }
      }
      if (p.studentLoanDebt > 0) {
        rows.add(_kv('學生貸款', '\$${p.studentLoanDebt}'));
      }
      if (p.jupasCode.isNotEmpty) {
        final prog = JupasCatalogue.byCode(p.jupasCode);
        rows.add(_kv('入讀', prog?.displayName ?? p.jupasCode));
        if (prog != null) {
          rows.add(_kv('收生要求', prog.requirementsLabel));
          if (prog.award == JupasAward.bachelor) {
            rows.add(_kv('Non-JUPAS', prog.nonJupasLabel));
          }
        }
      }
    }

    if (p.ibTier != IbTier.none) {
      rows.add(_kv('IB 成績', '${p.ibScore}/45 · ${p.ibTier.label}'));
      if (p.ibUniPath != IbUniPath.none) {
        rows.add(_kv('IB 升學', p.ibUniPath.label));
      }
    }
    if (p.ibSubjectSlots.isNotEmpty) {
      rows.add(_kv('IB DP 科目', IbCurriculum.subjectsLabel(p)));
    }
    if (IbPathway.isOnTrack(p) && p.streamAffinity != StreamAffinity.none) {
      rows.add(_kv('IB HL 傾向', p.streamAffinity.label));
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return _Card(title: '考試／升學', children: rows);
  }

  Widget _workCard(Player p) {
    final rows = <Widget>[];
    if (p.isEmployed) {
      rows.add(_kv('全職', p.jobTitle));
      rows.add(_kv('行業', p.currentSector.label));
      rows.add(
        _kv(
          '月薪約',
          '\$${CareerEmployment.effectiveMonthlySalary(p)}',
        ),
      );
      if (CareerGov.usesGovRules(p)) {
        rows.add(_kv('薪級', CareerGov.mpsLabel(p)));
        rows.add(_kv('年度調整', CareerGov.payScaleLabel(p)));
        if (p.jobGovPointFreezeQuarters > 0) {
          rows.add(
            _kv('凍增薪點', '剩 ${p.jobGovPointFreezeQuarters} 季'),
          );
        }
        rows.add(
          _kv(
            '評核 A',
            '${CareerGov.appraisalAs(p)}'
            '（升職通常要 ≥${CareerGov.asForPromote}）',
          ),
        );
      }
      rows.add(_kv('試用期', CareerEmployment.probationLabel(p)));
      if (p.currentSector == CareerSector.disciplinary) {
        rows.add(_kv('體能', '${p.fitness}'));
      }
      rows.add(_kv('工作表現', '${p.jobPerformance}'));
      if (CareerData.kpiProgressLabel(p) != null) {
        rows.add(_kv('本季 KPI', CareerData.kpiProgressLabel(p)!));
      }
      if (CareerData.kpiBusySeasonHint(p) != null) {
        rows.add(_kv('工作旺季', CareerData.kpiBusySeasonHint(p)!));
      }
      rows.add(_kv('本級年資', '${p.jobQuartersInRank} 季'));
      rows.add(_kv('現職年資', '${p.jobQuartersEmployed} 季'));
    }
    if (p.hasPartTime) {
      rows.add(_kv('兼職', PartTimeJobs.displayLabel(p)));
      rows.add(
        _kv(
          '兼職閒置',
          '${p.partTimeQuartersIdle}/4 季（滿 4 季唔返會炒）',
        ),
      );
      rows.add(_kv('已返更數', '${p.partTimeShiftsTotal}'));
    }
    if (CareerInternships.hasActive(p)) {
      rows.add(_kv('實習', CareerInternships.displayLabel(p)));
    }
    if (p.mpfBalance > 0) {
      rows.add(_kv('強積金', '\$${p.mpfBalance}'));
    }
    if (p.taxYearFtIncome > 0 || p.taxYearPtIncome > 0) {
      rows.add(_kv('本年全職入息', '\$${p.taxYearFtIncome}'));
      rows.add(_kv('本年兼職入息', '\$${p.taxYearPtIncome}'));
      rows.add(
        _kv(
          '報稅門檻',
          '總入息 > \$${CareerEmployment.personalAllowance} 先要交',
        ),
      );
    } else if (p.taxYearIncome > 0) {
      rows.add(_kv('本年度評稅入息', '\$${p.taxYearIncome}'));
    }
    if (p.lastTaxDeclared > 0) {
      rows.add(_kv('上次申報入息', '\$${p.lastTaxDeclared}'));
    }
    if (p.lastTaxPaid > 0) {
      rows.add(_kv('上次薪俸稅／罰款', '\$${p.lastTaxPaid}'));
    }
    return _Card(title: '工作', children: rows);
  }
}

class _ProfileHero extends StatelessWidget {
  final Player player;
  final VoidCallback onClose;

  const _ProfileHero({required this.player, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final p = player;
    final tierColor = switch (p.birthTier) {
      BirthTier.ssr => const Color(0xFFE3B341),
      BirthTier.sr => const Color(0xFF79C0FF),
      BirthTier.r => const Color(0xFF8B949E),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15202B), Color(0xFF0B0F14)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A3441), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '個人檔案',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 26),
                color: const Color(0xFFC9D1D9),
              ),
            ],
          ),
          Text(
            p.name.isEmpty ? '未命名' : p.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF0F3F6),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${p.age} 歲 · ${p.statusLabel}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC9D1D9),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(p.birthTier.label, tierColor),
              _pill('${p.year} ${p.quarterLabel}', const Color(0xFF58A6FF)),
              _pill(p.lifeStage.label, const Color(0xFF3FB950)),
              _pill(
                p.isInSchool ? p.schoolFormLabel : p.education.label,
                const Color(0xFFFFA657),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final Player player;
  const _StatGrid({required this.player});

  @override
  Widget build(BuildContext context) {
    final p = player;
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: '生命',
            value: '${p.hp}/${p.maxHp}',
            color: const Color(0xFF3FB950),
            ratio: p.maxHp > 0 ? p.hp / p.maxHp : 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: '神智',
            value: '${p.san}/${p.maxSan}',
            color: const Color(0xFFBC8CFF),
            ratio: p.maxSan > 0 ? p.san / p.maxSan : 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: '智慧',
            value: '${p.smarts}',
            color: const Color(0xFF79C0FF),
            ratio: p.smarts / 100,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: '人脈',
            value: '${p.network}',
            color: const Color(0xFFFFA657),
            ratio: p.network / 100,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double ratio;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12181F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF0F3F6),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFF21262D),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? accent;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.children,
    this.subtitle,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final line = accent ?? const Color(0xFF3D4A5C);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF12181F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: line.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: accent ?? const Color(0xFF79C0FF),
                letterSpacing: 0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6E7681),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _kv(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B949E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE6EDF3),
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _statBreakdown(
  String label,
  int base,
  int added,
  int total, {
  int? max,
  bool isMoney = false,
  Color? color,
}) {
  final sign = added >= 0 ? '+' : '';
  final prefix = isMoney ? '\$' : '';
  final maxStr = max != null ? '／$max' : '';
  final accent = color ?? const Color(0xFFE6EDF3);
  final ratio = max != null && max > 0 ? (total / max).clamp(0.0, 1.0) : null;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const Spacer(),
            Text(
              '$prefix$total$maxStr',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '基礎 $prefix$base　加成 $sign$added',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6E7681),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (ratio != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: const Color(0xFF21262D),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ],
    ),
  );
}
