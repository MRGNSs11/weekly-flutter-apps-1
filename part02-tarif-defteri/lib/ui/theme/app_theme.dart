import 'package:flutter/material.dart';

/// Görsel yön: "Defter".
///
/// Uygulama yeni bir şey gibi değil, annemin çizgili tarif defterinin devamı
/// gibi görünmeli. Bu yüzden: kağıt rengi zemin, üstünde ince mavi çizgiler,
/// sol kenarda kırmızı marj çizgisi, başlıklarda el yazısı.
///
/// Renkler `tasarimlar.html` içindeki onaylanmış taslaktan birebir alınmıştır.
class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.rule,
    required this.accent,
    required this.paperLine,
    required this.onAccent,
  });

  /// Sayfa zemini — kağıt.
  final Color background;

  /// Kart / satır yüzeyi.
  final Color surface;

  /// Ana metin — mürekkep.
  final Color ink;

  /// İkincil metin.
  final Color inkSoft;

  /// Ayraç ve kenarlık çizgisi.
  final Color rule;

  /// Vurgu — marj çizgisi, favori yıldızı, birincil düğme.
  final Color accent;

  /// Defter kağıdındaki yatay çizgi.
  final Color paperLine;

  /// Vurgu üzerine gelen metin.
  final Color onAccent;

  static const light = AppColors(
    background: Color(0xFFF6F1E4),
    surface: Color(0xFFFFFDF6),
    ink: Color(0xFF1E2B4D),
    inkSoft: Color(0xFF6B7590),
    rule: Color(0xFFD8CFB8),
    accent: Color(0xFFB4322C),
    paperLine: Color(0xFFDFE3EE),
    onAccent: Color(0xFFFFFDF6),
  );

  static const dark = AppColors(
    background: Color(0xFF191B22),
    surface: Color(0xFF21242E),
    ink: Color(0xFFE6E3D8),
    inkSoft: Color(0xFF918D80),
    rule: Color(0xFF333748),
    accent: Color(0xFFE0685F),
    paperLine: Color(0xFF2A2E3C),
    onAccent: Color(0xFF191B22),
  );
}

/// Tema nesnesinden renklere ulaşmak için kısayol:
/// `context.colors.accent`
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColorsTheme>()!.colors;
}

@immutable
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  const AppColorsTheme(this.colors);

  final AppColors colors;

  @override
  AppColorsTheme copyWith({AppColors? colors}) =>
      AppColorsTheme(colors ?? this.colors);

  @override
  AppColorsTheme lerp(ThemeExtension<AppColorsTheme>? other, double t) {
    if (other is! AppColorsTheme) return this;
    return t < 0.5 ? this : other;
  }
}

/// Defter sayfası hissi için köşeler neredeyse keskin.
const double kCornerRadius = 4;

/// Kağıttaki iki yatay çizgi arasındaki mesafe.
const double kRuleSpacing = 30;

/// Sol kenardaki kırmızı marj çizgisinin içeriden uzaklığı.
const double kMarginInset = 26;

/// El yazısı font — YALNIZCA başlıklar, tarif adları, kategori adları.
/// Uzun metinde kullanılmaz; hedef kullanıcı yaşlı ve el yazısı yorar.
const String kDisplayFont = 'Caveat';

/// Gövde fontu — malzeme satırları, pişirme adımları, düğmeler, ayarlar.
const String kBodyFont = 'Inter';

ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  // Caveat'ın x-yüksekliği düşük; aynı puntoda Inter'den küçük görünür.
  // Bu yüzden el yazısı başlıklar bilerek daha büyük kurulur.
  final textTheme = TextTheme(
    // Ekran başlığı — "Tarif Defteri", "Çorbalar"
    headlineMedium: TextStyle(
      fontFamily: kDisplayFont,
      fontSize: 30,
      height: 1.1,
      color: c.ink,
    ),
    // Kart ve satır başlığı — tarif adı, kategori adı
    titleLarge: TextStyle(
      fontFamily: kDisplayFont,
      fontSize: 25,
      height: 1.15,
      color: c.ink,
    ),
    // Bölüm etiketi — "MALZEMELER", "YAPILIŞI"
    labelLarge: TextStyle(
      fontFamily: kBodyFont,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: c.inkSoft,
    ),
    // Ana gövde — malzeme satırı, pişirme adımı
    bodyLarge: TextStyle(
      fontFamily: kBodyFont,
      fontSize: 17,
      height: 1.45,
      color: c.ink,
    ),
    // İkincil bilgi — "8 malzeme · 5 adım"
    bodyMedium: TextStyle(
      fontFamily: kBodyFont,
      fontSize: 13.5,
      height: 1.35,
      color: c.inkSoft,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    fontFamily: kBodyFont,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: c.accent,
          brightness: brightness,
        ).copyWith(
          surface: c.background,
          primary: c.accent,
          onPrimary: c.onAccent,
          outline: c.rule,
        ),
    textTheme: textTheme,
    dividerColor: c.rule,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineMedium,
      shape: Border(bottom: BorderSide(color: c.rule)),
    ),
    extensions: [AppColorsTheme(c)],
  );
}
