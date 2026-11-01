import 'package:flutter/material.dart';

import '../../uygulama/kasa_kontrol.dart';
import '../tema.dart';

/// Alttaki kasa şeridi: parmak izi ikonu + durum yazısı.
class KasaSeridi extends StatefulWidget {
  const KasaSeridi({
    super.key,
    required this.kasa,
    required this.kilitliSayisi,
    required this.onAc,
    required this.onKapat,
  });

  final KasaKontrol kasa;
  final int kilitliSayisi;
  final VoidCallback onAc;
  final VoidCallback onKapat;

  @override
  State<KasaSeridi> createState() => _KasaSeridiState();
}

class _KasaSeridiState extends State<KasaSeridi>
    with SingleTickerProviderStateMixin {
  // Doğrulanırken parmak izi nabzı
  late final _nabiz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(KasaSeridi eski) {
    super.didUpdateWidget(eski);
    final dogrulaniyor = widget.kasa.durum == KasaDurumu.dogrulaniyor;
    if (dogrulaniyor && !_nabiz.isAnimating) {
      if (!MediaQuery.disableAnimationsOf(context)) {
        _nabiz.repeat(reverse: true);
      }
    } else if (!dogrulaniyor && _nabiz.isAnimating) {
      _nabiz.animateTo(0, duration: const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _nabiz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    final k = widget.kasa;
    final n = widget.kilitliSayisi;

    final (ikon, yazi_, dokun) = switch (k.durum) {
      KasaDurumu.yukleniyor => (Icons.fingerprint_rounded, '…', null),
      KasaDurumu.kullanilamaz => (
        Icons.no_encryption_gmailerrorred_rounded,
        'Telefonda ekran kilidi yok, kasa kullanılamaz',
        null,
      ),
      KasaDurumu.kapali => (
        Icons.fingerprint_rounded,
        n == 0
            ? 'Kasa boş · bir notu basılı tutup kilitle'
            : '$n not camın arkasında · dokun',
        n == 0 ? null : widget.onAc,
      ),
      KasaDurumu.dogrulaniyor => (
        Icons.fingerprint_rounded,
        'Parmak izini okut…',
        null,
      ),
      KasaDurumu.acik => (Icons.lock_open_rounded, 'Kasa açık', widget.onKapat),
      KasaDurumu.bozuk => (
        Icons.error_outline_rounded,
        k.hata ?? 'Kasa açılamıyor',
        widget.onAc,
      ),
    };

    return Material(
      color: r.serit,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: dokun,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.25).animate(_nabiz),
                child: Icon(ikon, size: 28, color: r.vurgu2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(yazi_, style: yazi(13, renk: r.seritMetin)),
              ),
              if (k.durum == KasaDurumu.acik)
                Text(
                  'Kapat',
                  style: yazi(13, kalinlik: FontWeight.w700, renk: r.vurgu2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
