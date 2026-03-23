import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leaderboard_repository.dart';
import '../models/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

/// 通算一位（Firestore 未接続・未作成ドキュメント時は `null`）。
final allTimeLeaderboardProvider = StreamProvider<LeaderboardEntry?>((ref) {
  return ref.watch(leaderboardRepositoryProvider).watchAllTime();
});

/// 今日（JST）の日次一位。
final todayDailyLeaderboardProvider = StreamProvider<LeaderboardEntry?>((ref) {
  return ref.watch(leaderboardRepositoryProvider).watchTodayDaily();
});
