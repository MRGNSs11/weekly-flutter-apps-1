import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../alan/bicim.dart';
import '../alan/gorev.dart';
import '../alan/not.dart';
import '../uygulama/kasa_kontrol.dart';
import '../uygulama/notlar_kontrol.dart';
import 'parcalar/arac_cubugu.dart';
import 'parcalar/renkli_kaynak.dart';
import 'tema.dart';

enum _Kayit { yok, bekliyor, kaydedildi }

/// Y3 bölünmüş düzenleyici: üstte kaynak, altta canlı önizleme.
///
/// Kaydet düğmesi yok: yazmayı bırakınca 2 sn sonra, geri tuşunda ve
/// uygulama arka plana geçince kaydedilir. Kilitli not, kasa kapanmadan
/// hemen önce (anahtar hâlâ bellekteyken) şifrelenip yazılır.
class DuzenleyiciEkrani extends StatefulWidget {
  const DuzenleyiciEkrani({
    super.key,
    required this.not,
    required this.ilkMetin,
    required this.notlar,
    required this.kasa,
  });

  final Not? not;
  final String ilkMetin;
  final NotlarKontrol notlar;
  final KasaKontrol kasa;

  @override
  State<DuzenleyiciEkrani> createState() => _DuzenleyiciEkraniState();
}

class _DuzenleyiciEkraniState extends State<DuzenleyiciEkrani> {
  static const _bekleme = Duration(seconds: 2);

  late final RenkliKaynak _kaynak;
  late final AppLifecycleListener _yasam;
  Timer? _zamanlayici;

  int? _id;
  bool _kilitli = false;
  late String _kayitli; // diske en son yazılan metin
  _Kayit _kayit = _Kayit.yok;

  @override
  void initState() {
    super.initState();
    _id = widget.not?.id;
    _kilitli = widget.not?.kilitli ?? false;
    _kayitli = widget.ilkMetin;
    _kaynak = RenkliKaynak(text: widget.ilkMetin, isaretRengi: Colors.blue)
      ..addListener(_degisti);
    _yasam = AppLifecycleListener(onHide: _kaydet);
    widget.kasa.kapanmadanOnceEkle(_kaydet);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kaynak.isaretRengi = Renkler.of(context).vurgu2;
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    widget.kasa.kapanmadanOnceCikar(_kaydet);
    _yasam.dispose();
    _odak.dispose();
    _kaynak.dispose();
    super.dispose();
  }

  late String _onceki = widget.ilkMetin;

  void _degisti() {
    final eski = _onceki;
    _onceki = _kaynak.text;
    final secim = _kaynak.selection;
    if (secim.isValid && secim.isCollapsed) {
      final d = listeDevam(eski, _kaynak.text, secim.baseOffset);
      if (d != null) return _uygula(d); // tekrar _degisti'ye girer
    }
    if (_kaynak.text == _kayitli) return;
    setState(() => _kayit = _Kayit.bekliyor);
    _zamanlayici?.cancel();
    _zamanlayici = Timer(_bekleme, _kaydet);
  }

  // Zamanlayıcı, geri tuşu ve arka plan aynı anda kaydetmek isteyebilir;
  // sıraya alınmazsa yeni not iki kez eklenir.
  Future<void> _sira = Future.value();
  Future<void> _kaydet() => _sira = _sira.then((_) => _kaydetIc());

  Future<void> _kaydetIc() async {
    _zamanlayici?.cancel();
    final metin = _kaynak.text;
    if (metin == _kayitli) return;
    final depo = widget.notlar.depo;
    if (_id == null) {
      if (metin.trim().isEmpty) return;
      _id = await depo.ekle(metin);
    } else if (_kilitli) {
      if (!widget.kasa.acik) return; // kasa kapandı: anahtar yok
      await widget.kasa.kilitliKaydet(_id!, metin);
    } else {
      await depo.guncelle(_id!, metin);
    }
    _kayitli = metin;
    if (mounted) setState(() => _kayit = _Kayit.kaydedildi);
  }

  /// Çıkışta: boş kalan not silinir, değilse kaydedilir.
  Future<void> _cikis() async {
    if (_kaynak.text.trim().isEmpty && _id != null) {
      _zamanlayici?.cancel();
      await widget.notlar.depo.sil(_id!);
      return;
    }
    await _kaydet();
  }

  Future<void> _kilitDegistir() async {
    await _kaydet();
    if (_id == null) return; // boş yeni not kilitlenmez
    if (_kilitli) {
      await widget.kasa.kilidiAc(_id!);
      setState(() => _kilitli = false);
      return;
    }
    final not = await widget.notlar.depo.getir(_id!);
    if (not == null) return;
    if (await widget.kasa.kilitle(not, widget.notlar.tumu)) {
      HapticFeedback.mediumImpact();
      setState(() => _kilitli = true);
    }
  }

  void _uygula(Duzen d) {
    _kaynak.value = TextEditingValue(
      text: d.metin,
      selection: TextSelection.collapsed(offset: d.imlec),
    );
  }

  final _odak = FocusNode();

  void _arac(Duzen Function(String metin, TextSelection s) islem) {
    final s = _kaynak.selection.isValid
        ? _kaynak.selection
        : TextSelection.collapsed(offset: _kaynak.text.length);
    HapticFeedback.selectionClick();
    _uygula(islem(_kaynak.text, s));
    _odak.requestFocus();
  }

