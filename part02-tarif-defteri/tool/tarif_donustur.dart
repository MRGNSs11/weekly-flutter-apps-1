// ignore_for_file: avoid_print

/// Masaüstündeki `Tarifler.txt` dosyasını uygulamanın okuduğu JSON biçimine
/// çevirir.
///
/// Neden script? Defterden geçirilen 136 tarifi elle JSON'a yazmak hem uzun
/// hem hataya açık. Metin dosyası zaten düzenli: her tarif `## N. Ad`,
/// altında `### Malzemeler` ve (varsa) `### Hazırlanışı`. Bu düzeni okuyup
/// `BackupData` biçimine çeviriyoruz.
///
/// Çalıştırma:
///   dart run tool/tarif_donustur.dart `Tarifler.txt yolu` assets/recipes.json
///
/// Çıktı dosyası `.gitignore`'dadır — annemin gerçek tarifleri depoya girmez.
library;

import 'dart:convert';
import 'dart:io';

/// Tarif numarası → kategori.
///
/// Otomatik tahmin denenmedi: "Lokum Kek" kek, "Lokum Kurabiye" kurabiye,
/// "Mozaik Pasta" ise aslında bisküvi tatlısı. Anahtar kelimeyle ayırmak
/// yanlış sonuç veriyor, bu yüzden 136 tarifin tamamı elle eşleştirildi.
const Map<int, String> _kategoriler = {
  1: 'Tatlılar',
  2: 'Tatlılar',
  3: 'Tatlılar',
  4: 'Tatlılar',
  5: 'Tatlılar',
  6: 'Diğer',
  7: 'Tatlılar',
  8: 'Tatlılar',
  9: 'Kekler & Pastalar',
  10: 'Tatlılar',
  11: 'Tatlılar',
  12: 'Tatlılar',
  13: 'Tatlılar',
  14: 'Kekler & Pastalar',
  15: 'Tatlılar',
  16: 'Tatlılar',
  17: 'Tatlılar',
  18: 'Kekler & Pastalar',
  19: 'Kekler & Pastalar',
  20: 'Tatlılar',
  21: 'Tatlılar',
  22: 'Kekler & Pastalar',
  23: 'Kekler & Pastalar',
  24: 'Kekler & Pastalar',
  25: 'Kekler & Pastalar',
  26: 'Tatlılar',
  27: 'Kekler & Pastalar',
  28: 'Kekler & Pastalar',
  29: 'Kekler & Pastalar',
  30: 'Kekler & Pastalar',
  31: 'Kekler & Pastalar',
  32: 'Kekler & Pastalar',
  33: 'Kurabiyeler',
  34: 'Tatlılar',
  35: 'Kekler & Pastalar',
  36: 'Tatlılar',
  37: 'Kekler & Pastalar',
  38: 'Ekmek & Hamur',
  39: 'Kekler & Pastalar',
  40: 'Tatlılar',
  41: 'Poğaça & Börek',
  42: 'Poğaça & Börek',
  43: 'Poğaça & Börek',
  44: 'Ekmek & Hamur',
  45: 'Poğaça & Börek',
  46: 'Kurabiyeler',
  47: 'Poğaça & Börek',
  48: 'Poğaça & Börek',
  49: 'Tatlılar',
  50: 'Tatlılar',
  51: 'Tatlılar',
  52: 'Poğaça & Börek',
  53: 'Ekmek & Hamur',
  54: 'Poğaça & Börek',
  55: 'Kekler & Pastalar',
  56: 'Ekmek & Hamur',
  57: 'Ana Yemek',
  58: 'Kekler & Pastalar',
  59: 'Kekler & Pastalar',
  60: 'Ekmek & Hamur',
  61: 'Poğaça & Börek',
  62: 'Ekmek & Hamur',
  63: 'Kurabiyeler',
  64: 'Poğaça & Börek',
  65: 'Poğaça & Börek',
  66: 'Kekler & Pastalar',
  67: 'Tatlılar',
  68: 'Poğaça & Börek',
  69: 'Kurabiyeler',
  70: 'Kurabiyeler',
  71: 'Kurabiyeler',
  72: 'Diğer',
  73: 'Ekmek & Hamur',
  74: 'Kurabiyeler',
  75: 'Ekmek & Hamur',
  76: 'Poğaça & Börek',
  77: 'Ekmek & Hamur',
  78: 'Kurabiyeler',
  79: 'Kurabiyeler',
  80: 'Kurabiyeler',
  81: 'Kekler & Pastalar',
  82: 'Tatlılar',
  83: 'Kekler & Pastalar',
  84: 'Poğaça & Börek',
  85: 'Kurabiyeler',
  86: 'Tatlılar',
  87: 'Kurabiyeler',
  88: 'Tatlılar',
  89: 'Poğaça & Börek',
  90: 'Tatlılar',
  91: 'Poğaça & Börek',
  92: 'Kekler & Pastalar',
  93: 'Ana Yemek',
  94: 'Meze & Salata',
  95: 'Ana Yemek',
  96: 'Meze & Salata',
  97: 'Poğaça & Börek',
  98: 'Poğaça & Börek',
  99: 'Meze & Salata',
  100: 'Meze & Salata',
  101: 'Meze & Salata',
  102: 'Meze & Salata',
  103: 'Meze & Salata',
  104: 'Meze & Salata',
  105: 'Kurabiyeler',
  106: 'Kurabiyeler',
  107: 'Kurabiyeler',
  108: 'Ekmek & Hamur',
  109: 'Tatlılar',
  110: 'Kurabiyeler',
  111: 'Ekmek & Hamur',
  112: 'Kekler & Pastalar',
  113: 'Kurabiyeler',
  114: 'Ekmek & Hamur',
  115: 'Tatlılar',
  116: 'Ekmek & Hamur',
  117: 'Poğaça & Börek',
  118: 'Tatlılar',
  119: 'Poğaça & Börek',
  120: 'Kurabiyeler',
  121: 'Ekmek & Hamur',
  122: 'Kurabiyeler',
  123: 'Ekmek & Hamur',
  124: 'Meze & Salata',
  125: 'Tatlılar',
  126: 'Kekler & Pastalar',
  127: 'Kekler & Pastalar',
  128: 'Tatlılar',
  129: 'Tatlılar',
  130: 'Ana Yemek',
  131: 'Kekler & Pastalar',
  132: 'Tatlılar',
  133: 'Diğer',
  134: 'Ana Yemek',
  135: 'Ana Yemek',
  136: 'Tatlılar',
};

