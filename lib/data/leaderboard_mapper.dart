import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';

/// Firestore のフィールド名・型・ニックネーム整形を **ここに集約**する。
///
/// スキーマ変更時はこのクラスと [LeaderboardPaths] を見れば足りる想定。
abstract final class LeaderboardMapper {
  static const String fieldScore = 'score';
  static const String fieldNickname = 'nickname';
  static const String fieldUpdatedAt = 'updatedAt';

  static const int maxNicknameLength = 32;

  /// ドキュメントの `data()` から [LeaderboardEntry] へ。不正・空は `null`。
  static LeaderboardEntry? fromFirestore(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;

    final scoreVal = raw[fieldScore];
    final nickVal = raw[fieldNickname];
    if (scoreVal is! num) return null;

    final score = scoreVal.round();
    if (score < 0) return null;

    final nickname = _sanitizeNickname(
      nickVal is String ? nickVal : nickVal?.toString() ?? '',
    );
    if (nickname.isEmpty) return null;

    DateTime? updatedAt;
    final ts = raw[fieldUpdatedAt];
    if (ts is Timestamp) {
      updatedAt = ts.toDate().toUtc();
    }

    return LeaderboardEntry(
      score: score,
      nickname: nickname,
      updatedAt: updatedAt,
    );
  }

  /// 書き込み用 Map（`updatedAt` は呼び出し側で [FieldValue.serverTimestamp] を足す想定）。
  static Map<String, dynamic> toFirestoreWrite({
    required int score,
    required String nickname,
  }) {
    return {
      fieldScore: score,
      fieldNickname: _sanitizeNickname(nickname),
    };
  }

  // --- leaderboard_history コレクション（ベスト更新の履歴） ---

  static const String fieldHistoryKind = 'kind';
  static const String fieldHistoryJstDateKey = 'jstDateKey';
  static const String fieldHistoryCreatedAt = 'createdAt';

  /// [fieldHistoryKind] の値。
  static const String historyKindAllTime = 'all_time';
  static const String historyKindDaily = 'daily';

  /// 履歴 1 件分の書き込み用 Map（`createdAt` に serverTimestamp）。
  static Map<String, dynamic> toFirestoreHistory({
    required String kind,
    required int score,
    required String nickname,
    String? jstDateKey,
  }) {
    return {
      fieldHistoryKind: kind,
      fieldScore: score,
      fieldNickname: _sanitizeNickname(nickname),
      fieldHistoryCreatedAt: FieldValue.serverTimestamp(),
      if (jstDateKey != null) fieldHistoryJstDateKey: jstDateKey,
    };
  }

  /// 表示・保存前のニックネーム整形（空白除去・長さ制限）。
  static String sanitizeNicknameForInput(String input) => _sanitizeNickname(input);

  static String _sanitizeNickname(String s) {
    var t = s.trim();
    if (t.length > maxNicknameLength) {
      t = t.substring(0, maxNicknameLength);
    }
    // 連続空白は trim のみ。制御文字は除去したい場合はここでフィルタを足す。
    return t;
  }
}
