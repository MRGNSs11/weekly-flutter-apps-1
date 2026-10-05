import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'deprem.dart';

/// AFAD'a ulaşılamadığında ya da yanıt beklenmedik geldiğinde.
class AfadHatasi implements Exception {
  const AfadHatasi(this.mesaj);
  final String mesaj;
  @override
  String toString() => 'AfadHatasi: $mesaj';
}

/// AFAD'ın açık deprem uç noktası. Anahtar istemiyor.
class AfadIstemcisi {
  AfadIstemcisi({
    http.Client? istemci,
    this.zamanAsimi = const Duration(seconds: 15),
  }) : _istemci = istemci ?? http.Client();

  final http.Client _istemci;
  final Duration zamanAsimi;

  /// Eski adres (`deprem.afad.gov.tr/apiv2`) buraya yönlendiriyor.
  static const adres =
      'https://servisnet.afad.gov.tr/apigateway/deprem/apiv2/event/filter';

  /// Yalnız `start` ve `end`. `limit` BİLEREK yok: AFAD onu sıralamadan önce
  /// uyguluyor, "en yeni 50" isteyince aralığın başındaki 50 geliyor.
  /// Aralığın tamamı çekilip sıralama burada yapılıyor.
  static Uri url(DateTime bas, DateTime son) => Uri.parse(
    adres,
  ).replace(queryParameters: {'start': _bicim(bas), 'end': _bicim(son)});

  /// AFAD UTC bekliyor, `Z` ve milisaniye olmadan: 2026-10-05T07:30:00
  static String _bicim(DateTime z) =>
      z.toUtc().toIso8601String().substring(0, 19);

  /// Son [aralik] içindeki depremler, eskiden yeniye sıralı.
  Future<List<Deprem>> getir({
    required DateTime simdi,
    Duration aralik = const Duration(days: 7),
  }) async {
    final http.Response yanit;
    try {
      yanit = await _istemci
          .get(url(simdi.subtract(aralik), simdi))
          .timeout(zamanAsimi);
    } on TimeoutException {
      throw const AfadHatasi('AFAD yanıt vermedi');
    } on Exception {
      throw const AfadHatasi('Bağlantı yok');
    }
    if (yanit.statusCode != 200) {
      throw AfadHatasi('AFAD hata döndü (${yanit.statusCode})');
    }
    final Object? govde;
    try {
      // Gövde UTF-8 ama başlıkta karakter seti yazmıyor; `yanit.body`
      // Latin-1 sanıp "Türkiye"yi bozardı.
      govde = jsonDecode(utf8.decode(yanit.bodyBytes));
    } on FormatException {
      throw const AfadHatasi('AFAD yanıtı okunamadı');
    }
    if (govde is! List) throw const AfadHatasi('AFAD yanıtı okunamadı');
    return govde
        .whereType<Map<String, dynamic>>()
        .map(Deprem.fromAfad)
        .whereType<Deprem>()
        .toList()
      ..sort((a, b) => a.ms.compareTo(b.ms));
  }

  void kapat() => _istemci.close();
}
