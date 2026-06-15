import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'sudoku_nova.db';
  static const _dbVersion = 1;

  static const _tableGameHistory = 'game_history';

  // Singleton
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;
  Future<Database>? _initFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDatabase();
    _database = await _initFuture!;
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableGameHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        difficulty TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        won INTEGER NOT NULL,
        mistakes INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');
  }
}
