import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/ui/kayitlar_sayfasi.dart';

import 'yardim.dart';

void main() {
  Future<Kurulum> ac(WidgetTester t, {bool ornek = true}) async {
    final k = Kurulum();
    await t.pumpWidget(k.uygulama);
    if (ornek) await t.runAsync(k.ornekler);
    await t.pump();
    return k;
  }

  Future<void> dokun(WidgetTester t, Finder f) async {
    await t.runAsync(() async {
      await t.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  Future<void> sayfayiAc(WidgetTester t) =>
      dokun(t, find.bySemanticsLabel('Kayıtları aç'));

  testWidgets('şeride dokun → sayfa açılır, en yeni kayıt oynatıcıda', (
    t,
  ) async {
    final k = await ac(t);
    expect(find.text('4 ↑'), findsOneWidget);
    await sayfayiAc(t);
    expect(find.text('Kayıtlar'), findsWidgets);
    expect(find.byType(OynaticiKart), findsOneWidget);
    expect(find.text('Fizik dersi'), findsOneWidget);
    expect(find.text('Bugün 10:05'), findsOneWidget);
    expect(find.text('Market listesi'), findsOneWidget);
    expect(find.text('Dün 18:20'), findsOneWidget);
    expect(find.text('04:48'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('dalgaya dokun → o noktaya sarar', (t) async {
    final k = await ac(t);
    await sayfayiAc(t);
    final dalga = find.bySemanticsLabel('Dalga, dokun ve sar');
    final kutu = t.getRect(dalga);
    await dokun(t, dalga);
    // Ortaya dokunuldu → toplamın yarısı (04:48 / 2 = 02:24).
    expect(k.calar.cagrilar.last, 'sar 144');
    expect(find.text('02:24'), findsOneWidget);
    expect(kutu.width, greaterThan(200));
    await k.kapat(t);
  });

  testWidgets('hız hapı döner', (t) async {
    final k = await ac(t);
    await sayfayiAc(t);
    await dokun(t, find.bySemanticsLabel('Hız 1x'));
    expect(find.text('1,5x'), findsOneWidget);
    await dokun(t, find.bySemanticsLabel('Hız 1,5x'));
    expect(find.text('2x'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('başka satıra dokun → o kayıt oynatıcıya geçer', (t) async {
    final k = await ac(t);
    // Sahte çalar süre bilmesin: kayıttaki süre gösterilir.
    k.calar.sure = null;
    await sayfayiAc(t);
    await dokun(t, find.text('Toplantı'));
    expect(k.liste.secili!.ad, 'Toplantı');
    expect(find.text('22:15'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('sil → mesaj, geri al → geri gelir', (t) async {
    final k = await ac(t);
    await sayfayiAc(t);
    await dokun(t, find.bySemanticsLabel('Sil'));
    expect(find.text('"Fizik dersi" silindi'), findsOneWidget);
    await dokun(t, find.bySemanticsLabel('Geri al'));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump();
    expect(k.liste.kayitlar, hasLength(4));
    expect(find.text('"Fizik dersi" silindi'), findsNothing);
    await k.kapat(t);
  });

  testWidgets('ada dokun → düzenle → ✓', (t) async {
    final k = await ac(t);
    await sayfayiAc(t);
    await dokun(t, find.bySemanticsLabel('Yeniden adlandır'));
    await t.enterText(find.byType(TextField), 'Fizik dersi — hafta 6');
    await dokun(t, find.bySemanticsLabel('Adı kaydet'));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump();
    expect(find.text('Fizik dersi — hafta 6'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('Paylaş → seçili kayıt paylaşılır', (t) async {
    final k = await ac(t);
    await sayfayiAc(t);
    await dokun(t, find.bySemanticsLabel('Paylaş'));
    expect(k.paylasilanlar, ['Fizik dersi']);
    await k.kapat(t);
  });

  testWidgets('boş liste', (t) async {
    final k = await ac(t, ornek: false);
    await sayfayiAc(t);
    expect(find.text('Henüz kayıt yok'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('kayıt sırasında sayfa açılmaz', (t) async {
    final k = await ac(t);
    await dokun(t, find.bySemanticsLabel('Kaydet'));
    await sayfayiAc(t);
    expect(find.byType(KayitlarSayfasi), findsNothing);
    await k.kapat(t);
  });

  testWidgets('kapat: üstteki bulut alanına dokun', (t) async {
    final k = await ac(t);
    await sayfayiAc(t);
    await t.tapAt(const Offset(200, 60));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(KayitlarSayfasi), findsNothing);
    await k.kapat(t);
  });
}
