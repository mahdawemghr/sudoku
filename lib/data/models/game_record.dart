import 'difficulty.dart';

class GameRecord {
  final int? id;
  final Difficulty difficulty;
  final int durationSeconds;
  final bool won;
  final int mistakes;
  final DateTime completedAt;

  const GameRecord({
    this.id,
    required this.difficulty,
    required this.durationSeconds,
    required this.won,
    required this.mistakes,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'difficulty': difficulty.label,
      'duration_seconds': durationSeconds,
      'won': won ? 1 : 0,
      'mistakes': mistakes,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory GameRecord.fromMap(Map<String, dynamic> map) {
    return GameRecord(
      id: map['id'] as int?,
      difficulty: DifficultyExtension.fromString(map['difficulty'] as String),
      durationSeconds: map['duration_seconds'] as int,
      won: (map['won'] as int) == 1,
      mistakes: map['mistakes'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}
