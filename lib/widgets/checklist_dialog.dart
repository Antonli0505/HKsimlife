import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';
import '../models/game_event.dart';

/// 考試／里程碑 checklist 彈窗——條件用大字 + ✓／○ 顯示。
class ChecklistDialog extends StatelessWidget {
  final ChecklistExam exam;

  const ChecklistDialog({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final results = exam.evaluate(gs.player);
    final allMet = results.every((r) => r);
    final unmet = exam.requirements
        .asMap()
        .entries
        .where((e) => !results[e.key])
        .map((e) => e.value.label)
        .toList();

    return Dialog(
      backgroundColor: const Color(0xFF12161C),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: allMet ? const Color(0xFF3FB950) : const Color(0xFFE8A838),
          width: 1.8,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                exam.title,
                style: const TextStyle(
                  color: Color(0xFFF0F3F6),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exam.description,
                style: const TextStyle(
                  color: Color(0xFF9DA7B3),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: allMet
                      ? const Color(0xFF12261A)
                      : const Color(0xFF2A1F0A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  allMet
                      ? '✓ 條件齊晒——可以提交'
                      : '○ 仲差 ${unmet.length} 項——睇下面清單',
                  style: TextStyle(
                    color: allMet
                        ? const Color(0xFF3FB950)
                        : const Color(0xFFFFD080),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...exam.requirements.asMap().entries.map((entry) {
                        final met = results[entry.key];
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: met
                                  ? const Color(0xFF238636)
                                  : const Color(0xFF484F58),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                met ? '✓' : '○',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: met
                                      ? const Color(0xFF3FB950)
                                      : const Color(0xFF8B949E),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value.label,
                                  style: TextStyle(
                                    color: met
                                        ? const Color(0xFFC9D1D9)
                                        : const Color(0xFFE6EDF3),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: allMet
                      ? () {
                          gs.submitExam(exam);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF238636),
                    disabledBackgroundColor: const Color(0xFF21262D),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF6E7681),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    allMet ? '提交應考／完成' : '條件未齊，唔可以提交',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '關閉',
                    style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
