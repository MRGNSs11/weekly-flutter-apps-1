// Bildirim başlık ve gövdeleri (PLAN K6.3). Saf fonksiyonlar.
import '../alan/faz.dart';
import '../alan/kurallar.dart';
import '../alan/pomodoro_durumu.dart';

const fazAdi = {
  Faz.calisma: 'Çalışma',
  Faz.kisaMola: 'Kısa mola',
  Faz.uzunMola: 'Uzun mola',
};

/// Süre dolunca, başlayacak faza göre başlık.
const bittiBasligi = {
  Faz.calisma: 'Çalışma zamanı',
  Faz.kisaMola: 'Mola zamanı',
  Faz.uzunMola: 'Uzun mola zamanı',
};

String _iki(int n) => n.toString().padLeft(2, '0');

/// Yerel saat, `HH:mm`.
String saatDakika(DateTime an) {
  final y = an.toLocal();
  return '${_iki(y.hour)}:${_iki(y.minute)}';
}

/// `mm:ss`. Saniye yukarı yuvarlanır: 0,4 sn kala `00:01` görünür.
String dakikaSaniye(Duration d) {
  final sn = d.isNegative ? 0 : (d.inMilliseconds / 1000).ceil();
  return '${_iki(sn ~/ 60)}:${_iki(sn % 60)}';
}

/// Ayar süresi: `25 dk`, `1 dk 30 sn`, `45 sn`.
String sureYazisi(int saniye) {
  final dk = saniye ~/ 60;
  final sn = saniye % 60;
  if (sn == 0) return '$dk dk';
  if (dk == 0) return '$sn sn';
  return '$dk dk $sn sn';
}

/// `Çalışma · 2/4`, molada `Kısa mola` / `Uzun mola`.
String fazEtiketi(PomodoroDurumu d) => d.faz == Faz.calisma
    ? 'Çalışma · ${(d.donguSayaci + 1).clamp(1, 4)}/4'
    : fazAdi[d.faz]!;

String sayacGovdesi(PomodoroDurumu d) => 'Bitiş ${saatDakika(d.bitis!)}';

String duraklatildiBasligi(PomodoroDurumu d) =>
    'Duraklatıldı · ${fazAdi[d.faz]}';

String duraklatildiGovdesi(PomodoroDurumu d) =>
    'Kalan ${dakikaSaniye(d.kalan!)}';

/// "Süre doldu" metni. Zamanlarken hesaplanır: faz tamamlanınca oluşacak
/// durumdan (sıradaki faz ve günün sayısı).
({String baslik, String govde, Faz siradaki}) bittiMetni(PomodoroDurumu d) {
  final sonra = d.bitis == null ? d : ilerlet(d, d.bitis!);
  return alarmMetni(sonra, sonra.bugunSayisi);
}

/// Faz tamamlandıktan sonraki (`bosta`) durum için alarm metni.
({String baslik, String govde, Faz siradaki}) alarmMetni(
  PomodoroDurumu d,
  int bugun,
) => (
  baslik: bittiBasligi[d.faz]!,
  govde: 'Bugün $bugun pomodoro',
  siradaki: d.faz,
);
