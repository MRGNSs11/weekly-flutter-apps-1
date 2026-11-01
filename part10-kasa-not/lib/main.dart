import 'package:flutter/material.dart';

import 'alan/not.dart';
import 'kasa/yerel_kasa_servisi.dart';
import 'ui/duzenleyici_ekrani.dart';
import 'ui/liste_ekrani.dart';
import 'ui/rehber_katmani.dart';
import 'ui/tema.dart';
import 'uygulama/kasa_kontrol.dart';
import 'uygulama/notlar_kontrol.dart';
import 'uygulama/rehber_kontrol.dart';
import 'uygulama/tema_kontrol.dart';
import 'veri/not_deposu.dart';
import 'veri/veritabani.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = Veritabani();
  final depo = NotDeposu(db);
  final tema = TemaKontrol(db);
  await tema.yukle();
  final rehber = RehberKontrol(db);
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
      rehber: rehber,
    ),
  );
}

class KasaNotUygulamasi extends StatefulWidget {
  const KasaNotUygulamasi({
    super.key,
    required this.kasa,
    required this.notlar,
    required this.tema,
    required this.rehber,
  });

  final KasaKontrol kasa;
  final NotlarKontrol notlar;
  final TemaKontrol tema;
  final RehberKontrol rehber;

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
    widget.rehber.addListener(_rehberDegisti);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.rehber.ilkAcilis(),
    );
  }

  // Rehberin 2–3. adımı örnek bir düzenleyicide anlatılır; kaydetmez.
  bool _ornekAcik = false;

  void _rehberDegisti() {
    final r = widget.rehber;
    final duzenleyicide = r.aktif && r.adim.ekran == RehberEkrani.duzenleyici;
    if (duzenleyicide && !_ornekAcik) {
      _ornekAcik = true;
      _gezgin.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => DuzenleyiciEkrani(
            not: null,
            ilkMetin: '# Market listesi\n- [x] Süt\n- [ ] Ekmek\n- [ ] Domates',
            notlar: widget.notlar,
            kasa: widget.kasa,
            rehber: r.hedefler,
            ornek: true,
          ),
        ),
      );
    } else if (!duzenleyicide && _ornekAcik) {
      _ornekAcik = false;
      _gezgin.currentState?.pop();
    }
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
    widget.rehber.removeListener(_rehberDegisti);
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
    listenable: Listenable.merge([widget.tema, widget.rehber]),
    builder: (context, _) => MaterialApp(
      navigatorKey: _gezgin,
      title: 'Kasa Not',
      debugShowCheckedModeBanner: false,
      theme: temaYap(Brightness.light),
      darkTheme: temaYap(Brightness.dark),
      themeMode: widget.tema.mod,
      builder: (context, cocuk) => Stack(
        children: [
          cocuk!,
          if (widget.rehber.aktif) RehberKatmani(rehber: widget.rehber),
        ],
      ),
      home: ListeEkrani(
        notlar: widget.notlar,
        kasa: widget.kasa,
        tema: widget.tema,
        rehber: widget.rehber,
        notuAc: _notuAc,
      ),
    ),
  );
}
