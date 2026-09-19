import 'dart:math' as math;
import 'dart:ui' show Rect;

/// ML Kit'in döndürdüğü satır: metni ve sayfadaki yeri.
///
/// ML Kit sınıflarının kendisini kullanmıyoruz. Sebep: bu katmanı test
/// edebilmek. `TextLine` üretmek için eklentinin platform kanalını taklit
/// etmek gerekirdi; burada iki alanlık düz bir sınıf yetiyor.
class OkunanSatir {
  const OkunanSatir({required this.metin, required this.kutu});

  final String metin;
  final Rect kutu;
}

/// ML Kit'in "blok"u — kabaca bir paragraf.
class OkunanBlok {
  OkunanBlok({required this.satirlar})
    : assert(satirlar.isNotEmpty, 'boş blok anlamsız'),
      kutu = _kapsayanKutu(satirlar);

  final List<OkunanSatir> satirlar;

  /// Bloğun tüm satırlarını kapsayan dikdörtgen. Blokları sayfadaki
  /// yerlerine göre sıralarken kullanılıyor.
  final Rect kutu;

  static Rect _kapsayanKutu(List<OkunanSatir> satirlar) {
    var kutu = satirlar.first.kutu;
    for (final satir in satirlar.skip(1)) {
      kutu = kutu.expandToInclude(satir.kutu);
    }
    return kutu;
  }
}

/// Düzenleme sonucu: ekrana yazılacak metin ve kelime sayısı.
class OkunanSonuc {
  const OkunanSonuc({required this.metin, required this.kelimeSayisi});

  static const bos = OkunanSonuc(metin: '', kelimeSayisi: 0);

  final String metin;
  final int kelimeSayisi;

  bool get doluMu => metin.isNotEmpty;
}

/// ML Kit çıktısını okunur metne çeviren saf katman.
///
/// Model ne kadar iyi okursa okusun, ham çıktı doğrudan gösterilemez:
/// bloklar sayfadaki sıraya göre gelmez, paragraflar satır satır kırıktır,
/// satır sonundaki tire kelimeyi ikiye böler. Haftanın test edilen yeri
/// burası — kamera ve modelin kendisi test edilmiyor.
class MetinDuzenleyici {
  const MetinDuzenleyici._();

  /// İki bloğun aynı "satır bandında" sayılması için gereken dikey örtüşme.
  /// Yan yana duran iki sütun bu eşikle soldan sağa okunuyor.
  static const double _bantEsigi = 0.5;

  static const String _kucukHarfler = 'abcçdefgğhıijklmnoöprsştuüvyzqwx';

  /// Satır sonunda kelimeyi bölen işaretler. Düz tire, yumuşak tire ve
  /// kısa çizgi — üçü de tarama çıktısında görülüyor.
  static const String _tireler = '-‐­';

  static OkunanSonuc duzenle(List<OkunanBlok> bloklar) {
    final paragraflar = <String>[];

    for (final bant in _bantlaraAyir(bloklar)) {
      for (final blok in bant) {
        final paragraf = _bloguBirlestir(blok);
        if (paragraf.isNotEmpty) paragraflar.add(paragraf);
      }
    }

    if (paragraflar.isEmpty) return OkunanSonuc.bos;

    final metin = paragraflar.join('\n\n');
    return OkunanSonuc(metin: metin, kelimeSayisi: kelimeSay(metin));
  }

  /// Blokları okuma sırasına sokar: önce yukarıdan aşağı bantlar, her bandın
  /// içinde soldan sağa.
  ///
  /// Tek bir karşılaştırma fonksiyonuyla ("dikey örtüşüyorsa sola göre,
  /// yoksa yukarıya göre") yapmıyoruz; o karşılaştırma geçişli değil ve
  /// sıralamanın sonucu blokların geliş sırasına göre değişir.
  static List<List<OkunanBlok>> _bantlaraAyir(List<OkunanBlok> bloklar) {
    final sirali = [...bloklar]
      ..sort((a, b) {
        final dikey = a.kutu.top.compareTo(b.kutu.top);
        return dikey != 0 ? dikey : a.kutu.left.compareTo(b.kutu.left);
      });

    final bantlar = <List<OkunanBlok>>[];
    for (final blok in sirali) {
      if (bantlar.isNotEmpty && _ayniBant(bantlar.last, blok)) {
        bantlar.last.add(blok);
      } else {
        bantlar.add([blok]);
      }
    }

    for (final bant in bantlar) {
      bant.sort((a, b) => a.kutu.left.compareTo(b.kutu.left));
    }
    return bantlar;
  }

