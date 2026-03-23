/// Firestore のコレクション・ドキュメント ID（ここだけを変えれば構造を変更できる）。
abstract final class LeaderboardPaths {
  static const String collection = 'leaderboard';

  /// 通算一位（1ドキュメント）。
  static const String allTimeDocId = 'all_time';

  /// 日次一位用ドキュメント ID（`daily_` + JST の `YYYY-MM-DD`）。
  static String dailyDocId(String jstDateKey) => 'daily_$jstDateKey';

  /// ベスト更新のたびに 1 件追加される履歴（自動 ID）。
  static const String historyCollection = 'leaderboard_history';
}
