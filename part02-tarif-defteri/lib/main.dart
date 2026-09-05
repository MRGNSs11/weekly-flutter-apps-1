import 'package:flutter/material.dart';

import 'ui/theme/app_theme.dart';
import 'ui/theme/paper_background.dart';

void main() {
  runApp(const TarifDefteriApp());
}

class TarifDefteriApp extends StatelessWidget {
  const TarifDefteriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarif Defteri',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const _PlaceholderScreen(),
    );
  }
}

/// Aşama 0 iskeleti — Aşama 3'te ana ekranla değiştirilecek.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarif Defteri')),
      body: PaperBackground(
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            'Defter kuruldu.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
