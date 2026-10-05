import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../deprem/afad_istemcisi.dart';
import '../deprem/deprem.dart';
import '../deprem/sismogram.dart';
import 'parcalar/bilgi_seridi.dart';
import 'parcalar/deprem_haritasi.dart';
import 'parcalar/kayan_bant.dart';
import 'parcalar/sismogram_seridi.dart';
import 'parcalar/ust_bolum.dart';
import 'tema.dart';

/// Uygulamanın tek ekranı (PLAN B2.3):
/// üst · kayan bant · harita · bilgi şeridi · sismogram.
///
/// Bütün durum burada. Merkezde tek bir sayı var: [_oynatT], sismogramdaki
/// mor çizginin gösterdiği an (UTC milisaniye). Harita, bilgi şeridi ve
/// sismogram hep bu sayıya bakıyor.
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key, this.istemci});

  /// Testte sahte istemci vermek için.
  final AfadIstemcisi? istemci;

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran>
    with SingleTickerProviderStateMixin {
  late final AfadIstemcisi _istemci = widget.istemci ?? AfadIstemcisi();
  late final Ticker _ticker = createTicker(_tik);

  List<Deprem> _olaylar = const [];
  bool _yukleniyor = true;
  String? _hata;
  DateTime? _sonGuncelleme;

  final _oynatT = ValueNotifier<double>(0);
  final _secili = ValueNotifier<Deprem?>(null);

  /// Harita noktaları her karede değil, mor çizgi 12 dk ilerleyince kurulur.
  final _haritaAni = ValueNotifier<double>(0);

  bool _surukleniyor = false;
  int _birakilma = 0;
  Duration? _oncekiKare;

  /// Mor çizgi "şimdi"ye ulaştıysa her karede çizim yapmaya gerek yok.
  bool _simdide = false;

  static const _acilisGeri = 40.0 * Sismogram.saatMs;
  static const _akisHizi = 1.6; // saat / saniye
  static const _bekleme = 2500; // ms: bırakınca akış başlamadan önce
  static const _haritaAdimi = 12 * 60 * 1000.0;

  double get _simdi => DateTime.now().millisecondsSinceEpoch.toDouble();

  @override
  void initState() {
    super.initState();
    _yukle();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _istemci.kapat();
    _oynatT.dispose();
    _secili.dispose();
    _haritaAni.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    final ilk = _olaylar.isEmpty;
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final l = await _istemci.getir(simdi: DateTime.now().toUtc());
      if (!mounted) return;
      setState(() {
        _olaylar = l;
        _yukleniyor = false;
        _sonGuncelleme = DateTime.now();
      });
      // İlk açılışta şerit 40 saat geriden başlayıp şimdiye akar.
      // Yenilemede kullanıcı şimdideyse şimdide kalır, gezindiği yerdeyse orada.
      if (ilk) {
        _simdide = false;
        _ayarla(_simdi - _acilisGeri, haritaHemen: true);
      } else if (_simdide) {
        _ayarla(_simdi, haritaHemen: true);
      } else {
        _ayarla(_oynatT.value, haritaHemen: true);
      }
    } on AfadHatasi catch (e) {
      if (!mounted) return;
      setState(() {
        _yukleniyor = false;
        _hata = e.mesaj;
      });
    }
  }

  /// Mor çizgiyi [t]'ye taşır; seçili depremi ve gerekirse haritayı günceller.
  void _ayarla(double t, {bool haritaHemen = false}) {
    final yeni = Sismogram.sinirla(t, _simdi);
    _oynatT.value = yeni;
    _secili.value = Sismogram.enBuyukYakin(_olaylar, yeni);
    if (haritaHemen || (yeni - _haritaAni.value).abs() >= _haritaAdimi) {
      _haritaAni.value = yeni;
    }
  }

  void _tik(Duration gecen) {
    final dt = _oncekiKare == null
        ? 0.0
        : (gecen - _oncekiKare!).inMicroseconds / 1e6;
    _oncekiKare = gecen;
    if (_olaylar.isEmpty || _surukleniyor) return;
    final simdi = _simdi;
    if (simdi - _birakilma < _bekleme) return;
    if (_simdide) {
      // Zaman akıyor; dakikada bir yetişmek yeterli.
      if (simdi - _oynatT.value > 60000) _ayarla(simdi);
      return;
    }
    final t = _oynatT.value + _akisHizi * Sismogram.saatMs * dt;
    if (t >= simdi) {
      _simdide = true;
      _ayarla(simdi, haritaHemen: true);
    } else {
      _ayarla(t);
    }
  }

  void _suruklemeBasladi() {
    _surukleniyor = true;
    _simdide = false;
  }

  void _suruklendi(double dx) =>
      _ayarla(_oynatT.value - dx / Sismogram.dpSaat * Sismogram.saatMs);

  void _suruklemeBitti() {
    _surukleniyor = false;
    _birakilma = _simdi.toInt();
    _haritaAni.value = _oynatT.value;
  }

  /// Haritada bir noktaya dokununca şerit o depremin anına atlar.
  void _depremeAtla(Deprem e) {
    _simdide = false;
    _birakilma = _simdi.toInt();
    _ayarla(e.ms.toDouble(), haritaHemen: true);
  }

  @override
  Widget build(BuildContext context) {
    final alt = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Renk.zemin,
      body: Column(
        children: [
          UstBolum(
            sonGuncelleme: _sonGuncelleme,
            yukleniyor: _yukleniyor,
            onYenile: _yukleniyor ? null : _yukle,
          ),
          KayanBant(
            olaylar: _olaylar,
            durumMetni: _hata != null
                ? 'AFAD\'a ulaşılamadı'
                : _yukleniyor && _olaylar.isEmpty
                ? 'Veri bekleniyor…'
                : null,
          ),
          Expanded(
            child: DepremHaritasi(
              olaylar: _olaylar,
              an: _haritaAni,
              secili: _secili,
              onDeprem: _depremeAtla,
            ),
          ),
          BilgiSeridi(
            secili: _secili,
            yukleniyor: _yukleniyor && _olaylar.isEmpty,
            hata: _olaylar.isEmpty ? _hata : null,
            onYeniden: _yukle,
          ),
          SismogramSeridi(
            olaylar: _olaylar,
            oynatT: _oynatT,
            yukseklik: 222 + alt,
            altBosluk: alt,
            onBasla: _suruklemeBasladi,
            onSurukle: _suruklendi,
            onBitti: _suruklemeBitti,
          ),
        ],
      ),
    );
  }
}
