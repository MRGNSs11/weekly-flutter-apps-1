import 'dart:math' as math;

/// Telefonun eğiminden su yüzeyinin ekrandaki eğimi (dy/dx).
///
/// İvmeölçer yerçekimini ölçer: telefon dikken `y ≈ +9.8`, `x ≈ 0`.
/// Telefon sağa yatınca (sağ kenar aşağı) sol kenar yukarı bakar, `x` eksiye
/// düşer. Su dünyaya göre düz kalır; ekrana göre alçak tarafa, yani sağa
/// toplanır → sağda yüzey YÜKSEK (ekranda y küçük) → eğim eksi.
///
/// Açı `atan2(-x, y)`, ekrandaki eğim `-tan(açı)` = `x / y`.
abstract final class Egim {
  /// Taslaktaki üst sınır (yaklaşık 19°); daha fazlası ekrandan taşar.
  static const enFazla = .35;

  /// Telefon masada yatıyorsa x ve y ikisi de küçük; açı gürültüden ibaret.
  /// Yerçekiminin ekran düzlemindeki payı bundan azsa eğim 0 sayılır.
  static const enAzDuzlemIvme = 3.0;

  static double hesapla(double x, double y) {
    if (math.sqrt(x * x + y * y) < enAzDuzlemIvme) return 0;
    final aci = math.atan2(-x, y);
    // Telefon baş aşağıysa (|açı| > 90°) tan anlamsızlaşır; kenara yapıştır.
    if (aci.abs() >= math.pi / 2) return aci > 0 ? -enFazla : enFazla;
    return (-math.tan(aci)).clamp(-enFazla, enFazla);
  }
}
