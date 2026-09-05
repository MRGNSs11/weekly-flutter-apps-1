import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Defter sayfasına iliştirilmiş bir kart.
///
/// Gölge yerine 1 piksel kaymış bir kenar çizgisi kullanılıyor: Material'ın
/// bulanık gölgesi kağıt zemin üstünde kirli görünüyor, düz ofset ise
/// kartın kağıda değdiği hissini veriyor.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const radius = BorderRadius.all(Radius.circular(kCornerRadius));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(color: colors.rule),
        boxShadow: [BoxShadow(color: colors.rule, offset: const Offset(1, 1))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
