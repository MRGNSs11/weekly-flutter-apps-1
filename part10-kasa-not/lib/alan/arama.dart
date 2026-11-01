/// Türkçe arama: "ISPANAK", "ıspanak" ve "Ispanak" aynı notu bulmalı.
///
/// Dart'ın `toLowerCase()` tek başına yetmez: `'I'` → `'i'` verir (doğrusu
/// `'ı'`), `'İ'` → `'i'` + birleşen nokta verir. İkisi de aramayı sessizce
/// bozar. Bu yüzden harfler elle sadeleştirilir (Part 02'deki yöntem).
library;

const Map<String, String> _sadelestir = {
  'ç': 'c',
  'Ç': 'c',
  'ğ': 'g',
  'Ğ': 'g',
  'ı': 'i',
  'I': 'i',
  'İ': 'i',
  'ö': 'o',
  'Ö': 'o',
  'ş': 's',
  'Ş': 's',
  'ü': 'u',
  'Ü': 'u',
  'â': 'a',
  'Â': 'a',
  'î': 'i',
  'Î': 'i',
  'û': 'u',
  'Û': 'u',
  '̇': '',
};

String aramaIcinSadelestir(String metin) {
  final b = StringBuffer();
  for (final rune in metin.runes) {
    final harf = String.fromCharCode(rune);
    b.write(_sadelestir[harf] ?? harf.toLowerCase());
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Boş sorgu her notla eşleşir.
bool eslesir(String icerik, String sorgu) {
  final s = aramaIcinSadelestir(sorgu);
  if (s.isEmpty) return true;
  return aramaIcinSadelestir(icerik).contains(s);
}
