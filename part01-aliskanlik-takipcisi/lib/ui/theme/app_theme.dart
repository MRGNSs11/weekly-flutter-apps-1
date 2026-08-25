import 'package:flutter/material.dart';

/// PLAN.md § B2.1 — "05 Organik / Toprak" taslağından birebir çıkarılan
/// renk tokenları. Değerler `tasarimlar.html` içindeki `.organik` CSS
/// bloğuyla eşleşir.
abstract final class AppColors {
  static const bg = Color(0xFFF5F3EC);
  static const surface = Color(0xFFFFFEFA);
  static const text = Color(0xFF2B3226);
  static const muted = Color(0xFF8D9483);
  static const accent = Color(0xFF5C8A4A);
  static const onAccent = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6E5DA);
  static const sparkOff = Color(0xFFE4E6DC);

  /// Isı haritası 5 seviye: az → çok.
  static const heatmapLevels = [
    Color(0xFFE7E8DE), // L0 — işaretlenmemiş
    Color(0xFFC8DCBC), // L1 — 1-2 günlük seri
    Color(0xFF96BD83), // L2 — 3-6 günlük seri
    Color(0xFF5C8A4A), // L3 — 7-13 günlük seri
    Color(0xFF37592C), // L4 — 14+ günlük seri
  ];

  /// Alışkanlık rengi seçimi (Must, PLAN.md § C) için 8 tonluk, temanın
  /// toprak/organik paletiyle uyumlu bir seçenek listesi. Taslakta tek bir
  /// alışkanlık örneklendiği için bu palet taslakta yoktu — birden çok
  /// alışkanlığı ayırt etmek için gereken en küçük ek karardı.
  static const habitPalette = [
    Color(0xFF5C8A4A), // adaçayı yeşili (accent)
    Color(0xFFC97B4A), // toprak turuncusu
    Color(0xFFC9A227), // hardal
    Color(0xFF3E7C7B), // koyu deniz mavisi
    Color(0xFF8B5E4A), // kil kahvesi
    Color(0xFFB6607A), // toz gülü
    Color(0xFF6B7A3A), // zeytin
    Color(0xFF5B6B8C), // gök mavisi-gri
  ];
}

abstract final class AppRadius {
  static const card = 14.0;
  static const colorDot = 3.0;
  static const spark = 1.5;
  static const heatmapCell = 100.0; // tam yuvarlak
  static const checkbox = 100.0; // tam yuvarlak
  static const fab = 100.0; // tam yuvarlak
}

abstract final class AppSpacing {
  static const screenMargin = 18.0;
  static const rowGap = 9.0;
  static const rowPaddingV = 14.0;
  static const rowPaddingH = 15.0;
  static const statGap = 9.0;
  static const heatmapCellGap = 2.0;
}

abstract final class AppTextStyles {
  static const _lora = 'Lora';

  static const h1 = TextStyle(
    fontFamily: _lora,
    fontWeight: FontWeight.w600,
    fontSize: 25,
    height: 1.2,
    letterSpacing: -0.02 * 25,
    color: AppColors.text,
  );

  static const statNumber = TextStyle(
    fontFamily: _lora,
    fontWeight: FontWeight.w600,
    fontSize: 26,
    height: 1.15,
    letterSpacing: -0.03 * 26,
    color: AppColors.accent,
  );

  static const rowTitle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.3,
    letterSpacing: -0.01 * 15,
    color: AppColors.text,
  );

  static const rowSubtitle = TextStyle(fontSize: 11.5, color: AppColors.muted);

  static const dateHeader = TextStyle(
    fontSize: 11.5,
    letterSpacing: 0.09 * 11.5,
    color: AppColors.muted,
  );

  static const statLabel = TextStyle(
    fontSize: 10,
    letterSpacing: 0.05 * 10,
    color: AppColors.muted,
  );

  static const cardHeader = TextStyle(
    fontSize: 11,
    letterSpacing: 0.08 * 11,
    color: AppColors.muted,
  );

  static const monthLabel = TextStyle(fontSize: 9.5, color: AppColors.muted);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.bg,
    ),
    fontFamily: null, // sistem varsayılanı (sans) — sadece başlıklarda Lora
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
