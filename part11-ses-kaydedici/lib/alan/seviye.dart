/// `record` paketinin verdiği ses seviyesi dBFS'tir: 0 en yüksek, sessizlik
/// -160'a kadar iner. Çizim 0..1 ister.
library;

/// Bunun altı sessizlik sayılır (oda gürültüsü çizgiyi oynatmasın).
const sessizlikEsigi = -60.0;

/// dBFS → 0..1. Eşik ve altı 0, 0 dB ve üstü 1, arası doğrusal.
double seviye(double dbfs) {
  if (dbfs.isNaN || dbfs <= sessizlikEsigi) return 0;
  if (dbfs >= 0) return 1;
  return (dbfs - sessizlikEsigi) / -sessizlikEsigi;
}
