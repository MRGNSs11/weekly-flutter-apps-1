import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/paper_background.dart';
import '../widgets/paper_card.dart';

/// Kategori yönetimi: ekleme, yeniden adlandırma, silme, sıralama.
///
/// Kategoriler kodda sabit değil — annem "Börekler" isterse eklesin,
/// "Zeytinyağlı" hiç kullanmıyorsa silsin diye.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.repositoryOf(context);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Kategoriler')),
      body: PaperBackground(
        showMargin: false,
        child: StreamBuilder<List<Category>>(
          stream: repository.watchCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? const <Category>[];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sıralamayı değiştirmek için basılı tutup sürükle.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    itemCount: categories.length,
                    // onReorder değil: onReorderItem, çıkarılan öğeye göre
                    // newIndex'i kendi düzeltiyor.
                    onReorderItem: (oldIndex, newIndex) {
                      final ordered = [...categories];
                      ordered.insert(newIndex, ordered.removeAt(oldIndex));
                      repository.reorderCategories(
                        ordered.map((c) => c.id).toList(),
                      );
                    },
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        key: ValueKey(category.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PaperCard(
                          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Adını değiştir',
                                icon: Icon(Icons.edit, color: colors.inkSoft),
                                onPressed: () => _rename(context, category),
                              ),
                              IconButton(
                                tooltip: 'Sil',
                                icon: Icon(Icons.delete, color: colors.inkSoft),
                                onPressed: () => _delete(context, category),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: colors.inkSoft,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        icon: const Icon(Icons.add),
        label: const Text('Kategori ekle'),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final repository = AppScope.repositoryOf(context);
    final name = await _askName(context, title: 'Yeni kategori');
    if (name != null && name.isNotEmpty) {
      await repository.addCategory(name);
    }
  }

  Future<void> _rename(BuildContext context, Category category) async {
    final repository = AppScope.repositoryOf(context);
    final name = await _askName(
      context,
      title: 'Kategorinin adı',
      initialValue: category.name,
    );
    if (name != null && name.isNotEmpty) {
      await repository.renameCategory(category.id, name);
    }
  }

  /// Kategori silinince içindeki tarifler silinmez; bunu diyalogda açıkça
  /// yazıyoruz, yoksa "tariflerim gitti mi?" endişesi olur.
  Future<void> _delete(BuildContext context, Category category) async {
    final repository = AppScope.repositoryOf(context);

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${category.name}" silinsin mi?'),
        content: const Text(
          'Kategori silinir, içindeki tarifler silinmez. '
          'Onları ana ekranda "Kategorisiz" başlığı altında bulabilirsin.',
        ),
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

    if (approved == true) {
      await repository.deleteCategory(category.id);
    }
  }

  Future<String?> _askName(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Örnek: Börekler'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
