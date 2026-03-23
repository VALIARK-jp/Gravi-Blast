// 日本時間（UTC+9、DST なし）でのカレンダー日付。
// Firestore の「今日の一位」など日付キーに使う。端末 TZ ではなく JST の暦日で揃える。

/// [instant] の瞬間を日本時間の暦日にした `YYYY-MM-DD`。
///
/// [instant] を省略したときは `DateTime.now()`（端末のローカル時刻）を
/// UTC に直してから JST へ変換する。
String jstDateKey([DateTime? instant]) {
  final utc = (instant ?? DateTime.now()).toUtc();
  return jstDateKeyFromUtc(utc);
}

/// UTC の [utc] を日本時間の暦日にした `YYYY-MM-DD`。
String jstDateKeyFromUtc(DateTime utc) {
  if (!utc.isUtc) {
    throw ArgumentError.value(utc, 'utc', 'must be UTC');
  }
  final jst = utc.add(const Duration(hours: 9));
  final y = jst.year;
  final m = jst.month.toString().padLeft(2, '0');
  final d = jst.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
