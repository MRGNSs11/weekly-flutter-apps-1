import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../deprem/deprem.dart';
import '../../deprem/zaman_metni.dart';
import '../tema.dart';

/// Mürekkep zeminli, sola kayan son-depremler bandı (katalog E7).
///
/// Paket yok (`marquee` 23 aydır güncellenmiyor): içerik iki kez yan yana
/// diziliyor, ilk kopyanın genişliği kadar kayınca başa sarıyor.
class KayanBant extends StatefulWidget {
  const KayanBant({super.key, required this.olaylar, this.durumMetni});

  final List<Deprem> olaylar;

  /// Doluysa kayan içerik yerine sabit bu metin yazılır (yükleniyor/hata).
  final String? durumMetni;

  static const yukseklik = 30.0;
  static const hiz = 28.0; // dp/sn
  static const adet = 14;

  @override
  State<KayanBant> createState() => _KayanBantState();
}

class _KayanBantState extends State<KayanBant>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tik)..start();
  final _kaydirma = ValueNotifier<double>(0);
  final _ilkKopya = GlobalKey();
  Duration? _onceki;

  void _tik(Duration gecen) {
    final dt = _onceki == null ? 0.0 : (gecen - _onceki!).inMicroseconds / 1e6;
    _onceki = gecen;
    final w = _ilkKopya.currentContext?.size?.width ?? 0;
    if (w <= 0) return;
    var x = _kaydirma.value - KayanBant.hiz * dt;
    if (-x >= w) x += w;
    _kaydirma.value = x;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  Widget _kopya({Key? key}) {
    final son = widget.olaylar.reversed.take(KayanBant.adet);
    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in son)
          Padding(
            padding: const EdgeInsets.only(right: 26),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: e.buyukluk.toStringAsFixed(1),
                    style: Yazi.bantSayi,
                  ),
                  TextSpan(
                    text:
                        ' ${e.kisaYer} · ${ZamanMetni.saat(e.zaman.toLocal())}',
                  ),
                ],
              ),
              style: Yazi.bant,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final metin = widget.durumMetni;
    return Container(
      height: KayanBant.yukseklik,
      color: Renk.murekkep,
      alignment: Alignment.centerLeft,
      child: metin != null || widget.olaylar.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                metin ?? 'Son 7 günde deprem kaydı yok',
                style: Yazi.bant,
              ),
            )
          : ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: ValueListenableBuilder(
                  valueListenable: _kaydirma,
                  builder: (_, x, child) =>
                      Transform.translate(offset: Offset(x, 0), child: child),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _kopya(key: _ilkKopya),
                      _kopya(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
