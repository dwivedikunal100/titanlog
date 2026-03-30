import 'package:flutter/material.dart';
import 'package:titanlog/core/theme/app_colors.dart';

class ConsistencyCalendar extends StatelessWidget {
  final List<DateTime> workoutDates;

  const ConsistencyCalendar({super.key, required this.workoutDates});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weeks = 12;
    final startDate = now.subtract(const Duration(days: weeks * 7 - 1));

    // Count workouts per day
    final workoutCounts = <DateTime, int>{};
    for (final d in workoutDates) {
      final key = DateTime(d.year, d.month, d.day);
      workoutCounts[key] = (workoutCounts[key] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceContainerHigh,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Consistency',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                'Past $weeks weeks',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 7 * 16.0,
            child: Row(
              children: List.generate(weeks, (weekIndex) {
                return Expanded(
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(
                          Duration(days: weekIndex * 7 + dayIndex));
                      if (date.isAfter(now)) {
                        return _buildCell(context, null, false);
                      }
                      final count = workoutCounts[
                              DateTime(date.year, date.month, date.day)] ??
                          0;
                      final isToday = date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;
                      return _buildCell(context, count, isToday);
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, int? count, bool isToday) {
    Color color;
    if (count == null) {
      color = Colors.transparent;
    } else if (count == 0) {
      color = AppColors.heatmapEmpty;
    } else if (count == 1) {
      color = AppColors.heatmapLevel2;
    } else if (count == 2) {
      color = AppColors.heatmapLevel3;
    } else {
      color = AppColors.heatmapLevel4;
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6), width: 1)
              : null,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 4),
        _legendBox(AppColors.heatmapEmpty),
        _legendBox(AppColors.heatmapLevel1),
        _legendBox(AppColors.heatmapLevel2),
        _legendBox(AppColors.heatmapLevel3),
        _legendBox(AppColors.heatmapLevel4),
        const SizedBox(width: 4),
        Text('More', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
