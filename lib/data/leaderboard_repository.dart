import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';
import '../utils/jst_date.dart';
import 'leaderboard_mapper.dart';
import 'leaderboard_paths.dart';

/// ランキングの読み書き（整形は [LeaderboardMapper]）。
class LeaderboardRepository {
  LeaderboardRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _allTime =>
      _db.collection(LeaderboardPaths.collection).doc(LeaderboardPaths.allTimeDocId);

  DocumentReference<Map<String, dynamic>> _daily(String jstDateKey) =>
      _db.collection(LeaderboardPaths.collection).doc(LeaderboardPaths.dailyDocId(jstDateKey));

  /// 通算一位を購読。
  Stream<LeaderboardEntry?> watchAllTime() {
    return _allTime.snapshots().map((snap) => LeaderboardMapper.fromFirestore(snap.data()));
  }

  /// 指定 JST 日付の日次一位を購読。
  Stream<LeaderboardEntry?> watchDaily(String jstDateKey) {
    return _daily(jstDateKey).snapshots().map((snap) => LeaderboardMapper.fromFirestore(snap.data()));
  }

  /// 今日（JST）の日次一位を購読。
  Stream<LeaderboardEntry?> watchTodayDaily() => watchDaily(jstDateKey());

  Future<LeaderboardEntry?> getAllTimeOnce() async {
    final snap = await _allTime.get();
    return LeaderboardMapper.fromFirestore(snap.data());
  }

  Future<LeaderboardEntry?> getDailyOnce(String jstDateKey) async {
    final snap = await _daily(jstDateKey).get();
    return LeaderboardMapper.fromFirestore(snap.data());
  }

  /// 通算記録を更新（スコアが既存より大きいときだけ書く）。
  ///
  /// 戻り値: 実際に書き込んだか。
  Future<bool> tryUpdateAllTimeIfBetter({
    required int score,
    required String nickname,
  }) async {
    return _db.runTransaction((tx) async {
      final snap = await tx.get(_allTime);
      final current = LeaderboardMapper.fromFirestore(snap.data());
      if (current != null && score <= current.score) {
        return false;
      }
      tx.set(
        _allTime,
        {
          ...LeaderboardMapper.toFirestoreWrite(score: score, nickname: nickname),
          LeaderboardMapper.fieldUpdatedAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }

  /// 日次記録を更新（同じくスコアが大きいときだけ）。
  Future<bool> tryUpdateDailyIfBetter({
    required String jstDateKey,
    required int score,
    required String nickname,
  }) async {
    final ref = _daily(jstDateKey);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = LeaderboardMapper.fromFirestore(snap.data());
      if (current != null && score <= current.score) {
        return false;
      }
      tx.set(
        ref,
        {
          ...LeaderboardMapper.toFirestoreWrite(score: score, nickname: nickname),
          LeaderboardMapper.fieldUpdatedAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    });
  }
}
