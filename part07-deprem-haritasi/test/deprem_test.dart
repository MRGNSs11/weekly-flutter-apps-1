import 'package:deprem_haritasi/deprem/deprem.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> kayit({
  Object? lat = '37.742',
  Object? lon = '36.101',
  Object? mag = '5.2',
  Object? depth = '7',
  Object? date = '2026-10-04T11:43:23',
  Object? location = 'Saimbeyli (Adana)',
  Object? country = 'Türkiye',
}) => {
  'latitude': lat,
  'longitude': lon,
  'magnitude': mag,
  'depth': depth,
  'date': date,
  'location': location,
  'country': country,
};

void main() {
  test('geçerli kayıt okunur, sayılar metinden çevrilir', () {
    final d = Deprem.fromAfad(kayit())!;
    expect(d.enlem, 37.742);
    expect(d.boylam, 36.101);
    expect(d.buyukluk, 5.2);
    expect(d.derinlikKm, 7);
    expect(d.yer, 'Saimbeyli (Adana)');
  });

  test('tarih UTC okunur (AFAD Z eki koymuyor)', () {
    final d = Deprem.fromAfad(kayit())!;
    expect(d.zaman.isUtc, isTrue);
    expect(d.zaman, DateTime.utc(2026, 10, 4, 11, 43, 23));
  });

  test('Z eki zaten varsa ikinci kez eklenmez', () {
    final d = Deprem.fromAfad(kayit(date: '2026-10-04T11:43:23Z'))!;
    expect(d.zaman, DateTime.utc(2026, 10, 4, 11, 43, 23));
  });

  test('sayı olarak gelen değerler de okunur', () {
    final d = Deprem.fromAfad(kayit(lat: 38.5, mag: 3))!;
    expect(d.enlem, 38.5);
    expect(d.buyukluk, 3);
  });

  test('bozuk kayıt null döner', () {
    expect(Deprem.fromAfad(kayit(lat: 'abc')), isNull);
    expect(Deprem.fromAfad(kayit(mag: null)), isNull);
    expect(Deprem.fromAfad(kayit(lat: '123')), isNull);
    expect(Deprem.fromAfad(kayit(date: 'dün')), isNull);
    expect(Deprem.fromAfad(kayit(date: null)), isNull);
  });

  test('ülke boş gelirse sorun olmaz, derinlik yoksa 0', () {
    final d = Deprem.fromAfad(kayit(country: null, depth: null))!;
    expect(d.derinlikKm, 0);
  });

  test('yer adı yoksa yedek metin', () {
    expect(Deprem.fromAfad(kayit(location: ' '))!.yer, 'Bilinmeyen yer');
  });

  test('kisaYer deniz depreminde köşeli parantezden sonrasını atar', () {
    final d = Deprem.fromAfad(
      kayit(location: 'Ege Denizi - [13.24 km] Dikili (İzmir)'),
    )!;
    expect(d.kisaYer, 'Ege Denizi');
  });

  test('kisaYer normal adı değiştirmez', () {
    expect(Deprem.fromAfad(kayit())!.kisaYer, 'Saimbeyli (Adana)');
  });
}
