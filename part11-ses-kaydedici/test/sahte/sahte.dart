import 'dart:async';

import 'package:ses_kaydedici/alan/kayit.dart';
import 'package:ses_kaydedici/uygulama/calar.dart';
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

  void Function()? bildirimdenDurdur;

  @override
  void bildirimdenDurdurDinle(void Function() f) => bildirimdenDurdur = f;
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
  Future<void> adDegistir(int id, String ad) async {
    final i = _kayitlar.indexWhere((k) => k.id == id);
    final k = _kayitlar[i];
    _kayitlar[i] = Kayit(
      id: k.id,
      ad: ad,
      dosyaYolu: k.dosyaYolu,
      sure: k.sure,
      boyutBayt: k.boyutBayt,
      olusturma: k.olusturma,
      dalga: k.dalga,
    );
    _akis.add(List.of(_kayitlar));
  }

  @override
  Future<Kayit?> sil(int id) async {
    final i = _kayitlar.indexWhere((k) => k.id == id);
    if (i == -1) return null;
    final k = _kayitlar.removeAt(i);
    _akis.add(List.of(_kayitlar));
    return k;
  }

  @override
  Future<void> geriEkle(Kayit k) async {
    _kayitlar
      ..add(k)
      ..sort((a, b) => b.olusturma.compareTo(a.olusturma));
    _akis.add(List.of(_kayitlar));
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Hoparlörsüz çalar: konumu test kendisi gönderir.
class SahteCalar implements Calar {
  final List<String> cagrilar = [];
  Duration? sure = const Duration(minutes: 4, seconds: 48);
  double sonHiz = 1;
  final konumAkisi = StreamController<Duration>.broadcast();
  final caliyorAkisi = StreamController<bool>.broadcast();
  final bittiAkisi = StreamController<void>.broadcast();

  @override
  Future<Duration?> yukle(String yol) async {
    cagrilar.add('yukle $yol');
    return sure;
  }

  @override
  Future<void> oynat() async {
    cagrilar.add('oynat');
    caliyorAkisi.add(true);
  }

  @override
  Future<void> duraklat() async {
    cagrilar.add('duraklat');
    caliyorAkisi.add(false);
  }

  @override
  Future<void> sar(Duration konum) async =>
      cagrilar.add('sar ${konum.inSeconds}');

  @override
  Future<void> hiz(double h) async => sonHiz = h;

  @override
  Future<void> durdur() async {
    cagrilar.add('durdur');
    caliyorAkisi.add(false);
  }

  @override
  Stream<Duration> konum() => konumAkisi.stream;

  @override
  Stream<bool> caliyor() => caliyorAkisi.stream;

  @override
  Stream<void> bitti() => bittiAkisi.stream;

  @override
  Future<void> kapat() async {}
}
