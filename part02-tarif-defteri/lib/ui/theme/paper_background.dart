import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Uygulamanın imza öğesi: çizgili defter kağıdı ve sol kenarda kırmızı marj.
///
/// Çizgiler dekorasyon değil, hizalama ızgarasıdır — içerik satır aralığıyla
/// aynı ritimde durur, böylece ekran gerçekten bir defter sayfası gibi okunur.
class PaperBackground extends StatelessWidget {
  const PaperBackground({
    super.key,
    required this.child,
    this.showMargin = true,
    this.padding = const EdgeInsets.fromLTRB(14, 16, 18, 16),
  });

  final Widget child;

  /// Kırmızı marj çizgisi. Form ve ayarlar gibi "defter sayfası olmayan"
  /// ekranlarda kapatılır.
  final bool showMargin;

  /// İçeriğin marj çizgisinden sonraki iç boşluğu.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return CustomPaint(
      painter: _PaperPainter(
        lineColor: colors.paperLine,
        marginColor: showMargin
            ? colors.accent.withValues(alpha: 0.35)
            : Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: showMargin ? kMarginInset : 0),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter({required this.lineColor, required this.marginColor});

  final Color lineColor;
  final Color marginColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    // Yatay çizgiler, ilk çizgi biraz aşağıdan başlar (üst boşluk).
    for (double y = kRuleSpacing; y < size.height; y += kRuleSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }

    if (marginColor.a == 0) return;

    final margin = Paint()
      ..color = marginColor
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(kMarginInset, 0),
      Offset(kMarginInset, size.height),
      margin,
    );
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.lineColor != lineColor || old.marginColor != marginColor;
}