  void _gorev(int n) {
    final yeni = gorevDegistir(_kaynak.text, n);
    if (yeni == _kaynak.text) return;
    HapticFeedback.selectionClick();
    _kaynak.value = _kaynak.value.copyWith(
      text: yeni,
      selection: TextSelection.collapsed(
        offset: _kaynak.selection.baseOffset.clamp(0, yeni.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    final kasaVar =
        widget.kasa.durum != KasaDurumu.kullanilamaz &&
        widget.kasa.durum != KasaDurumu.bozuk;
    return PopScope(
      onPopInvokedWithResult: (_, _) => _cikis(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: r.zemin,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UstBar(
                  kayit: _kayit,
                  kilitli: _kilitli,
                  kilitEtkin: kasaVar,
                  onKilit: _kilitDegistir,
                ),
                _Etiket('KAYNAK'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: r.kaynak,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _kaynak,
                      focusNode: _odak,
                      autofocus: widget.not == null,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      cursorColor: r.vurgu2,
                      style: yazi(
                        13,
                        mono: true,
                        renk: r.kaynakMetin,
                        satir: 1.6,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '# Başlık\n\nYazmaya başla…',
                        hintStyle: yazi(
                          13,
                          mono: true,
                          renk: r.soluk,
                          satir: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
                _Etiket('ÖNİZLEME'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    decoration: BoxDecoration(
                      color: r.kart,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: r.cizgi),
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: _kaynak,
                      builder: (context, deger, _) =>
                          _Onizleme(metin: deger.text, onGorev: _gorev),
                    ),
                  ),
                ),
                AracCubugu(
                  onGorev: () =>
                      _arac((m, s) => satirOneki(m, s.baseOffset, '- [ ] ')),
                  onMadde: () =>
                      _arac((m, s) => satirOneki(m, s.baseOffset, '- ')),
                  onBaslik: () =>
                      _arac((m, s) => satirOneki(m, s.baseOffset, '# ')),
                  onKalin: () =>
                      _arac((m, s) => sarmala(m, s.start, s.end, '**')),
                  onEgik: () =>
                      _arac((m, s) => sarmala(m, s.start, s.end, '*')),
                  onKod: () => _arac((m, s) => sarmala(m, s.start, s.end, '`')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UstBar extends StatelessWidget {
  const _UstBar({
    required this.kayit,
    required this.kilitli,
    required this.kilitEtkin,
    required this.onKilit,
  });

  final _Kayit kayit;
  final bool kilitli, kilitEtkin;
  final VoidCallback onKilit;

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    final dugme = yazi(13, kalinlik: FontWeight.w700, renk: r.vurgu);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back_rounded, color: r.vurgu, size: 20),
            label: Text('Notlar', style: dugme),
          ),
          const Spacer(),
          AnimatedOpacity(
            opacity: kayit == _Kayit.yok ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Text(
              kayit == _Kayit.bekliyor ? 'yazılıyor…' : 'kaydedildi',
              style: yazi(11, renk: r.soluk),
            ),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: kilitEtkin ? onKilit : null,
            icon: Icon(
              kilitli ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: r.vurgu,
              size: 18,
            ),
            label: Text(kilitli ? 'Kasadan çıkar' : 'Kilitle', style: dugme),
          ),
        ],
      ),
    );
  }
}

class _Etiket extends StatelessWidget {
  const _Etiket(this.metin);
  final String metin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(
      metin,
      style: yazi(
        10,
        renk: Renkler.of(context).soluk,
      ).copyWith(letterSpacing: 1.2),
    ),
  );
}

/// Canlı önizleme. Görev kutuları çizim sırasıyla numaralanır; dokununca
/// kaynakta aynı sıradaki `- [ ]` değişir (`gorevDegistir`).
class _Onizleme extends StatelessWidget {
  const _Onizleme({required this.metin, required this.onGorev});
  final String metin;
  final void Function(int) onGorev;

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    var sira = 0;
    final govde = yazi(14, renk: r.metin, satir: 1.45);
    return Markdown(
      data: metin,
      padding: const EdgeInsets.all(12),
      softLineBreak: true,
      checkboxBuilder: (isaretli) {
        final n = sira++;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onGorev(n),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              isaretli
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: r.vurgu,
            ),
          ),
        );
      },
      styleSheet: MarkdownStyleSheet(
        p: govde,
        listBullet: govde,
        h1: yazi(20, kalinlik: FontWeight.w700, renk: r.metin),
        h2: yazi(17, kalinlik: FontWeight.w700, renk: r.metin),
        h3: yazi(15, kalinlik: FontWeight.w700, renk: r.metin),
        strong: const TextStyle(
          fontWeight: FontWeight.w700,
          fontVariations: [FontVariation('wght', 700)],
        ),
        em: const TextStyle(fontStyle: FontStyle.italic),
        code: yazi(12.5, mono: true, renk: r.vurgu),
        codeblockDecoration: BoxDecoration(
          color: r.kaynak,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(10),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: r.vurgu2, width: 3)),
        ),
        a: TextStyle(color: r.vurgu, decoration: TextDecoration.underline),
      ),
    );
  }
}
