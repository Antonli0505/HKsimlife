import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';
import '../models/game_event.dart';

class EventFeed extends StatelessWidget {
  const EventFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final events = gs.quarterEvents;
    final outcomes = gs.outcomeMessages;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      children: [
        if (events.isNotEmpty)
          _SectionHeader(
            title: '本季事件',
            subtitle: '請揀下面選項（${events.length} 張卡）',
            accent: const Color(0xFF58A6FF),
          ),
        if (events.isEmpty && outcomes.isEmpty)
          const _EmptyFeed()
        else ...[
          ...events.map((e) => _StoryCard(event: e)),
          if (outcomes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionHeader(
              title: '最近結果',
              subtitle: '詳細已用彈窗顯示；呢度係紀錄',
              accent: const Color(0xFF8B949E),
            ),
            ...outcomes.reversed.take(4).map(_OutcomeCard.new),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: const Column(
          children: [
            Text('✓', style: TextStyle(fontSize: 28, color: Color(0xFF3FB950))),
            SizedBox(height: 10),
            Text(
              '呢季事件搞掂晒',
              style: TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '用下面橙色／白色行動掣，\n或者撳「下一季」繼續人生。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  final String message;
  const _OutcomeCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141A22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF9DA7B3),
          height: 1.45,
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final StoryEvent event;
  const _StoryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final gs = context.read<GameState>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: event.isSystem
              ? const Color(0xFFDA3633)
              : const Color(0xFF58A6FF).withValues(alpha: 0.55),
          width: 1.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: event.isSystem
                    ? const Color(0xFF3D1214)
                    : const Color(0xFF12233A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                event.isSystem ? '系統' : '要決策',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: event.isSystem
                      ? const Color(0xFFFF7B72)
                      : const Color(0xFF79C0FF),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF0F3F6),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.body,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFC9D1D9),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '揀一個選項',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8B949E),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            ...event.choices.asMap().entries.map((entry) {
              final idx = entry.key;
              final choice = entry.value;
              final enabled = choice.enabled;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: enabled
                      ? const Color(0xFF1C2333)
                      : const Color(0xFF12161C),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: enabled
                        ? () => gs.selectChoice(event, idx)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: enabled
                              ? const Color(0xFF4A90D9)
                              : const Color(0xFF21262D),
                          width: enabled ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        choice.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: enabled
                              ? const Color(0xFFE6EDF3)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
