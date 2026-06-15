import '../models/difficulty.dart';
import '../models/game_record.dart';
import 'database_helper.dart';

class GameHistoryDao {
  static const _table = 'game_history';

  final DatabaseHelper _helper;

  GameHistoryDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  Future<int> insert(GameRecord record) async {
    final db = await _helper.database;
    return db.insert(_table, record.toMap());
  }

  Future<List<GameRecord>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query(
      _table,
      orderBy: 'completed_at DESC',
    );
    return rows.map(GameRecord.fromMap).toList();
  }

  /// Returns the best (minimum) duration in seconds for won games of [difficulty].
  /// Returns null if no won game exists for that difficulty.
  Future<int?> getBestTime(Difficulty difficulty) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT MIN(duration_seconds) AS best FROM $_table WHERE won = 1 AND difficulty = ?',
      [difficulty.label],
    );
    if (result.isEmpty) return null;
    return result.first['best'] as int?;
  }

  Future<void> deleteAll() async {
    final db = await _helper.database;
    await db.delete(_table);
  }
}
