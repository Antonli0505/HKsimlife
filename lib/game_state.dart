import 'dart:math';

import 'package:flutter/foundation.dart';

import 'data/birth_gacha.dart';
import 'data/career_data.dart';
import 'data/career_employment.dart';
import 'data/career_events.dart';
import 'data/career_exams.dart';
import 'data/career_gov.dart';
import 'data/career_hiring_seasons.dart';
import 'data/career_internships.dart';
import 'data/career_job_hunt.dart';
import 'data/career_tax.dart';
import 'data/church_pathway.dart';
import 'data/cssa_welfare.dart';
import 'data/elective_subjects.dart';
import 'data/family_assets.dart';
import 'data/hk_school_data.dart';
import 'data/housing_market.dart';
import 'data/ib_curriculum.dart';
import 'data/ib_pathway.dart';
import 'data/jupas/jupas.dart';
import 'data/jupas_pathway.dart';
import 'data/luck_modifiers.dart';
import 'data/market_engine.dart';
import 'data/part_time_jobs.dart';
import 'data/social_circle.dart';
import 'data/university_life.dart';
import 'data/university_pathway.dart';
import 'data/university_societies.dart';
import 'event_engine.dart';
import 'models/enums.dart';
import 'models/game_event.dart';
import 'models/player.dart';
import 'services/storage_service.dart';

