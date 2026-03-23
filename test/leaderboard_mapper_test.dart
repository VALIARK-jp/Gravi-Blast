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
}
