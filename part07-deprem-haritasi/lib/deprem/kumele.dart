import 'dart:ui' show Offset;

/// Ekranda birbirine çok yakın noktaları tek bir kümede toplar.
///
/// Izgara yöntemi: ekran [hucre] dp'lik karelere bölünür, aynı karedeki
/// noktalar bir küme olur. Kusursuz değil (iki komşu karenin sınırındaki
/// noktalar ayrı kalabilir) ama tek geçişte ve sırasız çalışır; haritanın
/// her kıpırdamasında yeniden hesaplanabilecek kadar ucuz.
class Kume<T> {
  Kume(this.uyeler, this.merkez);
  final List<T> uyeler;
  final Offset merkez;
  int get sayi => uyeler.length;
}

List<Kume<T>> kumele<T>(
  List<T> ogeler,
  Offset Function(T) konum, {
  double hucre = 58,
}) {
  final gruplar = <(int, int), List<T>>{};
  for (final o in ogeler) {
    final p = konum(o);
    final k = ((p.dx / hucre).floor(), (p.dy / hucre).floor());
    (gruplar[k] ??= []).add(o);
  }
  return [
    for (final g in gruplar.values)
      Kume(g, g.map(konum).reduce((a, b) => a + b) / g.length.toDouble()),
  ];
}
