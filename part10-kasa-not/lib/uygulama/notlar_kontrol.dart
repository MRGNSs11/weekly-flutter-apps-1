import 'dart:async';

import 'package:flutter/foundation.dart';

import '../alan/arama.dart';
import '../alan/not.dart';
import '../veri/not_deposu.dart';
import 'kasa_kontrol.dart';

/// Not listesi + arama. Kilitli notlar yalnız kasa açıkken aranır;
/// kapalıyken aramada hiç görünmezler (başlıkları bile şifreli).
class NotlarKontrol extends ChangeNotifier {
  NotlarKontrol(this.depo, this.kasa) {
    _abonelik = depo.izle().listen((n) {
      _notlar = n;
      _yuklendi = true;
      kasa.notlarDegisti(n);
      notifyListeners();
    });
  }

  final NotDeposu depo;
  final KasaKontrol kasa;
  late final StreamSubscription<List<Not>> _abonelik;

  List<Not> _notlar = const [];
  List<Not> get tumu => _notlar;
  bool _yuklendi = false;
  bool get yuklendi => _yuklendi;

  String _sorgu = '';
  String get sorgu => _sorgu;
  set sorgu(String s) {
    _sorgu = s;
    notifyListeners();
  }

  int get kilitliSayisi => _notlar.where((n) => n.kilitli).length;

  /// Ekranda görünecekler: arama varsa eşleşenler.
  List<Not> get gorunen {
    if (_sorgu.trim().isEmpty) return _notlar;
    return _notlar.where((n) {
      final metin = n.kilitli ? kasa.cozulmus(n.id) : n.icerik;
      return metin != null && eslesir(metin, _sorgu);
    }).toList();
  }

  @override
  void dispose() {
    _abonelik.cancel();
    super.dispose();
  }
}
