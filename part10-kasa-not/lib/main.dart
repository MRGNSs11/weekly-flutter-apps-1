import 'package:flutter/material.dart';

import 'alan/not.dart';
import 'kasa/yerel_kasa_servisi.dart';
import 'ui/duzenleyici_ekrani.dart';
import 'ui/liste_ekrani.dart';
import 'ui/tema.dart';
import 'uygulama/kasa_kontrol.dart';
import 'uygulama/notlar_kontrol.dart';
import 'uygulama/tema_kontrol.dart';
import 'veri/not_deposu.dart';
import 'veri/veritabani.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = Veritabani();
  final depo = NotDeposu(db);
  final tema = TemaKontrol(db);
  await tema.yukle();
  final kasa = KasaKontrol(
    servis: YerelKasaServisi(),
    gizlilik: KanalGizlilik(),
    depo: depo,
  );
  await kasa.baslat();
  runApp(
    KasaNotUygulamasi(
      kasa: kasa,
      notlar: NotlarKontrol(depo, kasa),
      tema: tema,
    ),
  );
}

class KasaNotUygulamasi extends StatefulWidget {
  const KasaNotUygulamasi({
    super.key,
    required this.kasa,
    required this.notlar,
    required this.tema,
  });

  final KasaKontrol kasa;
  final NotlarKontrol notlar;
  final TemaKontrol tema;

  @override
  State<KasaNotUygulamasi> createState() => _KasaNotUygulamasiState();
}

class _KasaNotUygulamasiState extends State<KasaNotUygulamasi> {
  final _gezgin = GlobalKey<NavigatorState>();
  late final AppLifecycleListener _yasam;

  @override
  void initState() {
    super.initState();
    _yasam = AppLifecycleListener(onStateChange: widget.kasa.yasamDegisti);
    // Kasa kapanınca açık kilitli not ekranı listeye döner.
    widget.kasa.addListener(_kasaDegisti);
  }

  bool _kilitliNotAcik = false;

  void _kasaDegisti() {
    if (!widget.kasa.acik && _kilitliNotAcik) {
      _kilitliNotAcik = false;
      _gezgin.currentState?.popUntil((r) => r.isFirst);
    }
  }

  @override
  void dispose() {
    _yasam.dispose();
    widget.kasa.removeListener(_kasaDegisti);
    super.dispose();
  }

  Future<void> _notuAc(BuildContext context, Not? not) async {
    if (not != null && not.kilitli && !widget.kasa.acik) {
      if (!await widget.kasa.ac(widget.notlar.tumu)) return;
    }
    final metin = not == null
        ? ''
        : (not.kilitli ? widget.kasa.cozulmus(not.id) : not.icerik) ?? '';
    _kilitliNotAcik = not?.kilitli ?? false;
    await _gezgin.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => DuzenleyiciEkrani(
          not: not,
          ilkMetin: metin,
          notlar: widget.notlar,
          kasa: widget.kasa,
        ),
      ),
    );
    _kilitliNotAcik = false;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.tema,
    builder: (context, _) => MaterialApp(
      navigatorKey: _gezgin,
      title: 'Kasa Not',
      debugShowCheckedModeBanner: false,
      theme: temaYap(Brightness.light),
      darkTheme: temaYap(Brightness.dark),
      themeMode: widget.tema.mod,
      home: ListeEkrani(
        notlar: widget.notlar,
        kasa: widget.kasa,
        tema: widget.tema,
        notuAc: _notuAc,
      ),
    ),
  );
}
