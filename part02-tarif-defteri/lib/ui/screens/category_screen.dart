import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../domain/turkish_text.dart';
import '../app_scope.dart';
import '../theme/paper_background.dart';
import '../widgets/recipe_row.dart';
import '../widgets/search_field.dart';
import 'recipe_screen.dart';

/// Bir kategorinin içindeki tarifler.
///
/// [category] boş verilirse kategorisiz tarifler listelenir — kategori
/// silindiğinde tariflerin kaybolmuş görünmemesi için.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final Category? category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.repositoryOf(context);
    final category = widget.category;
    final title = category?.name ?? 'Kategorisiz';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PaperBackground(
        showMargin: false,
        child: StreamBuilder<List<Recipe>>(
          stream: category == null
              ? repository.watchUncategorizedRecipes()
              : repository.watchRecipesInCategory(category.id),
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <Recipe>[];

            // Kategori içi arama veritabanına gitmeden yapılıyor: liste zaten
            // bellekte ve en fazla birkaç düzine tarif var.
            final visible = _query.trim().isEmpty
                ? all
                : all.where((r) => matchesQuery(r.searchText, _query)).toList();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                if (all.length > 5) ...[
                  SearchField(
                    controller: _searchController,
                    hintText: '$title içinde ara',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                ],
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      all.isEmpty
                          ? 'Bu kategoride henüz tarif yok.'
                          : '"${_query.trim()}" için tarif bulunamadı.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                for (final recipe in visible) ...[
                  RecipeRow(
                    recipe: recipe,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecipeScreen(recipeId: recipe.id),
                      ),
                    ),
                    onToggleFavorite: () =>
                        repository.setFavorite(recipe.id, !recipe.isFavorite),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
