import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SudokuNovaApp()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
