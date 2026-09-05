/// Türkçe metin karşılaştırma.
///
/// Annem "çorba" yazacak diye tutturmaz; klavyede ne denk gelirse onu yazar.
/// "corba", "ÇORBA", "Çorba" ve "corba " aynı sonucu vermeli.
///
/// Bu dosya Flutter'a ve veritabanına bağımlı değildir — bütün arama mantığı
/// burada saf fonksiyon olarak durur ve doğrudan test edilir.
library;

/// Türkçe'ye özgü harfleri ASCII karşılığına indirger.
///
/// Dart'ın `toLowerCase()` metodu burada tek başına YETMEZ:
///   * `'I'.toLowerCase()` → `'i'` verir. Türkçe'de doğrusu `'ı'`dır.
///   * `'İ'.toLowerCase()` → `'i'` + U+0307 (birleşen üst nokta) verir,
///     yani görünüşte "i" olan ama iki kod biriminden oluşan bir metin.
///     Bu metin `'i'` ile karşılaştırıldığında EŞLEŞMEZ.
///
/// İkisi de sessiz hatadır: arama çalışıyor görünür, bazı tarifler hiç
/// bulunamaz. Bu yüzden harfler `toLowerCase()` çağrılmadan önce elle
/// eşlenir.
const Map<String, String> _foldMap = {
  'ç': 'c', 'Ç': 'c',
  'ğ': 'g', 'Ğ': 'g',
  'ı': 'i', 'I': 'i', 'İ': 'i',
  'ö': 'o', 'Ö': 'o',
  'ş': 's', 'Ş': 's',
  'ü': 'u', 'Ü': 'u',
  // Eski yazımda geçen şapkalı harfler ("kâğıt", "hâlâ")
  'â': 'a', 'Â': 'a',
  'î': 'i', 'Î': 'i',
  'û': 'u', 'Û': 'u',
  // Birleşen üst nokta — 'İ' zaten yukarıda ele alındı, ama metne başka
  // yoldan girmişse burada düşer.
  '̇': '',
};

/// Metni aramaya uygun hale getirir: küçük harf, Türkçe harfler sadeleşmiş,
/// baştaki/sondaki boşluklar atılmış, aradaki boşluklar teke indirilmiş.
///
/// ```dart
/// normalizeTurkish('İzmir Köftesi') == 'izmir koftesi'
/// normalizeTurkish('  ÇOBAN   SALATA ') == 'coban salata'
/// ```
String normalizeTurkish(String input) {
  final buffer = StringBuffer();

  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final folded = _foldMap[char];
    if (folded != null) {
      buffer.write(folded);
    } else {
      buffer.write(char.toLowerCase());
    }
  }

  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Metni Türkçe kurallarına göre büyük harfe çevirir.
///
/// `toUpperCase()` burada da yanlış: `'tarifin'.toUpperCase()` → `'TARIFIN'`
/// veriyor, doğrusu `'TARİFİN'`. Küçük harfe çevirmenin tersi olan bu hata
/// arayüzdeki bölüm başlıklarında görünür.
///
/// Sadece iki harf farklı: `i → İ` ve `ı → I`.
String toUpperCaseTurkish(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(switch (char) {
      'i' => 'İ',
      'ı' => 'I',
      _ => char.toUpperCase(),
    });
  }
  return buffer.toString();
}

/// Bir tarifin aranabilir metnini üretir: adı + bütün malzemeleri.
///
/// Yapılış adımları bilerek dışarıda bırakıldı. Aksi halde "tuz ekle"
/// yazan her tarif "tuz" aramasında çıkar ve sonuç listesi işe yaramaz.
String buildSearchText(String name, List<String> ingredients) {
  return normalizeTurkish([name, ...ingredients].join(' '));
}

/// Aranan metin, hazırlanmış arama metninin içinde geçiyor mu?
///
/// Boş sorgu her şeyle eşleşir — kullanıcı arama kutusunu temizlediğinde
/// liste eski haline döner.
bool matchesQuery(String searchText, String query) {
  final needle = normalizeTurkish(query);
  if (needle.isEmpty) return true;
  return searchText.contains(needle);
}
