import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../tema.dart';

/// Basınca küçülen sarmalayıcı (taslak `:active { scale }`).
class _Basilan extends StatefulWidget {
  const _Basilan({
    required this.child,
    required this.onTap,
    required this.olcek,
    required this.etiket,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double olcek;
  final String etiket;

  @override
  State<_Basilan> createState() => _BasilanState();
}

class _BasilanState extends State<_Basilan> {
  bool _basili = false;

  void _ayarla(bool b) {
    if (widget.onTap != null) setState(() => _basili = b);
  }

  @override
  Widget build(BuildContext context) {
    final azalt = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.etiket,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _ayarla(true),
        onTapUp: (_) => _ayarla(false),
        onTapCancel: () => _ayarla(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _basili ? widget.olcek : 1,
          duration: azalt ? Duration.zero : const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Oynat ↔ duraklat ikonu: taslaktaki iki yolun köşeleri arasında geçiş.
class _OynatDuraklat extends CustomPainter {
  _OynatDuraklat(this.t, this.renk);

  /// 0 oynat, 1 duraklat.
  final double t;
  final Color renk;

  static const _oynat1 = [(8.0, 5.0), (13.0, 7.9), (13.0, 16.1), (8.0, 19.0)];
  static const _oynat2 = [
    (13.0, 7.9),
    (19.0, 12.0),
    (19.0, 12.0),
    (13.0, 16.1),
  ];
  static const _durdur1 = [(6.5, 5.0), (10.5, 5.0), (10.5, 19.0), (6.5, 19.0)];
  static const _durdur2 = [
    (13.5, 5.0),
    (17.5, 5.0),
    (17.5, 19.0),
    (13.5, 19.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final boya = Paint()..color = renk;
    for (final (a, b) in [(_oynat1, _durdur1), (_oynat2, _durdur2)]) {
      final yol = Path();
      for (var i = 0; i < 4; i++) {
        final x = lerpDouble(a[i].$1, b[i].$1, t)!;
        final y = lerpDouble(a[i].$2, b[i].$2, t)!;
        i == 0 ? yol.moveTo(x, y) : yol.lineTo(x, y);
      }
      canvas.drawPath(yol..close(), boya);
    }
  }

  @override
  bool shouldRepaint(_OynatDuraklat old) => old.t != t || old.renk != renk;
}

/// 78 px faz renginde ana buton, 4 px beyaz halka (PLAN B2.5).
class AnaButon extends StatelessWidget {
  const AnaButon({
    super.key,
    required this.oynuyor,
    required this.renk,
    required this.etiket,
    required this.onTap,
  });

  final bool oynuyor;
  final Color renk;
  final String etiket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final azalt = MediaQuery.disableAnimationsOf(context);
    return _Basilan(
      onTap: onTap,
      olcek: 0.93,
      etiket: etiket,
      child: Container(
        key: const ValueKey('anaButon'),
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: renk,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Renk.hap, spreadRadius: 4)],
        ),
        alignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: oynuyor ? 1 : 0),
          duration: azalt ? Duration.zero : Sure.ikonDonusum,
          curve: Curves.ease,
          builder: (_, t, _) => CustomPaint(
            size: const Size.square(32),
            painter: _OynatDuraklat(t, Colors.white),
          ),
        ),
      ),
    );
  }
}

/// 54 px beyaz hap içinde küçük buton: "■ Bitir", "+1 dk".
class KucukButon extends StatelessWidget {
  const KucukButon({
    super.key,
    required this.ust,
    required this.alt,
    required this.etiket,
    required this.onTap,
  });

  final String ust;
  final String alt;
  final String etiket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final azalt = MediaQuery.disableAnimationsOf(context);
    return _Basilan(
      onTap: onTap,
      olcek: 0.92,
      etiket: etiket,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.3 : 1,
        duration: azalt ? Duration.zero : const Duration(milliseconds: 200),
        child: Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Renk.hap,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ust,
                style: Yazi.inter(
                  15,
                  700,
                  renk: Renk.hapYazi,
                ).copyWith(height: 1),
              ),
              const SizedBox(height: 2),
              Text(
                alt,
                style: Yazi.inter(
                  10,
                  500,
                  renk: Renk.hapYazi.withValues(alpha: 0.75),
                ).copyWith(height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Üst satırdaki 36 px yuvarlak hap düğme: Atla, Ayarlar.
class HapDugme extends StatelessWidget {
  const HapDugme({
    super.key,
    required this.child,
    required this.etiket,
    required this.onTap,
  });

  final Widget child;
  final String etiket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Basilan(
    onTap: onTap,
    olcek: 0.92,
    etiket: etiket,
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Renk.hapUst,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: IconTheme(
        data: const IconThemeData(color: Renk.hapYazi, size: 22),
        child: child,
      ),
    ),
  );
}

/// Atla ikonu (taslak `ATLA_SVG`).
class AtlaIkonu extends StatelessWidget {
  const AtlaIkonu({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size.square(22), painter: _AtlaBoyaci());
}

class _AtlaBoyaci extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final boya = Paint()..color = Renk.hapYazi;
    canvas
      ..drawPath(
        Path()
          ..moveTo(5, 5.5)
          ..lineTo(5, 18.5)
          ..lineTo(14.5, 12)
          ..close(),
        boya,
      )
      ..drawRect(const Rect.fromLTWH(16, 5.5, 2.5, 13), boya);
  }

  @override
  bool shouldRepaint(_AtlaBoyaci old) => false;
}

/// Yazı hapı: faz etiketi, "Bugün N".
class YaziHapi extends StatelessWidget {
  const YaziHapi(this.metin, {super.key, required this.stil});

  final String metin;
  final TextStyle stil;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: Renk.hapUst,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(metin, style: stil.copyWith(color: Renk.hapYazi)),
  );
}
