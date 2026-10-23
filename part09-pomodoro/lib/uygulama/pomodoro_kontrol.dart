import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../alan/ayarlar.dart';
import '../alan/faz.dart';
import '../alan/kurallar.dart';
import '../alan/pomodoro_durumu.dart';
import '../bildirim/arka_plan.dart';
import '../bildirim/bildirim_servisi.dart';
import '../veri/durum_deposu.dart';
import 'saat.dart';
import 'zil.dart';

/// Üstte çıkan izin bandı (PLAN K6.7, K6.9).
enum Bant { bildirimKapali, kesinYok, tamEkranYok }

sealed class KontrolOlayi {
  const KontrolOlayi();
}

/// Uygulama açıkken bir faz bitti (titreşim).
class FazBitti extends KontrolOlayi {
  const FazBitti();
}

/// Bir pomodoro tamamlandı: [nokta] dolar, 4/4'te [buyuk] konfeti.
/// Alarm ekranı kapanınca gelir, kutlama alarmın altında kalmasın diye.
class Kutla extends KontrolOlayi {
  const Kutla({required this.nokta, required this.buyuk});
  final int nokta;
  final bool buyuk;
}

/// Bayrak adları: her izin yalnız bir kez sorulur.
abstract final class Bayrak {
  static const bildirimSoruldu = 'bildirimSoruldu';
  static const kesinSoruldu = 'kesinSoruldu';
  static const tamEkranSoruldu = 'tamEkranSoruldu';
}

/// Ekranın tek kaynağı. Durum her okunuşta [ilerlet] ile güncellenir:
/// açılış, `resumed`, her eylem ve saniye sayacı (PLAN K3).
class PomodoroKontrol extends ChangeNotifier with WidgetsBindingObserver {
  PomodoroKontrol({
    required this.depo,
    required this.bildirim,
    required this.zil,
    Saat? saat,
    this.portAdi = uiPortAdi,
  }) : saat = saat ?? gercekSaat;

  final DurumDeposu depo;
  final BildirimServisi bildirim;
  final Zil zil;
  final Saat saat;

  /// `null` ise port kurulmaz (testler).
  final String? portAdi;

  PomodoroDurumu _d = const PomodoroDurumu();
  Ayarlar _a = const Ayarlar();
  IzinDurumu _izin = IzinDurumu.hepsiVar;
  final _bayrak = <String, bool>{};
  bool _yuklendi = false;
  bool _alarm = false;
  bool _kapandi = false;
  int? _surukDk;
  Timer? _saniye;
  ReceivePort? _port;
  bool _tikte = false;
  final _olaylar = StreamController<KontrolOlayi>.broadcast();

  /// Uygulama açıkken biten faz: alarm aranır, kutlama bekletilir.
  DateTime? _tamamlanma;
  Kutla? _bekleyenKutlama;
  bool _alarmGoruldu = false;

  PomodoroDurumu get durum => _d;
  Ayarlar get ayarlar => _a;
  bool get yuklendi => _yuklendi;
  bool get alarmModu => _alarm;
  Stream<KontrolOlayi> get olaylar => _olaylar.stream;
  DateTime get simdi => saat();

  /// Sürüklenirken ekranda gösterilen çalışma süresi.
  int? get surukDk => _surukDk;

  Duration get kalan => _surukDk != null
      ? Duration(minutes: _surukDk!)
      : kalanSure(_d, _a, simdi);

  /// Geçen sürenin oranı. Saniye adımlı istenirse [an] verilir.
  double ilerlemeOrani([DateTime? an]) => ilerleme(_d, an ?? simdi);

  int get bugun => bugunGoster(_d, simdi);

  Bant? get bant {
    if (_bayrak[Bayrak.bildirimSoruldu] == true && !_izin.bildirim) {
      return Bant.bildirimKapali;
    }
    if (!_izin.bildirim) return null;
    if (_bayrak[Bayrak.kesinSoruldu] == true && !_izin.kesin) {
      return Bant.kesinYok;
    }
    if (_bayrak[Bayrak.tamEkranSoruldu] == true && !_izin.tamEkran) {
      return Bant.tamEkranYok;
    }
    return null;
  }

