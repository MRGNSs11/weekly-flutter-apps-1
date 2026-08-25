import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/habit_repository.dart';
import '../../domain/day_key.dart';
import '../../domain/streak.dart';
import '../theme/app_theme.dart';
import '../turkish_date.dart';
import '../widgets/heatmap_view.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({
    super.key,
    required this.initialHabit,
    required this.repository,
  });

  final Habit initialHabit;
  final HabitRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Habit?>(
      stream: repository.watchHabit(initialHabit.id),
      initialData: initialHabit,
      builder: (context, snapshot) {
        final habit = snapshot.data;
        if (habit == null) {
          // Alışkanlık (düzenleme ekranından) silindi — geri dön.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
          return const Scaffold(backgroundColor: AppColors.bg);
        }
        return _DetailBody(habit: habit, repository: repository);
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.habit, required this.repository});

  final Habit habit;
  final HabitRepository repository;

  @override
  Widget build(BuildContext context) {
    final today = todayDayKey();
    final color = Color(habit.colorValue);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.colorDot),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                habit.name,
                style: AppTextStyles.h1.copyWith(fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.text),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AddEditHabitScreen(repository: repository, habit: habit),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Set<int>>(
        stream: repository.watchCompletedDayKeys(habit.id),
        initialData: const <int>{},
        builder: (context, snapshot) {
          final completed = snapshot.data ?? const <int>{};
          final streak = calculateStreak(completed, today);

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${streak.current}',
                        label: turkishUpperCase('Şu an'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.statGap),
                    Expanded(
                      child: _StatCard(
                        value: '${streak.longest}',
                        label: turkishUpperCase('En uzun'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.statGap),
                    Expanded(
                      child: _StatCard(
                        value: '${completed.length}',
                        label: turkishUpperCase('Toplam'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(13, 14, 13, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turkishUpperCase('Son 1 yıl'),
                        style: AppTextStyles.cardHeader,
                      ),
                      const SizedBox(height: 11),
                      HeatmapView(
                        completedDayKeys: completed,
                        todayKey: today,
                        onDayTap: (dayKey, wasDone) => repository.setDayDone(
                          habit.id,
                          dayKey,
                          done: !wasDone,
                        ),
                      ),
                      const SizedBox(height: 11),
                      _HeatmapLegend(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.statNumber),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('az', style: AppTextStyles.monthLabel),
        const SizedBox(width: 4),
        for (final color in AppColors.heatmapLevels) ...[
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
        const SizedBox(width: 4),
        Text('çok', style: AppTextStyles.monthLabel),
      ],
    );
  }
}