class GameState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final EventEngine _engine = EventEngine();

  Player _player = Player();
  List<StoryEvent> _quarterEvents = [];
  final List<String> _outcomeMessages = [];
  final List<String> _popupQueue = [];
  ActionTab _activeTab = ActionTab.career;
  bool _profileOpen = false;
  bool _loaded = false;
  ChecklistExam? _pendingExam;

  Player get player => _player;
  List<StoryEvent> get quarterEvents => _quarterEvents;
  List<String> get outcomeMessages => _outcomeMessages;
  List<String> get popupQueue => List.unmodifiable(_popupQueue);
  bool get hasPendingPopup => _popupQueue.isNotEmpty;
  ActionTab get activeTab => _activeTab;
  bool get profileOpen => _profileOpen;
  bool get loaded => _loaded;
  ChecklistExam? get pendingExam => _pendingExam;

  /// 寫入結果 log，並排入彈窗隊列（重要資訊用 popup 顯示）
  void pushOutcome(String message, {bool popup = true}) {
    final msg = message.trim();
    if (msg.isEmpty) return;
    _outcomeMessages.add(msg);
    if (popup) _popupQueue.add(msg);
  }

  void dismissCurrentPopup() {
    if (_popupQueue.isEmpty) return;
    _popupQueue.removeAt(0);
    notifyListeners();
  }

  /// 一次過攞晒队列（下一季大量結算合併成一則彈窗）
  String? takePopupBatch({int separateUntil = 2}) {
    if (_popupQueue.isEmpty) return null;
    late final String msg;
    if (_popupQueue.length <= separateUntil) {
      msg = _popupQueue.removeAt(0);
    } else {
      msg = _popupQueue.join('\n\n———\n\n');
      _popupQueue.clear();
    }
    notifyListeners();
    return msg;
  }

  void _clearOutcomes() {
    _outcomeMessages.clear();
    _popupQueue.clear();
  }

  Future<void> init() async {
    final saved = await _storage.load();
    if (saved != null) {
      _player = saved;
      if (_player.age < 6) {
        BirthGacha.syncInfantState(_player);
      }
      // 舊存檔：有綜援資格但未開 active → 未滿 18 自動開通
      if (CssaWelfare.isEligibleTier(_player) &&
          _player.age < 18 &&
          !CssaWelfare.isActive(_player) &&
          CssaWelfare.lastRenewYear(_player) == null &&
          _player.wealth <= CssaWelfare.assetLimit) {
        CssaWelfare.activateAtBirth(_player);
      }
      _player.refreshActionPoints();
      MarketEngine.ensureInitialized(_player);
      _generateQuarterEvents();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> newGame({String name = '新移民'}) async {
    _player = Player(name: name, phase: GamePhase.gacha);
    _clearOutcomes();
    await _save();
    notifyListeners();
  }

  Future<void> startWithBirth(
    String name,
    BirthTier tier, {
    SchoolBand? primaryBand,
  }) async {
    _player = Player(name: name);
    BirthGacha.applyBirthTier(_player, tier, primaryBand: primaryBand);
    _player.refreshActionPoints();
    MarketEngine.ensureInitialized(_player);
    _clearOutcomes();
    pushOutcome(
      '🎴 出世档案\n'
      '家庭：${_player.birthTier.label}\n'
      '居住：${_player.homeDistrict.label}（${_player.homeDistrict.schoolNet}校網）\n'
      '小學 Band：${_player.primaryBand.primaryLabel}\n'
      '升小：6 歲先派位入讀',
    );
    _generateQuarterEvents();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _storage.save(_player);
  }

  void _generateQuarterEvents() {
    _quarterEvents = _engine.generateQuarterEvents(_player);
    final astray = _engine.goAstrayEvent(_player);
    if (astray != null) _quarterEvents.add(astray);
    _purgeStalePostResultsEvents();
    if (JupasPathway.isOfferDecisionPending(_player) &&
        !_quarterEvents.any((e) => e.id == 'jupas_offer_decision')) {
      _quarterEvents.insert(0, JupasPathway.offerDecisionEvent(_player));
    }
    // 大學開學卡置頂（高優先）
    if (UniversityLife.needsOrientation(_player)) {
      final orient = UniversityLife.orientationEvent(_player);
      if (orient != null) {
        _quarterEvents.removeWhere((e) => e.id == 'uni_orientation');
        _quarterEvents.insert(0, orient);
      }
    }
  }

  /// 升學卡：狀態已變（入讀／重讀等）但舊卡留喺 queue → 清走
  void _purgeStalePostResultsEvents() {
    if (JupasPathway.shouldShowPostResultsPlanner(_player)) return;
    final had = _quarterEvents.any((e) =>
        e.id == 'jupas_programme_pick' || e.id == 'dse_jupas_choice');
    if (!had) return;
    _quarterEvents.removeWhere((e) =>
        e.id == 'jupas_programme_pick' || e.id == 'dse_jupas_choice');
    _player.unlockedFlags.remove('jupas_chooser_pending');
  }

  void _insertPostResultsPlanner({bool dseCard = false}) {
    if (JupasPathway.isOfferDecisionPending(_player)) return;
    if (!JupasPathway.shouldShowPostResultsPlanner(_player)) return;
    _quarterEvents.removeWhere((e) =>
        e.id == 'jupas_programme_pick' || e.id == 'dse_jupas_choice');
    _quarterEvents.insert(
      0,
      dseCard
          ? _engine.dsePostResultsEventPublic(_player)
          : JupasPathway.applicationEvent(_player),
    );
  }

  void setActiveTab(ActionTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void toggleProfile() {
    _profileOpen = !_profileOpen;
    notifyListeners();
  }

  void closeProfile() {
    _profileOpen = false;
    notifyListeners();
  }

  Future<void> selectChoice(StoryEvent event, int choiceIndex) async {
    if (choiceIndex >= event.choices.length) return;
    final choice = event.choices[choiceIndex];
    if (!choice.enabled) return;
    final before = _snapshotStats();

    choice.apply(_player);
    _player.clampStats();

    final after = _snapshotStats();
    var outcome = _formatOutcome(choice.label, before, after);
    if (event.id == 'jupas_programme_pick' || event.id == 'dse_jupas_choice') {
      if (_player.jupasPath == JupasPath.awaitingOffer ||
          JupasPathway.isAwaitingMainRound(_player)) {
        outcome =
            '已提交 JUPAS 志願，等 Q3（或下季）出 Main Round。\n'
            '${JupasPathway.choicesLabel(_player)}';
      } else if (_player.assoDepositPaid) {
        outcome =
            '已交 Asso／HD 留位費（${_player.assoHoldCode}），未即入學。'
            '${JupasPathway.isAwaitingMainRound(_player) ? "兩手準備中。" : "可確認入讀或再報 JUPAS。"}';
      } else if (_player.assoHoldCode.isNotEmpty) {
        outcome =
            '已獲 conditional（${_player.assoHoldCode}）；記得交留位費。';
      } else if (_player.jupasChoices.isNotEmpty &&
          JupasPathway.canEditJupasChoices(_player)) {
        outcome =
            '志願更新咗（${_player.jupasChoices.length} 個）。\n'
            '${JupasPathway.choicesLabel(_player)}';
      } else if (_player.jupasCode.isNotEmpty &&
          _player.education == EducationLevel.bachelor) {
        outcome =
            '${_player.jupasPath.label}\n${_player.studyProgram}';
      } else if (_player.jupasPath == JupasPath.work) {
        outcome = '揀咗出社會／未報聯招。';
      } else if (_player.unlockedFlags.contains('dse_jupas_deferred')) {
        outcome = '決定咗下年再報聯招。';
      } else if (_player.unlockedFlags.contains('dse_retaking')) {
        outcome = '開始準備重考喇。';
      }
    }
    if (event.id == 'jupas_offer_decision') {
      if (_player.education == EducationLevel.bachelor) {
        outcome = '入讀咗學士\n${_player.studyProgram}';
      } else if (_player.education == EducationLevel.associate) {
        outcome = '入讀咗 Asso／HD\n${_player.studyProgram}';
      } else if (_player.unlockedFlags.contains('dse_jupas_deferred')) {
        outcome = '放棄咗今屆取錄／留位，下屆再報。';
      } else if (_player.jupasPath == JupasPath.work) {
        outcome = '揀咗出社會。';
      } else if (_player.unlockedFlags.contains('dse_retaking')) {
        outcome = '開始準備重考喇。';
      }
    }
    if (event.id.startsWith('asso_artic_')) {
      if (_player.education == EducationLevel.bachelor &&
          _player.bachelorYear > 0) {
        outcome =
            'Non-JUPAS 升學成功\n${_player.studyProgram}\n'
            '大學 Year ${_player.bachelorYear}';
      } else {
        outcome = 'Non-JUPAS 申請搞掂咗（GPA ${_player.assoGpa}）。';
      }
    }
    if (event.id == 'career_tax_return') {
      final log = _player.eventLog.reversed
          .cast<String?>()
          .firstWhere(
            (e) => e != null && e.contains('報稅'),
            orElse: () => null,
          );
      if (log != null) outcome = log;
    }
    if (event.id.startsWith('social_')) {
      final log = _player.eventLog.reversed
          .cast<String?>()
          .firstWhere(
            (e) =>
                e != null &&
                (e.contains('出街') ||
                    e.contains('食飯') ||
                    e.contains('送禮') ||
                    e.contains('表白') ||
                    e.contains('拍拖') ||
                    e.contains('分手') ||
                    e.contains('約會')),
            orElse: () => null,
          );
      if (log != null) {
        outcome = log.replaceFirst(RegExp(r'^\d+年：'), '');
      } else if (choice.label == '取消') {
        outcome = '取消咗。';
      }
    }
    if (event.id.startsWith('invest_') ||
        event.id.startsWith('housing_')) {
      final log = _player.eventLog.isNotEmpty ? _player.eventLog.last : null;
      if (log != null &&
          (log.contains('買入') ||
              log.contains('賣出') ||
              log.contains('成交') ||
              log.contains('租住') ||
              log.contains('加按') ||
              log.contains('公屋') ||
              log.contains('居屋') ||
              log.contains('賣出'))) {
        outcome = log.replaceFirst(RegExp(r'^\d+年：'), '');
      } else if (choice.label == '取消') {
        outcome = '取消咗。';
      }
    }
    pushOutcome(outcome);
    _quarterEvents.remove(event);
    // 去向卡揀完：清走 queue 內其餘同 id（防雙卡）
    if (event.id == 'jupas_offer_decision') {
      _quarterEvents.removeWhere((e) => e.id == 'jupas_offer_decision');
    }
    _requeueJupasPlannerIfNeeded(event);
    _flushJupasChooserIfNeeded();
    _flushPendingSchoolEvents();
    _flushPendingSocialEvents();
    _flushPendingInvestHousingEvents();

    if (event.id == 'f4_elective_pick') {
      final log = _player.eventLog.reversed
          .cast<String?>()
          .firstWhere(
            (e) =>
                e != null &&
                (e.contains('選科') || e.contains('取錄') || e.contains('選修')),
            orElse: () => null,
          );
      if (log != null) outcome = log;
    }
    if ((event.id == 'dse_jupas_choice' ||
            event.id == 'jupas_programme_pick') &&
        _player.eventLog.isNotEmpty) {
      final last = _player.eventLog.last;
      if (last.contains('Foundation') ||
          last.contains('入讀') ||
          last.contains('Asso') ||
          last.contains('JUPAS') ||
          last.contains('學費')) {
        outcome = last;
      }
    }

    _checkDeath();
    await _save();
    notifyListeners();
  }

  /// 加志願／交留位費後繼續同一張規劃卡（唔一次過結束）
  void _requeueJupasPlannerIfNeeded(StoryEvent event) {
    if (event.id != 'jupas_programme_pick' &&
        event.id != 'dse_jupas_choice') {
      return;
    }
    if (JupasPathway.isOfferDecisionPending(_player)) return;
    if (_player.completedExams.contains('jupas')) return;
    if (_player.unlockedFlags.contains('dse_retaking')) return;
    if (_player.jupasPath == JupasPath.work) return;
    if (_player.jupasPath == JupasPath.deferred) return;

    final still = JupasPathway.shouldShowPostResultsPlanner(_player);
    if (!still) return;

    _insertPostResultsPlanner(dseCard: event.id == 'dse_jupas_choice');
  }

  Map<String, int> _snapshotStats() => {
        'hp': _player.hp,
        'san': _player.san,
        'smarts': _player.smarts,
        'network': _player.network,
        'wealth': _player.wealth,
        'reputation': _player.reputation,
      };

  String _formatOutcome(
    String label,
    Map<String, int> before,
    Map<String, int> after,
  ) {
    final changes = <String>[];
    for (final key in before.keys) {
      final diff = after[key]! - before[key]!;
      if (diff != 0) {
        changes.add('${_statLabel(key)} ${diff > 0 ? "+" : ""}$diff');
      }
    }
    return changes.isEmpty
        ? '你揀咗「$label」，一切似乎冇乜變。'
        : '你揀咗「$label」→ ${changes.join("，")}';
  }

  String _statLabel(String key) => switch (key) {
        'hp' => '生命',
        'san' => '神智',
        'smarts' => '智慧',
        'network' => '人脈',
        'wealth' => '現金',
        'reputation' => '名望',
        _ => key,
      };

  void _checkDeath() {
    if (_player.hp <= 0) {
      _player.phase = GamePhase.dead;
      _player.eventLog.add('${_player.year}年：生命耗盡，離世。');
    }
    if (_player.san <= 0) {
      _player.phase = GamePhase.dead;
      _player.eventLog.add('${_player.year}年：神智崩潰。');
    }
  }

  Future<bool> executeAction(ActionButton action) async {
    if (!action.enabled) return false;
    if (_player.actionPoints < action.apCost) return false;
    if (_player.phase != GamePhase.playing && !_player.inPrison) return false;

    if (action.opensChecklistId != null) {
      _pendingExam = _engine
          .allExams(_player)
          .where((e) => e.id == action.opensChecklistId)
          .firstOrNull;
      notifyListeners();
      return true;
    }

    _player.actionPoints -= action.apCost;
    final prevLogLen = _player.eventLog.length;
    action.onExecute(_player);
    _player.clampStats();
    final hadJupasPending =
        _player.unlockedFlags.contains('jupas_chooser_pending');
    final hadElectivePending =
        _player.unlockedFlags.contains('f4_elective_pick_pending');
    final hadStreamPending =
        _player.unlockedFlags.contains('stream_affinity_pending');
    _flushJupasChooserIfNeeded();
    _flushPendingSchoolEvents();
    _flushPendingSocialEvents();
    _flushPendingInvestHousingEvents();
    if (_player.eventLog.length > prevLogLen) {
      pushOutcome(_player.eventLog.last);
    } else if (hadJupasPending &&
        _quarterEvents.any((e) =>
            e.id == 'dse_jupas_choice' || e.id == 'jupas_programme_pick')) {
      pushOutcome(
        '升學規劃卡已彈出——喺上面事件區揀 Foundation／JUPAS／Asso。',
      );
    } else if (hadStreamPending &&
        _quarterEvents.any((e) => e.id == 'stream_affinity')) {
      pushOutcome(
        '理文傾向卡已彈出——請揀理科定文科（影響之後中四選科）。',
      );
    } else if (hadElectivePending &&
        _quarterEvents.any((e) => e.id == 'f4_elective_pick')) {
      pushOutcome(
        '中四選科卡已彈出——喺上面事件區揀選修科。',
      );
    } else if (hadElectivePending &&
        _player.lifeStage == LifeStage.secondary &&
        _player.age < 14) {
      pushOutcome(
        '未到中三／中四選科時間——14 歲起先開。',
      );
    } else if (_quarterEvents.any((e) => e.id.startsWith('social_'))) {
      pushOutcome('社交卡已彈出——喺上面事件區揀朋友。');
    } else if (_quarterEvents.any((e) =>
        e.id.startsWith('invest_') || e.id.startsWith('housing_'))) {
      pushOutcome('投資／住屋卡已彈出——喺上面事件區繼續。');
    }
    _flushArticChooserIfNeeded();
    _checkDeath();
    await _save();
    notifyListeners();
    return true;
  }

  void _flushArticChooserIfNeeded() {
    if (_player.unlockedFlags.contains('artic_chooser_y1')) {
      _player.unlockedFlags.remove('artic_chooser_y1');
      if (AssoArticulation.canApplyYear1(_player)) {
        _quarterEvents.removeWhere((e) => e.id.startsWith('asso_artic_'));
        _quarterEvents.insert(
          0,
          AssoArticulation.applicationEvent(_player, entryYear: 1),
        );
      }
    }
    if (_player.unlockedFlags.contains('artic_chooser_y2')) {
      _player.unlockedFlags.remove('artic_chooser_y2');
      if (AssoArticulation.canApplyYear2(_player)) {
        _quarterEvents.removeWhere((e) => e.id.startsWith('asso_artic_'));
        _quarterEvents.insert(
          0,
          AssoArticulation.applicationEvent(_player, entryYear: 2),
        );
      }
    }
  }

  /// 掣／checklist 觸發後，將揀科事件卡插入本季事件
  void _flushJupasChooserIfNeeded() {
    if (_player.unlockedFlags.contains('jupas_chooser_pending')) {
      _player.unlockedFlags.remove('jupas_chooser_pending');
      _insertPostResultsPlanner();
    }
    if (_player.unlockedFlags.contains('another_bachelor_pending')) {
      _player.unlockedFlags.remove('another_bachelor_pending');
      if (UniversityLife.canApplyAnotherBachelor(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'another_bachelor');
        _quarterEvents.insert(0, UniversityLife.anotherBachelorEvent(_player));
      }
    }
    if (_player.unlockedFlags.contains('uni_society_join_pending')) {
      _player.unlockedFlags.remove('uni_society_join_pending');
      if (UniversityPathway.isStudyingBachelor(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'uni_society_join');
        _quarterEvents.insert(0, UniversitySocieties.joinEvent(_player));
      }
    }
    if (_player.unlockedFlags.contains('pt_hire_pending')) {
      _player.unlockedFlags.remove('pt_hire_pending');
      _quarterEvents.removeWhere((e) => e.id.startsWith('pt_hire'));
      _quarterEvents.insert(0, PartTimeJobs.hireEvent(_player));
    }
    if (_player.unlockedFlags.contains(CareerInternships.pendingFlag)) {
      _player.unlockedFlags.remove(CareerInternships.pendingFlag);
      _quarterEvents.removeWhere((e) => e.id.startsWith('intern_hire'));
      _quarterEvents.insert(0, CareerInternships.hireEvent(_player));
    }
    if (CareerJobHunt.hasPendingInterview(_player)) {
      _player.unlockedFlags.remove('job_interview_pending');
      _quarterEvents.removeWhere((e) => e.id.startsWith('job_interview'));
      _quarterEvents.insert(0, CareerJobHunt.interviewEvent(_player));
    }
    if (CareerJobHunt.hasPendingOffer(_player)) {
      _quarterEvents.removeWhere((e) => e.id.startsWith('job_offer'));
      _quarterEvents.insert(0, CareerJobHunt.offerEvent(_player));
    }
  }

  /// 中三理文／中四選科等待插入事件卡
  void _flushPendingSchoolEvents() {
    if (_player.unlockedFlags.contains('stream_affinity_pending')) {
      _player.unlockedFlags.remove('stream_affinity_pending');
      if (_player.lifeStage == LifeStage.secondary &&
          _player.streamAffinity == StreamAffinity.none &&
          !IbPathway.isOnTrack(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'stream_affinity');
        _quarterEvents.insert(0, _engine.streamAffinityEventPublic());
      }
    }

    if (!_player.unlockedFlags.contains('f4_elective_pick_pending')) return;
    if (_player.completedExams.contains('f4_electives') ||
        _player.lifeStage != LifeStage.secondary ||
        _player.age < 14 ||
        IbPathway.isOnTrack(_player)) {
      _player.unlockedFlags.remove('f4_elective_pick_pending');
      return;
    }
    // 未定理文：先保底再出選科卡
    if (_player.streamAffinity == StreamAffinity.none) {
      ElectiveData.ensureStreamAffinity(_player);
      pushOutcome(
        '未揀理文傾向——按智慧自動定為'
        '${_player.streamAffinity.label}（之後仍影響選科難度）。',
      );
    }
    _player.unlockedFlags.remove('f4_elective_pick_pending');
    _quarterEvents.removeWhere((e) => e.id == 'f4_elective_pick');
    _quarterEvents.insert(
      0,
      _engine.electiveSelectionEventPublic(_player),
    );
  }

  void _flushPendingSocialEvents() {
    if (_player.unlockedFlags.remove('social_hang_pending')) {
      if (_player.friends.isNotEmpty) {
        _quarterEvents.removeWhere((e) => e.id == 'social_hang_pick');
        _quarterEvents.insert(0, SocialCircle.hangOutPicker(_player));
      }
    }
    if (_player.unlockedFlags.remove('social_gift_pending')) {
      if (_player.friends.isNotEmpty) {
        _quarterEvents.removeWhere((e) => e.id == 'social_gift_pick');
        _quarterEvents.insert(0, SocialCircle.giftPicker(_player));
      }
    }
    if (_player.unlockedFlags.remove('social_confess_pending')) {
      final can = _player.friends.any(
        (f) =>
            !f.isPartner && f.affinity >= SocialCircle.confessMinAffinity,
      );
      if (can &&
          _player.age >= SocialCircle.datingMinAge &&
          !SocialCircle.isDating(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'social_confess_pick');
        _quarterEvents.insert(0, SocialCircle.confessPicker(_player));
      }
    }
  }

  void _flushPendingInvestHousingEvents() {
    if (_player.unlockedFlags.remove('invest_buy_pending')) {
      if (MarketEngine.canTrade(_player)) {
        MarketEngine.ensureInitialized(_player);
        _quarterEvents.removeWhere((e) => e.id == 'invest_buy_pick');
        _quarterEvents.insert(
          0,
          MarketEngine.assetPicker(_player, selling: false),
        );
      }
    }
    if (_player.unlockedFlags.remove('invest_sell_pending')) {
      if (MarketEngine.canTrade(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'invest_sell_pick');
        _quarterEvents.insert(
          0,
          MarketEngine.assetPicker(_player, selling: true),
        );
      }
    }
    if (_player.unlockedFlags.remove('invest_buy_amount_pending')) {
      _quarterEvents.removeWhere((e) => e.id == 'invest_buy_amount');
      _quarterEvents.insert(0, MarketEngine.buyAmountPicker(_player));
    }
    if (_player.unlockedFlags.remove('invest_sell_amount_pending')) {
      _quarterEvents.removeWhere((e) => e.id == 'invest_sell_amount');
      _quarterEvents.insert(0, MarketEngine.sellAmountPicker(_player));
    }
    if (_player.unlockedFlags.remove('housing_rent_pending')) {
      if (HousingMarket.canTransact(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'housing_rent_pick');
        _quarterEvents.insert(0, HousingMarket.rentPicker(_player));
      }
    }
    if (_player.unlockedFlags.remove('housing_buy_pending')) {
      if (HousingMarket.canTransact(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'housing_buy_pick');
        _quarterEvents.insert(0, HousingMarket.buyPicker(_player));
      }
    }
    if (_player.unlockedFlags.remove('housing_hos_buy_pending')) {
      if (HousingMarket.canTransact(_player)) {
        _quarterEvents.removeWhere((e) => e.id == 'housing_hos_buy_pick');
        _quarterEvents.insert(
          0,
          HousingMarket.buyPicker(_player, hosOnly: true),
        );
      }
    }
  }

  void clearPendingExam() {
    _pendingExam = null;
    notifyListeners();
  }

  Future<void> submitExam(ChecklistExam exam) async {
    final results = exam.evaluate(_player);
    final allMet = results.every((r) => r);

    if (allMet) {
      exam.onPass(_player);
      if (exam.id == 'primary_stream_test') {
        final school = _player.secondarySchoolName.isNotEmpty
            ? _player.secondarySchoolName
            : _player.schoolBand.secondaryLabel;
        pushOutcome(
          'SSA 統派放榜：$school\n'
          '${_player.ssaBandGroup.label} · ${_player.ssaPathway.label}\n'
          '呈分 ${_player.placementScore} · ${_player.homeDistrict.schoolNet}校網',
        );
      } else if (exam.id == 'ssr_secondary_path') {
        if (_player.unlockedFlags.contains('ssa_stay_international')) {
          pushOutcome(
            '升中路線：繼續國際\n${_player.secondarySchoolName}',
          );
        } else {
          pushOutcome('升中路線：轉入本地 SSA／DSE');
        }
      } else if (exam.id == 'f4_electives') {
        pushOutcome(
          '中四選科：${ElectiveData.electivesLabel(_player)}\n'
          '${_player.streamAffinity.label}',
        );
      } else if (exam.id == 'ib_dp_subjects') {
        pushOutcome(
          'IB DP 選科：\n${IbCurriculum.subjectsLabel(_player)}',
        );
      } else if (exam.id == 'ib_diploma') {
        pushOutcome(
          'IB Diploma 放榜：${_player.ibScore}/45\n${_player.ibTier.label}\n'
          '${IbCurriculum.subjectsLabel(_player)}',
        );
      } else if (exam.id == 'ib_university') {
        pushOutcome(
          '升學：${_player.ibUniPath.label}\n${_player.jobTitle}',
        );
      } else if (exam.id == 'dse_exam') {
        pushOutcome(
          'DSE 放榜：Best5 ${_player.dseBestScore}（${_player.dseTier.label}）\n'
          '${DseGradeGenerator.summaryLabel(_player.dseGrades)}\n'
          'GER：${JupasRequirements.gerSummary(_player)}\n'
          '考過 ${_player.dseSittingCount} 次 · 決定吓 JUPAS／重考',
        );
        if (JupasPathway.shouldShowPostResultsPlanner(_player)) {
          _insertPostResultsPlanner(dseCard: true);
          pushOutcome(
            '升學規劃卡已彈出——可揀 Foundation／Asso／JUPAS／出社會。',
          );
        } else if (FoundationPathway.canEnroll(_player)) {
          pushOutcome(
            '未達 22222：可喺「職業」分頁報讀 Foundation，'
            '或等下季升學卡再出。',
          );
        }
      } else if (exam.id == 'ssa_discretionary') {
        if (_player.secondarySchoolName.isNotEmpty) {
          pushOutcome(
            '自行分配結果：${_player.secondarySchoolName}\n'
            '${_player.ssaPathway.label}',
          );
        } else {
          pushOutcome(
            '自行分配未取錄／跳過咗\n'
            '申請：${_player.ssaDpChoices.isEmpty ? "—" : _player.ssaDpChoices}\n'
            'Q4 記得做「統一派位放榜」',
          );
        }
      } else if (CareerExams.isCareerExam(exam.id)) {
        final log = _player.eventLog.isNotEmpty ? _player.eventLog.last : '';
        pushOutcome(
          log.isNotEmpty
              ? log
              : '「${exam.title}」：已交卷。',
        );
      } else {
        pushOutcome('「${exam.title}」：條件全部齊，順利通過。');
      }
    } else {
      exam.onFail?.call(_player);
      pushOutcome('「${exam.title}」：過唔到。');
    }

    _player.clampStats();
    _pendingExam = null;
    await _save();
    notifyListeners();
  }

  Future<void> nextQuarter() async {
    if (_player.phase == GamePhase.dead) return;
    // 新一季只彈本季新結果，唔重播舊 popup
    _popupQueue.clear();

    if (_player.inPrison) {
      _player.prisonQuartersLeft--;
      if (_player.prisonQuartersLeft <= 0) {
        _player.inPrison = false;
        _player.phase = GamePhase.playing;
        _player.jobTitle = '待業';
        _player.lifeStage = LifeStage.adult;
        _player.eventLog.add('${player.year}年：刑滿出獄。');
        pushOutcome('刑滿釋放，重返社會。好多路已經永久封死。');
      }
      _advanceTime();
      _generateQuarterEvents();
      _applyQuarterlyEffects();
      _insertTaxReturnIfNeeded();
      await _save();
      notifyListeners();
      return;
    }

    _advanceTime();
    String? mainRoundMsg;
    if (JupasPathway.shouldResolveMainRoundThisQuarter(_player)) {
      mainRoundMsg = JupasPathway.resolveMainRound(_player);
      if (mainRoundMsg.isNotEmpty) {
        pushOutcome(mainRoundMsg);
      }
    }
    _generateQuarterEvents();
    // 結算季只保留一張去向卡（帶 resultMsg）；避免同 id 插兩張
    if (mainRoundMsg != null && mainRoundMsg.isNotEmpty) {
      _quarterEvents.removeWhere((e) => e.id == 'jupas_offer_decision');
      _quarterEvents.insert(
        0,
        JupasPathway.mainRoundResultEvent(_player, mainRoundMsg),
      );
    }
    _applyQuarterlyEffects();
    // Q4 報稅：出糧後再預填入息，避免漏咗今季糧／兼職
    _insertTaxReturnIfNeeded();
    await _save();
    notifyListeners();
  }

  void _insertTaxReturnIfNeeded() {
    if (!CareerTax.shouldOfferReturn(_player)) return;
    _quarterEvents.removeWhere((e) => e.id == 'career_tax_return');
    _quarterEvents.insert(0, CareerTax.returnEvent(_player));
  }

  void _advanceTime() {
    final prevAge = _player.age;
    // 離開 Q4：過門檻未報 → 逾期重罰；未過門檻未睇卡 → 淨係清入息
    if (_player.quarter == Quarter.q4 &&
        !CareerTax.alreadyFiledThisYear(_player)) {
      if (CareerTax.mustFile(_player)) {
        CareerTax.forceMissedReturn(_player);
        final msg =
            _player.eventLog.isNotEmpty ? _player.eventLog.last : null;
        if (msg != null && msg.contains('報稅')) {
          pushOutcome(msg);
        }
      } else if (CareerTax.totalActual(_player) > 0 ||
          _player.isEmployed ||
          _player.hasPartTime) {
        CareerTax.acknowledgeBelowThreshold(_player);
      }
    }
    _player.quarter = _player.quarter.next;
    if (_player.quarter == Quarter.q1) {
      _player.year++;
      _player.age++;
      BirthGacha.updateLifeStage(_player);
      if (_player.age == 6 && prevAge == 5) {
        final meet = SocialCircle.tryMeet(
              _player,
              FriendSource.classmate,
              baseChance: 0.55,
            ) ??
            SocialCircle.tryMeet(
              _player,
              FriendSource.neighbour,
              baseChance: 0.4,
            );
        pushOutcome(
          '升讀小學：${_player.jobTitle}\n'
          '${_player.primaryBand.primaryLabel} · ${_player.homeDistrict.schoolNet}校網'
          '${meet != null ? "\n\n$meet" : ""}',
        );
      }
      if (_player.age == 12 && prevAge == 11) {
        final school = _player.secondarySchoolName.isNotEmpty
            ? _player.secondarySchoolName
            : _player.schoolBand.secondaryLabel;
        final meet = SocialCircle.tryMeet(
          _player,
          FriendSource.classmate,
          baseChance: 0.5,
        );
        pushOutcome(
          '升中：$school\n'
          '${_player.ssaBandGroup.label} · ${_player.ssaPathway.label}'
          '${meet != null ? "\n\n$meet" : ""}',
        );
      }
      if (_player.age == 15 && prevAge == 14) {
        if (!IbPathway.isOnTrack(_player) &&
            _player.streamAffinity == StreamAffinity.none) {
          ElectiveData.ensureStreamAffinity(_player);
          pushOutcome(
            '中三完：未揀理文——自動定為${_player.streamAffinity.label}\n'
            '中四開始選修科會跟呢個傾向。',
          );
        }
      }
      if (_player.age == 16 && prevAge == 15) {
        if (_player.lifeStage == LifeStage.secondary &&
            _player.education.index < EducationLevel.f5.index) {
          _player.education = EducationLevel.f5;
        }
        if (!_player.completedExams.contains('f4_electives') &&
            !IbPathway.isOnTrack(_player)) {
          ElectiveData.finalize(_player, forceMinimum: true);
          pushOutcome(
            '中四選科截止：${ElectiveData.electivesLabel(_player)}',
          );
        }
      }
      if (_player.age == 17 && prevAge == 16) {
        if (IbPathway.isOnTrack(_player) &&
            !_player.completedExams.contains('ib_dp_subjects')) {
          IbCurriculum.autoSelectPackage(_player);
          pushOutcome(
            'DP 選科截止：\n${IbCurriculum.subjectsLabel(_player)}',
          );
        }
      }
      if (_player.age == 18 && prevAge == 17) {
        // IB：若未考 Diploma，自動補考（避免卡死）
        if (IbPathway.isOnTrack(_player) &&
            !_player.completedExams.contains('ib_diploma')) {
          final msg = IbPathway.applyDiplomaResult(_player);
          pushOutcome('IB 補考放榜：\n$msg');
        }
        // DSE：首次必考 — 18 歲仍未考則自動補考
        if (JupasPathway.isLocalTrack(_player) &&
            _player.dseSittingCount == 0) {
          final msg = JupasPathway.applySitting(_player);
          pushOutcome('DSE 補考放榜：\n$msg');
        }
        pushOutcome('成年了：${_player.jobTitle}');
      }
      if (_player.age == 19 && prevAge == 18) {
        // IB：未選升學 → 強制派本地非聯招／Foundation
        if (IbPathway.isOnTrack(_player) &&
            _player.completedExams.contains('ib_diploma') &&
            !_player.completedExams.contains('ib_university')) {
          final path = _player.ibTier == IbTier.fail
              ? IbUniPath.foundation
              : IbUniPath.localNonJupas;
          final msg = IbPathway.applyUniversityChoice(_player, path);
          pushOutcome('升學截止自動派位：\n$msg');
        }
        // DSE 重讀一年結束仍未考 → 自動第二次（唔強逼聯招）
        if (JupasPathway.isLocalTrack(_player) &&
            JupasPathway.isRetaking(_player) &&
            _player.dseSittingCount == 1) {
          final msg = JupasPathway.applySitting(_player);
          pushOutcome('DSE 重考自動放榜：\n$msg');
        }
      }
    }
    _player.refreshActionPoints();
    _player.eventLog.add('${_player.year}年 ${_player.quarterLabel} · ${_player.age}歲');
  }

  void _applyQuarterlyEffects() {
    MarketEngine.ensureInitialized(_player);

    // Housing costs (adult / 18+)
    final housingMsg = HousingMarket.tickQuarter(_player);
    if (housingMsg != null && housingMsg.isNotEmpty) {
      pushOutcome(housingMsg);
    }

    // 投資市況
    final marketMsg = MarketEngine.tickQuarter(_player);
    if (marketMsg != null && marketMsg.isNotEmpty) {
      pushOutcome(marketMsg);
    }

    if (_player.lifeStage == LifeStage.adult) {
      if (_player.isEmployed) {
        // 有返工先出糧；冇返工照樣走 applyPayroll（表現罰）
        final payMsg = CareerEmployment.applyPayroll(_player);
        if (payMsg != null && payMsg.isNotEmpty) {
          pushOutcome(payMsg);
        }
        _player.jobWorkedThisQuarter = false;
      } else {
        // 失業都可能有強積金投資回報
        final inv = CareerEmployment.tickMpfInvestment(_player);
        if (inv != null && inv.isNotEmpty) {
          pushOutcome(inv);
        }
      }
    }

    // 零用钱 — 18 岁前、同住、每季不一定有
    if (_player.livesWithFamily && _player.age < 18) {
      if (FamilyAssets.shouldReceiveAllowance(_player)) {
        final allowance = FamilyAssets.quarterlyAllowanceAmount(_player);
        if (allowance > 0) {
          _player.wealth += allowance;
          pushOutcome(
            '${_player.quarterLabel}：阿爸阿媽俾咗 \$$allowance 零用錢',
          );
        }
      }
    }

    // R 兒童綜援：每季入帳／續期／資產上限檢查
    final cssaMsg = CssaWelfare.tickQuarter(_player);
    if (cssaMsg != null && cssaMsg.isNotEmpty) {
      pushOutcome(cssaMsg);
    }

    // 社交：拍拖智慧扣／疏離
    final socialMsg = SocialCircle.tickQuarter(_player);
    if (socialMsg != null && socialMsg.isNotEmpty) {
      pushOutcome(socialMsg);
    }

    // 新年 Q1 利是 — 随机 range
    if (_player.quarter == Quarter.q1 && _player.livesWithFamily) {
      final laiSee = FamilyAssets.rollLaiSee(_player);
      if (laiSee != null && laiSee > 0) {
        _player.wealth += laiSee;
        pushOutcome('新年利是：收到 \$$laiSee（${FamilyAssets.laiSeeRangeLabel(_player)}）');
        _player.eventLog.add('${_player.year}年：新年利是 \$$laiSee');
      }
    }

    if (_player.isChildhood) {
      if (_player.lifeStage == LifeStage.primary) {
        BirthGacha.applyPrimaryQuarterlyEffects(_player);
      }
      _applySchoolBandEffects();
      if (_player.birthTier == BirthTier.r) {
        _player.san = (_player.san - 2).clamp(0, _player.maxSan);
        _player.stress = (_player.stress + 1).clamp(0, 100);
        _player.familyWealth =
            (_player.familyWealth - 200).clamp(0, 999999999);
      }
    }

    // Foundation：每季推進；滿一年 Pass＝視同 22222
    final foundMsg = FoundationPathway.tickQuarter(_player);
    if (foundMsg != null && foundMsg.isNotEmpty) {
      pushOutcome(foundMsg);
      if (FoundationPathway.hasPassed(_player) &&
          JupasPathway.shouldShowPostResultsPlanner(_player)) {
        _insertPostResultsPlanner();
      }
    }

    // 副學士：每季推進；滿一年升 Year 2／畢業
    final articMsg = AssoArticulation.tickQuarter(_player);
    if (articMsg != null && articMsg.isNotEmpty) {
      pushOutcome(articMsg);
      if (AssoArticulation.canApplyYear2(_player) ||
          AssoArticulation.canApplyYear1(_player)) {
        final year = AssoArticulation.canApplyYear2(_player) ? 2 : 1;
        _quarterEvents.removeWhere((e) => e.id.startsWith('asso_artic_'));
        _quarterEvents.insert(
          0,
          AssoArticulation.applicationEvent(_player, entryYear: year),
        );
      }
    }

    final uniMsg = UniversityPathway.tickQuarter(_player);
    if (uniMsg != null && uniMsg.isNotEmpty) {
      pushOutcome(uniMsg);
    }

    CareerData.tickQuarter(_player);

    final probationMsg = CareerEmployment.tickProbation(_player);
    if (probationMsg != null && probationMsg.isNotEmpty) {
      pushOutcome(probationMsg);
    }
    final appraisalMsg = CareerGov.tickAppraisal(_player);
    if (appraisalMsg != null && appraisalMsg.isNotEmpty) {
      pushOutcome(appraisalMsg);
    }
    final payReviewMsg = CareerGov.tickAnnualPay(_player);
    if (payReviewMsg != null && payReviewMsg.isNotEmpty) {
      pushOutcome(payReviewMsg);
    }

    final fireMsg = CareerEvents.maybeFireForPerformance(_player);
    if (fireMsg != null && fireMsg.isNotEmpty) {
      pushOutcome(fireMsg);
    }

    final ptMsg = PartTimeJobs.tickQuarter(_player);
    if (ptMsg != null && ptMsg.isNotEmpty) {
      pushOutcome(ptMsg);
    }

    final internMsg = CareerInternships.tickQuarter(_player);
    if (internMsg != null && internMsg.isNotEmpty) {
      pushOutcome(internMsg);
    }

    _player.hp = (_player.hp - 1).clamp(0, _player.maxHp);
    if (_player.stress > 50) {
      _player.san = (_player.san - 2).clamp(0, _player.maxSan);
    }

    _player.clampStats();
    _checkDeath();
  }

  void _applySchoolBandEffects() {
    if (_player.lifeStage != LifeStage.secondary) return;
    switch (_player.schoolBand) {
      case SchoolBand.band1:
        _player.smarts = (_player.smarts + 1).clamp(0, 100);
        _player.san = (_player.san - 3).clamp(0, _player.maxSan);
      case SchoolBand.band2:
        break;
      case SchoolBand.band3:
        _player.network = (_player.network + 1).clamp(0, 100);
      case SchoolBand.none:
        break;
    }
  }

  // ── Action builders ──

  List<ActionButton> _conditionalExams() {
    final p = _player;
    final buttons = _engine.eligibleExams(p).where((exam) {
      return exam.id != 'dse_exam';
    }).map((exam) {
      return ActionButton(
        label: '【季度】${exam.title}',
        apCost: 2,
        isConditional: true,
        opensChecklistId: exam.id,
        onExecute: (_) {},
      );
    }).toList();

    if (JupasPathway.shouldShowDseExamEntry(p)) {
      final dseExam = _engine
          .allExams(p)
          .where((e) => e.id == 'dse_exam')
          .firstOrNull;
      if (dseExam != null) {
        final ready = dseExam.evaluate(p).every((r) => r);
        buttons.insert(
          0,
          ActionButton(
            label: JupasPathway.dseExamEntryLabel(p),
            apCost: ready ? 2 : 0,
            isConditional: true,
            opensChecklistId: 'dse_exam',
            onExecute: (_) {},
          ),
        );
      }
    }

    return buttons;
  }

  List<ActionButton> getCareerActions() {
    final p = _player;
    final buttons = <ActionButton>[..._conditionalExams()];

    // ── School phase (0-18) ──
    if (p.isInSchool) {
      buttons.addAll([
        ActionButton(
          label: '勤力溫書',
          apCost: 1,
          onExecute: (pl) {
            BirthGacha.applyStudyGain(pl);
            pl.discipline = (pl.discipline + 2).clamp(0, 100);
            if (pl.lifeStage == LifeStage.primary) {
              pl.primaryScore += pl.primaryBand == SchoolBand.band1 ? 1 : 0;
            }
          },
        ),
        ActionButton(
          label: '蛇王',
          apCost: 1,
          onExecute: (pl) {
            pl.san = (pl.san + 5).clamp(0, pl.maxSan);
            pl.discipline = (pl.discipline - 2).clamp(0, 100);
          },
        ),
      ]);

      if (p.unlockedFlags.contains('specialized_cram_school')) {
        buttons.add(ActionButton(
          label: '優質補習（屋企代付）',
          apCost: 2,
          onExecute: (pl) {
            if (pl.wealth >= 5000) {
              pl.wealth -= 5000;
              BirthGacha.applyStudyGain(pl, base: 6);
              pl.primaryScore += 2;
            } else if (FamilyAssets.familyPays(pl, 8000, reason: '補習社學費')) {
              BirthGacha.applyStudyGain(pl, base: 6);
              pl.primaryScore += 2;
            }
          },
        ));
      }

      if (p.livesWithFamily && p.age < 18) {
        buttons.add(ActionButton(
          label: '問阿爸阿媽加零用錢',
          apCost: 1,
          onExecute: (pl) {
            if (pl.age >= 18) return;
            final bonus = switch (pl.birthTier) {
              BirthTier.ssr => 8000,
              BirthTier.sr => 2000,
              BirthTier.r => 300,
            };
            if (FamilyAssets.requestFromFamily(pl, bonus, reason: '加碼零用錢')) {
              pl.stress = (pl.stress + 2).clamp(0, 100);
            } else {
              pl.san = (pl.san - 3).clamp(0, pl.maxSan);
            }
          },
        ));
      }

      if (p.lifeStage == LifeStage.primary) {
        buttons.add(ActionButton(
          label: '課外活動',
          apCost: 1,
          onExecute: (pl) {
            pl.san = (pl.san + 4).clamp(0, pl.maxSan);
            pl.network = (pl.network + 2).clamp(0, 100);
            pl.hp = (pl.hp + 2).clamp(0, pl.maxHp);
            SocialCircle.tryMeet(
              pl,
              FriendSource.classmate,
              baseChance: 0.4,
            );
          },
        ));
        buttons.add(ActionButton(
          label: '溫呈分／做練習（多呈分，傷神智）',
          apCost: 2,
          onExecute: (pl) {
            BirthGacha.applyStudyGain(pl, base: 4, harsh: true);
            SocialCircle.markHarshStudy(pl);
            pl.primaryScore += pl.age >= 9 ? 3 : 2;
            pl.discipline = (pl.discipline + 1).clamp(0, 100);
          },
        ));
      }

      if (p.lifeStage == LifeStage.secondary) {
        buttons.add(ActionButton(
          label: '社團／校隊',
          apCost: 1,
          onExecute: (pl) {
            pl.network = (pl.network + 4).clamp(0, 100);
            pl.san = (pl.san + 3).clamp(0, pl.maxSan);
            pl.discipline = (pl.discipline + 1).clamp(0, 100);
            SocialCircle.tryMeet(
              pl,
              FriendSource.club,
              baseChance: 0.45,
            );
          },
        ));
        if (p.age >= 15) {
          buttons.add(ActionButton(
            label: '做 Past Paper（傷神智）',
            apCost: 2,
            onExecute: (pl) {
              BirthGacha.applyStudyGain(pl, base: 5, harsh: true);
              SocialCircle.markHarshStudy(pl);
              pl.discipline = (pl.discipline + 2).clamp(0, 100);
            },
          ));
        }
        if (p.age >= 16 && !IbPathway.isOnTrack(p)) {
          buttons.add(ActionButton(
            label: '報補習班（DSE）',
            apCost: 2,
            onExecute: (pl) {
              final cost = 6000;
              if (pl.wealth >= cost) {
                pl.wealth -= cost;
              } else if (!FamilyAssets.familyPays(pl, cost, reason: 'DSE 補習')) {
                pl.san = (pl.san - 2).clamp(0, pl.maxSan);
                pl.eventLog.add('${pl.year}年：補習費唔夠，報唔到');
                return;
              }
              BirthGacha.applyStudyGain(pl, base: 6, harsh: true);
              SocialCircle.markHarshStudy(pl);
              pl.eventLog.add('${pl.year}年：報咗 DSE 補習班');
              SocialCircle.tryMeet(
                pl,
                FriendSource.classmate,
                baseChance: 0.25,
              );
            },
          ));
        }
        // 中三：理文傾向（必見）
        if (p.age == 14 &&
            !IbPathway.isOnTrack(p) &&
            p.streamAffinity == StreamAffinity.none) {
          buttons.add(ActionButton(
            label: '★ 中三：揀理科定文科',
            apCost: 1,
            isConditional: true,
            onExecute: (pl) {
              pl.unlockedFlags.add('stream_affinity_pending');
            },
          ));
        }
        // 中三尾／中四：選科（14–15 歲）
        if (p.age >= 14 &&
            p.age <= 15 &&
            !IbPathway.isOnTrack(p) &&
            !p.completedExams.contains('f4_electives')) {
          buttons.add(ActionButton(
            label: p.electiveIds.isEmpty
                ? '★ 中四選科（開選課卡）'
                : '★ 中四選科（${ElectiveData.electivesLabel(p)}）',
            apCost: 1,
            isConditional: true,
            onExecute: (pl) {
              pl.unlockedFlags.add('f4_elective_pick_pending');
            },
          ));
        }
      }

      return buttons;
    }

    // ── Infant (0-5) ──
    if (p.lifeStage == LifeStage.infant) {
      buttons.addAll([
        ActionButton(
          label: '玩玩具／探索',
          apCost: 1,
          onExecute: (pl) {
            pl.san = (pl.san + 4).clamp(0, pl.maxSan);
            pl.smarts = (pl.smarts + 1).clamp(0, 100);
          },
        ),
        ActionButton(
          label: '聽故事／學嘢',
          apCost: 1,
          onExecute: (pl) {
            pl.smarts = (pl.smarts + 2).clamp(0, 100);
            if (pl.age >= 4) pl.primaryScore += 1;
          },
        ),
        ActionButton(
          label: '去公園放電',
          apCost: 1,
          onExecute: (pl) {
            pl.san = (pl.san + 3).clamp(0, pl.maxSan);
            pl.hp = (pl.hp + 2).clamp(0, pl.maxHp);
            pl.network = (pl.network + 1).clamp(0, 100);
          },
        ),
        ActionButton(
          label: '同阿媽阿爸玩',
          apCost: 1,
          onExecute: (pl) {
            pl.san = (pl.san + 4).clamp(0, pl.maxSan);
            pl.network = (pl.network + 2).clamp(0, 100);
            pl.stress = (pl.stress - 2).clamp(0, 100);
          },
        ),
      ]);

      if (p.age >= 4) {
        buttons.add(ActionButton(
          label: '幫手做簡單家務',
          apCost: 1,
          onExecute: (pl) {
            pl.discipline = (pl.discipline + 3).clamp(0, 100);
            pl.network = (pl.network + 1).clamp(0, 100);
            pl.san = (pl.san - 1).clamp(0, pl.maxSan);
          },
        ));
      }

      if (p.birthTier != BirthTier.r || p.age >= 3) {
        buttons.add(ActionButton(
          label: p.birthTier == BirthTier.ssr
              ? 'Playgroup／會所活動'
              : '報興趣班試堂',
          apCost: 2,
          onExecute: (pl) {
            final cost = switch (pl.birthTier) {
              BirthTier.ssr => 8000,
              BirthTier.sr => 3500,
              BirthTier.r => 1200,
            };
            if (FamilyAssets.familyPays(pl, cost, reason: '幼兒興趣班')) {
              pl.smarts = (pl.smarts + 3).clamp(0, 100);
              pl.network = (pl.network + 2).clamp(0, 100);
              pl.discipline = (pl.discipline + 1).clamp(0, 100);
            } else {
              pl.san = (pl.san - 2).clamp(0, pl.maxSan);
              pl.eventLog.add('${pl.year}年：興趣班費唔夠／屋企唔批');
            }
          },
        ));
      }

      if (p.livesWithFamily) {
        buttons.add(ActionButton(
          label: '撒嬌問零用',
          apCost: 1,
          onExecute: (pl) {
            final bonus = switch (pl.birthTier) {
              BirthTier.ssr => 1500,
              BirthTier.sr => 400,
              BirthTier.r => 80,
            };
            if (FamilyAssets.requestFromFamily(pl, bonus, reason: '幼兒零用')) {
              pl.stress = (pl.stress + 1).clamp(0, 100);
            } else {
              pl.san = (pl.san - 2).clamp(0, pl.maxSan);
            }
          },
        ));
      }

      return buttons;
    }

    // ── Adult career ──
    if (p.isEmployed) {
      buttons.addAll(CareerData.employedActions(p));
      buttons.add(ActionButton(
        label: '辭工',
        apCost: 1,
        onExecute: (pl) {
          CareerData.quitJob(pl);
          pl.san = (pl.san + 8).clamp(0, pl.maxSan);
        },
      ));
    }

    if (p.isStudying && p.lifeStage == LifeStage.adult) {
      if (UniversityPathway.isStudyingBachelor(p)) {
        buttons.addAll(UniversityLife.studyButtons());
      } else {
        buttons.add(
          ActionButton(
            label: FoundationPathway.isStudying(p)
                ? '勤力溫書（Foundation）'
                : p.education == EducationLevel.associate
                    ? '勤力溫書（提升 GPA）'
                    : '勤力溫書',
            apCost: 1,
            onExecute: (pl) {
              if (FoundationPathway.isStudying(pl)) {
                FoundationPathway.studyAction(pl);
              } else if (pl.education == EducationLevel.associate) {
                AssoArticulation.studyAction(pl);
              } else {
                BirthGacha.applyStudyGain(pl, base: 4);
                pl.san = (pl.san - 3).clamp(0, pl.maxSan);
              }
            },
          ),
        );
      }
      buttons.addAll([
        if (AssoArticulation.canApplyYear1(p))
          ActionButton(
            label: '申請 Non-JUPAS Year 1（睇 GPA）',
            apCost: 2,
            onExecute: (pl) {
              pl.unlockedFlags.add('artic_chooser_y1');
            },
          ),
        if (AssoArticulation.canApplyYear2(p))
          ActionButton(
            label: '申請 Non-JUPAS Year 2 銜接（睇 GPA）',
            apCost: 2,
            onExecute: (pl) {
              pl.unlockedFlags.add('artic_chooser_y2');
            },
          ),
        ActionButton(
          label: '退學唔讀',
          apCost: 1,
          onExecute: (pl) {
            if (FoundationPathway.isStudying(pl)) {
              FoundationPathway.dropOut(pl);
              return;
            }
            if (UniversityPathway.isStudyingBachelor(pl)) {
              pl.eventLog.add(
                UniversityLife.leaveWithoutGraduate(
                  pl,
                  reason: '自行退學唔讀',
                ),
              );
              return;
            }
            pl.isStudying = false;
            pl.currentSector = CareerSector.none;
            pl.jobTitle = '待業';
            pl.studyProgram = '';
            pl.completedExams.remove('jupas');
            if (pl.jupasPath == JupasPath.bachelor ||
                pl.jupasPath == JupasPath.associate) {
              pl.jupasPath = JupasPath.none;
            }
          },
        ),
      ]);
    }

    // 副學士已畢業、未升學
    if (!p.isStudying &&
        p.education == EducationLevel.associate &&
        AssoArticulation.canApplyYear2(p)) {
      buttons.add(ActionButton(
        label: '申請 Non-JUPAS Year 2 銜接（GPA ${p.assoGpa}）',
        apCost: 2,
        onExecute: (pl) {
          pl.unlockedFlags.add('artic_chooser_y2');
        },
      ));
    }

    _addEducationReentryButtons(buttons, p);

    if (!p.isEmployed && !p.isStudying && p.lifeStage == LifeStage.adult) {
      buttons.add(ActionButton(
        label: '私人技能進修（自費）',
        apCost: 2,
        onExecute: (pl) {
          if (pl.wealth >= 15000) {
            pl.wealth -= 15000;
            BirthGacha.applyStudyGain(pl, base: 6);
            pl.network = (pl.network + 2).clamp(0, 100);
          }
        },
      ));
    }

    _addCareerEntryButtons(buttons, p);
    return buttons;
  }

  /// 讀完／出社會後：再進修入口（事件卡／生活 tab；DSE 考試季由【季度】checklist 提供）
  void _addEducationReentryButtons(List<ActionButton> buttons, Player p) {
    if (p.lifeStage != LifeStage.adult || p.age < 18) return;
    if (IbPathway.isOnTrack(p)) return;
    if (p.isStudying &&
        p.education.index >= EducationLevel.bachelor.index) {
      return;
    }

    // 非考試季：提示仍可再考（實際入口喺 Q3/Q4 嘅【季度】DSE）
    if (!JupasPathway.canSitDse(p) &&
        !p.isStudying &&
        (JupasPathway.hasSatDse(p) || JupasPathway.isLocalTrack(p))) {
      buttons.add(ActionButton(
        label: 'DSE 自修生：等 Q3/Q4 考試季',
        apCost: 0,
        isConditional: true,
        onExecute: (pl) {
          pl.eventLog.add(
            '${pl.year}年：DSE 自修生報考只喺 Q3/Q4 開放'
            '（報名費 \$${JupasPathway.privateCandidateFee}）。',
          );
        },
      ));
    }

    if (JupasPathway.shouldShowPostResultsPlanner(p)) {
      final inSeason = JupasPathway.isJupasChoiceWindow(p) ||
          JupasPathway.isAwaitingMainRound(p);
      buttons.add(ActionButton(
        label: p.isEmployed
            ? '★ 辭工並處理 JUPAS／Asso'
            : (JupasPathway.isAwaitingMainRound(p)
                ? '★ 兩手準備（Asso 留位／等結果）'
                : !inSeason && JupasPathway.isDeferred(p)
                    ? '★ 升學：等 Q4／Q1 再開 JUPAS'
                    : JupasPathway.canApplyFoundation(p) &&
                            !JupasPathway.hasAssoGer(p)
                        ? '★ 升學：Foundation／Asso／JUPAS'
                        : JupasPathway.isJupasLateSeason(p)
                            ? '★ 報 JUPAS／Asso（逾期窗 Q1）'
                            : JupasPathway.isJupasFormalSeason(p)
                                ? '★ 報 JUPAS／Asso（正式報名 Q4）'
                                : '★ 報 JUPAS／Asso（交志願）'),
        apCost: 2,
        isConditional: true,
        onExecute: (pl) {
          if (pl.isEmployed) {
            CareerData.quitJob(pl);
          }
          pl.unlockedFlags.add('jupas_chooser_pending');
        },
      ));
    } else if (FoundationPathway.canEnroll(p)) {
      buttons.add(ActionButton(
        label:
            '★ 報讀 Foundation（\$${FoundationPathway.fee} · 未達 22222）',
        apCost: 2,
        isConditional: true,
        onExecute: (pl) {
          final msg = FoundationPathway.enroll(
            pl,
            source: 'DSE 未達 22222',
          );
          pl.eventLog.add(msg);
        },
      ));
    } else if (JupasPathway.isDeferred(p) &&
        JupasPathway.hasSatDse(p) &&
        !JupasPathway.isInJupasApplicationSeason(p)) {
      buttons.add(ActionButton(
        label: 'JUPAS：等 Q4 正式／Q1 逾期窗',
        apCost: 0,
        onExecute: (pl) {
          pl.eventLog.add(
            '${pl.year}年：${JupasPathway.jupasSeasonLabel(pl)}。'
            '下屆可報聯招。',
          );
        },
      ));
    }

    // 畢業／退學／輟學後：再讀學士（Non-JUPAS；有 DSE 亦可等 Q4／Q1 走 JUPAS）
    if (UniversityLife.canApplyAnotherBachelor(p)) {
      buttons.add(ActionButton(
        label: p.unlockedFlags.contains('bachelor_graduated')
            ? '再讀一個學士（Non-JUPAS）'
            : '再入讀學士（Non-JUPAS）',
        apCost: 2,
        onExecute: (pl) {
          if (pl.isEmployed) CareerData.quitJob(pl);
          pl.unlockedFlags.add('another_bachelor_pending');
        },
      ));
    }
  }

  void _addCareerEntryButtons(List<ActionButton> buttons, Player p) {
    if (p.isStudying) return;
    if (p.lifeStage != LifeStage.adult) return;
    if (p.isEmployed) return;
    if (CareerJobHunt.hasPendingInterview(p) ||
        CareerJobHunt.hasPendingOffer(p)) {
      return;
    }

    void addIf(
      CareerSector sector,
      String label, {
      int ap = 1,
      String employer = '',
      bool prestige = false,
    }) {
      if (!CareerData.canEnter(p, sector)) return;
      final seasonBlock = CareerHiringSeasons.blockReason(
        p,
        sector,
        prestige: prestige,
      );
      final soft = CareerHiringSeasons.isOffPeakSoft(
        p,
        sector,
        prestige: prestige,
      );
      final seasonTag = seasonBlock != null
          ? '（非旺季：${CareerHiringSeasons.peakHint(sector)}）'
          : soft
              ? '（淡季）'
              : '';
      buttons.add(ActionButton(
        label: '$label$seasonTag',
        apCost: ap,
        enabled: seasonBlock == null,
        onExecute: (pl) {
          pl.eventLog.add(
            CareerJobHunt.apply(
              pl,
              sector,
              employer: employer,
              prestige: prestige,
            ),
          );
        },
      ));
    }

    addIf(CareerSector.labour, '應徵餐廳／零售／地盤');
    addIf(
      CareerSector.insurance,
      UniversitySocieties.wasInInvestment(p)
          ? '應徵保險 Agent（投資學會背景）'
          : '應徵保險 Agent',
      employer: 'AIA',
    );
    addIf(CareerSector.realEstate, '應徵地產代理（中原／美聯）', employer: '中原');
    addIf(
      CareerSector.flightAttendant,
      '應徵國泰空服',
      ap: 2,
      employer: '國泰 Cathay',
    );
    addIf(CareerSector.medical, '應徵 HA 實習醫生', ap: 2, employer: 'HA');

    // 公務員部門＋紀律部隊分位（CareerGov）
    if (!p.isStudying && !p.isEmployed) {
      for (final post in CareerGov.posts) {
        final req = CareerGov.blockReason(p, post);
        final season = CareerGov.seasonBlock(p, post);
        final soft = CareerGov.seasonSoft(p, post);
        final tag = season != null
            ? '（非招募期）'
            : soft
                ? '（淡季）'
                : '';
        buttons.add(ActionButton(
          label: req == null
              ? '應徵${post.deptZh}｜${post.entryTitleZh}$tag'
              : '應徵${post.entryTitleZh}（未夠條件）',
          apCost: 2,
          enabled: req == null && season == null,
          onExecute: (pl) {
            final b = CareerGov.blockReason(pl, post);
            if (b != null) {
              pl.eventLog.add('${pl.year}年：應徵唔到 — $b');
              return;
            }
            final sb = CareerGov.seasonBlock(pl, post);
            if (sb != null) {
              pl.eventLog.add('${pl.year}年：應徵唔到 — $sb');
              return;
            }
            final msg = CareerJobHunt.apply(
              pl,
              post.sector,
              employer: CareerGov.taggedEmployer(post),
              prestige: post.id == 'ao' ||
                  post.id == 'police_ip' ||
                  post.id == 'icac_inv',
              bypassSeason: true,
            );
            if (CareerGov.seasonSoft(pl, post)) {
              pl.unlockedFlags.add(CareerHiringSeasons.offPeakFlag);
            }
            pl.eventLog.add(msg);
          },
        ));
      }
    }

    addIf(CareerSector.entertainment, '應徵 TVB 訓練班', ap: 2, employer: 'TVB');
    addIf(CareerSector.taxi, '開始做的士', ap: 2);
    addIf(CareerSector.legalBarrister, '應徵大律師 Pupillage', ap: 2);
    addIf(CareerSector.legalSolicitor, '應徵事務律師 Trainee', ap: 2);
    addIf(
      CareerSector.pharmacy,
      p.unlockedFlags.contains('pharm_degree') ||
              p.unlockedFlags.contains('grad_pharmacy')
          ? '應徵註冊藥劑師'
          : '應徵藥劑師助理',
      ap: 2,
    );
    addIf(
      CareerSector.politics,
      UniversitySocieties.wasInSu(p)
          ? '應徵從政（議員助理 · 學生會背景）'
          : '應徵從政（議員助理）',
      ap: 2,
    );
    addIf(
      CareerSector.socialWork,
      p.unlockedFlags.contains('social_degree') ||
              p.unlockedFlags.contains('grad_social')
          ? '應徵社福（ASWO）'
          : '應徵社福（SWA）',
      ap: 2,
    );
    addIf(
      CareerSector.teaching,
      p.unlockedFlags.contains('education_degree') ||
              p.unlockedFlags.contains('grad_education')
          ? '應徵學位教師'
          : '應徵教學助理（TA）',
      ap: 2,
    );
    addIf(CareerSector.nursing, '應徵 HA 護理', ap: 2, employer: 'HA');
    addIf(CareerSector.banking, '應徵銀行', ap: 2, employer: '中銀香港');
    addIf(CareerSector.accounting, '應徵審計／會計', ap: 2, employer: '本地事務所');
    addIf(CareerSector.it, '應徵 IT／科網', ap: 2, employer: '本地初創');
    addIf(
      CareerSector.media,
      UniversitySocieties.wasInEditorial(p)
          ? '應徵傳媒（編委背景）'
          : '應徵傳媒／新聞',
      ap: 2,
    );

    if (CareerData.canEnter(p, CareerSector.banking)) {
      final seasonBlock = CareerHiringSeasons.blockReason(
        p,
        CareerSector.banking,
        prestige: true,
      );
      buttons.add(ActionButton(
        label: seasonBlock == null
            ? '搏名企銀行面試（滙豐等）'
            : '搏名企銀行（秋招 Q3–Q4）',
        apCost: 3,
        enabled: seasonBlock == null,
        onExecute: (pl) {
          pl.eventLog.add(
            CareerJobHunt.apply(
              pl,
              CareerSector.banking,
              employer: '滙豐 HSBC',
              prestige: true,
            ),
          );
        },
      ));
    }
    if (CareerData.canEnter(p, CareerSector.accounting)) {
      final seasonBlock = CareerHiringSeasons.blockReason(
        p,
        CareerSector.accounting,
        prestige: true,
      );
      buttons.add(ActionButton(
        label: seasonBlock == null ? '搏四大面試' : '搏四大（秋招 Q3–Q4）',
        apCost: 3,
        enabled: seasonBlock == null,
        onExecute: (pl) {
          final firm = ['PwC', 'Deloitte', 'EY', 'KPMG'][Random().nextInt(4)];
          pl.eventLog.add(
            CareerJobHunt.apply(
              pl,
              CareerSector.accounting,
              employer: firm,
              prestige: true,
            ),
          );
        },
      ));
    }
    if (CareerData.canEnter(p, CareerSector.it)) {
      final soft = CareerHiringSeasons.isOffPeakSoft(
        p,
        CareerSector.it,
        prestige: true,
      );
      buttons.add(ActionButton(
        label: soft ? '搏 Google／Microsoft（淡季）' : '搏 Google／Microsoft 面試',
        apCost: 3,
        onExecute: (pl) {
          pl.eventLog.add(
            CareerJobHunt.apply(
              pl,
              CareerSector.it,
              employer: Random().nextBool() ? 'Google' : 'Microsoft HK',
              prestige: true,
            ),
          );
        },
      ));
    }
  }

  List<ActionButton> getAssetActions() {
    final p = _player;
    final buttons = <ActionButton>[..._conditionalExams()];

    // ── 年齡閘：投資／置業 ≥18 ──
    if (p.age < MarketEngine.minAge) {
      buttons.add(ActionButton(
        label: '投資／置業：滿 ${MarketEngine.minAge} 歲先可以',
        apCost: 0,
        onExecute: (pl) {
          pl.eventLog.add(
            '${pl.year}年：未滿 ${MarketEngine.minAge} 歲——'
            '唔可以投資、租樓、申請公屋／居屋或買樓。',
          );
        },
      ));
    } else {
      MarketEngine.ensureInitialized(p);

      // 住屋階梯
      buttons.add(ActionButton(
        label: '住屋：${HousingMarket.housingStatusLabel(p)}',
        apCost: 0,
        onExecute: (pl) {
          pl.eventLog.add(
            '${pl.year}年：${HousingMarket.housingStatusLabel(pl)}',
          );
        },
      ));

      if (!p.ownsFlat) {
        buttons.add(ActionButton(
          label: '搬出／租私樓',
          apCost: 1,
          onExecute: (pl) {
            pl.unlockedFlags.add('housing_rent_pending');
          },
        ));
        if (p.housingType != HousingType.publicHousing &&
            !p.unlockedFlags.contains('prh_waiting')) {
          buttons.add(ActionButton(
            label: '申請公屋',
            apCost: 2,
            onExecute: (pl) {
              pl.eventLog.add(HousingMarket.startPublicHousingWait(pl));
            },
          ));
        } else if (p.unlockedFlags.contains('prh_waiting')) {
          buttons.add(ActionButton(
            label: '公屋輪候中（已等 ${p.publicHousingWaitQuarters} 季）',
            apCost: 0,
            onExecute: (pl) {
              pl.eventLog.add(
                '${pl.year}年：公屋輪候中（${pl.publicHousingWaitQuarters} 季）。',
              );
            },
          ));
        }
        buttons.add(ActionButton(
          label: '申請居屋抽籤',
          apCost: 2,
          onExecute: (pl) {
            pl.eventLog.add(HousingMarket.ballotHos(pl));
            if (pl.unlockedFlags.contains('hos_offer_pending')) {
              pl.unlockedFlags.add('housing_hos_buy_pending');
            }
          },
        ));
        if (p.unlockedFlags.contains('hos_offer_pending')) {
          buttons.add(ActionButton(
            label: '★ 確認買居屋（已抽中）',
            apCost: 1,
            isConditional: true,
            onExecute: (pl) {
              pl.unlockedFlags.add('housing_hos_buy_pending');
            },
          ));
        }
        buttons.add(ActionButton(
          label: '睇樓／買私樓（或居屋）',
          apCost: 1,
          onExecute: (pl) {
            pl.unlockedFlags.add('housing_buy_pending');
          },
        ));
      } else {
        buttons.add(ActionButton(
          label: '加按套現',
          apCost: 2,
          onExecute: (pl) {
            pl.eventLog.add(HousingMarket.refinance(pl));
          },
        ));
        buttons.add(ActionButton(
          label: '賣樓',
          apCost: 2,
          onExecute: (pl) {
            pl.eventLog.add(HousingMarket.sell(pl));
          },
        ));
      }

      // 投資 12 資產
      buttons.add(ActionButton(
        label: '投資：${MarketEngine.statusSummary(p)}',
        apCost: 0,
        onExecute: (pl) {
          MarketEngine.ensureInitialized(pl);
          pl.eventLog.add('${pl.year}年：${MarketEngine.statusSummary(pl)}');
        },
      ));
      buttons.add(ActionButton(
        label: '買入股票／ETF／加密',
        apCost: 1,
        onExecute: (pl) {
          pl.unlockedFlags.add('invest_buy_pending');
        },
      ));
      if (p.holdings.any((h) => h.units > 0)) {
        buttons.add(ActionButton(
          label: '賣出持倉',
          apCost: 1,
          onExecute: (pl) {
            pl.unlockedFlags.add('invest_sell_pending');
          },
        ));
      }
      buttons.add(ActionButton(
        label: '睇市況（12 資產）',
        apCost: 0,
        onExecute: (pl) {
          MarketEngine.ensureInitialized(pl);
          final lines = MarketEngine.catalogue.map((a) {
            final px = MarketEngine.priceOf(pl, a.id);
            final ch = MarketEngine.quarterChangePct(pl, a.id);
            final sign = ch >= 0 ? '+' : '';
            return '${a.nameZh} \$${px.toStringAsFixed(2)} '
                '($sign${ch.toStringAsFixed(1)}%)';
          });
          pl.eventLog.add('${pl.year}年市況：\n${lines.join('\n')}');
        },
      ));
    }

    // 成年娛樂：賭馬（唔受 18 投資閘以外——其實 18+ 先有資產 tab 大部分）
    if (p.age >= 18) {
      buttons.add(ActionButton(
        label: '賭馬／六合彩（\$500）',
        apCost: 1,
        onExecute: (pl) {
          if (pl.wealth < 500) {
            pl.eventLog.add('${pl.year}年：現金唔夠賭。');
            return;
          }
          pl.wealth -= 500;
          if (LuckModifiers.roll(pl, 0.08, Random())) {
            pl.wealth += 8000;
            pl.eventLog.add('${pl.year}年：中彩 \$8000！');
          } else {
            pl.eventLog.add('${pl.year}年：賭馬輸咗 \$500。');
          }
        },
      ));
    }

    // R：兒童綜援（18 歲以下）＋學費 Grant／Loan 說明
    if (CssaWelfare.isEligibleTier(p)) {
      if (p.age < 18) {
        if (CssaWelfare.isActive(p)) {
          final left = CssaWelfare.yearsUntilRenewDue(p);
          final renewLabel = left == null
              ? '★ 綜援手動續期'
              : left <= 0
                  ? '★ 綜援續期（已逾期！）'
                  : left <= 1
                      ? '★ 綜援續期（即將到期）'
                      : '綜援續期（下次約 ${p.year + (left)} 年）';
          buttons.add(ActionButton(
            label: renewLabel,
            apCost: left != null && left <= 1 ? 1 : 0,
            isConditional: left != null && left <= 1,
            onExecute: (pl) {
              pl.eventLog.add(CssaWelfare.renew(pl));
            },
          ));
          buttons.add(ActionButton(
            label:
                '綜援狀態：每季 \$${CssaWelfare.quarterlyAmount} · ${CssaWelfare.statusLabel(p)}',
            apCost: 0,
            onExecute: (pl) {
              pl.eventLog.add(
                '${pl.year}年：${CssaWelfare.statusLabel(pl)}。'
                '現金上限 \$${CssaWelfare.assetLimit}；超過會自動取消。',
              );
            },
          ));
        } else {
          buttons.add(ActionButton(
            label: p.wealth > CssaWelfare.assetLimit
                ? '綜援：現金超過 \$${CssaWelfare.assetLimit}，唔可以申請'
                : '★ 申請兒童綜援（每季 \$${CssaWelfare.quarterlyAmount}）',
            apCost: p.wealth > CssaWelfare.assetLimit ? 0 : 1,
            isConditional: p.wealth <= CssaWelfare.assetLimit,
            onExecute: (pl) {
              pl.eventLog.add(CssaWelfare.apply(pl));
            },
          ));
        }
      } else {
        buttons.add(ActionButton(
          label: '綜援：已滿 18 歲，兒童綜援已終止',
          apCost: 0,
          onExecute: (pl) {
            pl.eventLog.add(
              '${pl.year}年：兒童綜援只限 18 歲以下。'
              '學費 Grant／Loan 入讀專上時自動計。',
            );
          },
        ));
      }
    }

    if (p.unlockedFlags.contains('student_grant_loan') ||
        p.unlockedFlags.contains('cssa_welfare')) {
      if (p.isStudying &&
          (p.education == EducationLevel.bachelor ||
              p.education == EducationLevel.associate ||
              FoundationPathway.isStudying(p))) {
        buttons.add(ActionButton(
          label: '學費資助說明（Grant／Loan）',
          apCost: 0,
          onExecute: (pl) {
            pl.eventLog.add(
              '${pl.year}年：學費會自動計屋企幫補＋政府 Grant（唔使還）'
              '＋不足先借 Loan（要還）。'
              '${pl.studentLoanDebt > 0 ? " 而家尚欠貸款 \$${pl.studentLoanDebt}。" : ""}',
            );
          },
        ));
      } else if (p.age >= 15 &&
          p.age < 18 &&
          p.unlockedFlags.contains('student_grant_loan') &&
          !p.unlockedFlags.contains('synergy_r_grant')) {
        buttons.add(ActionButton(
          label: '中學：等學校通知申請學費前資助',
          apCost: 0,
          onExecute: (pl) {
            pl.eventLog.add(
              '${pl.year}年：中學有機會出「學生資助」事件卡；'
              '大學 Grant／Loan 要入讀專上先自動計。',
            );
          },
        ));
      }
    }

    return buttons;
  }

  List<ActionButton> getLifestyleActions() {
    final buttons = <ActionButton>[
      ..._conditionalExams(),
      ActionButton(
        label: '飲茶行山',
        apCost: 1,
        onExecute: (pl) {
          pl.san = (pl.san + 6).clamp(0, pl.maxSan);
          pl.hp = (pl.hp + 3).clamp(0, pl.maxHp);
          if (pl.lifeStage == LifeStage.adult) pl.wealth -= 200;
        },
      ),
      ActionButton(
        label: '蒲吧擴闊人脈',
        apCost: 1,
        onExecute: (pl) {
          pl.network = (pl.network + 4).clamp(0, 100);
          if (pl.lifeStage == LifeStage.adult) pl.wealth -= 500;
          pl.san = (pl.san + 3).clamp(0, pl.maxSan);
          if (pl.age >= 16) {
            SocialCircle.tryMeet(
              pl,
              FriendSource.bar,
              baseChance: 0.4,
            );
          }
        },
      ),
      ActionButton(
        label: '打機減壓',
        apCost: 1,
        onExecute: (pl) {
          pl.san = (pl.san + 8).clamp(0, pl.maxSan);
          pl.discipline = (pl.discipline - 2).clamp(0, 100);
        },
      ),
    ];

    // ── 社交：朋友／拍拖 ──
    if (_player.friends.isEmpty) {
      buttons.add(ActionButton(
        label: '社交：去學校／社團／教會／蒲吧先識人',
        apCost: 0,
        onExecute: (pl) {
          pl.eventLog.add(
            '${pl.year}年：未有朋友——升學、社團、教會、蒲吧、大學聚會有機會識人。',
          );
        },
      ));
    } else {
      buttons.add(ActionButton(
        label:
            '★ 約朋友出街／傾偈（${_player.friends.length}/${SocialCircle.maxFriends}）',
        apCost: 1,
        isConditional: true,
        onExecute: (pl) {
          pl.unlockedFlags.add('social_hang_pending');
        },
      ));
      buttons.add(ActionButton(
        label: '請朋友食飯／送禮',
        apCost: 1,
        onExecute: (pl) {
          pl.unlockedFlags.add('social_gift_pending');
        },
      ));
      final canConfess = _player.age >= SocialCircle.datingMinAge &&
          !SocialCircle.isDating(_player) &&
          _player.friends.any(
            (f) =>
                !f.isPartner &&
                f.affinity >= SocialCircle.confessMinAffinity,
          );
      if (canConfess) {
        buttons.add(ActionButton(
          label: '★ 表白（好感≥${SocialCircle.confessMinAffinity}）',
          apCost: 2,
          isConditional: true,
          onExecute: (pl) {
            pl.unlockedFlags.add('social_confess_pending');
          },
        ));
      }
      if (SocialCircle.isDating(_player)) {
        final partner = SocialCircle.partnerOf(_player)!;
        buttons.add(ActionButton(
          label: '約會（${partner.nameZh} · 每季智慧−${SocialCircle.datingSmartsPenalty}）',
          apCost: 1,
          isConditional: true,
          onExecute: (pl) {
            pl.eventLog.add(SocialCircle.datePartner(pl));
          },
        ));
        buttons.add(ActionButton(
          label: '分手（${partner.nameZh}）',
          apCost: 1,
          onExecute: (pl) {
            pl.eventLog.add(SocialCircle.breakUp(pl));
          },
        ));
      }
    }

    if (_player.lifeStage == LifeStage.adult) {
      buttons.add(ActionButton(
        label: UniversitySocieties.wasInVolunteer(_player)
            ? '做義工（社服團背景）'
            : '做義工',
        apCost: 2,
        onExecute: (pl) {
          final bonus = UniversitySocieties.wasInVolunteer(pl);
          pl.reputation =
              (pl.reputation + (bonus ? 8 : 5)).clamp(0, 100);
          pl.network = (pl.network + (bonus ? 5 : 3)).clamp(0, 100);
        },
      ));
    }

    buttons.addAll(UniversityLife.lifestyleActions(_player));
    buttons.addAll(UniversityLife.loanRepayActions(_player));
    buttons.addAll(PartTimeJobs.lifestyleActions(_player));

    _addChurchActions(buttons);

    return buttons;
  }

  void _addChurchActions(List<ActionButton> buttons) {
    final p = _player;
    if (!ChurchPathway.canAttend(p)) return;

    buttons.add(ActionButton(
      label: p.churchMember ? '參加教會／主日' : '去教會（首次）',
      apCost: 1,
      onExecute: (pl) {
        pl.eventLog.add(ChurchPathway.attendWorship(pl));
        SocialCircle.tryMeet(
          pl,
          FriendSource.church,
          baseChance: 0.28,
        );
      },
    ));

    if (ChurchPathway.canBaptize(p)) {
      buttons.add(ActionButton(
        label: '受洗禮',
        apCost: 1,
        onExecute: (pl) {
          pl.eventLog.add(ChurchPathway.baptize(pl));
        },
      ));
    }

    if (p.churchMember && p.age >= 14) {
      buttons.add(ActionButton(
        label: '教會服事',
        apCost: 2,
        onExecute: (pl) {
          pl.eventLog.add(ChurchPathway.serve(pl));
          SocialCircle.tryMeet(
            pl,
            FriendSource.church,
            baseChance: 0.35,
          );
        },
      ));
    }

    if (ChurchPathway.canApplyReference(p)) {
      final pct =
          (ChurchPathway.referenceProbability(p) * 100).round();
      buttons.add(ActionButton(
        label: '申請教會推薦信（約 $pct%）',
        apCost: 2,
        onExecute: (pl) {
          pl.eventLog.add(
            ChurchPathway.applyReferenceLetter(pl, Random()),
          );
        },
      ));
    }
  }

  List<ActionButton> getJobActions() {
    if (_player.isChildhood && _player.age < 16) {
      return _conditionalExams();
    }

    final buttons = <ActionButton>[..._conditionalExams()];

    // 16+ 兼職（讀書／全職都得）
    buttons.addAll(PartTimeJobs.lifestyleActions(_player));
    buttons.addAll(CareerInternships.actions(_player));
    buttons.addAll(CareerGov.fitnessActions(_player));
    buttons.addAll(CareerEmployment.convertActions(_player));

    if (_player.isStudying) {
      return buttons;
    }

    if (!_player.isEmployed) {
      buttons.add(ActionButton(
        label: '街頭／網上搵全職',
        apCost: 2,
        onExecute: (pl) {
          pl.eventLog.add(CareerJobHunt.walkInHunt(pl));
        },
      ));
      if (_player.mpfBalance > 0 &&
          (_player.age >= 60 ||
              _player.unlockedFlags.contains('retired'))) {
        buttons.add(ActionButton(
          label: '提取強積金（\$${_player.mpfBalance}）',
          apCost: 1,
          onExecute: (pl) {
            pl.eventLog.add(CareerEmployment.withdrawMpf(pl) ?? '');
          },
        ));
      }
      return buttons;
    }

    buttons.addAll(CareerData.employedActions(_player));
    buttons.add(ActionButton(
      label: '進修增值',
      apCost: 2,
      onExecute: (pl) {
        BirthGacha.applyStudyGain(pl, base: 3);
        pl.jobPerformance = (pl.jobPerformance + 3).clamp(0, 100);
      },
    ));
    buttons.add(ActionButton(
      label: '辭全職',
      apCost: 1,
      onExecute: (pl) {
        CareerData.quitJob(pl, reason: '主動辭工');
      },
    ));
    if (_player.mpfBalance > 0 &&
        (_player.age >= 60 || _player.unlockedFlags.contains('retired'))) {
      buttons.add(ActionButton(
        label: '提取強積金（\$${_player.mpfBalance}）',
        apCost: 1,
        onExecute: (pl) {
          pl.eventLog.add(CareerEmployment.withdrawMpf(pl) ?? '');
        },
      ));
    }
    buttons.add(ActionButton(
      label: '走灰色地帶（風險）',
      apCost: 1,
      onExecute: (pl) {
        pl.wealth += 30000;
        pl.investigation = InvestigationStatus.police;
        pl.unlockedFlags.add('went_astray');
      },
    ));
    return buttons;
  }

  List<ActionButton> actionsForTab(ActionTab tab) => switch (tab) {
        ActionTab.career => getCareerActions(),
        ActionTab.assets => getAssetActions(),
        ActionTab.lifestyle => getLifestyleActions(),
        ActionTab.job => getJobActions(),
      };

  Future<void> resetGame() async {
    await _storage.clear();
    await newGame();
  }
}
