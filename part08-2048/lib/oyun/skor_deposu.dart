import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın kalıcı olarak tuttuğu tek şey: en iyi skor (bir sayı).
class SkorDeposu {
  SkorDeposu(this._prefs);

  final SharedPreferences _prefs;

  static const anahtar = 'en_iyi_skor';

  int oku() => _prefs.getInt(anahtar) ?? 0;

  Future<void> yaz(int skor) => _prefs.setInt(anahtar, skor);
}
