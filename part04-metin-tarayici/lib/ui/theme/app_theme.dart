import 'package:flutter/material.dart';

/// Renkler, `tasarimlar.html` içindeki 02 "Vurgu Kalemi" taslağından birebir.
/// Taslak spesifikasyondur; buraya yeni renk eklenmez.
class AppColors {
  const AppColors._();

  /// Kamera dışındaki her ekranın zemini.
  static const Color bg = Color(0xFFFFFFFF);

  /// Kamera önizlemesi ve sonuç ekranının üst şeridi.
  static const Color preview = Color(0xFF17171A);

  static const Color ink = Color(0xFF111114);
  static const Color muted = Color(0xFF86868C);

  /// Uygulamanın tek rengi. Dekor değil: tanınan alanı ve seçili metni gösterir.
  static const Color accent = Color(0xFFD8F24B);

  /// Accent üstündeki yazı. Beyaz KULLANILMAZ — fosforlu sarıda okunmuyor.
  static const Color onAccent = Color(0xFF17171A);

  static const Color line = Color(0xFFE2E2E4);
}

/// Ölçüler de taslaktan geliyor (B2.3).
class AppSizes {
  const AppSizes._();

  static const double kenar = 16;
  static const double deklansor = 72;
  static const double nisanKose = 28;
  static const double nisanKalinlik = 2;
  static const double sonucSerit = 128;
  static const double dugmeYukseklik = 46;
  static const double dugmeYuvarlak = 22;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      surface: AppColors.bg,
      onSurface: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      // Yazı tipi gömülmüyor: Android'in kendi Roboto'su kullanılıyor.
      // Gerekçe PLAN.md B2.4'te.
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.85,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: AppColors.muted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(AppSizes.dugmeYukseklik),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(AppSizes.dugmeYukseklik),
          side: const BorderSide(color: AppColors.line),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
