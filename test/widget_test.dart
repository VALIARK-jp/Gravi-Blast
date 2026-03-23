import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:graviblast/app.dart';

void main() {
  testWidgets('GraviBlast game screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GraviBlastApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GraviBlast'), findsOneWidget);
    expect(find.textContaining('POINTS'), findsOneWidget);
  });
}