  Future<void> yukle() async {
    WidgetsBinding.instance.addObserver(this);
    _a = await depo.ayarlarOku();
    _d = await depo.durumOku();
    for (final b in [
      Bayrak.bildirimSoruldu,
      Bayrak.kesinSoruldu,
      Bayrak.tamEkranSoruldu,
    ]) {
      _bayrak[b] = await depo.bayrakOku(b);
    }
    await _ilerlet(acilis: true);
    await _alarmKontrol();
    if (!_alarm) {
      await zil.sustur();
      // Telefon yeniden başladıysa kalıcı sayaç bildirimi geri konur (K6.8).
      await bildirim.esitle(_d, _a);
    }
    await _izinleriOku();
    _saniye = Timer.periodic(const Duration(seconds: 1), (_) => _tik());
    _portKur();
    _yuklendi = true;
    _bildir();
  }

  void _portKur() {
    final ad = portAdi;
    if (ad == null) return;
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(ad);
    IsolateNameServer.registerPortWithName(port.sendPort, ad);
    port.listen((_) => _yenile());
    _port = port;
  }

  /// Arka plandaki bildirim butonu kaydı değiştirdi.
  Future<void> _yenile() async {
    _d = await depo.durumOku();
    if (_alarm && !await bildirim.alarmVar()) await _alarmBitti();
    await _ilerlet();
    _bildir();
  }

  /// Faz bittiyse sıradakine geçer, kaydeder. Geçtiyse `true`.
  Future<bool> _ilerlet({bool acilis = false}) async {
    final y = ilerlet(_d, simdi);
    if (y == _d) return false;
    final calismaydi = _d.faz == Faz.calisma;
    _d = y;
    await depo.durumYaz(y);
    _tamamlanma = simdi;
    _alarmGoruldu = false;
    if (!acilis) _olaylar.add(const FazBitti());
    if (calismaydi) {
      _bekleyenKutlama = Kutla(
        nokta: (y.donguSayaci - 1).clamp(0, 3),
        buyuk: y.donguSayaci == 4,
      );
    }
    return true;
  }

  Future<void> _tik() async {
    if (_tikte || _kapandi) return;
    _tikte = true;
    try {
      await _ilerlet();
      if (_alarm) {
        // Panelden Başlat/Atla'ya basıldıysa ya da kaydırıldıysa bildirim
        // gitmiştir: zili de sustur.
        if (!await bildirim.alarmVar()) await _alarmBitti();
      } else if (_tamamlanma case final t?
          when simdi.difference(t) < const Duration(seconds: 15)) {
        // Zamanlanmış bildirim birkaç saniye geç düşebilir.
        await _alarmKontrol();
      }
      _kutlamaKontrol();
      _bildir();
    } finally {
      _tikte = false;
    }
  }

  /// Panelde "süre doldu" duruyorsa alarm ekranına geç ve zili çal (K6.9).
  Future<void> _alarmKontrol() async {
    if (_alarm || _kapandi) return;
    if (!await bildirim.alarmVar()) return;
    _alarm = true;
    _alarmGoruldu = true;
    await bildirim.alarmiSessizYap(_d, _a, bugun);
    if (_a.ses) await zil.cal();
    _bildir();
  }

  Future<void> _alarmBitti() async {
    _alarm = false;
    await zil.sustur();
    _kutlamaKontrol();
    _bildir();
  }

  void _kutlamaKontrol() {
    final k = _bekleyenKutlama;
    final t = _tamamlanma;
    if (k == null || _alarm) return;
    final alarmsiz =
        t == null || simdi.difference(t) >= const Duration(seconds: 3);
    if (!_alarmGoruldu && !alarmsiz) return;
    _bekleyenKutlama = null;
    _olaylar.add(k);
  }

  /// Ekrandaki ve bildirimdeki butonlar buradan geçer (PLAN K4).
  Future<void> eylemYap(String ad) async {
    // Arka plandaki buton kaydı değiştirmiş olabilir.
    _d = await depo.durumOku();
    await _ilerlet();
    final y = eylem(ad, _d, _a, simdi);
    if (_alarm && (ad == 'baslat' || ad == 'atla' || ad == 'bitir')) {
      _alarm = false;
      await zil.sustur();
    }
    if (y != _d) {
      _d = y;
      await depo.durumYaz(y);
    }
    await bildirim.esitle(_d, _a);
    _kutlamaKontrol();
    _bildir();
  }

  /// Bildirime dokunuldu ya da ön plandayken bildirim butonuna basıldı.
  Future<void> bildirimYaniti(String? ad) async {
    if (ad == null || ad.isEmpty) {
      await _alarmKontrol();
    } else {
      await eylemYap(ad);
    }
  }

  /// Alarm ekranındaki Durdur: yalnız susturur, durum sıradaki fazda `bosta`.
  Future<void> alarmiDurdur() async {
    await bildirim.alarmiKapat();
    await _alarmBitti();
  }

