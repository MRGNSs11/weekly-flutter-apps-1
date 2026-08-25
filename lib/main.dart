import 'package:flutter/material.dart';

import 'data/database.dart';
import 'data/habit_repository.dart';
import 'ui/screens/habit_list_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  final database = AppDatabase();
  final repository = HabitRepository(database);
  runApp(HabitTrackerApp(repository: repository));
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key, required this.repository});

  final HabitRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alışkanlık Takipçisi',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: HabitListScreen(repository: repository),
    );
  }
}
