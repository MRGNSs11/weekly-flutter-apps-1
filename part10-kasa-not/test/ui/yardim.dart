import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/ui/liste_ekrani.dart';
import 'package:kasa_not/ui/tema.dart';
import 'package:kasa_not/uygulama/kasa_kontrol.dart';
import 'package:kasa_not/uygulama/notlar_kontrol.dart';
import 'package:kasa_not/uygulama/rehber_kontrol.dart';
import 'package:kasa_not/uygulama/tema_kontrol.dart';
import 'package:kasa_not/veri/not_deposu.dart';
import 'package:kasa_not/veri/veritabani.dart';

import '../sahte/sahte_kasa.dart';

Future<void> fontlariYukle() async {
  for (final (aile, dosya) in [
    ('DMSans', 'DMSans.ttf'),
    ('JetBrainsMono', 'JetBrainsMono.ttf'),
  ]) {
    final bayt = File('assets/fonts/$dosya').readAsBytesSync();
    await (FontLoader(
      aile,
    )..addFont(Future.value(ByteData.sublistView(bayt)))).load();
  }
  // İkonlar görüntülerde kare çıkmasın: Flutter SDK'nın ikon fontu.
  final flutterKoku = Platform.environment['FLUTTER_ROOT'];
  if (flutterKoku == null) return;
  final ikon = File(
    '$flutterKoku/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!ikon.existsSync()) return;
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(ikon.readAsBytesSync()))))
      .load();
}

class Kurulum {
  late Veritabani db;
  late NotDeposu depo;
  final servis = SahteKasaServisi();
  late KasaKontrol kasa;
  late NotlarKontrol notlar;
  late TemaKontrol tema;
  late RehberKontrol rehber;

  /// Örnek notlar + 3 kilitli not; kasa kapalı başlar.
  Future<void> hazirla(WidgetTester t) async {
    await t.runAsync(() async {
      db = Veritabani.test(NativeDatabase.memory());
      var dk = 0;
      depo = NotDeposu(db, saat: () => DateTime(2026, 11, 1, 10, dk++));
      kasa = KasaKontrol(servis: servis, gizlilik: SahteGizlilik(), depo: depo);
      await kasa.baslat();
      for (final m in [
        '# Hediye fikirleri\nKulaklık, kitap',
        '# Günlük — 28 Ekim\nBugün sınav sonucu açıklandı ve çok mutluyum.',
        '# Doğum günü\nPasta Cumartesi 14:00',
      ]) {
        final id = await depo.ekle(m);
        await kasa.kilitle((await depo.getir(id))!, const []);
      }
      await kasa.kapat();
      for (final m in [
        '# Alıntılar\n"Basit olan zordur."',
        '# Toplantı\nSprint sonu demo',
        '# Market listesi\n- [x] Süt\n- [ ] Ekmek\n- [ ] Domates **(2 kg)**\n\nPazardan *taze* olanı al.',
      ]) {
        await depo.ekle(m);
      }
      notlar = NotlarKontrol(depo, kasa);
      tema = TemaKontrol(db);
      rehber = RehberKontrol(db);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  }

  Widget ekran({Brightness parlaklik = Brightness.light}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: temaYap(parlaklik),
    home: ListeEkrani(
      notlar: notlar,
      kasa: kasa,
      tema: tema,
      rehber: rehber,
      notuAc: (_, _) {},
    ),
  );

  Future<void> kapat(WidgetTester t) => t
      .runAsync(() async {
        notlar.dispose();
        await db.close();
      })
      .then((_) {});
}
