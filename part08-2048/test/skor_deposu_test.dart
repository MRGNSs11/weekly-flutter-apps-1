import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_2048/oyun/skor_deposu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('kayıt yoksa 0', () async {
    SharedPreferences.setMockInitialValues({});
    final d = SkorDeposu(await SharedPreferences.getInstance());
    expect(d.oku(), 0);
  });

  test('yazılan okunur ve aynı anahtarda kalır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SkorDeposu(prefs).yaz(12480);
    expect(SkorDeposu(prefs).oku(), 12480);
    expect(prefs.getKeys(), {
      SkorDeposu.anahtar,
    }, reason: 'başka bir şey tutulmaz');
  });
}
