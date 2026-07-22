import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';
import '../models/enums.dart';
import '../models/game_event.dart';
import 'checklist_dialog.dart';

class ActionHub extends StatelessWidget {
  const ActionHub({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    if (gs.pendingExam != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && gs.pendingExam != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => ChecklistDialog(exam: gs.pendingExam!),
          ).then((_) => gs.clearPendingExam());
        }
      });
    }

    final actions = gs.actionsForTab(gs.activeTab);
    final important = actions.where((a) => a.isConditional).toList();
    final normal = actions.where((a) => !a.isConditional).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1419),
        border: Border(top: BorderSide(color: Color(0xFF2A3441), width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (important.isNotEmpty)
              _ImportantBanner(count: important.length),
            _TabRow(activeTab: gs.activeTab, onTab: gs.setActiveTab),
            _ActionList(important: important, normal: normal),
            const _NextQuarterButton(),
          ],
        ),
      ),
    );
  }
}

class _ImportantBanner extends StatelessWidget {
  final int count;
  const _ImportantBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8A838), width: 1.5),
      ),
      child: Text(
        '⚠ 本季有 $count 項重要事項（橙色掣）——例如 DSE／選科／考試',
        style: const TextStyle(
          color: Color(0xFFFFD080),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  final ActionTab activeTab;
  final void Function(ActionTab) onTab;

  const _TabRow({required this.activeTab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.player;
    final hasJob = p.isEmployed;
    final inSchool = p.isInSchool;

    final tabs = <({ActionTab tab, String icon, String label})>[
      (
        tab: ActionTab.career,
        icon: inSchool ? '📚' : '💼',
        label: inSchool ? '溫書' : '事業',
      ),
      (tab: ActionTab.assets, icon: '📈', label: '資產'),
      (tab: ActionTab.lifestyle, icon: '🎭', label: '生活'),
      if (hasJob)
        (tab: ActionTab.job, icon: '⚡', label: '現職')
      else if (!inSchool && p.lifeStage == LifeStage.adult)
        (tab: ActionTab.job, icon: '🔍', label: '搵工')
      else
        (tab: ActionTab.job, icon: '🏠', label: '福利'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Row(
        children: [
          for (final t in tabs) ...[
            Expanded(
              child: _TabChip(
                icon: t.icon,
                label: t.label,
                selected: activeTab == t.tab,
                onTap: () => onTab(t.tab),
              ),
            ),
            if (t != tabs.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1A3A5C) : const Color(0xFF161B22),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF58A6FF)
                  : const Color(0xFF30363D),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? const Color(0xFF79C0FF)
                      : const Color(0xFF8B949E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final List<ActionButton> important;
  final List<ActionButton> normal;

  const _ActionList({required this.important, required this.normal});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final ap = gs.player.actionPoints;
    final all = [...important, ...normal];

    return SizedBox(
      height: 210,
      child: all.isEmpty
          ? const Center(
              child: Text(
                '暫無可用行動\n可撳下面「下一季」',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6E7681),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              itemCount: all.length,
              itemBuilder: (context, index) {
                final action = all[index];
                final canAfford = ap >= action.apCost;
                final usable = action.enabled && canAfford;
                final isKey = action.isConditional;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: !usable
                        ? const Color(0xFF12161C)
                        : isKey
                            ? const Color(0xFF2A1F0A)
                            : const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: usable
                          ? () => gs.executeAction(action)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !usable
                                ? const Color(0xFF21262D)
                                : isKey
                                    ? const Color(0xFFE8A838)
                                    : const Color(0xFF3D4A5C),
                            width: isKey ? 2 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isKey) ...[
                              const Text('★', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                action.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isKey ? FontWeight.w800 : FontWeight.w600,
                                  height: 1.25,
                                  color: !usable
                                      ? const Color(0xFF484F58)
                                      : isKey
                                          ? const Color(0xFFFFD080)
                                          : const Color(0xFFE6EDF3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: usable
                                    ? const Color(0xFF21262D)
                                    : const Color(0xFF0D1117),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                !action.enabled
                                    ? '未開放'
                                    : !canAfford
                                        ? 'AP不足'
                                        : action.apCost == 0
                                            ? '免費'
                                            : '${action.apCost} AP',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: usable
                                      ? const Color(0xFF8B949E)
                                      : const Color(0xFF484F58),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NextQuarterButton extends StatelessWidget {
  const _NextQuarterButton();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.player;
    final hasEvents = gs.quarterEvents.isNotEmpty;

    String label;
    if (p.phase == GamePhase.dead) {
      label = '人生已結束';
    } else if (p.inPrison) {
      label = '下一季（剩餘 ${p.prisonQuartersLeft} 季）';
    } else if (hasEvents) {
      label = '仍有事件未處理 · 仍可下一季 ▶';
    } else {
      label = '下一季 ▶';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: p.phase == GamePhase.dead ? null : () => gs.nextQuarter(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF238636),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF21262D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
