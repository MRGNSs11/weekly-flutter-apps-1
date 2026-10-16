import 'package:flutter/material.dart';

import 'kil_yuzey.dart';
import 'tema.dart';

/// 12480 → "12.480".
String binlik(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// Kabarık kil düğme. Basılınca içe çöker (taslak `button:active`).
class KilDugme extends StatefulWidget {
  const KilDugme({
    super.key,
    required this.yazi,
    required this.onTap,
    this.ikon,
    this.vurgulu = false,
    this.genis = true,
  });

  final String yazi;

  /// Yazının önündeki simge. "↶" Nunito'da yok, bu yüzden yazı değil simge.
  final IconData? ikon;

  /// null ise düğme pasif: yazı soluk, basılmaz.
  final VoidCallback? onTap;
  final bool vurgulu;
  final bool genis;

  @override
  State<KilDugme> createState() => _KilDugmeState();
}

class _KilDugmeState extends State<KilDugme> {
  bool _basili = false;

  void _bas(bool b) {
    if (widget.onTap != null && b != _basili) setState(() => _basili = b);
  }

  @override
  Widget build(BuildContext context) {
    final etkin = widget.onTap != null;
    final renk = !etkin
        ? Renk.soluk.withValues(alpha: 0.6)
        : (widget.vurgulu ? Renk.vurgu : Renk.yazi);
    return Semantics(
      button: true,
      enabled: etkin,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _bas(true),
        onTapUp: (_) => _bas(false),
        onTapCancel: () => _bas(false),
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _basili ? -4 : 5),
          duration: const Duration(milliseconds: 90),
          builder: (context, yuk, child) =>
              KilYuzey(yukseklik: yuk, kose: 18, child: child),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 14,
              horizontal: widget.genis ? 8 : 18,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.ikon != null) ...[
                  Icon(widget.ikon, size: 19, color: renk),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    widget.yazi,
                    textAlign: TextAlign.center,
                    style: Yazi.dugme.copyWith(color: renk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Üstteki kabarık skor kutusu: küçük etiket + büyük sayı.
class SkorKutusu extends StatelessWidget {
  const SkorKutusu({
    super.key,
    required this.etiket,
    required this.deger,
    this.degerAnahtari,
  });

  final String etiket;
  final int deger;
  final Key? degerAnahtari;

  @override
  Widget build(BuildContext context) => KilYuzey(
    yukseklik: 6,
    kose: 18,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(etiket, style: Yazi.etiket),
          Text(binlik(deger), key: degerAnahtari, style: Yazi.skor),
        ],
      ),
    ),
  );
}