/// Ana ekranda görünecek sıra.
const List<String> _kategoriSirasi = [
  'Tatlılar',
  'Kekler & Pastalar',
  'Kurabiyeler',
  'Poğaça & Börek',
  'Ekmek & Hamur',
  'Meze & Salata',
  'Ana Yemek',
  'Diğer',
];

class _Tarif {
  _Tarif(this.numara, this.ad);

  final int numara;
  final String ad;
  final List<String> malzemeler = [];
  final List<String> adimlar = [];
}

void main(List<String> args) {
  if (args.length < 2) {
    print('Kullanım: dart run tool/tarif_donustur.dart <girdi.txt> <cikti.json>');
    exitCode = 64;
    return;
  }

  final girdi = File(args[0]);
  if (!girdi.existsSync()) {
    print('Girdi dosyası bulunamadı: ${args[0]}');
    exitCode = 66;
    return;
  }

  // Dosya UTF-8. Windows'un varsayılan kod sayfasıyla okunursa Türkçe
  // harfler bozulur, o yüzden encoding açıkça veriliyor.
  final satirlar = const LineSplitter().convert(
    girdi.readAsStringSync(encoding: utf8),
  );

  final tarifler = _ayristir(satirlar);
  _dogrula(tarifler);

  final kullanilan = _kategoriSirasi
      .where((k) => tarifler.any((t) => _kategoriler[t.numara] == k))
      .toList();

  final json = {
    'surum': 1,
    'kategoriler': [
      for (var i = 0; i < kullanilan.length; i++)
        {'ad': kullanilan[i], 'sira': i},
    ],
    'tarifler': [
      for (final t in tarifler)
        {
          'ad': t.ad,
          'kategori': _kategoriler[t.numara] ?? 'Diğer',
          'malzemeler': t.malzemeler,
          'adimlar': t.adimlar,
        },
    ],
  };

  File(args[1]).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(json),
    encoding: utf8,
  );

  _ozet(tarifler, kullanilan, args[1]);
}

