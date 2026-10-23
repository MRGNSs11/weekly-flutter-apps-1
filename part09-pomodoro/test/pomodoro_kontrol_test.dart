import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/alan/ayarlar.dart';
import 'package:pomodoro/alan/faz.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';
import 'package:pomodoro/bildirim/bildirim_servisi.dart';
import 'package:pomodoro/uygulama/pomodoro_kontrol.dart';
import 'package:pomodoro/uygulama/saat.dart';

import 'sahte/sahteler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SahteSaat saat;
  setUp(() => saat = SahteSaat(DateTime.utc(2026, 10, 23, 9)));

  PomodoroKontrol kur(SahteDepo depo, SahteBildirim bildirim, SahteZil zil) =>
      PomodoroKontrol(
        depo: depo,
        bildirim: bildirim,
        zil: zil,
        saat: saat.call,
        portAdi: null,
      );

  Future<bool> evet(String _, String _) async => true;

  test('sürükleme: ekranın dibi 1 dk, tepesi 90 dk', () {
    expect(surukDakika(0), 1);
    expect(surukDakika(1), 90);
    expect(surukDakika(0.5), 45);
    expect(surukDakika(-3), 1);
  });

  test('sürükleme bırakılınca çalışma süresi ayara yazılır', () async {
    final depo = SahteDepo();
    final k = kur(depo, SahteBildirim(), SahteZil());
    await k.yukle();
    expect(k.surukle(0.4), 36);
    expect(k.kalan, const Duration(minutes: 36));
    await k.surukBitti();
    expect(depo.ayarlar.calismaDk, 36);
    expect(k.surukDk, isNull);
    k.dispose();
  });

  test('çalışırken sürükleme bir şey yapmaz', () async {
    final k = kur(SahteDepo(), SahteBildirim(), SahteZil());
    await k.yukle();
    await k.eylemYap('baslat');
    expect(k.surukle(0.9), isNull);
    expect(k.surukDk, isNull);
    k.dispose();
  });

  test('açılışta panelde alarm varsa alarm ekranı açılır, zil çalar', () async {
    final depo = SahteDepo(
      durum: PomodoroDurumu(
        durum: Durum.calisiyor,
        bitis: saat.simdi.subtract(const Duration(seconds: 5)),
        toplam: const Duration(minutes: 25),
      ),
    );
    final bildirim = SahteBildirim()..alarm = true;
    final zil = SahteZil();
    final k = kur(depo, bildirim, zil);
    final olaylar = <KontrolOlayi>[];
    k.olaylar.listen(olaylar.add);
    await k.yukle();

    expect(k.alarmModu, isTrue);
    expect(k.durum.faz, Faz.kisaMola);
    expect(zil.caliyor, isTrue);
    expect(bildirim.istenen, contains('sessiz'));
    // Kutlama alarm kapanana kadar bekler.
    await pumpEventQueue();
    expect(olaylar.whereType<Kutla>(), isEmpty);

    await k.alarmiDurdur();
    await pumpEventQueue();
    expect(k.alarmModu, isFalse);
    expect(zil.caliyor, isFalse);
    expect(k.durum.durum, Durum.bosta);
    expect(olaylar.whereType<Kutla>().single.nokta, 0);
    k.dispose();
  });

  test('ses kapalıyken alarm ekranı açılır ama zil çalmaz', () async {
    final depo = SahteDepo(ayarlar: const Ayarlar(ses: false));
    final bildirim = SahteBildirim()..alarm = true;
    final zil = SahteZil();
    final k = kur(depo, bildirim, zil);
    await k.yukle();
    expect(k.alarmModu, isTrue);
    expect(zil.calmaSayisi, 0);
    k.dispose();
  });

  test(
    'alarm ekranında Sıradakini başlat zili susturur ve fazı başlatır',
    () async {
      final bildirim = SahteBildirim()..alarm = true;
      final zil = SahteZil();
      final k = kur(
        SahteDepo(durum: const PomodoroDurumu(faz: Faz.kisaMola)),
        bildirim,
        zil,
      );
      await k.yukle();
      await k.eylemYap('baslat');
      expect(k.alarmModu, isFalse);
      expect(zil.caliyor, isFalse);
      expect(k.durum.durum, Durum.calisiyor);
      expect(k.durum.faz, Faz.kisaMola);
      k.dispose();
    },
  );

  test('bildirim izni reddedilince bant çıkar, kesin alarm sorulmaz', () async {
    final bildirim = SahteBildirim(
      izin: const IzinDurumu(bildirim: false, kesin: false, tamEkran: false),
    )..bildirimCevabi = false;
    final k = kur(SahteDepo(), bildirim, SahteZil());
    await k.yukle();
    expect(k.bant, isNull, reason: 'sorulmadan bant çıkmaz');
    await k.eylemYap('baslat');
    await k.izinAkisi(evet);
    expect(k.bant, Bant.bildirimKapali);
    expect(bildirim.istenen, ['bildirim']);
    expect(k.durum.durum, Durum.calisiyor, reason: 'sayaç yine çalışır');
    k.dispose();
  });

  test('kesin alarm ve tam ekran bir kez sorulur, reddedilince bant', () async {
    final depo = SahteDepo();
    final bildirim = SahteBildirim(
      izin: const IzinDurumu(bildirim: true, kesin: false, tamEkran: false),
    );
    final k = kur(depo, bildirim, SahteZil());
    await k.yukle();
    await k.izinAkisi(evet);
    expect(bildirim.istenen, ['kesin', 'tamEkran']);
    expect(k.bant, Bant.kesinYok);
    await k.izinAkisi(evet);
    expect(bildirim.istenen, [
      'kesin',
      'tamEkran',
    ], reason: 'ikinci kez sorulmaz');
    expect(depo.bayraklar[Bayrak.kesinSoruldu], isTrue);
    k.dispose();
  });
}
