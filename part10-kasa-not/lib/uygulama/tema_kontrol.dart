import 'package:flutter/material.dart';

import '../veri/veritabani.dart';

/// Sistem · Aydınlık · Karanlık. Varsayılan sistem; seçim veritabanında kalır.
class TemaKontrol extends ChangeNotifier {
  TemaKontrol(this._db);

  final Veritabani _db;
  static const _anahtar = 'tema';

  ThemeMode _mod = ThemeMode.system;
  ThemeMode get mod => _mod;

  Future<void> yukle() async {
    final kayit = await _db.ayarOku(_anahtar);
    _mod = ThemeMode.values.firstWhere(
      (m) => m.name == kayit,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> sec(ThemeMode m) async {
    _mod = m;
    notifyListeners();
    await _db.ayarYaz(_anahtar, m.name);
  }
}