/// Metni tariflere böler.
///
/// Ayrıştırma kuralları:
///   `## 7. Sarı Muhallebi`  → yeni tarif
///   `### Malzemeler`        → bundan sonrası malzeme
///   `### Hazırlanışı`       → bundan sonrası adım  (`(Döşeme)` gibi ekler olabilir)
///   `**Şerbeti İçin:**`     → malzeme listesinde başlık satırı
///   `*(Kaynat, soğut)*`     → parantezi korunarak listede kalır; hangi
///                             bölüme ait olduğu ancak yerinde durursa belli olur
///   `- `, `* `, `1. `       → madde işaretleri temizlenir
List<_Tarif> _ayristir(List<String> satirlar) {
  final tarifler = <_Tarif>[];
  _Tarif? aktif;
  var bolum = _Bolum.yok;

  for (final ham in satirlar) {
    final satir = ham.trim();
    if (satir.isEmpty || satir == '---') continue;

    final baslik = RegExp(r'^##\s+(\d+)\.\s*(.+)$').firstMatch(satir);
    if (baslik != null) {
      aktif = _Tarif(
        int.parse(baslik.group(1)!),
        baslik.group(2)!.trim(),
      );
      tarifler.add(aktif);
      bolum = _Bolum.yok;
      continue;
    }

    if (satir.startsWith('# ')) continue; // dosyanın kendi başlığı

    if (satir.startsWith('### ')) {
      final ad = satir.substring(4).toLowerCase();
      bolum = ad.startsWith('malzeme') ? _Bolum.malzeme : _Bolum.adim;
      continue;
    }

    if (aktif == null || bolum == _Bolum.yok) continue;

    final metin = _temizle(satir);
    if (metin.isEmpty) continue;

    if (bolum == _Bolum.malzeme) {
      aktif.malzemeler.add(metin);
    } else {
      aktif.adimlar.add(metin);
    }
  }

  return tarifler;
}

enum _Bolum { yok, malzeme, adim }

/// Bir satırdaki markdown işaretlerini temizler.
String _temizle(String satir) {
  var s = satir;

  // Madde işareti: "- ", "* ", "1. "
  s = s.replaceFirst(RegExp(r'^[-*]\s+'), '');
  s = s.replaceFirst(RegExp(r'^\d+\.\s+'), '');

  // *(Kaynat, soğut)* → (Kaynat, soğut)
  final italik = RegExp(r'^\*\((.+)\)\*$').firstMatch(s);
  if (italik != null) {
    return '(${italik.group(1)!.trim()})';
  }

  // **Şerbeti İçin:** → Şerbeti İçin:
  s = s.replaceAll('**', '');

  // Satır içinde kalan tekil yıldızlar
  s = s.replaceAll(RegExp(r'(^\*+|\*+$)'), '');

  return s.trim();
}

/// Ayrıştırma sonrası akla yatkınlık kontrolü.
///
/// Sessizce yanlış çıktı üretmektense burada bağırsın: eksik tarif ya da
/// malzemesiz bir tarif, metin dosyasında beklenmeyen bir biçim demektir.
void _dogrula(List<_Tarif> tarifler) {
  final sorunlar = <String>[];

  for (var i = 0; i < tarifler.length; i++) {
    final t = tarifler[i];
    if (t.numara != i + 1) {
      sorunlar.add('Sıra atlaması: ${i + 1}. sırada ${t.numara} numara var.');
    }
    if (t.ad.isEmpty) sorunlar.add('${t.numara}. tarifin adı boş.');
    if (t.malzemeler.isEmpty) {
      sorunlar.add('${t.numara}. "${t.ad}" — hiç malzeme okunamadı.');
    }
    if (!_kategoriler.containsKey(t.numara)) {
      sorunlar.add('${t.numara}. "${t.ad}" — kategori tablosunda yok.');
    }
  }

  if (sorunlar.isEmpty) return;
  print('UYARI — ayrıştırmada sorunlar var:');
  for (final s in sorunlar) {
    print('  • $s');
  }
}

void _ozet(List<_Tarif> tarifler, List<String> kategoriler, String cikti) {
  print('$cikti yazıldı — ${tarifler.length} tarif.');
  print('');
  for (final k in kategoriler) {
    final adet = tarifler.where((t) => _kategoriler[t.numara] == k).length;
    print('  ${k.padRight(20)} $adet');
  }

  final adimsiz = tarifler.where((t) => t.adimlar.isEmpty).toList();
  print('');
  print('Hazırlanışı olmayan tarif: ${adimsiz.length}');
  print('Toplam malzeme satırı: '
      '${tarifler.fold<int>(0, (a, t) => a + t.malzemeler.length)}');
  print('Toplam adım satırı: '
      '${tarifler.fold<int>(0, (a, t) => a + t.adimlar.length)}');
}
