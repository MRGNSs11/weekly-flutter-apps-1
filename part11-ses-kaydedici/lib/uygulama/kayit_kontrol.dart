import 'dart:async';

import 'package:flutter/foundation.dart';

import '../alan/ad.dart';
import '../alan/seviye.dart';
import '../veri/kayit_deposu.dart';
import 'kaydedici.dart';

enum Asama { hazir, izinYok, kayit, duraklatildi, kaydediliyor }

/// Kayıt ekranının beyni: kaydet → duraklat/devam → durdur (depoya yaz)
/// ya da iptal (dosya silinir, depoya yazılmaz).
class KayitKontrol extends ChangeNotifier {
  KayitKontrol({
    required this._kaydedici,
    required this._sistem,
    required this._depo,
    required this._klasor,
    required this._boyutOku,
    DateTime Function()? saat,
  }) : _saat = saat ?? DateTime.now;

  final Kaydedici _kaydedici;
  final Sistem _sistem;
  final KayitDeposu _depo;
  final Future<String> Function() _klasor;
  final Future<int> Function(String) _boyutOku;
  final DateTime Function() _saat;

  final _kronometre = Stopwatch();
  final List<double> _ornekler = [];
  StreamSubscription<double>? _seviyeAbone;
  StreamSubscription<KaydediciDurumu>? _durumAbone;
  DateTime? _baslangic;
  String? _yol;

  Asama _asama = Asama.hazir;
  Asama get asama => _asama;

  Duration get sure => _kronometre.elapsed;

  /// Kayıt sırasında gelen seviyeler (0..1); durdurunca dalga olarak saklanır.
  List<double> get ornekler => List.unmodifiable(_ornekler);

  /// Dosyanın o anki boyu; saniyede bir okunur.
  int boyut = 0;

  bool get kayitta => _asama == Asama.kayit || _asama == Asama.duraklatildi;

  Future<void> kaydet() async {
    if (_asama != Asama.hazir && _asama != Asama.izinYok) return;
    if (!await _kaydedici.izinVar()) {
      _degis(Asama.izinYok);
      return;
    }
    // Bildirim izni olmasa da kayıt sürer; yalnız "Kaydediliyor" görünmez.
    await _sistem.bildirimIzniIste();

    final t = _saat();
    final yol = '${await _klasor()}/${dosyaAdi(t)}';
    await _sistem.servisBaslat();
    try {
      await _kaydedici.baslat(yol);
    } catch (_) {
      await _sistem.servisDurdur();
      rethrow;
    }
    _baslangic = t;
    _yol = yol;
    _ornekler.clear();
    boyut = 0;
    _kronometre
      ..reset()
      ..start();
    _seviyeAbone = _kaydedici.seviyeler().listen(_seviyeGeldi);
    _durumAbone = _kaydedici.durumlar().listen(_durumGeldi);
    _degis(Asama.kayit);
  }

  void _seviyeGeldi(double dbfs) {
    if (_asama != Asama.kayit) return;
    _ornekler.add(seviye(dbfs));
    if (_ornekler.length % 20 == 1) _boyutGuncelle();
    notifyListeners();
  }

  Future<void> _boyutGuncelle() async {
    final yol = _yol;
    if (yol == null) return;
    try {
      boyut = await _boyutOku(yol);
    } catch (_) {
      // Dosya henüz yazılmadıysa bir sonraki okumada gelir.
    }
  }

  /// Telefon gelince mikrofon kendiliğinden duraklar; ekran da buna uyar.
  void _durumGeldi(KaydediciDurumu d) {
    if (d == KaydediciDurumu.duraklatildi && _asama == Asama.kayit) {
      _kronometre.stop();
      _degis(Asama.duraklatildi);
    }
  }

  Future<void> duraklat() async {
    if (_asama != Asama.kayit) return;
    await _kaydedici.duraklat();
    _kronometre.stop();
    _degis(Asama.duraklatildi);
  }

  Future<void> devam() async {
    if (_asama != Asama.duraklatildi) return;
    await _kaydedici.devam();
    _kronometre.start();
    _degis(Asama.kayit);
  }

  /// Kaydı bitirir ve listeye ekler.
  Future<void> durdur() async {
    if (!kayitta) return;
    _kronometre.stop();
    _degis(Asama.kaydediliyor);
    final yol = await _kaydedici.durdur();
    await _bagiKes();
    if (yol != null) {
      await _depo.ekle(
        ad: varsayilanAd(_baslangic!),
        dosyaYolu: yol,
        sure: _kronometre.elapsed,
        boyutBayt: await _boyutOku(yol),
        dalga: List.of(_ornekler),
        olusturma: _baslangic,
      );
    }
    _sifirla();
  }

  /// Kaydı tutmadan çıkar.
  Future<void> iptal() async {
    if (!kayitta) return;
    _kronometre.stop();
    await _kaydedici.iptal();
    await _bagiKes();
    _sifirla();
  }

  /// Ayarlardan dönünce: izin verildiyse hazır.
  Future<void> izniYokla() async {
    if (_asama != Asama.izinYok) return;
    if (await _kaydedici.izinVar(iste: false)) _degis(Asama.hazir);
  }

  /// "Tekrar sor": Android penceresi yeniden (kalıcı retten sonra açılmaz).
  Future<void> tekrarSor() async {
    if (_asama != Asama.izinYok) return;
    if (await _kaydedici.izinVar()) _degis(Asama.hazir);
  }

  Future<void> ayarlariAc() => _sistem.ayarlariAc();

  Future<void> _bagiKes() async {
    await _seviyeAbone?.cancel();
    await _durumAbone?.cancel();
    _seviyeAbone = null;
    _durumAbone = null;
    await _sistem.servisDurdur();
  }

  void _sifirla() {
    _ornekler.clear();
    _kronometre.reset();
    boyut = 0;
    _yol = null;
    _baslangic = null;
    _degis(Asama.hazir);
  }

  void _degis(Asama a) {
    _asama = a;
    notifyListeners();
  }

  @override
  void dispose() {
    _seviyeAbone?.cancel();
    _durumAbone?.cancel();
    super.dispose();
  }
}
