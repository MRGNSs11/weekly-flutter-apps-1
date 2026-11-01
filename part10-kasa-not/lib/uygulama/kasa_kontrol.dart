import 'package:flutter/widgets.dart';

import '../alan/not.dart';
import '../kasa/kasa_servisi.dart';
import '../kasa/sifreleme.dart';
import '../veri/not_deposu.dart';

enum KasaDurumu { yukleniyor, kullanilamaz, kapali, dogrulaniyor, acik, bozuk }

/// Kasanın durumu: anahtar yalnız kasa açıkken bellekte durur.
///
/// Kapanınca anahtar ve çözülmüş metinler bellekten silinir. Kapanmadan önce
/// [kapanmadanOnce] ile kaydolan işler (düzenleyicideki bekleyen kayıt)
/// çalıştırılır, çünkü şifrelemek için anahtar hâlâ gerekir.
class KasaKontrol extends ChangeNotifier {
  KasaKontrol({
    required this._servis,
    required this._gizlilik,
    required this._depo,
    Sifreleme? sifreleme,
  }) : _sifreleme = sifreleme ?? Sifreleme();

  final KasaServisi _servis;
  final Gizlilik _gizlilik;
  final NotDeposu _depo;
  final Sifreleme _sifreleme;

  KasaDurumu _durum = KasaDurumu.yukleniyor;
  KasaDurumu get durum => _durum;
  bool get acik => _durum == KasaDurumu.acik;

  List<int>? _anahtar;
  final Map<int, String> _cozulmus = {};

  /// Kasa açıkken kilitli notun düz metni; kapalıyken null.
  String? cozulmus(int id) => _cozulmus[id];

  /// Anahtar bu oturumda üretildiyse paket onu bellekte tutuyor ve sonraki
  /// okumalar parmak izi istemiyor (K1 bulgusu). Bu oturumda kasa açılırken
  /// ayrıca parmak izi istenir.
  bool _ilkKurulumOturumu = false;

  String? _hata;
  String? get hata => _hata;

  final List<Future<void> Function()> _kapanmadanOnce = [];
  void kapanmadanOnceEkle(Future<void> Function() is_) =>
      _kapanmadanOnce.add(is_);
  void kapanmadanOnceCikar(Future<void> Function() is_) =>
      _kapanmadanOnce.remove(is_);

  Future<void> baslat() async {
    _durum = await _servis.cihazUygun()
        ? KasaDurumu.kapali
        : KasaDurumu.kullanilamaz;
    notifyListeners();
  }

  /// Parmak izi ister. İptalde kapalı kalır. Başarıda [notlar]ı çözer.
  Future<bool> ac(List<Not> notlar) async {
    if (_durum != KasaDurumu.kapali && _durum != KasaDurumu.bozuk) return acik;
    _durumYap(KasaDurumu.dogrulaniyor);
    try {
      if (_ilkKurulumOturumu && !await _servis.dogrula()) {
        _durumYap(KasaDurumu.kapali);
        return false;
      }
      _anahtar = await _servis.anahtariOku();
      await _coz(notlar);
      _hata = null;
      _durumYap(KasaDurumu.acik);
      await _gizlilik.onizlemeyiGizle(true);
      return true;
    } on KasaIptal {
      _durumYap(KasaDurumu.kapali);
      return false;
    } on AnahtarGecersiz {
      _bozuk();
      return false;
    } on SifrelemeHatasi {
      _bozuk();
      return false;
    } catch (e) {
      _hata = 'Kasa açılamadı: $e';
      _durumYap(KasaDurumu.kapali);
      return false;
    }
  }

  void _bozuk() {
    _anahtar = null;
    _cozulmus.clear();
    _hata =
        'Kasanın anahtarı artık açılmıyor. Telefona yeni parmak izi '
        'eklenmiş olabilir; kilitli notlar okunamaz.';
    _durumYap(KasaDurumu.bozuk);
  }

  /// Kasa açıkken not listesi değişince yeni kilitli notları çözer.
  Future<void> notlarDegisti(List<Not> notlar) async {
    if (!acik) return;
    await _coz(notlar);
    notifyListeners();
  }

  Future<void> _coz(List<Not> notlar) async {
    final anahtar = _anahtar!;
    final kilitliler = notlar.where((n) => n.kilitli && n.sifreli != null);
    _cozulmus.removeWhere((id, _) => !kilitliler.any((n) => n.id == id));
    for (final n in kilitliler) {
      _cozulmus[n.id] = await _sifreleme.coz(n.sifreli!, anahtar);
    }
  }

  Future<void> kapat() async {
    if (!acik) return;
    for (final is_ in List.of(_kapanmadanOnce)) {
      await is_();
    }
    _anahtar = null;
    _cozulmus.clear();
    _durumYap(KasaDurumu.kapali);
    await _gizlilik.onizlemeyiGizle(false);
  }

  /// Arka plana geçince kapanır. `inactive` sayılmaz: parmak izi penceresi
  /// ve bildirim perdesi de onu tetikler (K1'de ölçüldü).
  Future<void> yasamDegisti(AppLifecycleState s) async {
    if (s == AppLifecycleState.hidden || s == AppLifecycleState.paused) {
      await kapat();
    }
  }

  /// Notu kasaya koyar. Kasa kapalıysa önce açılır; anahtar hiç yoksa üretilir.
  Future<bool> kilitle(Not not, List<Not> notlar) async {
    if (!acik) {
      if (_durum == KasaDurumu.kapali && !await _servis.anahtarVar()) {
        _durumYap(KasaDurumu.dogrulaniyor);
        try {
          _anahtar = await _servis.anahtarOlustur();
          _ilkKurulumOturumu = true;
          _durumYap(KasaDurumu.acik);
          await _gizlilik.onizlemeyiGizle(true);
        } on KasaIptal {
          _durumYap(KasaDurumu.kapali);
          return false;
        }
      } else if (!await ac(notlar)) {
        return false;
      }
    }
    final metin = not.icerik ?? '';
    await _depo.kilitle(not.id, await _sifreleme.sifrele(metin, _anahtar!));
    _cozulmus[not.id] = metin;
    notifyListeners();
    return true;
  }

  /// Notu kasadan çıkarır (kasa açık olmalı).
  Future<void> kilidiAc(int id) async {
    final metin = _cozulmus[id];
    if (!acik || metin == null) return;
    await _depo.kilidiAc(id, metin);
    _cozulmus.remove(id);
    notifyListeners();
  }

  /// Kasa açıkken kilitli notun yeni hâlini şifreleyip yazar.
  Future<void> kilitliKaydet(int id, String metin) async {
    if (!acik) return;
    await _depo.sifreliGuncelle(id, await _sifreleme.sifrele(metin, _anahtar!));
    _cozulmus[id] = metin;
  }

  void _durumYap(KasaDurumu d) {
    _durum = d;
    notifyListeners();
  }
}
