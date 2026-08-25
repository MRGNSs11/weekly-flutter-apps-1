/// `DateTime` ile veritabanı arasındaki köprü.
///
/// Tarihler veritabanında `DateTime` değil `yyyymmdd` biçiminde bir `int`
/// (dayKey) olarak tutulur. Nedeni: saat dilimi ve yaz saati kaymalarının
/// gün karşılaştırmalarını bozmasını baştan engellemek (bkz. PLAN.md § Veri).
library;

int dayKeyOf(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

DateTime dateOfDayKey(int dayKey) {
  final year = dayKey ~/ 10000;
  final month = (dayKey ~/ 100) % 100;
  final day = dayKey % 100;
  return DateTime.utc(year, month, day);
}

int todayDayKey() => dayKeyOf(DateTime.now());

/// 1970-01-01'den bu yana geçen gün sayısı. Ardışıklık (streak) ve hafta
/// hizalama hesapları bu doğrusal sayı üzerinden yapılır — dayKey'in kendisi
/// (yyyymmdd) ay/yıl sınırlarında +1 artmadığı için doğrudan kullanılamaz.
int epochDayOf(int dayKey) =>
    dateOfDayKey(dayKey).difference(DateTime.utc(1970, 1, 1)).inDays;

int dayKeyOfEpoch(int epochDay) =>
    dayKeyOf(DateTime.utc(1970, 1, 1).add(Duration(days: epochDay)));
