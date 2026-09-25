import 'package:flutter/services.dart';

/// Damla sesleri. Çalma işi Kotlin'de (`MainActivity.kt` → `DamlaSesleri`,
/// Android SoundPool); burası yalnız kanal üzerinden "çal" der.
///
/// Neden paket değil: tek iş iki kısa ses çalmak. Bir ses paketi hem APK'ya
/// boyut hem manifest'e izin ekleyebiliyor (Part 04'te görüldü); kendi
/// kanalımızla ikisi de sıfır.
class Ses {
  const Ses._();

  static const _kanal = MethodChannel('su_takipcisi/ses');

  /// Ayarlar → Ses. Kapalıyken hiçbir çağrı Kotlin'e gitmez.
  static bool acik = true;

  /// "+1"e basınca, damla bırakılırken ("vınn").
  static Future<void> birak() => _cal('birak');

  /// Damla suya değdiği anda ("bloop").
  static Future<void> carp() => _cal('carp');

  static Future<void> _cal(String yontem) async {
    if (!acik) return;
    try {
      await _kanal.invokeMethod<void>(yontem);
    } on MissingPluginException {
      // Testlerde ya da Android dışında kanal yok: sessiz kal.
    } on PlatformException {
      // Ses çalınamadı (ör. ses servisi meşgul): uygulama akışı sürsün.
    }
  }
}
