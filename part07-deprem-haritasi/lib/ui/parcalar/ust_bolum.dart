import 'package:flutter/material.dart';

import '../../deprem/zaman_metni.dart';
import '../tema.dart';

/// Solda "Sismogram", sağda "● AFAD · 10:30".
///
/// Taslakta "● AFAD CANLI" yazıyordu; uygulama canlı akış almıyor, açılışta
/// ve dokununca çekiyor. "Canlı" yanlış iddia olurdu → son güncelleme saati
/// (PLAN B2.5/1). Etikete dokununca yenilenir.
class UstBolum extends StatelessWidget {
  const UstBolum({
    super.key,
    required this.sonGuncelleme,
    required this.yukleniyor,
    required this.onYenile,
  });

  final DateTime? sonGuncelleme;
  final bool yukleniyor;
  final VoidCallback? onYenile;

  @override
  Widget build(BuildContext context) {
    final etiket = yukleniyor
        ? '● AFAD · YÜKLENİYOR'
        : sonGuncelleme == null
        ? '● AFAD · YENİLE'
        : '● AFAD · ${ZamanMetni.saat(sonGuncelleme!)}';
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Sismogram', style: Yazi.baslik),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Verileri yenile',
                child: InkWell(
                  onTap: onYenile,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(etiket, style: Yazi.afad),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
