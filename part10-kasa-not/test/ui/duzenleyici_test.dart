import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/ui/duzenleyici_ekrani.dart';
import 'package:kasa_not/ui/tema.dart';
import 'package:kasa_not/uygulama/tema_kontrol.dart';

import 'yardim.dart';

void main() {
  setUpAll(fontlariYukle);

  Future<Kurulum> ac(WidgetTester t, {int? id, String metin = ''}) async {
    final k = Kurulum();
    await k.hazirla(t);
    final not = id == null ? null : await t.runAsync(() => k.depo.getir(id));
    await t.pumpWidget(
      MaterialApp(
        theme: temaYap(Brightness.light),
        home: DuzenleyiciEkrani(
          not: not,
          ilkMetin: metin,
          notlar: k.notlar,
          kasa: k.kasa,
        ),
      ),
    );
    await t.pump();
    return k;
  }

  Future<String?> diskteki(WidgetTester t, Kurulum k, int id) async =>
      (await t.runAsync(() => k.depo.getir(id)))?.icerik;

  testWidgets('yazılan önizlemede anında biçimlenir', (t) async {
    final k = await ac(t);
    await t.enterText(find.byType(TextField), '# Başlık\n**kalın** yazı');
    await t.pump();
    expect(find.text('Başlık'), findsOneWidget);
    expect(find.textContaining('kalın'), findsWidgets);
    await k.kapat(t);
  });

  testWidgets('yazmayı bırakınca 2 sn sonra kaydedilir, önce değil', (t) async {
    final id = 4; // Kurulum'daki "Alıntılar" notu
    final k = await ac(t, id: id, metin: '# Alıntılar\n"Basit olan zordur."');
    await t.enterText(find.byType(TextField), '# Alıntılar\nyeni');
    await t.pump(const Duration(milliseconds: 1500));
    expect(await diskteki(t, k, id), isNot(contains('yeni')));
    expect(find.text('yazılıyor…'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 600));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump();
    expect(await diskteki(t, k, id), contains('yeni'));
    expect(find.text('kaydedildi'), findsOneWidget);
    await k.kapat(t);
  });

  testWidgets('önizlemedeki 2. kutuya dokununca kaynakta 2. görev değişir', (
    t,
  ) async {
    final k = await ac(t, metin: '# L\n- [x] Süt\n- [ ] Ekmek\n- [ ] Domates');
    await t.tap(find.byIcon(Icons.check_box_outline_blank_rounded).first);
    await t.pump();
    final kaynak = t.widget<TextField>(find.byType(TextField)).controller!.text;
    expect(kaynak, contains('- [x] Ekmek'));
    expect(kaynak, contains('- [ ] Domates'));
    await k.kapat(t);
  });

  testWidgets('boş yeni not kaydedilmez', (t) async {
    final k = await ac(t);
    await t.enterText(find.byType(TextField), '   ');
    await t.pump(const Duration(seconds: 3));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    final hepsi = await t.runAsync(() => k.depo.izle().first);
    expect(hepsi, hasLength(6));
    await k.kapat(t);
  });

  testWidgets('tema seçimi kaydedilir ve geri okunur', (t) async {
    final k = Kurulum();
    await k.hazirla(t);
    await t.runAsync(() async {
      await k.tema.sec(ThemeMode.dark);
      final yeni = TemaKontrol(k.db);
      await yeni.yukle();
      expect(yeni.mod, ThemeMode.dark);
    });
    await k.kapat(t);
  });

  testWidgets('☑ düğmesi satıra görev öneki koyar', (t) async {
    final k = await ac(t, metin: 'Ekmek');
    await t.tap(find.byTooltip('Görev kutusu'));
    await t.pump();
    final c = t.widget<TextField>(find.byType(TextField)).controller!;
    expect(c.text, '- [ ] Ekmek');
    await k.kapat(t);
  });

  testWidgets('görev satırında Enter yeni boş görev açar', (t) async {
    final k = await ac(t, metin: '- [ ] Süt');
    final c = t.widget<TextField>(find.byType(TextField)).controller!;
    c.value = const TextEditingValue(
      text: '- [ ] Süt\n',
      selection: TextSelection.collapsed(offset: 10),
    );
    await t.pump();
    expect(c.text, '- [ ] Süt\n- [ ] ');
    expect(c.selection.baseOffset, c.text.length);
    await k.kapat(t);
  });
}
