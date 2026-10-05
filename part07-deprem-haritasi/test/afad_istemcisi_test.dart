import 'dart:async';
import 'dart:convert';

import 'package:deprem_haritasi/deprem/afad_istemcisi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final simdi = DateTime.utc(2026, 10, 5, 7, 30);

Map<String, Object?> k(String tarih, String yer, [String m = '2.0']) => {
  'latitude': '38.1',
  'longitude': '35.2',
  'magnitude': m,
  'depth': '7',
  'date': tarih,
  'location': yer,
  'country': null,
};

http.Response json(Object govde, [int durum = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(govde)), durum);

void main() {
  test('URL: yalnız start ve end, UTC, Z ve milisaniye yok, limit yok', () {
    final u = AfadIstemcisi.url(simdi.subtract(const Duration(days: 7)), simdi);
    expect(u.host, 'servisnet.afad.gov.tr');
    expect(u.queryParameters, {
      'start': '2026-09-28T07:30:00',
      'end': '2026-10-05T07:30:00',
    });
  });

  test('yerel saatle verilen tarih UTC\'ye çevrilir', () {
    final yerel = DateTime.utc(2026, 10, 5, 7, 30).toLocal();
    expect(
      AfadIstemcisi.url(yerel, yerel).queryParameters['end'],
      '2026-10-05T07:30:00',
    );
  });

  test('istek son 7 güne atılır', () async {
    late Uri istenen;
    final a = AfadIstemcisi(
      istemci: MockClient((r) async {
        istenen = r.url;
        return json([]);
      }),
    );
    await a.getir(simdi: simdi);
    expect(istenen.queryParameters['start'], '2026-09-28T07:30:00');
  });

  test('sonuç eskiden yeniye sıralı, bozuk kayıt atlanır', () async {
    final a = AfadIstemcisi(
      istemci: MockClient(
        (_) async => json([
          k('2026-10-05T06:00:00', 'Üç'),
          {'latitude': 'bozuk'},
          k('2026-10-03T06:00:00', 'Bir'),
          'metin',
          k('2026-10-04T06:00:00', 'İki'),
        ]),
      ),
    );
    final l = await a.getir(simdi: simdi);
    expect(l.map((e) => e.yer), ['Bir', 'İki', 'Üç']);
  });

  test('Türkçe karakterler bozulmaz (gövde UTF-8 okunur)', () async {
    final a = AfadIstemcisi(
      istemci: MockClient(
        (_) async => json([k('2026-10-05T06:00:00', 'Sındırgı (Balıkesir)')]),
      ),
    );
    expect((await a.getir(simdi: simdi)).single.yer, 'Sındırgı (Balıkesir)');
  });

  test('200 dışı durum hata', () async {
    final a = AfadIstemcisi(istemci: MockClient((_) async => json([], 500)));
    expect(a.getir(simdi: simdi), throwsA(isA<AfadHatasi>()));
  });

  test('liste olmayan yanıt hata', () async {
    final a = AfadIstemcisi(istemci: MockClient((_) async => json({'x': 1})));
    expect(a.getir(simdi: simdi), throwsA(isA<AfadHatasi>()));
  });

  test('JSON olmayan yanıt hata', () async {
    final a = AfadIstemcisi(
      istemci: MockClient((_) async => http.Response('<html>', 200)),
    );
    expect(a.getir(simdi: simdi), throwsA(isA<AfadHatasi>()));
  });

  test('bağlantı hatası AfadHatasi olur', () async {
    final a = AfadIstemcisi(
      istemci: MockClient((_) async => throw http.ClientException('ağ yok')),
    );
    expect(a.getir(simdi: simdi), throwsA(isA<AfadHatasi>()));
  });

  test('zaman aşımı AfadHatasi olur', () async {
    final a = AfadIstemcisi(
      zamanAsimi: const Duration(milliseconds: 20),
      istemci: MockClient((_) => Completer<http.Response>().future),
    );
    expect(a.getir(simdi: simdi), throwsA(isA<AfadHatasi>()));
  });
}
