import 'package:shared_preferences/shared_preferences.dart';

import 'kayit.dart';
import 'oyun_durumu.dart';

/// Uygulamanın kalıcı olarak tuttuğu iki şey: en iyi skor (bir sayı) ve
/// yarım kalan oyun (16 sayı + skor + hamle sayısı). İkisi de uygulamanın
/// kendi klasöründe; başka uygulamalar okuyamaz.
class KayitDeposu {
  KayitDeposu(this._prefs);

  final SharedPreferences _prefs;

  static const enIyiAnahtari = 'en_iyi_skor';
  static const oyunAnahtari = 'yarim_oyun';

  int enIyiOku() => _prefs.getInt(enIyiAnahtari) ?? 0;

  Future<void> enIyiYaz(int skor) => _prefs.setInt(enIyiAnahtari, skor);

  /// Kayıt yoksa ya da bozuksa null.
  OyunDurumu? oyunOku() => oyunuOku(_prefs.getString(oyunAnahtari));

  Future<void> oyunYaz(OyunDurumu d) =>
      _prefs.setString(oyunAnahtari, oyunuYaz(d));

  Future<void> oyunSil() => _prefs.remove(oyunAnahtari);
}
