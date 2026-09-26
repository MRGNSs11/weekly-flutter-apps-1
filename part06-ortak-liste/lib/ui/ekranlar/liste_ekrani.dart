import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../liste/liste_deposu.dart';
import '../../liste/urun.dart';
import '../parcalar/kapi.dart';
import '../parcalar/karo.dart';
import '../parcalar/not_karti.dart';
import '../tema.dart';

class ListeEkrani extends StatefulWidget {
  const ListeEkrani({super.key, required this.depo, required this.liste});

  final ListeDeposu depo;
  final Liste liste;

  @override
  State<ListeEkrani> createState() => _ListeEkraniState();
}

class _ListeEkraniState extends State<ListeEkrani> {
  static const _kademe = Duration(milliseconds: 90);
  static const _yerDegistirme = Duration(milliseconds: 560);

  late Stream<List<Urun>> _akis = widget.depo.urunAkisi(widget.liste.id);
  final _girdi = TextEditingController();
  final _girdiOdak = FocusNode();

  /// Her ürünün düşme animasyonunun başlayacağı an. İlk yüklemede kademeli
  /// (90 ms arayla), sonra gelenler — öbür telefondan olanlar dahil — hemen.
  final _giris = <String, DateTime>{};
  bool _ilkYukleme = true;

  /// İşaretlenen not çizgisi oynarken yerinde kalsın: sıralamada 560 ms
  /// boyunca eski "alındı" değeri kullanılır, sonra alta iner.
  final _dondurulmus = <String, bool>{};
  final _zamanlayicilar = <Timer>[];

  bool _kopyalandi = false;
  Timer? _kopyaZamani;

  @override
  void dispose() {
    _girdi.dispose();
    _girdiOdak.dispose();
    for (final z in _zamanlayicilar) {
      z.cancel();
    }
    _kopyaZamani?.cancel();
    super.dispose();
  }

  List<Urun> _sirala(List<Urun> urunler) {
    final gorunen = {for (final u in urunler) u.id: u};
    final siralik = urunler.map(
      (u) => _dondurulmus.containsKey(u.id)
          ? Urun(
              id: u.id,
              ad: u.ad,
              alindi: _dondurulmus[u.id]!,
              ekleyen: u.ekleyen,
              olusturma: u.olusturma,
            )
          : u,
    );
    return Urun.sirala(siralik).map((u) => gorunen[u.id]!).toList();
  }

  void _girisleriKaydet(List<Urun> sirali) {
    final simdi = DateTime.now();
    for (var i = 0; i < sirali.length; i++) {
      _giris.putIfAbsent(
        sirali[i].id,
        () => _ilkYukleme ? simdi.add(_kademe * i) : simdi,
      );
    }
    if (sirali.isNotEmpty) _ilkYukleme = false;
  }

  void _isaretle(Urun u) {
    _dondurulmus.putIfAbsent(u.id, () => u.alindi);
    widget.depo.isaretle(widget.liste.id, u);
    _zamanlayicilar.add(
      Timer(_yerDegistirme, () {
        if (mounted) setState(() => _dondurulmus.remove(u.id));
      }),
    );
  }

  Future<void> _silSor(Urun u) async {
    final evet = await _onayla('“${u.ad}” silinsin mi?', 'Sil');
    if (evet) widget.depo.sil(widget.liste.id, u);
  }

  Future<void> _ayrilSor() async {
    final evet = await _onayla(
      'Listeden ayrılırsan geri dönmek için kodu yeniden girmen gerekir.',
      'Ayrıl',
    );
    if (evet) await widget.depo.ayril(widget.liste);
  }

