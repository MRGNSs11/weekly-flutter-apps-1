import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/alan/ayarlar.dart';
import 'package:pomodoro/alan/faz.dart';
import 'package:pomodoro/alan/kurallar.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';

void main() {
  const a = Ayarlar();
  final t0 = DateTime(2026, 10, 22, 10);
  final calisan = baslat(const PomodoroDurumu(), a, t0);
  final bitis = calisan.bitis!;

  test('bitişten önce durum değişmez', () {
    final once = bitis.subtract(const Duration(milliseconds: 1));
    expect(ilerlet(calisan, once), calisan);
  });

  test('bitiş anında tamamlanır, sıradaki faz bosta', () {
    final d = ilerlet(calisan, bitis);
    expect(d.faz, Faz.kisaMola);
    expect(d.durum, Durum.bosta);
    expect(d.bugunSayisi, 1);
    expect(d.donguSayaci, 1);
  });

  test('bitişten sonra da tamamlanır', () {
    final d = ilerlet(calisan, bitis.add(const Duration(minutes: 3)));
    expect(d.faz, Faz.kisaMola);
    expect(d.bugunSayisi, 1);
  });

  test('molanın bitişi sayıyı artırmaz', () {
    final mola = baslat(ilerlet(calisan, bitis), a, bitis);
    final d = ilerlet(mola, mola.bitis!);
    expect(d.faz, Faz.calisma);
    expect(d.bugunSayisi, 1);
    expect(d.donguSayaci, 1);
  });

  test('saatlerce kapalı kalınca yalnız bir faz tamamlanır', () {
    final d = ilerlet(calisan, t0.add(const Duration(hours: 9)));
    expect(d.faz, Faz.kisaMola);
    expect(d.durum, Durum.bosta);
    expect(d.bugunSayisi, 1);
    // Bir kez daha okumak bir şey değiştirmez: sonraki faz kendiliğinden başlamaz.
    expect(ilerlet(d, t0.add(const Duration(hours: 10))), d);
  });

  test('gece yarısı: 23:50 bitişi dünün sayısına gider, yeni gün 0', () {
    final dun = DateTime(2026, 10, 22, 23, 25);
    final eski = PomodoroDurumu(bugunSayisi: 5, gun: gunAnahtari(dun));
    final b = baslat(eski, a, dun); // 23:50'de biter
    final gece = DateTime(2026, 10, 23, 0, 10);
    final d = ilerlet(b, gece);
    expect(d.gun, '2026-10-22');
    expect(d.bugunSayisi, 6);
    expect(bugunGoster(d, gece), 0);
    expect(bugunGoster(d, DateTime(2026, 10, 22, 23, 55)), 6);
  });

  test('yeni günün ilk pomodorosu sayacı 1\'den başlatır', () {
    final eski = PomodoroDurumu(bugunSayisi: 7, gun: '2026-10-21');
    final b = baslat(eski, a, t0);
    final d = ilerlet(b, b.bitis!);
    expect(d.gun, '2026-10-22');
    expect(d.bugunSayisi, 1);
  });

  test('ilerleme oranı 0 → 1, bosta iken 0', () {
    expect(ilerleme(calisan, t0), 0);
    expect(
      ilerleme(calisan, t0.add(const Duration(minutes: 5))),
      closeTo(0.2, 1e-9),
    );
    expect(ilerleme(calisan, bitis.add(const Duration(minutes: 1))), 1);
    expect(ilerleme(const PomodoroDurumu(), t0), 0);
  });
}