  Future<void> ayarlariDegistir(Ayarlar a) async {
    _a = a;
    await depo.ayarlarYaz(a);
    // Ses ayarı zamanlanmış "bitti"yi etkiler. Çalışan faz süresi değişmez.
    if (!_alarm) await bildirim.esitle(_d, _a);
    _bildir();
  }

  /// Dikey sürükleme yalnız `bosta` + çalışmada (PLAN B2.6).
  bool get surukleyebilir => _d.durum == Durum.bosta && _d.faz == Faz.calisma;

  /// [seviye] 0 (ekranın dibi) – 1 (tepesi). Dakikayı döndürür.
  int? surukle(double seviye) {
    if (!surukleyebilir) return null;
    _surukDk = surukDakika(seviye);
    _bildir();
    return _surukDk;
  }

  Future<void> surukBitti() async {
    final dk = _surukDk;
    if (dk == null) return;
    _surukDk = null;
    await ayarlariDegistir(_a.kopya(calismaDk: dk));
  }

  /// İlk Başlat'tan sonra izinleri sırayla bir kez sorar (PLAN K6.7, K6.9).
  /// [aciklama] kullanıcıya kısa açıklama gösterir, onaylanırsa `true`.
  Future<void> izinAkisi(
    Future<bool> Function(String baslik, String metin) aciklama,
  ) async {
    await _izinleriOku();
    if (!_izin.bildirim && !_soruldu(Bayrak.bildirimSoruldu)) {
      await _isaretle(Bayrak.bildirimSoruldu);
      await bildirim.bildirimIzniIste();
      await _izinleriOku();
    }
    if (_izin.bildirim && !_izin.kesin && !_soruldu(Bayrak.kesinSoruldu)) {
      await _isaretle(Bayrak.kesinSoruldu);
      if (await aciklama(
        'Tam zamanında uyarı',
        'Süre bittiği an uyarabilmek için "Alarmlar ve hatırlatıcılar" '
            'izni gerekiyor. Vermezsen uyarı birkaç dakika gecikebilir.',
      )) {
        await bildirim.kesinIzniIste();
      }
      await _izinleriOku();
    }
    if (_izin.bildirim &&
        !_izin.tamEkran &&
        !_soruldu(Bayrak.tamEkranSoruldu)) {
      await _isaretle(Bayrak.tamEkranSoruldu);
      if (await aciklama(
        'Kilit ekranında alarm',
        'Telefon kilitliyken süre dolunca ekranın açılması için '
            '"Tam ekran bildirimleri" izni gerekiyor.',
      )) {
        await bildirim.tamEkranIzniIste();
      }
      await _izinleriOku();
    }
    if (!_alarm) await bildirim.esitle(_d, _a);
    _bildir();
  }

  /// Banttaki "Ayarları aç / İzin ver".
  Future<void> bantEylemi() async {
    switch (bant) {
      case Bant.bildirimKapali:
        await bildirim.bildirimAyarlariniAc();
      case Bant.kesinYok:
        await bildirim.kesinIzniIste();
      case Bant.tamEkranYok:
        await bildirim.tamEkranIzniIste();
      case null:
        return;
    }
    await _izinleriOku();
    _bildir();
  }

  bool _soruldu(String b) => _bayrak[b] == true;

  Future<void> _isaretle(String b) async {
    _bayrak[b] = true;
    await depo.bayrakYaz(b, true);
  }

  Future<void> _izinleriOku() async => _izin = await bildirim.izinler();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_donus());
  }

  Future<void> _donus() async {
    _d = await depo.durumOku();
    await _ilerlet(acilis: true);
    await _alarmKontrol();
    await _izinleriOku();
    if (!_alarm) {
      await zil.sustur();
      await bildirim.esitle(_d, _a);
    }
    _bildir();
  }

  void _bildir() {
    if (!_kapandi) notifyListeners();
  }

  @override
  void dispose() {
    _kapandi = true;
    _saniye?.cancel();
    _port?.close();
    final ad = portAdi;
    if (ad != null && _port != null) {
      IsolateNameServer.removePortNameMapping(ad);
    }
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_olaylar.close());
    super.dispose();
  }
}

/// Ekranın dibi 1 dk, tepesi 90 dk (PLAN B2.6).
int surukDakika(double seviye) =>
    (seviye.clamp(0.0, 1.0) * Ayarlar.calismaAralik.$2).round().clamp(
      Ayarlar.calismaAralik.$1,
      Ayarlar.calismaAralik.$2,
    );
