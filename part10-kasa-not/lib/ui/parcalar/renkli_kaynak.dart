import 'package:flutter/material.dart';

/// Kaynak kutusunda Markdown işaretlerini (`#`, `- [ ]`, `**`, `*`, `` ` ``)
/// vurgu rengiyle boyar; metnin kendisi değişmez.
class RenkliKaynak extends TextEditingController {
  RenkliKaynak({super.text, required this.isaretRengi});

  Color isaretRengi;

  static final _isaret = RegExp(
    r'^#{1,6}(?=\s)|^\s*[-*+]\s+\[[ xX]\]|^\s*[-*+](?=\s)|^\s*\d+\.(?=\s)|^```.*$|\*\*|__|\*|`',
    multiLine: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Klavye kelime oluştururken (altı çizili bölge) bölmeyelim.
    if (withComposing &&
        value.composing.isValid &&
        !value.composing.isCollapsed) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final parcalar = <TextSpan>[];
    var son = 0;
    for (final m in _isaret.allMatches(text)) {
      if (m.start > son) {
        parcalar.add(TextSpan(text: text.substring(son, m.start)));
      }
      parcalar.add(
        TextSpan(
          text: m[0],
          style: TextStyle(color: isaretRengi),
        ),
      );
      son = m.end;
    }
    if (son < text.length) parcalar.add(TextSpan(text: text.substring(son)));
    return TextSpan(style: style, children: parcalar);
  }
}
