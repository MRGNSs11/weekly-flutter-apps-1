import 'dart:async';

import 'package:flutter/foundation.dart';

import '../alan/ad.dart';
import '../alan/hiz.dart';
import '../alan/kayit.dart';
import '../veri/kayit_deposu.dart';
import 'calar.dart';

/// Kayıtlar sayfası + oynatıcı: seç, çal, sar, hız, yeniden adlandır,
/// sil (Geri al süresi bitince dosya da silinir).
class ListeKontrol extends ChangeNotifier {
  ListeKontrol({
    required this._depo,
    required this._calar,
    required this._dosyaSil,
    required this._paylasici,
    this.geriAlSuresi = const Duration(seconds: 5),
  }) {
    _listeAbone = _depo.izle().listen(_listeGeldi);
    _konumAbone = _calar.konum().listen((k) {
      konum = k;
      notifyListeners();
    });
    _caliyorAbone = _calar.caliyor().listen((c) {
      caliyor = c;
      notifyListeners();
    });
    _bittiAbone = _calar.bitti().listen((_) => _sonaGeldi());
  }

  final KayitDeposu _depo;
  final Calar _calar;
  final Future<void> Function(String) _dosyaSil;

  /// Android paylaş menüsü (testte sahte).
  final Future<void> Function(Kayit) _paylasici;
  final Duration geriAlSuresi;

  late final StreamSubscription<List<Kayit>> _listeAbone;
  late final StreamSubscription<Duration> _konumAbone;
  late final StreamSubscription<bool> _caliyorAbone;
  late final StreamSubscription<void> _bittiAbone;
  Timer? _silZamanlayici;

  List<Kayit> kayitlar = const [];
  Kayit? secili;
  Duration konum = Duration.zero;
  Duration toplam = Duration.zero;
  bool caliyor = false;
  double hiz = 1;

  /// "Geri al" bekleyen kayıt.
  Kayit? silinen;

  void _listeGeldi(List<Kayit> l) {
    kayitlar = l;
    final s = secili;
    if (s != null) {
      // Ad değişince güncel hâli; silindiyse seçim kalkar.
      secili = l.where((k) => k.id == s.id).firstOrNull;
    }
    notifyListeners();
  }

  /// Sayfa açılınca: seçili yoksa en yeni kayıt (çalmadan).
  Future<void> acildi() async {
    if (secili == null && kayitlar.isNotEmpty) await sec(kayitlar.first);
  }

  Future<void> sec(Kayit k) async {
    if (secili?.id == k.id) return;
    await _calar.durdur();
    secili = k;
    konum = Duration.zero;
    toplam = k.sure;
    caliyor = false;
    notifyListeners();
    // Çaların ölçtüğü süre esastır (bizim kronometre ile birkaç ms fark).
    final sure = await _calar.yukle(k.dosyaYolu);
    if (sure != null && sure > Duration.zero) toplam = sure;
    await _calar.hiz(hiz);
    notifyListeners();
  }

  Future<void> oynatDuraklat() async {
    if (secili == null) return;
    caliyor ? await _calar.duraklat() : await _calar.oynat();
  }

  Future<void> sar(Duration k) async {
    if (secili == null) return;
    konum = k;
    notifyListeners();
    await _calar.sar(k);
  }

  Future<void> hizDegistir() async {
    hiz = sonrakiHiz(hiz);
    notifyListeners();
    await _calar.hiz(hiz);
  }

  Future<void> adDegistir(String girdi) async {
    final s = secili;
    if (s == null) return;
    final ad = temizAd(girdi, s.ad);
    if (ad != s.ad) await _depo.adDegistir(s.id, ad);
  }

  Future<void> sil(Kayit k) async {
    await _bekleyeniBitir();
    if (secili?.id == k.id) {
      await _calar.durdur();
      secili = null;
      caliyor = false;
    }
    silinen = await _depo.sil(k.id);
    notifyListeners();
    _silZamanlayici = Timer(geriAlSuresi, _bekleyeniBitir);
  }

  Future<void> geriAl() async {
    final k = silinen;
    if (k == null) return;
    _silZamanlayici?.cancel();
    silinen = null;
    notifyListeners();
    await _depo.geriEkle(k);
  }

  /// Süre doldu (ya da yeni bir silme geldi): dosya da gider.
  Future<void> _bekleyeniBitir() async {
    _silZamanlayici?.cancel();
    final k = silinen;
    if (k == null) return;
    silinen = null;
    notifyListeners();
    try {
      await _dosyaSil(k.dosyaYolu);
    } catch (_) {
      // Dosya zaten yoksa sorun değil.
    }
  }

  /// Yalnız kullanıcı basınca dosya uygulamadan çıkar (B5).
  Future<void> paylas(Kayit k) => _paylasici(k);

  /// Kayıt başlarken çalan susar.
  Future<void> durdur() async {
    if (caliyor) await _calar.duraklat();
  }

  void _sonaGeldi() {
    _calar
      ..duraklat()
      ..sar(Duration.zero);
    konum = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _bekleyeniBitir();
    _listeAbone.cancel();
    _konumAbone.cancel();
    _caliyorAbone.cancel();
    _bittiAbone.cancel();
    super.dispose();
  }
}
