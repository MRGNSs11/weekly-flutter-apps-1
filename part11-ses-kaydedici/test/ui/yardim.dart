import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/main.dart';
import 'package:ses_kaydedici/uygulama/kayit_kontrol.dart';

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
  Kurulum() {
    kontrol = KayitKontrol(
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
  late final KayitKontrol kontrol;

  SesKaydedici get uygulama => SesKaydedici(kontrol: kontrol, depo: depo);

  /// Sürekli akan animasyonlar test sonunda asılı kalmasın.
  Future<void> kapat(WidgetTester t) => t.pumpWidget(const SizedBox());
}
