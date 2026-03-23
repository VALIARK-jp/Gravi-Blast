import 'package:flutter_test/flutter_test.dart';
import 'package:graviblast/utils/jst_date.dart';

void main() {
  test('JST date key: UTC midnight crosses JST date', () {
    // 2025-03-23 15:00 UTC = 2025-03-24 00:00 JST
    final utc = DateTime.utc(2025, 3, 23, 15, 0);
    expect(jstDateKeyFromUtc(utc), '2025-03-24');
  });

  test('JST date key: same calendar day in Tokyo', () {
    final utc = DateTime.utc(2025, 3, 24, 10, 30);
    expect(jstDateKeyFromUtc(utc), '2025-03-24');
  });
}
