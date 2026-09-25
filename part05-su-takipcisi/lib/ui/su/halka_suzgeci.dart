import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'su_fizigi.dart';

/// Suya dokununca sahneyi halka halka büken GPU süzgeci (`shaders/halka.frag`).
///
/// Halka yokken süzgeç kapalı: shader her karede tüm ekranı işlemesin.
/// Cihaz shader süzgecini desteklemiyorsa (Impeller yok) sessizce kapalı
/// kalır; `SuBoyaci`nın çizdiği halka çizgileri yine görünür.
class HalkaSuzgeci extends StatefulWidget {
  const HalkaSuzgeci({
    super.key,
    required this.fizik,
    required this.kare,
    required this.child,
  });

  final SuFizigi fizik;
  final ValueListenable<int> kare;
  final Widget child;

  @override
  State<HalkaSuzgeci> createState() => _HalkaSuzgeciState();
}

class _HalkaSuzgeciState extends State<HalkaSuzgeci> {
  static Future<ui.FragmentProgram>? _yukleniyor;
  ui.FragmentShader? _shader;

  /// Süzgeç kapalıyken ağaç yapısı değişmesin diye verilen etkisiz süzgeç.
  static final _etkisiz = ui.ImageFilter.matrix(Matrix4.identity().storage);

  @override
  void initState() {
    super.initState();
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    _yukleniyor ??= ui.FragmentProgram.fromAsset('shaders/halka.frag');
    _yukleniyor!.then((p) {
      if (mounted) setState(() => _shader = p.fragmentShader());
    });
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.kare,
      child: widget.child,
      builder: (context, _, cocuk) {
        final shader = _shader;
        final f = widget.fizik;
        final halkalar = f.dokunmaHalkalari.toList();
        final aktif = shader != null && halkalar.isNotEmpty && f.genislik > 0;
        if (aktif) _uniformlar(shader, f, halkalar);
        return ImageFiltered(
          enabled: aktif,
          imageFilter: aktif ? ui.ImageFilter.shader(shader) : _etkisiz,
          child: cocuk,
        );
      },
    );
  }

  /// Sıra `halka.frag`taki uniform sırasıyla aynı. 0–1 `uBoyut`: motor doldurur.
  void _uniformlar(ui.FragmentShader s, SuFizigi f, List<Halka> halkalar) {
    final w = f.genislik;
    final h = f.yukseklik;
    s.setFloat(2, h / w);
    for (var i = 0; i < 4; i++) {
      final yuva = 3 + i * 4;
      if (i < halkalar.length) {
        final hk = halkalar[i];
        s
          ..setFloat(yuva, hk.x / w)
          ..setFloat(yuva + 1, hk.y / h)
          ..setFloat(yuva + 2, hk.r / w)
          ..setFloat(yuva + 3, hk.a);
      } else {
        s.setFloat(yuva + 3, 0); // boş yuva
      }
    }
  }
}
