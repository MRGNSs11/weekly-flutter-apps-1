import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardim.dart';

void main() {
  setUpAll(fontlariYukle);

  testWidgets('kasa kapalıyken kilitli notların başlığı görünmez', (t) async {
    final k = Kurulum();
    await k.hazirla(t);
    await t.pumpWidget(k.ekran());
    await t.pump();
    expect(find.text('Market listesi'), findsOneWidget);
    expect(find.text('Doğum günü'), findsNothing);
    expect(find.text('3 not camın arkasında · dokun'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('şeride dokununca kasa açılır, başlıklar görünür', (t) async {
    final k = Kurulum();
    await k.hazirla(t);
    await t.pumpWidget(k.ekran());
    await t.pump();
    await t.runAsync(() async {
      await t.tap(find.text('3 not camın arkasında · dokun'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pumpAndSettle();
    expect(find.text('Doğum günü'), findsOneWidget);
    expect(find.text('Kasa açık'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets(
    'arama Türkçe harfleri sadeleştirir, kilitliler kapalıyken çıkmaz',
    (t) async {
      final k = Kurulum();
      await k.hazirla(t);
      await t.pumpWidget(k.ekran());
      await t.pump();
      await t.enterText(find.byType(TextField), 'ALINTI');
      await t.pump();
      expect(find.text('Alıntılar'), findsOneWidget);
      expect(find.text('Market listesi'), findsNothing);
      await t.enterText(find.byType(TextField), 'pasta');
      await t.pump();
      expect(find.text('Eşleşen not yok.'), findsOneWidget);
      await k.kapat(t);
    },
  );
}
