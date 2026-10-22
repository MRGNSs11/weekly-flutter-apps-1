import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/deneme_saat.dart';

void main() {
  test('tz.UTC saat dilimi verisi yüklenmeden aynı anı verir', () {
    final an = DateTime(2026, 10, 22, 23, 50);
    final z = utcZaman(an);
    expect(z.millisecondsSinceEpoch, an.millisecondsSinceEpoch);
    expect(z.timeZoneOffset, Duration.zero);
  });
}
