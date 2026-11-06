import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'uygulama/calar.dart';
import 'uygulama/kaydedici.dart';
import 'uygulama/kayit_kontrol.dart';
import 'uygulama/liste_kontrol.dart';
import 'ui/kayit_ekrani.dart';
import 'ui/tema.dart';
import 'veri/kayit_deposu.dart';
import 'veri/veritabani.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final depo = KayitDeposu(Veritabani());
  final kontrol = KayitKontrol(
    kaydedici: RecordKaydedici(),
    sistem: KanalSistemi(),
    depo: depo,
    klasor: _kayitKlasoru,
    boyutOku: (yol) => File(yol).length(),
  );
  final liste = ListeKontrol(
    depo: depo,
    calar: JustAudioCalar(),
    dosyaSil: (yol) => File(yol).delete(),
  );
  runApp(SesKaydedici(kontrol: kontrol, liste: liste));
}

/// Ses dosyaları uygulamanın kendi klasöründe (yedeklenmez, B5).
Future<String> _kayitKlasoru() async {
  final klasor = Directory(
    '${(await getApplicationDocumentsDirectory()).path}/kayitlar',
  );
  await klasor.create(recursive: true);
  return klasor.path;
}

class SesKaydedici extends StatelessWidget {
  const SesKaydedici({
    super.key,
    required this.kontrol,
    required this.liste,
    this.simdi,
  });

  final KayitKontrol kontrol;
  final ListeKontrol liste;

  /// Tarih yazısı için (testte sabit).
  final DateTime Function()? simdi;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ses Kaydedici',
    debugShowCheckedModeBanner: false,
    theme: tema(),
    home: KayitEkrani(kontrol: kontrol, liste: liste, simdi: simdi),
  );
}
