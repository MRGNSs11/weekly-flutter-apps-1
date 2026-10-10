import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../deprem/deprem.dart';
import '../../deprem/zaman_metni.dart';
import '../tema.dart';

/// Haritayla sismogram arasındaki beyaz şerit: mor çizgiye en yakın
/// (±1,5 saat) en büyük deprem, dev puntoyla (katalog E4).
class BilgiSeridi extends StatelessWidget {
  const BilgiSeridi({
    super.key,
    required this.secili,
    required this.yukleniyor,
    required this.hata,
    required this.onYeniden,
  });

  final ValueListenable<Deprem?> secili;
  final bool yukleniyor;
  final String? hata;
  final VoidCallback onYeniden;

  static const yukseklik = 84.0;

  /// "7.0" → "7", "6.8" → "6.8" (taslaktaki gibi nokta ile).
  static String km(double d) =>
      d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(1);

  Widget _satir(String dev, String ust, String alt, {Color? devRenk}) => Row(
    children: [
      // Bricolage 800 Instrument Serif'ten geniş: kutu büyüdü, yine de
      // sığmayan bir değer olursa kesilmek yerine küçülür.
      SizedBox(
        width: 100,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            dev,
            style: Yazi.dev.copyWith(color: devRenk),
            maxLines: 1,
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ust,
              style: Yazi.yer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              alt,
              style: Yazi.alt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final Widget icerik;
    if (hata != null) {
      icerik = InkWell(
        onTap: onYeniden,
        child: _satir('!', hata!, 'Dokun, yeniden dene', devRenk: Renk.soluk),
      );
    } else if (yukleniyor) {
      icerik = _satir('–', 'Veri bekleniyor…', 'AFAD, son 7 gün');
    } else {
      icerik = ValueListenableBuilder(
        valueListenable: secili,
        builder: (_, e, _) => e == null
            ? _satir('–', 'Sakin bir an', '±1,5 saat içinde deprem yok')
            : Semantics(
                label:
                    'Büyüklük ${e.buyukluk.toStringAsFixed(1)}, ${e.kisaYer}',
                child: _satir(
                  e.buyukluk.toStringAsFixed(1),
                  e.kisaYer,
                  '${ZamanMetni.tarihSaat(e.zaman.toLocal())} · ${km(e.derinlikKm)} km derinlik',
                ),
              ),
      );
    }
    return Container(
      height: yukseklik,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Renk.yuzey,
        border: Border.symmetric(horizontal: BorderSide(color: Renk.ayrac)),
      ),
      child: icerik,
    );
  }
}
