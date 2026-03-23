import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graviblast/data/leaderboard_mapper.dart';

void main() {
  test('fromFirestore: valid map', () {
    final e = LeaderboardMapper.fromFirestore({
      'score': 1200,
      'nickname': '  Player1  ',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2025, 3, 24, 15)),
    });
    expect(e, isNotNull);
    expect(e!.score, 1200);
    expect(e.nickname, 'Player1');
    expect(e.updatedAt, isNotNull);
  });

  test('fromFirestore: null or empty -> null', () {
    expect(LeaderboardMapper.fromFirestore(null), isNull);
    expect(LeaderboardMapper.fromFirestore({}), isNull);
  });

  test('fromFirestore: invalid score', () {
    expect(LeaderboardMapper.fromFirestore({'score': -1, 'nickname': 'a'}), isNull);
    expect(LeaderboardMapper.fromFirestore({'score': 'x', 'nickname': 'a'}), isNull);
  });

  test('sanitizeNicknameForInput: length cap', () {
    final long = 'a' * 40;
    final out = LeaderboardMapper.sanitizeNicknameForInput(long);
    expect(out.length, LeaderboardMapper.maxNicknameLength);
  });

  test('toFirestoreWrite: keys and sanitize', () {
    final m = LeaderboardMapper.toFirestoreWrite(
      score: 99,
      nickname: '  hi  ',
    );
    expect(m['score'], 99);
    expect(m['nickname'], 'hi');
  });

  test('toFirestoreHistory: all_time', () {
    final m = LeaderboardMapper.toFirestoreHistory(
      kind: LeaderboardMapper.historyKindAllTime,
      score: 5000,
      nickname: 'Player',
    );
    expect(m['kind'], LeaderboardMapper.historyKindAllTime);
    expect(m['score'], 5000);
    expect(m['nickname'], 'Player');
    expect(m['createdAt'], isA<FieldValue>());
    expect(m.containsKey('jstDateKey'), isFalse);
  });

  test('toFirestoreHistory: daily with jstDateKey', () {
    final m = LeaderboardMapper.toFirestoreHistory(
      kind: LeaderboardMapper.historyKindDaily,
      score: 300,
      nickname: 'Day',
      jstDateKey: '2025-03-24',
    );
    expect(m['kind'], LeaderboardMapper.historyKindDaily);
    expect(m['jstDateKey'], '2025-03-24');
  });
}
