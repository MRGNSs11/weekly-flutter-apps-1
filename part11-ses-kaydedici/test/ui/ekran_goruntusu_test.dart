// Taslakla karşılaştırma görüntüleri. CI'da çalışmaz (golden'lar işletim
// sistemine göre değişir). Üretmek için:
//   flutter test --dart-define=EKRAN=true --update-goldens test/ui/ekran_goruntusu_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardim.dart';

const _ekran = bool.fromEnvironment('EKRAN');

void main() {
  setUpAll(fontlariYukle);

  Future<void> cek(
    WidgetTester t,
    String ad,
    Future<void> Function(Kurulum k) hazirla, {
    bool izinYok = false,
    Future<void> Function(WidgetTester t, Kurulum k)? sayfa,
  }) async {
    // A56: 1080×2340, yoğunluk 3 → 360×780.
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    t.view.padding = const FakeViewPadding(top: 72, bottom: 48);
    addTearDown(t.view.reset);
    final k = Kurulum(kronometre: _SabitSure())..mik.izin = !izinYok;
    await t.pumpWidget(k.uygulama);
    await t.runAsync(() => hazirla(k));
    await t.pump();
    if (sayfa != null) {
      await t.tap(find.bySemanticsLabel('Kayıtları aç'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await sayfa(t, k);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await t.pump();
    }
    await t.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goruntu/$ad.png'),
    );
    await k.kapat(t);
  }

  Future<void> konus(Kurulum k) async {
    await k.ornekler();
    await k.kontrol.kaydet();
    // Konuşmaya benzer: dalgalı, arada sessiz.
    for (var i = 0; i < 40; i++) {
      final db = -32 + 26 * math.sin(i * .9) * math.cos(i * .23);
      k.mik.seviye.add(i % 13 > 10 ? -58 : db);
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  testWidgets(
    'hazır',
    (t) => cek(t, 'k4-hazir', (k) => k.ornekler()),
    skip: !_ekran,
  );
  testWidgets('kayıt', (t) => cek(t, 'k4-kayit', konus), skip: !_ekran);
  testWidgets(
    'duraklatıldı',
    (t) => cek(t, 'k4-duraklatildi', (k) async {
      await konus(k);
      await k.kontrol.duraklat();
    }),
    skip: !_ekran,
  );
  testWidgets(
    'kayıtlar + oynatıcı',
    (t) => cek(
      t,
      'k5-liste',
      (k) => k.ornekler(),
      sayfa: (t, k) async {
        await k.liste.sar(const Duration(seconds: 112));
        await k.liste.oynatDuraklat();
      },
    ),
    skip: !_ekran,
  );
  testWidgets(
    'ad + hız + geri al',
    (t) => cek(
      t,
      'k5-ek',
      (k) => k.ornekler(),
      sayfa: (t, k) async {
        await k.liste.sar(const Duration(seconds: 112));
        await k.liste.hizDegistir();
        await k.liste.sil(
          k.liste.kayitlar.firstWhere((x) => x.ad == 'Market listesi'),
        );
        await k.liste.oynatDuraklat();
        await k.liste.adDegistir('Fizik dersi — hafta 6');
      },
    ),
    skip: !_ekran,
  );
  testWidgets(
    'boş liste',
    (t) => cek(t, 'k5-bos', (_) async {}, sayfa: (t, k) async {}),
    skip: !_ekran,
  );
  testWidgets(
    'izin yok',
    (t) => cek(t, 'k4-izin', (k) async {
      await k.kontrol.kaydet();
      await k.kontrol.izinIsteVeBasla();
    }, izinYok: true),
    skip: !_ekran,
  );
  testWidgets(
    'ön izin',
    (t) => cek(t, 'k6-onizin', (k) => k.kontrol.kaydet(), izinYok: true),
    skip: !_ekran,
  );
}

/// Görüntülerde süre gerçekçi dursun (testte zaman akmıyor).
class _SabitSure extends Stopwatch {
  @override
  Duration get elapsed => isRunning || _baslatildi
      ? const Duration(minutes: 1, seconds: 24)
      : Duration.zero;

  bool _baslatildi = false;

  @override
  void start() {
    _baslatildi = true;
    super.start();
  }

  @override
  void reset() {
    _baslatildi = false;
    super.reset();
  }
}
