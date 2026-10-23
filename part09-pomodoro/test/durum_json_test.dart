import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/alan/ayarlar.dart';
import 'package:pomodoro/alan/faz.dart';
import 'package:pomodoro/alan/kurallar.dart';
import 'package:pomodoro/alan/pomodoro_durumu.dart';

void main() {
  final t0 = DateTime(2026, 10, 22, 10);

  test('durum gidiş-dönüş aynı', () {
    final calisan = baslat(
      const PomodoroDurumu(donguSayaci: 2, bugunSayisi: 3, gun: '2026-10-22'),
      const Ayarlar(),
      t0,
    );
    final duran = duraklat(calisan, t0.add(const Duration(minutes: 4)));
    for (final d in [const PomodoroDurumu(), calisan, duran]) {
      expect(PomodoroDurumu.fromJson(d.toJson()), d);
    }
  });

  test('ayarlar gidiş-dönüş aynı', () {
    const a = Ayarlar(
      calismaDk: 50,
      kisaMolaDk: 10,
      uzunMolaDk: 30,
      ses: false,
    );
    expect(Ayarlar.fromJson(a.toJson()), a);
  });

  test('bozuk ya da eksik veri varsayılana düşer, çökmez', () {
    expect(PomodoroDurumu.fromJson(null), const PomodoroDurumu());
    expect(PomodoroDurumu.fromJson('saçma'), const PomodoroDurumu());
    expect(
      PomodoroDurumu.fromJson({'faz': 'yok', 'durum': 'bosta'}),
      const PomodoroDurumu(),
    );
    // Çalışıyor ama bitiş yok → aynı fazda bosta.
    expect(
      PomodoroDurumu.fromJson({'faz': 'kisaMola', 'durum': 'calisiyor'}),
      const PomodoroDurumu(faz: Faz.kisaMola),
    );
    expect(Ayarlar.fromJson({'calismaDk': 'x', 'ses': 3}), const Ayarlar());
    expect(Ayarlar.fromJson({'calismaDk': 999}).calismaDk, 90);
  });
}
