import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/alan/faz.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';
import 'package:pomodoro/bildirim/bildirim_servisi.dart';
import 'package:pomodoro/main.dart';
import 'package:pomodoro/ui/parcalar/dolgu_boyaci.dart';
import 'package:pomodoro/ui/sayac_ekrani.dart';
import 'package:pomodoro/ui/tema.dart';
import 'package:pomodoro/uygulama/pomodoro_kontrol.dart';
import 'package:pomodoro/uygulama/saat.dart';

import 'sahte/sahteler.dart';

void main() {
  late SahteSaat saat;
  setUp(() => saat = SahteSaat(DateTime.utc(2026, 10, 23, 9)));

  /// Uygulamayı sahte depo ve bildirimle kurar. Test sonunda kapatır.
  Future<PomodoroKontrol> kur(
    WidgetTester tester, {
    SahteDepo? depo,
    SahteBildirim? bildirim,
    SahteZil? zil,
  }) async {
    final k = PomodoroKontrol(
      depo: depo ?? SahteDepo(),
      bildirim: bildirim ?? SahteBildirim(),
      zil: zil ?? SahteZil(),
      saat: saat.call,
      portAdi: null,
    );
    await k.yukle();
    await tester.pumpWidget(PomodoroUygulamasi(kontrol: k));
    await tester.pump();
    return k;
  }

  /// Saniye sayacı test bitmeden durmalı.
  Future<void> kapat(WidgetTester tester, PomodoroKontrol k) async {
    await tester.pumpWidget(const SizedBox());
    k.dispose();
  }

  Future<void> bekle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('Başlat çalıştırır, ikinci dokunuş duraklatır', (tester) async {
    final k = await kur(tester);
    expect(find.bySemanticsLabel('Başlat'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('anaButon')));
    await bekle(tester);
    expect(k.durum.durum, Durum.calisiyor);
    expect(find.bySemanticsLabel('Duraklat'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('anaButon')));
    await bekle(tester);
    expect(k.durum.durum, Durum.duraklatildi);
    expect(find.bySemanticsLabel('Devam'), findsOneWidget);
    await kapat(tester, k);
  });

  testWidgets('bildirim izni reddedilince bant çıkar, sayaç yine çalışır', (
    tester,
  ) async {
    final bildirim = SahteBildirim(
      izin: const IzinDurumu(bildirim: false, kesin: true, tamEkran: true),
    )..bildirimCevabi = false;
    final k = await kur(tester, bildirim: bildirim);
    expect(find.textContaining('Bildirimler kapalı'), findsNothing);
    expect(k.bant, isNull, reason: 'sorulmadan bant gizli');

    await tester.tap(find.byKey(const ValueKey('anaButon')));
    await bekle(tester);
    expect(k.bant, Bant.bildirimKapali);
    expect(k.durum.durum, Durum.calisiyor);

    await tester.tap(find.byKey(const ValueKey('izinBandi')));
    await bekle(tester);
    expect(bildirim.istenen, contains('ayarlar'));
    await kapat(tester, k);
  });

  testWidgets('sahte saat ilerleyince kalan süre değişir', (tester) async {
    final k = await kur(tester);
    expect(find.bySemanticsLabel('Kalan süre 25:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('anaButon')));
    await bekle(tester);
    saat.ilerle(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    expect(find.bySemanticsLabel('Kalan süre 23:59'), findsOneWidget);
    await kapat(tester, k);
  });

  testWidgets('dolgu %100 iken noktalar beyaz hapın içinde (B2.5)', (
    tester,
  ) async {
    final k = await kur(
      tester,
      depo: SahteDepo(
        durum: const PomodoroDurumu(faz: Faz.kisaMola, donguSayaci: 2),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(hedefSeviye(k, azalt: false), 1);
    final dolgu = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('dolgu')),
    );
    expect((dolgu.painter! as DolguBoyaci).kare.value.seviye, 1);

    final hap = find.byKey(const ValueKey('noktaHapi'));
    final kutu = tester.widget<Container>(hap).decoration! as BoxDecoration;
    expect(kutu.color, Renk.hap);
    expect(
      find.descendant(of: hap, matching: find.byType(AnimatedContainer)),
      findsNWidgets(4),
    );
    await kapat(tester, k);
  });

  testWidgets('süre dolunca alarm ekranı açılır, Durdur kapatır', (
    tester,
  ) async {
    final bildirim = SahteBildirim();
    final zil = SahteZil();
    final k = await kur(tester, bildirim: bildirim, zil: zil);
    await tester.tap(find.byKey(const ValueKey('anaButon')));
    await bekle(tester);
    saat.ilerle(const Duration(minutes: 25));
    bildirim.alarm = true;
    await tester.pump(const Duration(seconds: 1));
    await bekle(tester);
    expect(find.byKey(const ValueKey('alarmEkrani')), findsOneWidget);
    expect(find.text('Mola zamanı'), findsOneWidget);
    expect(zil.caliyor, isTrue);

    await tester.tap(find.text('Durdur'));
    await bekle(tester);
    expect(find.byKey(const ValueKey('alarmEkrani')), findsNothing);
    expect(zil.caliyor, isFalse);
    expect(k.durum.faz, Faz.kisaMola);
    expect(k.durum.durum, Durum.bosta);
    await kapat(tester, k);
  });

  group('animasyon', () {
    testWidgets('animasyonları azalt açıkken geçişler anında', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final k = await kur(tester);
      final renk = tester.widget<TweenAnimationBuilder<Color?>>(
        find.byType(TweenAnimationBuilder<Color?>),
      );
      expect(renk.duration, Duration.zero);
      expect(tester.hasRunningAnimations, isFalse, reason: 'kenar durur');
      await kapat(tester, k);
    });

    testWidgets('nefes nabzı yalnız duraklatılmışken', (tester) async {
      final k = await kur(tester);
      DolguBoyaci boyaci() =>
          tester
                  .widget<CustomPaint>(find.byKey(const ValueKey('dolgu')))
                  .painter!
              as DolguBoyaci;

      await tester.tap(find.byKey(const ValueKey('anaButon')));
      await bekle(tester);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(boyaci().nefes.value, 0);

      await tester.tap(find.byKey(const ValueKey('anaButon')));
      await bekle(tester);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(boyaci().nefes.value, greaterThan(0.5));
      await kapat(tester, k);
    });
  });
}
