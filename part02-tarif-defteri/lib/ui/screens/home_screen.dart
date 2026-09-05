import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/recipe_repository.dart';
import '../../domain/turkish_text.dart';
import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/paper_background.dart';
import '../widgets/paper_card.dart';
import '../widgets/recipe_row.dart';
import '../widgets/search_field.dart';
import 'category_screen.dart';
import 'edit_recipe_screen.dart';
import 'recipe_screen.dart';
import 'settings_screen.dart';

/// Ana ekran: arama, sık yapılanlar, kategoriler.
///
/// Arama kutusuna bir şey yazıldığı anda kategoriler yerini sonuç listesine
/// bırakır. İki ayrı ekran yapmadım; annemin "aramadan çık" diye ayrı bir
/// hareket öğrenmesi gerekmesin.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarif Defteri'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings, size: 26),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: PaperBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SearchField(
              controller: _searchController,
              hintText: 'Tarif ara',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 18),
            if (_query.trim().isEmpty)
              ..._browseSections(repository)
            else
              _searchResults(repository),
          ],
        ),
      ),
      bottomNavigationBar: _AddRecipeBar(onPressed: () => _openEditor(context)),
    );
  }

  // ── Arama sonuçları ────────────────────────────────────────────────────

  Widget _searchResults(RecipeRepository repository) {
    return StreamBuilder<List<Recipe>>(
      stream: repository.watchSearch(_query),
      builder: (context, snapshot) {
        final results = snapshot.data ?? const <Recipe>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (results.isEmpty) {
          return _EmptyNote(
            '"${_query.trim()}" için tarif bulunamadı.\n'
            'Tarifin adını ya da içindeki bir malzemeyi yazabilirsin.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('${results.length} tarif bulundu'),
            for (final recipe in results) ...[
              RecipeRow(
                recipe: recipe,
                onTap: () => _openRecipe(context, recipe.id),
                onToggleFavorite: () =>
                    repository.setFavorite(recipe.id, !recipe.isFavorite),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  // ── Gezinme bölümleri ──────────────────────────────────────────────────

  List<Widget> _browseSections(RecipeRepository repository) {
    return [
      StreamBuilder<List<Recipe>>(
        stream: repository.watchFavorites(),
        builder: (context, snapshot) {
          final favorites = (snapshot.data ?? const <Recipe>[])
              .take(3)
              .toList();
          if (favorites.isEmpty) return const SizedBox.shrink();

          // Şeridin yüksekliği sabit veriliyor. Serbest bırakıldığında Row,
          // dikey listenin içinde ölçüsüz kalıp kartları hiç çizmiyor.
          final scale = MediaQuery.textScalerOf(context).scale(1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Sık yaptıkların'),
              SizedBox(
                height: 92 * scale,
                child: Row(
                  children: [
                    for (var i = 0; i < favorites.length; i++) ...[
                      if (i > 0) const SizedBox(width: 9),
                      Expanded(
                        child: _FavoriteCard(
                          recipe: favorites[i],
                          onTap: () => _openRecipe(context, favorites[i].id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
      StreamBuilder<List<CategorySummary>>(
        stream: repository.watchCategorySummaries(),
        builder: (context, snapshot) {
          final summaries = snapshot.data ?? const <CategorySummary>[];
          if (summaries.isEmpty) return const SizedBox.shrink();

          // Yazı boyutu büyüdükçe kart da büyümeli, yoksa kategori adı taşar.
          final scale = MediaQuery.textScalerOf(context).scale(1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Kategoriler'),
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 86 * scale,
                ),
                itemCount: summaries.length,
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  return _CategoryCard(
                    title: summary.category.name,
                    subtitle: '${summary.recipeCount} tarif',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CategoryScreen(category: summary.category),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      // Kategorisi silinmiş tarifler kaybolmasın diye ayrı bir giriş.
      StreamBuilder<List<Recipe>>(
        stream: repository.watchUncategorizedRecipes(),
        builder: (context, snapshot) {
          final loose = snapshot.data ?? const <Recipe>[];
          if (loose.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _CategoryCard(
              title: 'Kategorisiz',
              subtitle: '${loose.length} tarif',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoryScreen(category: null),
                ),
              ),
            ),
          );
        },
      ),
      StreamBuilder<List<CategorySummary>>(
        stream: repository.watchCategorySummaries(),
        builder: (context, snapshot) {
          final hasCategories = (snapshot.data ?? const []).isNotEmpty;
          if (hasCategories) return const SizedBox.shrink();
          return const _EmptyNote(
            'Defter henüz boş.\n'
            'Aşağıdaki düğmeyle ilk tarifi ekleyebilirsin.',
          );
        },
      ),
      const SizedBox(height: 24),
    ];
  }

  void _openRecipe(BuildContext context, int id) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => RecipeScreen(recipeId: id)));
  }

  void _openEditor(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditRecipeScreen()));
  }
}

// ── Küçük parçalar ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        toUpperCaseTurkish(text),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 18, color: colors.accent),
          const SizedBox(height: 4),
          // Yıldızlar üst hizada kalsın diye metin kalan alanı doldurup
          // kendi içinde ortalanıyor; yoksa iki satırlık tarif adı yıldızı
          // aşağı itiyor ve şerit dağınık görünüyor.
          Expanded(
            child: Center(
              child: Text(
                recipe.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PaperCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

/// Ekranın altında sabit duran "Tarif Ekle" düğmesi.
class _AddRecipeBar extends StatelessWidget {
  const _AddRecipeBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: const Text('Tarif Ekle'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              minimumSize: const Size.fromHeight(56),
              textStyle: const TextStyle(
                fontFamily: kBodyFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(kCornerRadius)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
