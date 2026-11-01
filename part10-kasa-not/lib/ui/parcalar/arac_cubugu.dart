import 'package:flutter/material.dart';

import '../tema.dart';

/// Klavyenin hemen üstünde: telefonda `[ ]`, `#`, `*` yazmak zahmetli.
class AracCubugu extends StatelessWidget {
  const AracCubugu({
    super.key,
    required this.onGorev,
    required this.onMadde,
    required this.onBaslik,
    required this.onKalin,
    required this.onEgik,
    required this.onKod,
  });

  final VoidCallback onGorev, onMadde, onBaslik, onKalin, onEgik, onKod;

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    Widget dugme(String ipucu, Widget ikon, VoidCallback f) => Expanded(
      child: Tooltip(
        message: ipucu,
        child: InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(height: 44, child: Center(child: ikon)),
        ),
      ),
    );
    Widget harf(
      String h, {
      FontWeight k = FontWeight.w700,
      bool egik = false,
      bool mono = false,
    }) => Text(
      h,
      style: yazi(
        16,
        kalinlik: k,
        renk: r.vurgu,
        mono: mono,
      ).copyWith(fontStyle: egik ? FontStyle.italic : null),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: r.kart,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.cizgi),
      ),
      child: Row(
        children: [
          dugme(
            'Görev kutusu',
            Icon(Icons.check_box_outlined, color: r.vurgu, size: 22),
            onGorev,
          ),
          dugme(
            'Madde',
            Icon(Icons.format_list_bulleted_rounded, color: r.vurgu, size: 22),
            onMadde,
          ),
          dugme('Başlık', harf('H'), onBaslik),
          dugme('Kalın', harf('B'), onKalin),
          dugme('Eğik', harf('I', k: FontWeight.w400, egik: true), onEgik),
          dugme('Kod', harf('‹›', k: FontWeight.w400, mono: true), onKod),
        ],
      ),
    );
  }
}
