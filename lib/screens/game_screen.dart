import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';
import '../models/enums.dart';
import '../widgets/action_hub.dart';
import '../widgets/event_feed.dart';
import '../widgets/hud_bar.dart';
import '../widgets/mobile_container.dart';
import '../widgets/popup_message.dart';
import '../widgets/profile_drawer.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showingPopup = false;

  Future<void> _drainPopups(GameState gs) async {
    if (_showingPopup || !gs.hasPendingPopup || !mounted) return;
    _showingPopup = true;
    while (mounted) {
      final state = context.read<GameState>();
      if (!state.hasPendingPopup) break;
      final remainingBefore = state.popupQueue.length;
      final msg = state.takePopupBatch(separateUntil: 2);
      if (msg == null) break;
      final remaining = remainingBefore > 2 ? 0 : remainingBefore - 1;
      await showOutcomePopup(
        context,
        message: msg,
        title: remainingBefore > 2 ? '本季結算' : popupTitleFor(msg),
        remaining: remaining,
      );
      if (!mounted) break;
    }
    _showingPopup = false;
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final p = gs.player;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainPopups(gs);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF010409),
      body: MobileContainer(
        child: Stack(
          children: [
            Column(
              children: [
                const HudBar(),
                if (p.phase == GamePhase.dead)
                  const _StatusBanner(
                    text: '人生已結束。刷新頁面可重新開始。',
                    bg: Color(0xFF3D1214),
                    fg: Color(0xFFFF7B72),
                  )
                else if (p.inPrison)
                  _StatusBanner(
                    text: '監獄模式 · 剩餘 ${p.prisonQuartersLeft} 季',
                    bg: const Color(0xFF2A1A4A),
                    fg: const Color(0xFFBC8CFF),
                  )
                else if (p.investigation != InvestigationStatus.none)
                  _StatusBanner(
                    text: switch (p.investigation) {
                      InvestigationStatus.police => '警方調查中…',
                      InvestigationStatus.icac => 'ICAC 請你飲咖啡中…',
                      InvestigationStatus.court => '法院應訊中…',
                      InvestigationStatus.convicted => '已定罪',
                      InvestigationStatus.none => '',
                    },
                    bg: const Color(0xFF2A1F0A),
                    fg: const Color(0xFFFFA657),
                  ),
                if (gs.quarterEvents.isNotEmpty)
                  _StatusBanner(
                    text:
                        '↑ 上面有 ${gs.quarterEvents.length} 張事件卡要處理（藍色掣）',
                    bg: const Color(0xFF12233A),
                    fg: const Color(0xFF79C0FF),
                  ),
                const Expanded(child: EventFeed()),
                const ActionHub(),
              ],
            ),
            const ProfileDrawer(),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _StatusBanner({
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      color: bg,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
