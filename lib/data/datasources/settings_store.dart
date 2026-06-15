import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_game.dart';

class SettingsStore {
  static const _keySound = 'sound_enabled';
  static const _keySavedGame = 'saved_game_json';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> getSoundEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keySound) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keySound, value);
  }

  Future<SavedGame?> getSavedGame() async {
    final prefs = await _prefs;
    final json = prefs.getString(_keySavedGame);
    if (json == null) return null;
    return SavedGame.fromJsonString(json);
  }

  Future<void> setSavedGame(SavedGame? game) async {
    final prefs = await _prefs;
    if (game == null) {
      await prefs.remove(_keySavedGame);
    } else {
      await prefs.setString(_keySavedGame, game.toJsonString());
    }
  }
}
