/// Kayıt sırasında 50 ms'de bir gelen seviyeler (0..1) dalganın kendisidir.
/// Dosyayı çözmeyiz: bu liste kayıtla birlikte saklanır, dinlerken çizilir.
library;

import 'dart:typed_data';

/// [ornekler]i [cubuk] taneye indirir. Her kova kendi en büyük değerini
/// alır, böylece kısa bir ses patlaması sıkıştırınca kaybolmaz.
/// Örnek zaten azsa olduğu gibi döner.
List<double> sikistir(List<double> ornekler, int cubuk) {
  if (cubuk <= 0 || ornekler.isEmpty) return const [];
  if (ornekler.length <= cubuk) return List.of(ornekler);
  final sonuc = List<double>.filled(cubuk, 0);
  for (var i = 0; i < cubuk; i++) {
    final bas = i * ornekler.length ~/ cubuk;
    final son = (i + 1) * ornekler.length ~/ cubuk;
    var enBuyuk = 0.0;
    for (var j = bas; j < son; j++) {
      if (ornekler[j] > enBuyuk) enBuyuk = ornekler[j];
    }
    sonuc[i] = enBuyuk;
  }
  return sonuc;
}

/// Saklama: her örnek 1 bayt (0..255). Bir saatlik kayıt ~72 KB.
Uint8List kodla(List<double> ornekler) => Uint8List.fromList([
  for (final o in ornekler) (o.clamp(0.0, 1.0) * 255).round(),
]);

List<double> coz(Uint8List baytlar) => [for (final b in baytlar) b / 255];
