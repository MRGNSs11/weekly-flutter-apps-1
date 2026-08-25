import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/habit_repository.dart';
import '../theme/app_theme.dart';
import '../turkish_date.dart';
import '../widgets/habit_row.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';

class HabitListScreen extends StatelessWidget {
  const HabitListScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Text(
                turkishUpperCase(formatHeaderDate(DateTime.now())),
                style: AppTextStyles.dateHeader,
              ),
              const SizedBox(height: 5),
              Text('Alışkanlıklar', style: AppTextStyles.h1),
              const SizedBox(height: 18),
              Expanded(
                child: StreamBuilder<List<Habit>>(
                  stream: repository.watchHabits(),
                  builder: (context, snapshot) {
                    final habits = snapshot.data;
                    if (habits == null) {
                      return const SizedBox.shrink();
                    }
                    if (habits.isEmpty) {
                      return const _EmptyState();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: habits.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.rowGap),
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return HabitRow(
                          habit: habit,
                          repository: repository,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HabitDetailScreen(
                                initialHabit: habit,
                                repository: repository,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _AddFab(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEditHabitScreen(repository: repository),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Henüz alışkanlık yok',
              style: AppTextStyles.h1.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 8),
            Text(
              'Sağ alttaki + ile ilk alışkanlığını ekle',
              style: AppTextStyles.rowSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Text(
            '+',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w300,
              color: AppColors.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}
