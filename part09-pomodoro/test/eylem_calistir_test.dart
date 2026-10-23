import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/alan/faz.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';
import 'package:pomodoro/bildirim/arka_plan.dart';

import 'sahte/sahteler.dart';

void main() {
  final simdi = DateTime.utc(2026, 10, 23, 9);

  test('eylem kaydedilir ve panel yeni durumla eşitlenir', () async {
    final depo = SahteDepo();
    final bildirim = SahteBildirim();
    final y = await eylemCalistir(
      'baslat',
      depo: depo,
      bildirim: bildirim,
      simdi: simdi,
    );
    expect(depo.durum.durum, Durum.calisiyor);
    expect(depo.durum.bitis, simdi.add(const Duration(minutes: 25)));
    expect(bildirim.esitlenen, [y]);
  });

  test('duraklat butonu kalan süreyi kaydeder', () async {
    final depo = SahteDepo(
      durum: PomodoroDurumu(
        durum: Durum.calisiyor,
        bitis: simdi.add(const Duration(minutes: 10)),
        toplam: const Duration(minutes: 25),
      ),
    );
    final bildirim = SahteBildirim();
    await eylemCalistir(
      'duraklat',
      depo: depo,
      bildirim: bildirim,
      simdi: simdi,
    );
    expect(depo.durum.durum, Durum.duraklatildi);
    expect(depo.durum.kalan, const Duration(minutes: 10));
    expect(bildirim.esitlenen.single.durum, Durum.duraklatildi);
  });

  test('alarmdaki Atla sıradaki fazı geçer', () async {
    final depo = SahteDepo(
      durum: const PomodoroDurumu(faz: Faz.kisaMola, donguSayaci: 1),
    );
    final bildirim = SahteBildirim()..alarm = true;
    await eylemCalistir('atla', depo: depo, bildirim: bildirim, simdi: simdi);
    expect(depo.durum.faz, Faz.calisma);
    expect(bildirim.alarm, isFalse);
  });

  test('bilinmeyen eylem hiçbir şey yapmaz', () async {
    final depo = SahteDepo();
    final bildirim = SahteBildirim();
    final y = await eylemCalistir(
      'uc',
      depo: depo,
      bildirim: bildirim,
      simdi: simdi,
    );
    expect(y, isNull);
    expect(depo.yazmaSayisi, 0);
    expect(bildirim.esitlenen, isEmpty);
  });
}
