import 'package:flutter/widgets.dart';

import '../veri/veritabani.dart';

enum RehberEkrani { liste, duzenleyici }

enum RehberHareketi { dokun, basiliTut }

class RehberAdimi {
  const RehberAdimi(
    this.hedef,
    this.ekran,
    this.hareket,
    this.baslik,
    this.metin,
  );
  final GlobalKey Function(RehberHedefleri) hedef;
  final RehberEkrani ekran;
  final RehberHareketi hareket;
  final String baslik, metin;
}

/// Turun ışık tuttuğu öğeler. Ekranlar bu anahtarları kendi öğelerine verir.
class RehberHedefleri {
  final yeniNot = GlobalKey(debugLabel: 'yeniNot');
  final ilkKart = GlobalKey(debugLabel: 'ilkKart');
  final kasaSeridi = GlobalKey(debugLabel: 'kasaSeridi');
  final soru = GlobalKey(debugLabel: 'soru');
  final gorevDugmesi = GlobalKey(debugLabel: 'gorevDugmesi');
  final onizlemeKutusu = GlobalKey(debugLabel: 'onizlemeKutusu');
}

const rehberAdimlari = [
  RehberAdimi(
    _yeniNot,
    RehberEkrani.liste,
    RehberHareketi.dokun,
    'Yeni not',
    '+ düğmesine bas, yazmaya başla. Kaydet düğmesi yok, kendiliğinden kaydedilir.',
  ),
  RehberAdimi(
    _gorev,
    RehberEkrani.duzenleyici,
    RehberHareketi.dokun,
    'Görev kutusu',
    "Bu düğme satıra görev kutusu ekler. Enter'a basınca liste kendiliğinden devam eder.",
  ),
  RehberAdimi(
    _kutu,
    RehberEkrani.duzenleyici,
    RehberHareketi.dokun,
    'İşaretle',
    'Önizlemedeki kutuya dokun: iş bitti olarak işaretlenir.',
  ),
  RehberAdimi(
    _kart,
    RehberEkrani.liste,
    RehberHareketi.basiliTut,
    'Notu kilitle',
    'Bir notu basılı tut, "Kilitle"yi seç. Not camın arkasına geçer, şifrelenir.',
  ),
  RehberAdimi(
    _serit,
    RehberEkrani.liste,
    RehberHareketi.dokun,
    'Kasayı aç',
    'Alttaki şeride dokun, parmak izini okut. Uygulamadan çıkınca kasa kendiliğinden kapanır.',
  ),
  RehberAdimi(
    _soru,
    RehberEkrani.liste,
    RehberHareketi.dokun,
    'Rehber hep burada',
    'Bu rehberi istediğin zaman ? düğmesinden tekrar açabilirsin.',
  ),
];

GlobalKey _yeniNot(RehberHedefleri h) => h.yeniNot;
GlobalKey _gorev(RehberHedefleri h) => h.gorevDugmesi;
GlobalKey _kutu(RehberHedefleri h) => h.onizlemeKutusu;
GlobalKey _kart(RehberHedefleri h) => h.ilkKart;
GlobalKey _serit(RehberHedefleri h) => h.kasaSeridi;
GlobalKey _soru(RehberHedefleri h) => h.soru;

/// İlk açılışta bir kez, sonra ? ile. Tur sırasında dokunuşlar yalnız
/// ilerletir, gerçek işlem yapmaz.
class RehberKontrol extends ChangeNotifier {
  RehberKontrol(this._db);

  final Veritabani _db;
  static const _anahtar = 'rehber';
  final hedefler = RehberHedefleri();

  int? _adim;
  bool get aktif => _adim != null;
  int get adimNo => _adim ?? 0;
  RehberAdimi get adim => rehberAdimlari[adimNo];

  /// İlk açılışsa turu başlatır.
  Future<void> ilkAcilis() async {
    if (await _db.ayarOku(_anahtar) == null) baslat();
  }

  void baslat() {
    _adim = 0;
    notifyListeners();
  }

  void ileri() {
    if (_adim == null) return;
    if (_adim! + 1 >= rehberAdimlari.length) return bitir();
    _adim = _adim! + 1;
    notifyListeners();
  }

  void bitir() {
    _adim = null;
    notifyListeners();
    _db.ayarYaz(_anahtar, 'goruldu');
  }
}
