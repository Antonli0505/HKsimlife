import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/birth_gacha.dart';
import '../game_state.dart';
import '../models/enums.dart';
import 'game_screen.dart';

class GachaScreen extends StatefulWidget {
  final String playerName;

  const GachaScreen({super.key, required this.playerName});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen>
    with SingleTickerProviderStateMixin {
  bool _rolling = false;
  bool _revealed = false;
  BirthTier? _result;
  SchoolBand? _primaryBand;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _rollGacha() async {
    if (_rolling) return;
    setState(() {
      _rolling = true;
      _revealed = false;
    });

    await _spinController.forward(from: 0);
    final tier = BirthGacha.roll();
    final primary = BirthGacha.rollPrimaryBand(tier);
    setState(() {
      _result = tier;
      _primaryBand = primary;
      _revealed = true;
      _rolling = false;
    });
  }

  Future<void> _confirmBirth() async {
    if (_result == null || _primaryBand == null) return;
    final gs = context.read<GameState>();
    await gs.startWithBirth(
      widget.playerName,
      _result!,
      primaryBand: _primaryBand,
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  Color _tierColor(BirthTier tier) => switch (tier) {
        BirthTier.ssr => const Color(0xFFFFD700),
        BirthTier.sr => const Color(0xFFBC8CFF),
        BirthTier.r => const Color(0xFF8B949E),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.playerName} 嘅出生命運',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE6EDF3),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gacha 抽卡 · 家庭 Level + 小學 Band',
                  style: TextStyle(fontSize: 12, color: Color(0xFF484F58)),
                ),
                const SizedBox(height: 40),
                RotationTransition(
                  turns: _spinController,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _revealed && _result != null
                            ? [
                                _tierColor(_result!).withValues(alpha: 0.4),
                                const Color(0xFF161B22),
                              ]
                            : [
                                const Color(0xFF30363D),
                                const Color(0xFF161B22),
                              ],
                      ),
                      border: Border.all(
                        color: _revealed && _result != null
                            ? _tierColor(_result!)
                            : const Color(0xFF30363D),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _revealed && _result != null
                            ? _result!.shortLabel
                            : '?',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: _revealed && _result != null
                              ? _tierColor(_result!)
                              : const Color(0xFF484F58),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_revealed && _result != null && _primaryBand != null) ...[
                  Text(
                    _result!.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _tierColor(_result!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _birthRow('家庭 Level', _result!.shortLabel),
                        const SizedBox(height: 6),
                        _birthRow('小學 Band', _primaryBand!.primaryLabel),
                        const SizedBox(height: 6),
                        _birthRow('升小', '6 歲先派位入讀'),
                        const SizedBox(height: 8),
                        const Text(
                          '小六：自行分配（Q1–Q2）→ 統派（Q4）· Band 1／2／3',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF484F58),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _result!.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B949E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _confirmBirth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF238636),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '接受命運，開始人生',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _rolling ? null : _rollGacha,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21262D),
                        foregroundColor: const Color(0xFFE6EDF3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF30363D)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _rolling ? '抽卡中...' : '抽出生卡',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'SSR 1% · SR 19% · R 80%',
                  style: TextStyle(fontSize: 11, color: Color(0xFF484F58)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _birthRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF484F58)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFE6EDF3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
