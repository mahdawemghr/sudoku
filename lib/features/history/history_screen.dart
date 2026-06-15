import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/game_record.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/features/history/widgets/history_tile.dart';

final historyProvider = FutureProvider.autoDispose<List<GameRecord>>((ref) async {
  return GameRepository().getHistory();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'History',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: colors.primaryNeon,
            strokeWidth: 2,
          ),
        ),
        error: (e, s) => Center(
          child: Text(
            'Could not load history.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Text(
                'No games yet. Start playing!',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final sorted = List<GameRecord>.from(records)
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return HistoryTile(record: sorted[index]);
            },
          );
        },
      ),
    );
  }
}
