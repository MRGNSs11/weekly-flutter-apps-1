import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/database.dart';
import '../../domain/turkish_text.dart';
import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/paper_background.dart';
import 'cooking_screen.dart';
import 'edit_recipe_screen.dart';

/// Tarif okuma ekranı.
///
/// Ekran açıkken telefon kendini kapatmaz: eller hamurluyken ekrana dokunup
/// uyandırmak gerekmesin.
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipeId});

  final int recipeId;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  /// İşaretlenen malzemeler bilerek kaydedilmiyor: bir sonraki pişirmede
  /// tarifin yarısı çizili açılsa kafa karıştırır.
  final _checked = <int>{};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.repositoryOf(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return StreamBuilder<Recipe?>(
      stream: repository.watchRecipe(widget.recipeId),
      builder: (context, snapshot) {
        final recipe = snapshot.data;
        if (recipe == null) {
          return Scaffold(appBar: AppBar(title: const Text('Tarif')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(recipe.name),
            actions: [
              IconButton(
                tooltip: recipe.isFavorite
                    ? 'Sık yaptıklarımdan çıkar'
                    : 'Sık yaptıklarıma ekle',
                onPressed: () =>
                    repository.setFavorite(recipe.id, !recipe.isFavorite),
                icon: Icon(
                  recipe.isFavorite ? Icons.star : Icons.star_border,
                  color: recipe.isFavorite ? colors.accent : colors.inkSoft,
                  size: 28,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Diğer işlemler',
                onSelected: (value) => switch (value) {
                  'duzenle' => _openEditor(recipe),
                  'sil' => _confirmDelete(recipe),
                  _ => null,
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
                  PopupMenuItem(value: 'sil', child: Text('Sil')),
                ],
              ),
            ],
          ),
          body: PaperBackground(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (recipe.ingredients.isEmpty && recipe.steps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Bu tarifin içi henüz boş.\n'
                      'Sağ üstteki menüden düzenleyebilirsin.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),

                if (recipe.ingredients.isNotEmpty) ...[
                  _Label('Malzemeler'),
                  for (var i = 0; i < recipe.ingredients.length; i++)
                    _IngredientRow(
                      text: recipe.ingredients[i],
                      checked: _checked.contains(i),
                      onTap: () => setState(() {
                        if (!_checked.remove(i)) _checked.add(i);
                      }),
                    ),
                  const SizedBox(height: 22),
                ],

                if (recipe.note != null && recipe.note!.isNotEmpty) ...[
                  _Label('Not'),
                  Text(recipe.note!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 22),
                ],

                if (recipe.steps.isNotEmpty) ...[
                  _Label('Yapılışı'),
                  for (var i = 0; i < recipe.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${i + 1}.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              recipe.steps[i],
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 28),
              ],
            ),
          ),
          bottomNavigationBar: recipe.steps.isEmpty
              ? null
              : _StartCookingBar(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CookingScreen(recipe: recipe),
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _openEditor(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditRecipeScreen(recipe: recipe)),
    );
  }

  /// Silme iki aşamalı: önce onay, sonra "geri al".
  ///
  /// Tek başına onay yetmiyor — yanlış düğmeye basmak kolay ve annemin
  /// defterinde bu tarifin yedeği yok.
  Future<void> _confirmDelete(Recipe recipe) async {
    final repository = AppScope.repositoryOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${recipe.name}" silinsin mi?'),
        content: const Text('Tarif defterden çıkarılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (approved != true) return;

    final removed = await repository.deleteRecipe(recipe.id);
    if (removed == null) return;

    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${removed.name}" silindi.'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () => repository.restoreRecipe(removed),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        toUpperCaseTurkish(text),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.text,
    required this.checked,
    required this.onTap,
  });

  final String text;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: checked ? colors.accent : Colors.transparent,
                borderRadius: const BorderRadius.all(
                  Radius.circular(kCornerRadius),
                ),
                border: Border.all(
                  color: checked ? colors.accent : colors.inkSoft,
                  width: 2,
                ),
              ),
              child: checked
                  ? Icon(Icons.check, size: 18, color: colors.onAccent)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: checked ? colors.inkSoft : colors.ink,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  decorationColor: colors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartCookingBar extends StatelessWidget {
  const _StartCookingBar({required this.onPressed});

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
          child: FilledButton(
            onPressed: onPressed,
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
            child: const Text('Pişirmeye Başla'),
          ),
        ),
      ),
    );
  }
}
