import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/ui/liste_ekrani.dart';
import 'package:kasa_not/ui/rehber_katmani.dart';
import 'package:kasa_not/ui/tema.dart';
import 'package:kasa_not/uygulama/rehber_kontrol.dart';

import 'yardim.dart';

void main() {
  setUpAll(fontlariYukle);

  Widget uygulama(Kurulum k) => MaterialApp(
    theme: temaYap(Brightness.light),
    builder: (c, cocuk) => ListenableBuilder(
      listenable: k.rehber,
      builder: (c, _) => Stack(
        children: [
          cocuk!,
          if (k.rehber.aktif) RehberKatmani(rehber: k.rehber),
        ],
      ),
    ),
    home: ListeEkrani(
      notlar: k.notlar,
      kasa: k.kasa,
      tema: k.tema,
      rehber: k.rehber,
      notuAc: (_, _) {},
    ),
  );

  testWidgets('ilk açılışta tur başlar, bitince bir daha başlamaz', (t) async {
    final k = Kurulum();
    await k.hazirla(t);
    await t.runAsync(() => k.rehber.ilkAcilis());
    expect(k.rehber.aktif, isTrue);
    await t.runAsync(() async {
      k.rehber.bitir();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final yeni = RehberKontrol(k.db);
      await yeni.ilkAcilis();
      expect(yeni.aktif, isFalse);
    });
    await k.kapat(t);
  });

  testWidgets('balon adımı anlatır, Sonraki ilerletir, son adımda Bitir', (
    t,
  ) async {
    final k = Kurulum();
    await k.hazirla(t);
    await t.pumpWidget(uygulama(k));
    k.rehber.baslat();
    await t.pump();
    await t.pump();
    expect(find.text('Yeni not'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    await t.tap(find.text('Sonraki →'));
    await t.pump();
    expect(k.rehber.adimNo, 1);
    // Son adım
    while (k.rehber.adimNo < 5) {
      k.rehber.ileri();
    }
    await t.pump();
    await t.pump();
    expect(find.text('Bitir ✓'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('tur sırasında hedef dışına dokunmak hiçbir şey yapmaz', (
    t,
  ) async {
    final k = Kurulum();
    await k.hazirla(t);
    await t.pumpWidget(uygulama(k));
    k.rehber.baslat();
    await t.pump();
    await t.pump();
    await t.tapAt(const Offset(20, 300));
    await t.pump();
    expect(k.rehber.adimNo, 0);
    expect(k.rehber.aktif, isTrue);
    await k.kapat(t);
  });

  testWidgets('? düğmesi turu yeniden başlatır', (t) async {
    final k = Kurulum();
    await k.hazirla(t);
    await t.pumpWidget(uygulama(k));
    await t.tap(find.byTooltip('Rehber'));
    await t.pump();
    expect(k.rehber.aktif, isTrue);
    expect(k.rehber.adimNo, 0);
    await k.kapat(t);
  });
}
