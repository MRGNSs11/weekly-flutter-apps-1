import 'package:aliskanlik_takipcisi/domain/day_key.dart';
import 'package:aliskanlik_takipcisi/domain/streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = 20260825;
  int daysAgo(int n) => dayKeyOfEpoch(epochDayOf(today) - n);

  group('calculateStreak', () {
    test('boş set -> ikisi de sıfır', () {
      final r = calculateStreak({}, today);
      expect(r, const StreakResult(current: 0, longest: 0));
    });

    test('sadece bugün işaretli -> current ve longest 1', () {
      final r = calculateStreak({today}, today);
      expect(r, const StreakResult(current: 1, longest: 1));
    });

    test('sadece dün işaretli, bugün değil -> grace period ile current 1', () {
      final r = calculateStreak({daysAgo(1)}, today);
      expect(r, const StreakResult(current: 1, longest: 1));
    });

    test('sadece 2 gün önce işaretli -> ne bugün ne dün, current 0', () {
      final r = calculateStreak({daysAgo(2)}, today);
      expect(r.current, 0);
      expect(r.longest, 1);
    });

    test('bugüne kadar ardışık 5 gün -> current ve longest 5', () {
      final days = {for (var i = 0; i < 5; i++) daysAgo(i)};
      final r = calculateStreak(days, today);
      expect(r, const StreakResult(current: 5, longest: 5));
    });

    test(
      'bugün boş ama dünden geriye 4 gün ardışık -> grace ile current 4',
      () {
        final days = {for (var i = 1; i <= 4; i++) daysAgo(i)};
        final r = calculateStreak(days, today);
        expect(r.current, 4);
      },
    );

    test('kesintili seri: eski uzun seri + yeni kısa seri', () {
      final days = {
        for (var i = 15; i <= 20; i++) daysAgo(i), // 6 günlük eski seri
        daysAgo(1), today, // 2 günlük güncel seri
      };
      final r = calculateStreak(days, today);
      expect(r.current, 2);
      expect(r.longest, 6);
    });

    test("longest, current'tan büyük olabilir (seri geçmişte kırıldı)", () {
      final days = {
        for (var i = 6; i <= 10; i++) daysAgo(i), // 5 günlük eski seri
        today, // tek başına bugün, aradaki gün boş
      };
      final r = calculateStreak(days, today);
      expect(r.current, 1);
      expect(r.longest, 5);
    });

    test('ay sınırını aşan ardışık günler doğru sayılır (regresyon)', () {
      final days = {20260130, 20260131, 20260201, 20260202};
      final r = calculateStreak(days, 20260202);
      expect(r.current, 4);
      expect(r.longest, 4);
    });
  });
}
