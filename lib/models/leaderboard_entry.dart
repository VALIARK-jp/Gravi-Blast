import 'package:flutter/foundation.dart';

/// ランキング1件分（アプリ内のドメイン表現）。
///
/// Firestore の生 Map との変換は [LeaderboardMapper] に任せる。
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.score,
    required this.nickname,
    this.updatedAt,
  });

  /// スコア（0 以上）。
  final int score;

  /// 表示名（既に整形済みである想定）。
  final String nickname;

  /// 最終更新（Firestore の serverTimestamp を UTC で保持）。
  final DateTime? updatedAt;

  /// UI 用の一行表示。
  String get displayLine => '$nickname … $score';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          nickname == other.nickname &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(score, nickname, updatedAt);
}
