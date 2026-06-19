import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/theme/app_theme.dart';
import 'package:sudoku/features/game/widgets/out_of_lives_dialog.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  required Future<bool> Function() onWatchAd,
  required VoidCallback onEndGame,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => OutOfLivesDialog(
                onWatchAd: onWatchAd,
                onEndGame: onEndGame,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the headline and both action buttons', (tester) async {
    await _openDialog(
      tester,
      onWatchAd: () async => true,
      onEndGame: () {},
    );

    expect(find.text('Out of Lives!'), findsOneWidget);
    expect(find.text('WATCH AD · +1 LIFE'), findsOneWidget);
    expect(find.text('END GAME'), findsOneWidget);
  });

  testWidgets('tapping End Game calls onEndGame and closes the dialog',
      (tester) async {
    var endGameCalled = false;

    await _openDialog(
      tester,
      onWatchAd: () async => true,
      onEndGame: () => endGameCalled = true,
    );

    await tester.tap(find.text('END GAME'));
    await tester.pumpAndSettle();

    expect(endGameCalled, isTrue);
    expect(find.text('Out of Lives!'), findsNothing);
  });

  testWidgets(
      'tapping Watch Ad shows a loading indicator, then calls onWatchAd and closes',
      (tester) async {
    final completer = Completer<bool>();
    var watchAdCalled = false;

    await _openDialog(
      tester,
      onWatchAd: () {
        watchAdCalled = true;
        return completer.future;
      },
      onEndGame: () {},
    );

    await tester.tap(find.text('WATCH AD · +1 LIFE'));
    await tester.pump();

    expect(watchAdCalled, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('WATCH AD · +1 LIFE'), findsNothing);

    completer.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Out of Lives!'), findsNothing);
  });
}
