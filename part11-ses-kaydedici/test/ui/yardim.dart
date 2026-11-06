import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/main.dart';
import 'package:ses_kaydedici/uygulama/kayit_kontrol.dart';
import 'package:ses_kaydedici/uygulama/liste_kontrol.dart';

import '../sahte/sahte.dart';

/// Görüntülerde gerçek yazı: Outfit + Flutter'ın ikon fontu.
Future<void> fontlariYukle() async {
  final bayt = File('assets/fonts/Outfit.ttf').readAsBytesSync();
  await (FontLoader(
    'Outfit',
  )..addFont(Future.value(ByteData.sublistView(bayt)))).load();
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

/// Sahte mikrofon + bellek içi depo ile uygulamanın kendisi.
class Kurulum {
  Kurulum({Stopwatch? kronometre}) {
    kontrol = KayitKontrol(
      kronometre: kronometre,
      kaydedici: mik,
      sistem: sistem,
      depo: depo,
      klasor: () async => '/kayitlar',
      boyutOku: (_) async => 300 * 1024,
      saat: () => DateTime(2026, 11, 6, 14, 32),
    );
  }

  final mik = SahteKaydedici();
  final sistem = SahteSistem();
  final depo = SahteDepo();
  final calar = SahteCalar();
  final silinenDosyalar = <String>[];
  final paylasilanlar = <String>[];
  late final KayitKontrol kontrol;
  late final ListeKontrol liste = ListeKontrol(
    depo: depo,
    calar: calar,
    dosyaSil: (yol) async => silinenDosyalar.add(yol),
    paylasici: (k) async => paylasilanlar.add(k.ad),
    geriAlSuresi: const Duration(seconds: 5),
  );

  SesKaydedici get uygulama => SesKaydedici(
    kontrol: kontrol,
    liste: liste,
    simdi: () => DateTime(2026, 11, 6, 14, 40),
  );

  /// Örnek kayıtlar (taslaktaki adlar).
  Future<void> ornekler() async {
    final dalga = [
      for (var i = 0; i < 300; i++)
        (0.55 + 0.45 * math.sin(i * .37) * math.cos(i * .11)).abs() *
            (i % 47 > 40 ? .1 : 1),
    ];
    for (final (ad, t, sn) in [
      ('08:12', DateTime(2026, 11, 6, 8, 12), 63),
      ('Toplantı', DateTime(2026, 11, 5, 9, 30), 1335),
      ('Market listesi', DateTime(2026, 11, 5, 18, 20), 41),
      ('Fizik dersi', DateTime(2026, 11, 6, 10, 5), 288),
    ]) {
      await depo.ekle(
        ad: ad,
        dosyaYolu: '/kayitlar/$ad.ogg',
        sure: Duration(seconds: sn),
        boyutBayt: sn * 4000,
        dalga: dalga,
        olusturma: t,
      );
    }
  }

  /// Sürekli akan animasyonlar test sonunda asılı kalmasın.
  Future<void> kapat(WidgetTester t) => t.pumpWidget(const SizedBox());
}
