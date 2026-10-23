import 'package:flutter/services.dart';

/// "Süre doldu" ekranında döngüyle çalan alarm sesi (PLAN K6.9).
abstract class Zil {
  Future<void> cal();

  /// Sesi keser, kilit ekranı üstünde görünmeyi de geri alır.
  Future<void> sustur();
}

/// `MainActivity.kt` içindeki `pomodoro/alarm` kanalı.
class KanalZil implements Zil {
  static const _kanal = MethodChannel('pomodoro/alarm');

  @override
  Future<void> cal() => _kanal.invokeMethod<void>('cal');

  @override
  Future<void> sustur() => _kanal.invokeMethod<void>('sustur');
}
