import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Arama kutusu.
///
/// Kendi kenarlığını çiziyor çünkü Material'ın varsayılan alanı kağıt zeminde
/// yüzer gibi duruyor; burada kutu, defterin üstüne çizilmiş bir çerçeve gibi
/// görünmeli.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasText = controller.text.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(kCornerRadius)),
        border: Border.all(color: colors.rule, width: 2),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colors.inkSoft),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          prefixIcon: Icon(Icons.search, color: colors.inkSoft),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(Icons.close, color: colors.inkSoft),
                  tooltip: 'Aramayı temizle',
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}
