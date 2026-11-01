// Taslakla karşılaştırma görüntüleri. CI'da çalışmaz (golden'lar işletim
// sistemine göre değişir). Üretmek için:
//   flutter test --dart-define=EKRAN=true --update-goldens test/ui/ekran_goruntusu_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasa_not/ui/duzenleyici_ekrani.dart';
import 'package:kasa_not/ui/tema.dart';

import 'yardim.dart';

const _ekran = bool.fromEnvironment('EKRAN');

void main() {
  setUpAll(fontlariYukle);

  Future<void> cek(
    WidgetTester t,
    String ad,
    Brightness p, {
    bool ac = false,
    Duration? ara,
  }) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final k = Kurulum();
    await k.hazirla(t);
    await t.pumpWidget(k.ekran(parlaklik: p));
    await t.pump();
    if (ac) {
      await t.runAsync(() async {
        await k.kasa.ac(k.notlar.tumu);
      });
      await t.pump();
      if (ara != null) {
        await t.pump(ara);
      } else {
        await t.pumpAndSettle();
      }
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goruntu/$ad.png'),
    );
    await k.kapat(t);
  }

  testWidgets(
    'aydınlık kapalı',
    (t) => cek(t, 'k4-aydinlik-kapali', Brightness.light),
    skip: !_ekran,
  );
  testWidgets(
    'karanlık kapalı',
    (t) => cek(t, 'k4-karanlik-kapali', Brightness.dark),
    skip: !_ekran,
  );
  testWidgets(
    'aydınlık açılıyor',
    (t) => cek(
      t,
      'k4-aydinlik-aciliyor',
      Brightness.light,
      ac: true,
      ara: const Duration(milliseconds: 300),
    ),
    skip: !_ekran,
  );
  testWidgets(
    'aydınlık açık',
    (t) => cek(t, 'k4-aydinlik-acik', Brightness.light, ac: true),
    skip: !_ekran,
  );
  testWidgets(
    'karanlık açık',
    (t) => cek(t, 'k4-karanlik-acik', Brightness.dark, ac: true),
    skip: !_ekran,
  );

  Future<void> duzenleyici(WidgetTester t, String ad, Brightness p) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final k = Kurulum();
    await k.hazirla(t);
    const metin = '''
# Market listesi

- [x] Süt
- [ ] Ekmek
- [ ] Domates **(2 kg)**

Pazardan *taze* olanı al.

```
toplam ≈ 180 ₺
```''';
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaYap(p),
        home: DuzenleyiciEkrani(
          not: null,
          ilkMetin: metin,
          notlar: k.notlar,
          kasa: k.kasa,
        ),
      ),
    );
    await t.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goruntu/$ad.png'),
    );
    await k.kapat(t);
  }

  testWidgets(
    'düzenleyici aydınlık',
    (t) => duzenleyici(t, 'k5-duzenleyici-aydinlik', Brightness.light),
    skip: !_ekran,
  );
  testWidgets(
    'düzenleyici karanlık',
    (t) => duzenleyici(t, 'k5-duzenleyici-karanlik', Brightness.dark),
    skip: !_ekran,
  );
}
