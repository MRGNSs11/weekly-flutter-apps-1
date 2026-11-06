import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/uygulama/kayit_kontrol.dart';

import 'yardim.dart';

void main() {
  // Bulut ve çizgi sürekli akar: pumpAndSettle yerine tek kare.
  Future<Kurulum> ac(WidgetTester t) async {
    final k = Kurulum();
    await t.pumpWidget(k.uygulama);
    await t.pump();
    return k;
  }

  Future<void> dokun(WidgetTester t, String etiket) async {
    await t.runAsync(() async {
      await t.tap(find.bySemanticsLabel(etiket));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await t.pump();
  }

  testWidgets('hazır: başlık, 00:00, ipucu, kayıtlar şeridi', (t) async {
    final k = await ac(t);
    expect(find.text('SES KAYDEDİCİ'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('DOKUN, KAYDET'), findsOneWidget);
    expect(find.text('Kayıtlar'), findsOneWidget);
    expect(find.bySemanticsLabel('Duraklat'), findsNothing);
    await k.kapat(t);
  });

  testWidgets('kaydet → KAYDEDİLİYOR, duraklat ve iptal görünür', (t) async {
    final k = await ac(t);
    await dokun(t, 'Kaydet');
    expect(k.kontrol.asama, Asama.kayit);
    expect(find.text('KAYDEDİLİYOR'), findsOneWidget);
    expect(find.text('DURAKLAT'), findsOneWidget);
    expect(find.text('İPTAL'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('duraklat → DURAKLATILDI + DEVAM; devam geri döner', (t) async {
    final k = await ac(t);
    await dokun(t, 'Kaydet');
    await dokun(t, 'Duraklat');
    expect(find.text('DURAKLATILDI'), findsOneWidget);
    expect(find.text('DEVAM'), findsOneWidget);
    expect(find.text('DEVAM İÇİN'), findsOneWidget);
    await dokun(t, 'Devam');
    expect(find.text('KAYDEDİLİYOR'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('durdur → hazır, kayıt sayısı 1', (t) async {
    final k = await ac(t);
    await dokun(t, 'Kaydet');
    await dokun(t, 'Durdur ve kaydet');
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump();
    expect(find.text('SES KAYDEDİCİ'), findsOneWidget);
    expect(find.text('1 ↑'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('izin reddi: açıklama + Ayarları aç + Tekrar sor', (t) async {
    final k = Kurulum()..mik.izin = false;
    await t.pumpWidget(k.uygulama);
    await t.pump();
    await dokun(t, 'Kaydet');
    expect(find.text('Mikrofon izni gerekli'), findsOneWidget);
    expect(find.text('Tekrar sor'), findsOneWidget);
    await t.tap(find.text('Ayarları aç'));
    await t.pump();
    expect(k.sistem.cagrilar, contains('ayarlariAc'));
    await k.kapat(t);
  });

  testWidgets('küçük ekranda taşma yok (360×640)', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final k = await ac(t);
    await dokun(t, 'Kaydet');
    expect(t.takeException(), isNull);
    await k.kapat(t);
  });
}
