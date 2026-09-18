import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/tmdb_config.dart';
import 'ui/screens/missing_key_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: FilmAramaApp()));
}

class FilmAramaApp extends StatelessWidget {
  const FilmAramaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Film Arama',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Anahtar verilmeden çalıştırılmışsa hiç istek atmaya kalkmıyoruz.
      home: TmdbConfig.hasKey ? const SearchScreen() : const MissingKeyScreen(),
    );
  }
}
