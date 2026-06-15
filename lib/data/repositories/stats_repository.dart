import '../datasources/game_history_dao.dart';
import '../models/difficulty.dart';

class StatsRepository {
  final GameHistoryDao _dao;

  StatsRepository({GameHistoryDao? dao}) : _dao = dao ?? GameHistoryDao();

  Future<int?> getBestTime(Difficulty difficulty) async {
    return _dao.getBestTime(difficulty);
  }

  Future<Map<Difficulty, int?>> getAllBestTimes() async {
    final results = <Difficulty, int?>{};
    for (final difficulty in Difficulty.values) {
      results[difficulty] = await _dao.getBestTime(difficulty);
    }
    return results;
  }
}
