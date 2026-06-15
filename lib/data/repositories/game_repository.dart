import '../datasources/game_history_dao.dart';
import '../datasources/settings_store.dart';
import '../models/game_record.dart';
import '../models/saved_game.dart';

class GameRepository {
  final GameHistoryDao _dao;
  final SettingsStore _store;

  GameRepository({
    GameHistoryDao? dao,
    SettingsStore? store,
  })  : _dao = dao ?? GameHistoryDao(),
        _store = store ?? SettingsStore();

  Future<void> saveRecord(GameRecord record) async {
    await _dao.insert(record);
  }

  Future<List<GameRecord>> getHistory() async {
    return _dao.getAll();
  }

  Future<void> saveCurrentGame(SavedGame game) async {
    await _store.setSavedGame(game);
  }

  Future<SavedGame?> loadCurrentGame() async {
    return _store.getSavedGame();
  }

  Future<void> clearCurrentGame() async {
    await _store.setSavedGame(null);
  }
}
