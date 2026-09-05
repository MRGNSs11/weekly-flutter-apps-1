import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../domain/turkish_text.dart';
import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/paper_background.dart';

/// Tarif ekleme ve düzenleme.
///
/// Aynı ekran iki işi de görüyor; "yeni tarif" ile "tarifi düzelt" arasında
/// öğrenilecek ikinci bir arayüz olmasın.
class EditRecipeScreen extends StatefulWidget {
  const EditRecipeScreen({super.key, this.recipe});

  /// Boşsa yeni tarif eklenir.
  final Recipe? recipe;

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final List<TextEditingController> _ingredients;
  late final List<TextEditingController> _steps;
  int? _categoryId;

  bool get _isNew => widget.recipe == null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;

    _name = TextEditingController(text: recipe?.name ?? '');
    _note = TextEditingController(text: recipe?.note ?? '');
    _categoryId = recipe?.categoryId;

    // Boş tarifte bile bir satır açık gelsin; boş ekrana bakıp "nereye
    // yazacağım" diye düşünmek istemiyoruz.
    _ingredients = _controllersFor(recipe?.ingredients);
    _steps = _controllersFor(recipe?.steps);
  }

  static List<TextEditingController> _controllersFor(List<String>? values) {
    if (values == null || values.isEmpty) return [TextEditingController()];
    return values.map((v) => TextEditingController(text: v)).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    for (final c in [..._ingredients, ..._steps]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.repositoryOf(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Vazgeç',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isNew ? 'Yeni Tarif' : 'Tarifi Düzenle'),
      ),
      body: PaperBackground(
        showMargin: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _FieldLabel('Tarifin adı'),
            _TextBox(controller: _name, hintText: 'Örnek: Mercimek Çorbası'),
            const SizedBox(height: 22),

            _FieldLabel('Kategori'),
            StreamBuilder<List<Category>>(
              stream: repository.watchCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const <Category>[];
                return Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final category in categories)
                      _CategoryChip(
                        label: category.name,
                        selected: _categoryId == category.id,
                        onTap: () => setState(
                          () => _categoryId = _categoryId == category.id
                              ? null
                              : category.id,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),

            _FieldLabel('Malzemeler'),
            ..._buildLineFields(
              controllers: _ingredients,
              hintText: 'Örnek: 1 su bardağı un',
              addLabel: 'Malzeme ekle',
            ),
            const SizedBox(height: 22),

            _FieldLabel('Yapılışı'),
            ..._buildLineFields(
              controllers: _steps,
              hintText: 'Bu adımda ne yapılacak?',
              addLabel: 'Adım ekle',
              numbered: true,
            ),
            const SizedBox(height: 22),

            _FieldLabel('Not (isteğe bağlı)'),
            _TextBox(
              controller: _note,
              hintText: 'Püf noktası, kimin tarifi, ne zaman yapılır...',
              maxLines: 3,
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
      bottomNavigationBar: _SaveBar(onPressed: _save),
    );
  }

  List<Widget> _buildLineFields({
    required List<TextEditingController> controllers,
    required String hintText,
    required String addLabel,
    bool numbered = false,
  }) {
    return [
      for (var i = 0; i < controllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (numbered)
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              Expanded(
                child: _TextBox(controller: controllers[i], hintText: hintText),
              ),
              IconButton(
                tooltip: 'Bu satırı sil',
                onPressed: () => setState(() {
                  controllers.removeAt(i).dispose();
                  if (controllers.isEmpty) {
                    controllers.add(TextEditingController());
                  }
                }),
                icon: Icon(Icons.close, color: context.colors.inkSoft),
              ),
            ],
          ),
        ),
      _AddLineButton(
        label: addLabel,
        onTap: () => setState(() => controllers.add(TextEditingController())),
      ),
    ];
  }

  Future<void> _save() async {
    final repository = AppScope.repositoryOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = _name.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tarifin adını yazman gerekiyor.')),
      );
      return;
    }

    final ingredients = _lines(_ingredients);
    final steps = _lines(_steps);
    final note = _note.text.trim();

    if (_isNew) {
      await repository.insertRecipe(
        name: name,
        categoryId: _categoryId,
        ingredients: ingredients,
        steps: steps,
        note: note.isEmpty ? null : note,
      );
    } else {
      await repository.updateRecipe(
        id: widget.recipe!.id,
        name: name,
        categoryId: _categoryId,
        ingredients: ingredients,
        steps: steps,
        note: note.isEmpty ? null : note,
      );
    }

    navigator.pop();
  }

  static List<String> _lines(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

// ── Küçük parçalar ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        toUpperCaseTurkish(text),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(kCornerRadius)),
        border: Border.all(color: colors.rule, width: 2),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colors.inkSoft),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? colors.accent : colors.rule,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 15,
            color: selected ? colors.onAccent : colors.ink,
          ),
        ),
      ),
    );
  }
}

class _AddLineButton extends StatelessWidget {
  const _AddLineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(kCornerRadius)),
          border: Border.all(color: colors.rule, width: 2),
        ),
        child: Text(
          '+  $label',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onPressed});

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
            child: const Text('Kaydet'),
          ),
        ),
      ),
    );
  }
}
