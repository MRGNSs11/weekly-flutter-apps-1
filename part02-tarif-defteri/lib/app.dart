import 'package:flutter/material.dart';

import 'data/database.dart';
import 'data/recipe_repository.dart';
import 'data/seed_loader.dart';
import 'domain/app_settings.dart';
import 'ui/app_scope.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

class TarifDefteriApp extends StatefulWidget {
  const TarifDefteriApp({super.key});

  @override
  State<TarifDefteriApp> createState() => _TarifDefteriAppState();
}

class _TarifDefteriAppState extends State<TarifDefteriApp> {
  late final AppDatabase _database;
  late final RecipeRepository _repository;

  /// İlk açılışta tarifler yüklenene kadar ana ekran gösterilmez; yoksa
  /// annem bir anlığına "hiç tarif yok" ekranını görür.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _repository = RecipeRepository(_database);
    _prepare();
  }

  Future<void> _prepare() async {
    await _repository.seedIfEmpty(await loadSeedData());
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: _repository.watchPreferences(),
      builder: (context, snapshot) {
        final settings = AppSettings.fromPreferences(snapshot.data ?? const {});

        return AppScope(
          repository: _repository,
          settings: settings,
          child: MaterialApp(
            title: 'Tarif Defteri',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: settings.themeMode,
            // Yazı boyutu ayarı bütün uygulamayı birden büyütür; her ekranda
            // ayrı ayrı punto hesabı yapılmaz.
            // Telefonun kendi yazı boyutu ayarı burada bilerek göz ardı
            // edilir: annemin telefonunda sistem yazısı küçük, ama tarif
            // okurken büyük olmalı. Uygulama kendi ayarını kullanır.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(settings.textScale)),
              child: child!,
            ),
            home: _ready ? const HomeScreen() : const _OpeningScreen(),
          ),
        );
      },
    );
  }
}

/// Tarifler yüklenirken görünen kısa ara ekran.
class _OpeningScreen extends StatelessWidget {
  const _OpeningScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Tarif Defteri',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
