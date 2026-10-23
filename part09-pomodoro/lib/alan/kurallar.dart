// Pomodoro kuralları (PLAN K3–K4). Saf fonksiyonlar: hepsi `simdi` alır,
// hiçbiri durumu değiştirmez, geçersiz eylemde durumu olduğu gibi döndürür.
import 'ayarlar.dart';
import 'faz.dart';
import 'pomodoro_durumu.dart';

const _birDakika = Duration(minutes: 1);

/// Yerel tarih anahtarı, `YYYY-AA-GG`.
String gunAnahtari(DateTime an) {
  final y = an.toLocal();
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${y.year}-${iki(y.month)}-${iki(y.day)}';
}

/// Tembel tamamlama (PLAN K3): bitiş anı geçtiyse fazı tamamlar ve sıradaki
/// fazı `bosta` kurar. Saatlerce kapalı kalınsa da yalnız bir faz tamamlanır.
PomodoroDurumu ilerlet(PomodoroDurumu d, DateTime simdi) {
  final bitis = d.bitis;
  if (d.durum != Durum.calisiyor || bitis == null) return d;
  if (simdi.isBefore(bitis)) return d;
  return _gec(d, say: true, tamamlanma: bitis);
}

PomodoroDurumu _gec(
  PomodoroDurumu d, {
  required bool say,
  DateTime? tamamlanma,
}) {
  var dongu = d.donguSayaci;
  var bugun = d.bugunSayisi;
  var gun = d.gun;
  if (d.faz == Faz.calisma && say) {
    final tarih = gunAnahtari(tamamlanma!);
    if (tarih != gun) {
      gun = tarih;
      bugun = 0;
    }
    bugun++;
    dongu++;
  }
  final sonraki = siradakiFaz(d.faz, dongu);
  if (d.faz == Faz.uzunMola) dongu = 0;
  return PomodoroDurumu(
    faz: sonraki,
    donguSayaci: dongu.clamp(0, 4),
    bugunSayisi: bugun,
    gun: gun,
  );
}

PomodoroDurumu baslat(PomodoroDurumu d, Ayarlar a, DateTime simdi) {
  d = ilerlet(d, simdi);
  if (d.durum != Durum.bosta) return d;
  final sure = a.sure(d.faz);
  return d.kopya(
    durum: Durum.calisiyor,
    bitis: () => simdi.toUtc().add(sure),
    kalan: () => null,
    toplam: () => sure,
  );
}

PomodoroDurumu duraklat(PomodoroDurumu d, DateTime simdi) {
  d = ilerlet(d, simdi);
  if (d.durum != Durum.calisiyor) return d;
  return d.kopya(
    durum: Durum.duraklatildi,
    kalan: () => d.bitis!.difference(simdi),
    bitis: () => null,
  );
}

PomodoroDurumu devam(PomodoroDurumu d, DateTime simdi) {
  d = ilerlet(d, simdi);
  if (d.durum != Durum.duraklatildi) return d;
  return d.kopya(
    durum: Durum.calisiyor,
    bitis: () => simdi.toUtc().add(d.kalan!),
    kalan: () => null,
  );
}

PomodoroDurumu dakikaEkle(PomodoroDurumu d, DateTime simdi) {
  d = ilerlet(d, simdi);
  final toplam = (d.toplam ?? Duration.zero) + _birDakika;
  return switch (d.durum) {
    Durum.calisiyor => d.kopya(
      bitis: () => d.bitis!.add(_birDakika),
      toplam: () => toplam,
    ),
    Durum.duraklatildi => d.kopya(
      kalan: () => d.kalan! + _birDakika,
      toplam: () => toplam,
    ),
    Durum.bosta => d,
  };
}

/// Aynı fazda `bosta`. Sayılmaz.
PomodoroDurumu bitir(PomodoroDurumu d, DateTime simdi) {
  d = ilerlet(d, simdi);
  if (d.durum == Durum.bosta) return d;
  return PomodoroDurumu(
    faz: d.faz,
    donguSayaci: d.donguSayaci,
    bugunSayisi: d.bugunSayisi,
    gun: d.gun,
  );
}

/// Sıradaki fazda `bosta`. Sayılmaz.
PomodoroDurumu atla(PomodoroDurumu d, DateTime simdi) =>
    _gec(ilerlet(d, simdi), say: false);

/// Bildirim butonlarının kimlikleri (PLAN K6.4) → eylem.
/// Bilinmeyen kimlik durumu değiştirmez.
PomodoroDurumu eylem(String ad, PomodoroDurumu d, Ayarlar a, DateTime simdi) =>
    switch (ad) {
      'baslat' => baslat(d, a, simdi),
      'duraklat' => duraklat(d, simdi),
      'devam' => devam(d, simdi),
      'dakika_ekle' => dakikaEkle(d, simdi),
      'bitir' => bitir(d, simdi),
      'atla' => atla(d, simdi),
      _ => ilerlet(d, simdi),
    };

/// Kalan süre. `bosta` iken fazın tam süresi.
Duration kalanSure(PomodoroDurumu d, Ayarlar a, DateTime simdi) =>
    switch (d.durum) {
      Durum.calisiyor => _negatifDegil(d.bitis!.difference(simdi)),
      Durum.duraklatildi => d.kalan!,
      Durum.bosta => a.sure(d.faz),
    };

/// Geçen sürenin toplama oranı, 0–1. `bosta` iken 0.
double ilerleme(PomodoroDurumu d, DateTime simdi) {
  final toplam = d.toplam;
  if (d.durum == Durum.bosta || toplam == null || toplam == Duration.zero) {
    return 0;
  }
  final kalan = d.durum == Durum.calisiyor
      ? _negatifDegil(d.bitis!.difference(simdi))
      : d.kalan!;
  return (1 - kalan.inMilliseconds / toplam.inMilliseconds).clamp(0.0, 1.0);
}

/// Ekranda gösterilecek "Bugün N": kayıt bugüne ait değilse 0.
int bugunGoster(PomodoroDurumu d, DateTime simdi) =>
    d.gun == gunAnahtari(simdi) ? d.bugunSayisi : 0;

Duration _negatifDegil(Duration x) => x.isNegative ? Duration.zero : x;
