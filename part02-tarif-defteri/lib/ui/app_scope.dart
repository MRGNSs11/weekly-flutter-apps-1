import 'package:flutter/widgets.dart';

import '../data/recipe_repository.dart';
import '../domain/app_settings.dart';

/// Depoya ve ayarlara her ekranın ulaşabilmesi için.
///
/// Riverpod/Provider eklemedim: paylaşılan şey iki nesne ve uygulama altı
/// ekran. `InheritedWidget` bu iş için yeterli, ek paket ve ek kavram
/// getirmiyor.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.settings,
    required super.child,
  });

  final RecipeRepository repository;
  final AppSettings settings;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope widget ağacında bulunamadı.');
    return scope!;
  }

  static RecipeRepository repositoryOf(BuildContext context) =>
      of(context).repository;

  static AppSettings settingsOf(BuildContext context) => of(context).settings;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.repository != repository || oldWidget.settings != settings;
}
