/// Dalgaya dokunma ↔ kayıttaki an.
library;

/// Dalganın [genislik]i içinde [x]'e dokunuldu → kayıtta hangi an.
/// Dalganın dışına taşan sürükleme baş ya da sona yapışır.
Duration dokunulanKonum(double x, double genislik, Duration toplam) {
  if (genislik <= 0 || toplam <= Duration.zero) return Duration.zero;
  final oran = (x / genislik).clamp(0.0, 1.0);
  return Duration(milliseconds: (toplam.inMilliseconds * oran).round());
}

/// Konum çizgisinin yeri: 0..1.
double ilerlemeOrani(Duration konum, Duration toplam) {
  if (toplam <= Duration.zero) return 0;
  return (konum.inMilliseconds / toplam.inMilliseconds).clamp(0.0, 1.0);
}
