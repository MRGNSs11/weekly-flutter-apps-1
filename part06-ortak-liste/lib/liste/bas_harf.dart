/// Notu tutan harf karosu için ürün adının baş harfi.
///
/// Dart'ın `toUpperCase()`'i dilden habersiz: "incir" → "INCIR" olur,
/// "İ" olmaz. Part 02'de aynı hata arama kutusunda çıkmıştı. Türkçe'nin
/// iki i'si elle eşleniyor, gerisi standart büyütmeye bırakılıyor.
String turkceBuyuk(String metin) {
  final tampon = StringBuffer();
  for (final harf in metin.split('')) {
    tampon.write(switch (harf) {
      'i' => 'İ',
      'ı' => 'I',
      _ => harf.toUpperCase(),
    });
  }
  return tampon.toString();
}

/// Adın ilk karakteri, Türkçe kurala göre büyütülmüş.
/// Harf değilse (rakam, emoji) olduğu gibi döner; ad boşsa "?".
String basHarf(String ad) {
  final kirpik = ad.trim();
  if (kirpik.isEmpty) return '?';
  // runes: emoji gibi iki parçalı karakterler ortadan bölünmesin.
  return turkceBuyuk(String.fromCharCode(kirpik.runes.first));
}
