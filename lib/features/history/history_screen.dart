import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/game_record.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/features/history/widgets/history_tile.dart';

final historyProvider = FutureProvider<List<GameRecord>>((ref) async {
  return GameRepository().getHistory();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryNeon,
            strokeWidth: 2,
          ),
        ),
        error: (_, __) => const Center(
          child: Text(
            'Could not load history.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'No games yet. Start playing!',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Sort most recent first
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
