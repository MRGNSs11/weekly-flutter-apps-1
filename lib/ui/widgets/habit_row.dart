import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/habit_repository.dart';
import '../../domain/day_key.dart';
import '../../domain/streak.dart';
import '../theme/app_theme.dart';

class HabitRow extends StatelessWidget {
  const HabitRow({
    super.key,
    required this.habit,
    required this.repository,
    required this.onTap,
  });

  final Habit habit;
  final HabitRepository repository;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = todayDayKey();
    final color = Color(habit.colorValue);

    return StreamBuilder<Set<int>>(
      stream: repository.watchCompletedDayKeys(habit.id),
      initialData: const <int>{},
      builder: (context, snapshot) {
        final completed = snapshot.data ?? const <int>{};
        final streak = calculateStreak(completed, today);
        final isDoneToday = completed.contains(today);

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.rowPaddingV,
                horizontal: AppSpacing.rowPaddingH,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => repository.setDayDone(
                      habit.id,
                      today,
                      done: !isDoneToday,
                    ),
                    child: _CheckCircle(done: isDoneToday, color: color),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          habit.name,
                          style: AppTextStyles.rowTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _streakLabel(streak),
                          style: AppTextStyles.rowSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SparkBars(
                    completedDayKeys: completed,
                    today: today,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _streakLabel(StreakResult streak) {
  if (streak.current == 0) return 'Bugün henüz yok';
  return '${streak.current} günlük seri';
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.color});

  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 15, color: AppColors.onAccent)
          : null,
    );
  }
}

class _SparkBars extends StatelessWidget {
  const _SparkBars({
    required this.completedDayKeys,
    required this.today,
    required this.color,
  });

  final Set<int> completedDayKeys;
  final int today;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final todayEpoch = epochDayOf(today);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final epoch = todayEpoch - 6 + i;
        final on = completedDayKeys.contains(dayKeyOfEpoch(epoch));
        return Container(
          width: 5,
          height: 15,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 2.5),
          decoration: BoxDecoration(
            color: on ? color : AppColors.sparkOff,
            borderRadius: BorderRadius.circular(AppRadius.spark),
          ),
        );
      }),
    );
  }
}
