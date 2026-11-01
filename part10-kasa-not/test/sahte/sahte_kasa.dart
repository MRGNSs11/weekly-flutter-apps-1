import 'package:kasa_not/kasa/kasa_servisi.dart';

/// Parmak izi her zaman "evet" der; davranış bayraklarla değiştirilir.
class SahteKasaServisi implements KasaServisi {
  bool uygun = true;
  List<int>? anahtar;
  bool iptalEt = false;
  bool gecersiz = false;
  int okumaSayisi = 0;
  int dogrulamaSayisi = 0;

  @override
  Future<bool> cihazUygun() async => uygun;

  @override
  Future<bool> anahtarVar() async => anahtar != null;

  @override
  Future<List<int>> anahtarOlustur() async {
    if (iptalEt) throw const KasaIptal();
    return anahtar = List<int>.generate(32, (i) => i * 7 % 256);
  }

  @override
  Future<List<int>> anahtariOku() async {
    okumaSayisi++;
    if (iptalEt) throw const KasaIptal();
    if (gecersiz) throw const AnahtarGecersiz('test');
    return anahtar!;
  }

  @override
  Future<bool> dogrula() async {
    dogrulamaSayisi++;
    if (iptalEt) throw const KasaIptal();
    return true;
  }
}

class SahteGizlilik implements Gizlilik {
  final cagrilar = <bool>[];
  @override
  Future<void> onizlemeyiGizle(bool gizle) async => cagrilar.add(gizle);
}
