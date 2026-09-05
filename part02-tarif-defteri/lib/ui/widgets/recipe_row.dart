import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../theme/app_theme.dart';
import 'paper_card.dart';

/// Listelerdeki tarif satırı: adı, kısa özeti ve favori yıldızı.
class RecipeRow extends StatelessWidget {
  const RecipeRow({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onToggleFavorite,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(_summary(recipe), style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (onToggleFavorite != null)
            IconButton(
              onPressed: onToggleFavorite,
              icon: Icon(
                recipe.isFavorite ? Icons.star : Icons.star_border,
                color: recipe.isFavorite ? colors.accent : colors.rule,
                size: 28,
              ),
              tooltip: recipe.isFavorite
                  ? 'Sık yaptıklarımdan çıkar'
                  : 'Sık yaptıklarıma ekle',
            ),
        ],
      ),
    );
  }

  static String _summary(Recipe recipe) {
    final parts = <String>[
      if (recipe.ingredients.isNotEmpty) '${recipe.ingredients.length} malzeme',
      if (recipe.steps.isNotEmpty) '${recipe.steps.length} adım',
    ];
    return parts.isEmpty ? 'Henüz doldurulmadı' : parts.join(' · ');
  }
}
