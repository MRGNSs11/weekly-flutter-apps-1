import '../alan/ayarlar.dart';
import '../alan/pomodoro_durumu.dart';

class IzinDurumu {
  const IzinDurumu({
    required this.bildirim,
    required this.kesin,
    required this.tamEkran,
  });

  static const hepsiVar = IzinDurumu(
    bildirim: true,
    kesin: true,
    tamEkran: true,
  );

  final bool bildirim;
  final bool kesin;
  final bool tamEkran;
}

/// Bildirim paneli. Panel çizilmez, durumdan türetilir: [esitle] Flutter'ın
/// `build`'i gibi çalışır (PLAN K6.5).
abstract class BildirimServisi {
  Future<void> esitle(PomodoroDurumu d, Ayarlar a);

  /// Panelde "süre doldu" bildirimi duruyor mu (PLAN K6.9).
  Future<bool> alarmVar();

  /// Alarm bildirimini kapatıp aynısını sessiz koyar: ısrarcı ses susar,
  /// yerine uygulamanın zili çalar.
  Future<void> alarmiSessizYap(PomodoroDurumu d, Ayarlar a, int bugun);

  Future<void> alarmiKapat();

  Future<IzinDurumu> izinler();
  Future<bool> bildirimIzniIste();
  Future<bool> kesinIzniIste();
  Future<bool> tamEkranIzniIste();
  Future<void> bildirimAyarlariniAc();
}
