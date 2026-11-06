/// Oynatma hızı: tek hap, her dokunuşta bir sonraki.
library;

const hizlar = [1.0, 1.5, 2.0];

/// 1x → 1,5x → 2x → 1x. Listede olmayan bir hız 1x'e döner.
double sonrakiHiz(double hiz) {
  final i = hizlar.indexOf(hiz);
  return i == -1 ? hizlar.first : hizlar[(i + 1) % hizlar.length];
}

/// `1x`, `1,5x`, `2x`.
String hizYaz(double hiz) {
  final metin = hiz == hiz.roundToDouble()
      ? hiz.toInt().toString()
      : hiz.toString().replaceAll('.', ',');
  return '${metin}x';
}
