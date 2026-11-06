import 'dart:async';

import 'package:ses_kaydedici/alan/kayit.dart';
import 'package:ses_kaydedici/uygulama/kaydedici.dart';
import 'package:ses_kaydedici/veri/kayit_deposu.dart';

/// Mikrofonsuz kaydedici: seviyeleri ve durumları test kendisi gönderir.
class SahteKaydedici implements Kaydedici {
  bool izin = true;
  bool izinIstendi = false;
  String? yol;
  final List<String> cagrilar = [];
  final seviye = StreamController<double>.broadcast();
  final durum = StreamController<KaydediciDurumu>.broadcast();

  @override
  Future<bool> izinVar({bool iste = true}) async {
    if (iste) izinIstendi = true;
    return izin;
  }

  @override
  Future<void> baslat(String yol) async {
    this.yol = yol;
    cagrilar.add('baslat');
  }

  @override
  Future<void> duraklat() async => cagrilar.add('duraklat');

  @override
  Future<void> devam() async => cagrilar.add('devam');

  @override
  Future<String?> durdur() async {
    cagrilar.add('durdur');
    return yol;
  }

  @override
  Future<void> iptal() async => cagrilar.add('iptal');

  @override
  Stream<double> seviyeler() => seviye.stream;

  @override
  Stream<KaydediciDurumu> durumlar() => durum.stream;

  @override
  Future<void> kapat() async {}
}

class SahteSistem implements Sistem {
  final List<String> cagrilar = [];
  bool get servisAcik =>
      cagrilar.lastIndexOf('servisBaslat') >
      cagrilar.lastIndexOf('servisDurdur');

  @override
  Future<void> servisBaslat() async => cagrilar.add('servisBaslat');

  @override
  Future<void> servisDurdur() async => cagrilar.add('servisDurdur');

  @override
  Future<void> bildirimIzniIste() async => cagrilar.add('bildirimIzniIste');

  @override
  Future<void> ayarlariAc() async => cagrilar.add('ayarlariAc');
}

/// Bellek içi depo: ekran testlerinde gerçek veritabanı sahte saatle
/// kapanırken asılı kalıyor (gerçek depo kendi testinde sınanır).
class SahteDepo implements KayitDeposu {
  final List<Kayit> _kayitlar = [];
  final _akis = StreamController<List<Kayit>>.broadcast();

  @override
  Stream<List<Kayit>> izle() async* {
    yield List.of(_kayitlar);
    yield* _akis.stream;
  }

  @override
  Future<int> ekle({
    required String ad,
    required String dosyaYolu,
    required Duration sure,
    required int boyutBayt,
    required List<double> dalga,
    DateTime? olusturma,
  }) async {
    final id = _kayitlar.length + 1;
    _kayitlar.insert(
      0,
      Kayit(
        id: id,
        ad: ad,
        dosyaYolu: dosyaYolu,
        sure: sure,
        boyutBayt: boyutBayt,
        olusturma: olusturma ?? DateTime(2026),
        dalga: dalga,
      ),
    );
    _akis.add(List.of(_kayitlar));
    return id;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
