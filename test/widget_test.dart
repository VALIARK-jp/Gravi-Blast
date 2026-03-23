import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:graviblast/app.dart';
import 'package:graviblast/providers/leaderboard_provider.dart';

void main() {
  testWidgets('GraviBlast game screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // テストでは Firebase に接続しない
          allTimeLeaderboardProvider.overrideWith((ref) => Stream.value(null)),
          todayDailyLeaderboardProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const GraviBlastApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0'), findsWidgets);
    expect(find.textContaining('Lines:'), findsOneWidget);
    expect(find.textContaining('Best score'), findsOneWidget);
    expect(find.textContaining("Today's best score"), findsOneWidget);
  });
}
