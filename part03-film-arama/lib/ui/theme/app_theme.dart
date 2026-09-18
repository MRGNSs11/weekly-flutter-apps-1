import 'package:flutter/material.dart';

/// Koyu, poster odaklı sinema teması.
///
/// Renk seçimi: posterler ekranın yıldızı, arayüz onların önüne geçmesin.
/// Bu yüzden nötr koyu zemin + tek vurgu rengi (kehribar).
class AppTheme {
  const AppTheme._();

  static const Color _background = Color(0xFF0E1013);
  static const Color _surface = Color(0xFF181B20);
  static const Color _accent = Color(0xFFF5B301);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _background,
      primary: _accent,
      secondary: _accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _background,
      cardColor: _surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
