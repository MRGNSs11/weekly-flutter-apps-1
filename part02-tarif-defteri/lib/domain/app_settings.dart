import 'package:flutter/material.dart';

/// Annemin ayarlardan değiştirebildiği iki şey: tema ve yazı boyutu.
///
/// Tercihler veritabanındaki `Preferences` tablosunda metin olarak durur;
/// bu sınıf o metinleri anlamlı değerlere çevirir.
@immutable
class AppSettings {
  /// Varsayılan açık tema. "Sistem teması" diye bir seçenek sunulmuyor:
  /// annem için anlamı olmayan bir kavram ve ayarda üçüncü bir düğme demek.
  const AppSettings({this.themeMode = ThemeMode.light, this.textSizeStep = 0});

  static const themeKey = 'tema';
  static const textSizeKey = 'yaziBoyutu';

  /// Üç kademe. Daha fazlası seçim yapmayı zorlaştırır, daha azı yetmez.
  static const textScales = <double>[1.0, 1.15, 1.32];
  static const textSizeLabels = <String>['Normal', 'Büyük', 'Çok büyük'];

  final ThemeMode themeMode;

  /// 0 = Normal, 1 = Büyük, 2 = Çok büyük.
  final int textSizeStep;

  double get textScale => textScales[textSizeStep];

  AppSettings copyWith({ThemeMode? themeMode, int? textSizeStep}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        textSizeStep: textSizeStep ?? this.textSizeStep,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.textSizeStep == textSizeStep;

  @override
  int get hashCode => Object.hash(themeMode, textSizeStep);

  static AppSettings fromPreferences(Map<String, String> prefs) {
    return AppSettings(
      themeMode: _themeFromString(prefs[themeKey]),
      textSizeStep: _stepFromString(prefs[textSizeKey]),
    );
  }

  static String themeToString(ThemeMode mode) =>
      mode == ThemeMode.dark ? 'koyu' : 'acik';

  static ThemeMode _themeFromString(String? value) =>
      value == 'koyu' ? ThemeMode.dark : ThemeMode.light;

  static int _stepFromString(String? value) {
    final parsed = int.tryParse(value ?? '') ?? 0;
    return parsed.clamp(0, textScales.length - 1);
  }
}