  Future<bool> _onayla(String soru, String eylem) async {
    final cevap = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Renk.krem,
        shape: const RoundedRectangleBorder(),
        content: Text(
          soru,
          style: const TextStyle(fontSize: 16, color: Renk.murekkep),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç', style: TextStyle(color: Renk.soluk)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              eylem,
              style: const TextStyle(
                color: Renk.kiraz,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return cevap ?? false;
  }

  void _ekle() {
    final ad = Urun.adiDuzelt(_girdi.text);
    if (ad == null) return;
    widget.depo.ekle(widget.liste.id, ad);
    _girdi.clear();
    _girdiOdak.requestFocus();
  }

  void _kopyala() {
    Clipboard.setData(ClipboardData(text: widget.liste.kod));
    _kopyaZamani?.cancel();
    setState(() => _kopyalandi = true);
    _kopyaZamani = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _kopyalandi = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Kapi(
        child: SafeArea(
          child: Column(
            children: [
              _ust(),
              Expanded(
                child: StreamBuilder<List<Urun>>(
                  stream: _akis,
                  builder: (context, s) {
                    if (s.hasError) {
                      // Firestore dinleyicisi hatadan sonra kapanır; yenisi açılır.
                      return _Bilgi(
                        'Liste yüklenemedi.\nİnterneti kontrol et.',
                        onTekrar: () => setState(
                          () => _akis = widget.depo.urunAkisi(widget.liste.id),
                        ),
                      );
                    }
                    if (!s.hasData) {
                      return const Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Renk.kiraz,
                          ),
                        ),
                      );
                    }
                    if (s.data!.isEmpty) {
                      return const _Bilgi(
                        'Liste boş.\nAşağıdan ilk ürünü ekle.',
                      );
                    }
                    final sirali = _sirala(s.data!);
                    _girisleriKaydet(sirali);
                    return _izgara(sirali);
                  },
                ),
              ),
              _ekleSatiri(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ust() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KaroSatiri('liste'),
                const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: 'Liste kodu ${widget.liste.kod}, dokun kopyala',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: _kopyala,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'kod ',
                            style: TextStyle(fontSize: 11.5, color: Renk.soluk),
                          ),
                          Text(
                            widget.liste.kod,
                            style: const TextStyle(
                              fontFamily: Yazi.karo,
                              fontSize: 11.5,
                              letterSpacing: 1.6,
                              color: Renk.murekkep,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: Renk.soluk,
                          ),
                          if (_kopyalandi)
                            const Text(
                              '  kopyalandı',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Renk.kiraz,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<void>(
            tooltip: 'Liste menüsü',
            icon: const Icon(Icons.more_horiz, color: Renk.murekkep),
            color: Renk.krem,
            shape: const RoundedRectangleBorder(),
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: _ayrilSor,
                child: const Text(
                  'Listeden ayrıl',
                  style: TextStyle(color: Renk.murekkep),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// İki sütun; aynı satırdaki notlar aynı boyda (CSS grid gibi).
  Widget _izgara(List<Urun> urunler) {
    final satirlar = <Widget>[];
    for (var i = 0; i < urunler.length; i += 2) {
      satirlar.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _not(urunler[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < urunler.length
                    ? _not(urunler[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 18, 26, 10),
      itemCount: satirlar.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (_, i) => satirlar[i],
    );
  }

  Widget _not(Urun u) => NotKarti(
    key: ValueKey(u.id),
    urun: u,
    benEkledim: u.ekleyen == widget.depo.uid,
    girisZamani: _giris[u.id] ?? DateTime.now(),
    onTap: () => _isaretle(u),
    onLongPress: () => _silSor(u),
  );

  Widget _ekleSatiri() {
    const kenar = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Renk.girdiKenar, width: 1.5),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _girdi,
              focusNode: _girdiOdak,
              maxLength: Urun.azamiUzunluk,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _ekle(),
              style: const TextStyle(fontSize: 14, color: Renk.murekkep),
              decoration: const InputDecoration(
                hintText: 'Ürün ekle…',
                hintStyle: TextStyle(color: Renk.soluk),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: Renk.krem,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                enabledBorder: kenar,
                border: kenar,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Renk.kiraz, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _EkleDugmesi(onTap: _ekle),
        ],
      ),
    );
  }
}

/// 40 dp kiraz daire; basınca 0.85'e iner, yaylanarak döner.
class _EkleDugmesi extends StatefulWidget {
  const _EkleDugmesi({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_EkleDugmesi> createState() => _EkleDugmesiState();
}

class _EkleDugmesiState extends State<_EkleDugmesi> {
  bool _basili = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ekle',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _basili = true),
        onTapUp: (_) => setState(() => _basili = false),
        onTapCancel: () => setState(() => _basili = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _basili ? 0.85 : 1,
          duration: const Duration(milliseconds: 300),
          curve: yay,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Renk.kiraz,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Renk.krem, size: 22),
          ),
        ),
      ),
    );
  }
}

class _Bilgi extends StatelessWidget {
  const _Bilgi(this.metin, {this.onTekrar});

  final String metin;
  final VoidCallback? onTekrar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              metin,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Renk.soluk),
            ),
            if (onTekrar != null)
              TextButton(
                onPressed: onTekrar,
                child: const Text(
                  'Tekrar dene',
                  style: TextStyle(
                    color: Renk.kiraz,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
