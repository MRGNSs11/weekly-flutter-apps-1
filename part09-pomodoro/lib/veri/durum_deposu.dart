import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../alan/ayarlar.dart';
import '../alan/pomodoro_durumu.dart';

/// Kalıcı kayıt. İki isolate (uygulama ve bildirim butonları) aynı veriyi
/// yazdığı için önbelleksiz okunur (PLAN K8.5).
abstract class DurumDeposu {
  Future<PomodoroDurumu> durumOku();
  Future<void> durumYaz(PomodoroDurumu d);
  Future<Ayarlar> ayarlarOku();
  Future<void> ayarlarYaz(Ayarlar a);

  /// İzinlerin sorulup sorulmadığı gibi tek seferlik bayraklar.
  Future<bool> bayrakOku(String ad);
  Future<void> bayrakYaz(String ad, bool deger);
}

class PrefsDurumDeposu implements DurumDeposu {
  PrefsDurumDeposu([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _durum = 'durum';
  static const _ayarlar = 'ayarlar';

  Future<Object?> _json(String anahtar) async {
    final metin = await _prefs.getString(anahtar);
    if (metin == null) return null;
    try {
      return jsonDecode(metin);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<PomodoroDurumu> durumOku() async =>
      PomodoroDurumu.fromJson(await _json(_durum));

  @override
  Future<void> durumYaz(PomodoroDurumu d) =>
      _prefs.setString(_durum, jsonEncode(d.toJson()));

  @override
  Future<Ayarlar> ayarlarOku() async => Ayarlar.fromJson(await _json(_ayarlar));

  @override
  Future<void> ayarlarYaz(Ayarlar a) =>
      _prefs.setString(_ayarlar, jsonEncode(a.toJson()));

  @override
  Future<bool> bayrakOku(String ad) async => await _prefs.getBool(ad) ?? false;

  @override
  Future<void> bayrakYaz(String ad, bool deger) => _prefs.setBool(ad, deger);
}
