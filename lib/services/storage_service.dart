import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';

class StorageService {
  static const _saveKey = 'hk_life_simulator_save_v18';

  Future<void> save(Player player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, player.encode());
  }

  Future<Player?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Player.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }
}
