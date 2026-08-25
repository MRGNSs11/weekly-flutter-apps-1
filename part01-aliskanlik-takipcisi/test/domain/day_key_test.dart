import 'package:aliskanlik_takipcisi/domain/day_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dayKeyOf / dateOfDayKey', () {
    test('DateTime -> dayKey dönüşümü doğru basamaklara yerleşir', () {
      expect(dayKeyOf(DateTime(2026, 8, 5)), 20260805);
      expect(dayKeyOf(DateTime(2026, 12, 31)), 20261231);
    });

    test('dayKey -> DateTime gidiş-dönüşü kaybetmeden çalışır', () {
      final original = DateTime(2026, 3, 17);
      final restored = dateOfDayKey(dayKeyOf(original));
      expect(restored.year, original.year);
      expect(restored.month, original.month);
      expect(restored.day, original.day);
    });
  });

  group('epochDayOf / dayKeyOfEpoch', () {
    test('epoch gün sayısı gidiş-dönüşte kayıpsız', () {
      const key = 20260825;
      expect(dayKeyOfEpoch(epochDayOf(key)), key);
    });

    test('ay sınırını geçerken epoch tam 1 artar (31 Oca -> 1 Şub)', () {
      final jan31 = epochDayOf(20260131);
      final feb1 = epochDayOf(20260201);
      expect(feb1 - jan31, 1);
    });

    test('yıl sınırını geçerken epoch tam 1 artar (31 Ara -> 1 Oca)', () {
      final dec31 = epochDayOf(20261231);
      final jan1 = epochDayOf(20270101);
      expect(jan1 - dec31, 1);
    });
  });
}
