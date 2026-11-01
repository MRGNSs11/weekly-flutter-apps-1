import 'package:flutter/material.dart';

import '../../uygulama/tema_kontrol.dart';
import '../tema.dart';

/// Başlığın sağında: Sistem · Aydınlık · Karanlık.
class TemaDugmesi extends StatelessWidget {
  const TemaDugmesi({super.key, required this.tema});
  final TemaKontrol tema;

  static const _secenekler = [
    (ThemeMode.system, Icons.brightness_auto_rounded, 'Sistem'),
    (ThemeMode.light, Icons.light_mode_rounded, 'Aydınlık'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Karanlık'),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Renkler.of(context);
    final simdiki = _secenekler.firstWhere((s) => s.$1 == tema.mod);
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Tema',
      icon: Icon(simdiki.$2, color: r.metin),
      initialValue: tema.mod,
      onSelected: tema.sec,
      itemBuilder: (_) => [
        for (final (mod, ikon, ad) in _secenekler)
          PopupMenuItem(
            value: mod,
            child: Row(
              children: [
                Icon(ikon, size: 20, color: mod == tema.mod ? r.vurgu : null),
                const SizedBox(width: 12),
                Text(ad),
              ],
            ),
          ),
      ],
    );
  }
}
