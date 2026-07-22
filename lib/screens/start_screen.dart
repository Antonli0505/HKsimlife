import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_state.dart';
import '../services/storage_service.dart';
import 'gacha_screen.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _checking = true;
  bool _hasSave = false;
  final _nameController = TextEditingController(text: '新移民');

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  Future<void> _checkSave() async {
    final has = await StorageService().hasSave();
    if (mounted) {
      setState(() {
        _hasSave = has;
        _checking = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _playerName =>
      _nameController.text.trim().isEmpty ? '新移民' : _nameController.text.trim();

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF58A6FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '香港生存模擬器',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.red.shade400,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'HK Life Simulator',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF484F58),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gacha 出生 · 呈分試 · DSE · OT\n喺香港活落去，由 0 歲開始',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B949E),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                if (!_hasSave) ...[
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Color(0xFFE6EDF3)),
                    decoration: InputDecoration(
                      labelText: '你的名字',
                      labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final gs = context.read<GameState>();
                      if (_hasSave) {
                        await gs.init();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const GameScreen(),
                            ),
                          );
                        }
                      } else {
                        await gs.newGame(name: _playerName);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  GachaScreen(playerName: _playerName),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF238636),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _hasSave ? '繼續遊戲' : '開始新人生',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (_hasSave) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        final gs = context.read<GameState>();
                        await gs.newGame(name: _playerName);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  GachaScreen(playerName: _playerName),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B949E),
                        side: const BorderSide(color: Color(0xFF30363D)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('重新開始（新 Gacha）'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
