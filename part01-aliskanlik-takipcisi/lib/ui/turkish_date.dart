/// `intl` paketi eklemeden (2 paket sınırı, bkz. PLAN.md § B4) Türkçe tarih
/// biçimlendirme için küçük yardımcılar.
library;

const _weekdays = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String formatHeaderDate(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  final month = _months[date.month - 1];
  return '$weekday, ${date.day} $month';
}

/// Dart'ın `toUpperCase()`'i Türkçe 'i' harfini noktasız 'I' yapar
/// (bilinen Unicode/Türkçe büyük harf sorunu). Görsel tarih başlığı BÜYÜK
/// HARF gerektirdiği için (bkz. PLAN.md § B2.2) bunu elle düzeltiyoruz.
String turkishUpperCase(String input) {
  return input.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
}