  static bool _ayniBant(List<OkunanBlok> bant, OkunanBlok aday) {
    for (final blok in bant) {
      final ust = math.max(blok.kutu.top, aday.kutu.top);
      final alt = math.min(blok.kutu.bottom, aday.kutu.bottom);
      final ortusme = alt - ust;
      if (ortusme <= 0) continue;

      final kucukYukseklik = math.min(blok.kutu.height, aday.kutu.height);
      if (kucukYukseklik <= 0) continue;
      if (ortusme / kucukYukseklik >= _bantEsigi) return true;
    }
    return false;
  }

  /// Bir bloğun satırlarını tek paragrafa çevirir.
  static String _bloguBirlestir(OkunanBlok blok) {
    final satirlar = [...blok.satirlar]
      ..sort((a, b) => a.kutu.top.compareTo(b.kutu.top));

    final tampon = StringBuffer();
    for (final satir in satirlar) {
      final metin = _bosluklariTopla(satir.metin);
      if (metin.isEmpty) continue;

      if (tampon.isEmpty) {
        tampon.write(metin);
        continue;
      }

      final onceki = tampon.toString();
      if (_tireyleBolunmus(onceki, metin)) {
        // Tireyi ve boşluğu atıyoruz: "eko-" + "nomi" → "ekonomi".
        tampon.clear();
        tampon
          ..write(onceki.substring(0, onceki.length - 1))
          ..write(metin);
      } else {
        tampon.write(' $metin');
      }
    }

    return tampon.toString().trim();
  }

  /// Önceki satır tireyle bitiyor ve sonraki satır küçük harfle başlıyorsa
  /// kelime bölünmüştür.
  ///
  /// Küçük harf şartı olmadan "2024-" + "2025" gibi aralıkları ve
  /// "Ankara-" + "İstanbul" gibi birleşik adları bozardık.
  static bool _tireyleBolunmus(String onceki, String sonraki) {
    if (onceki.isEmpty || sonraki.isEmpty) return false;
    if (!_tireler.contains(onceki[onceki.length - 1])) return false;
    // Tireden önce harf olmalı: "- madde" gibi madde imlerini birleştirmeyelim.
    if (onceki.length < 2 || !_harfMi(onceki[onceki.length - 2])) return false;
    return _kucukHarfMi(sonraki[0]);
  }

  /// Dart'ın `toLowerCase()`'i Türkçe'de yanlış çalışıyor (I→i, İ→i̇), o
  /// yüzden harf karşılaştırması değil doğrudan liste üyeliği bakıyoruz.
  static bool _kucukHarfMi(String karakter) =>
      _kucukHarfler.contains(karakter);

  static bool _harfMi(String karakter) =>
      _kucukHarfler.contains(karakter) ||
      _kucukHarfler.contains(_kucult(karakter));

  /// Türkçe'ye uygun küçültme — yalnızca harf mi diye bakmak için.
  static String _kucult(String karakter) {
    const buyuk = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZQWX';
    const kucuk = 'abcçdefgğhıijklmnoöprsştuüvyzqwx';
    final sira = buyuk.indexOf(karakter);
    return sira < 0 ? karakter : kucuk[sira];
  }

  /// Satır içi fazla boşlukları teke indirir, baştaki/sondaki boşluğu atar.
  static String _bosluklariTopla(String metin) =>
      metin.replaceAll(RegExp(r'\s+'), ' ').trim();

  static int kelimeSay(String metin) {
    if (metin.trim().isEmpty) return 0;
    return metin.trim().split(RegExp(r'\s+')).length;
  }
}
