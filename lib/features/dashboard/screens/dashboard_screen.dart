import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/features/providers/database_providers.dart';
import 'package:titanlog/features/workout/providers/workout_providers.dart';
import 'package:titanlog/features/analytics/providers/analytics_providers.dart';
import 'package:titanlog/features/dashboard/widgets/consistency_calendar.dart';
import 'package:titanlog/features/dashboard/widgets/bento_card.dart';
import 'package:titanlog/features/dashboard/widgets/recent_prs_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutDatesAsync = ref.watch(workoutDatesProvider);
    final recentPRs = ref.watch(recentPRsProvider);
    final workoutCount = ref.watch(workoutCountThisMonthProvider);
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  Text(
                    'TITAN',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                  ),
                  Text(
                    'LOG',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: AppColors.onSurface,
                          letterSpacing: 2,
                        ),
                  ),
                ],
              ),
            ),
            backgroundColor: AppColors.surface,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Active workout banner
                if (activeWorkout != null) ...[
                  _buildActiveWorkoutBanner(context, activeWorkout),
                  const SizedBox(height: 16),
                ],

                // Consistency Calendar
                workoutDatesAsync.when(
                  data: (dates) => ConsistencyCalendar(workoutDates: dates),
                  loading: () => _buildShimmerCard(height: 180),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),

                // Bento Grid - Quick Stats
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 150,
                        child: workoutCount.when(
                          data: (count) => BentoCard(
                            title: 'This Month',
                            value: '$count',
                            icon: Icons.calendar_today_rounded,
                            iconColor: AppColors.chartLine2,
                          ),
                          loading: () => _buildShimmerCard(),
                          error: (_, __) => const BentoCard(
                            title: 'This Month',
                            value: '0',
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 150,
                        child: workoutDatesAsync.when(
                          data: (dates) {
                            final streak = _calculateStreak(dates);
                            return BentoCard(
                              title: 'Streak',
                              value: '$streak',
                              icon: Icons.local_fire_department,
                              iconColor: AppColors.warning,
                              subtitle: streak == 1 ? 'day' : 'days',
                            );
                          },
                          loading: () => _buildShimmerCard(),
                          error: (_, __) => const BentoCard(
                            title: 'Streak',
                            value: '0',
                            icon: Icons.local_fire_department,
                            iconColor: AppColors.warning,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 150,
                        child: BentoCard(
                          title: 'Current Week',
                          value: _getWeekdayName(),
                          icon: Icons.trending_up_rounded,
                          iconColor: AppColors.success,
                          subtitle: 'Keep pushing!',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: SizedBox(
                        height: 150,
                        child: BentoCard(
                          title: 'Total Exercises',
                          value: '204',
                          icon: Icons.fitness_center_rounded,
                          iconColor: AppColors.chartLine3,
                          subtitle: 'In library',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recent PRs
                recentPRs.when(
                  data: (prs) => _buildPRsSection(context, ref, prs),
                  loading: () => _buildShimmerCard(height: 200),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkoutBanner(BuildContext context, Workout workout) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.surfaceContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout in Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                Text(
                  workout.name,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppColors.primary, size: 16),
        ],
      ),
    );
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final uniqueDays = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (int i = 0; i < uniqueDays.length; i++) {
      final expected = today.subtract(Duration(days: i));
      if (uniqueDays.contains(expected)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Widget _buildPRsSection(
      BuildContext context, WidgetRef ref, List<PersonalRecord> prs) {
    return FutureBuilder<Map<int, String>>(
      future: _getExerciseNames(ref, prs),
      builder: (context, snapshot) {
        return RecentPRsCard(
          prs: prs,
          exerciseNames: snapshot.data ?? {},
        );
      },
    );
  }

  Future<Map<int, String>> _getExerciseNames(
      WidgetRef ref, List<PersonalRecord> prs) async {
    final dao = ref.read(exerciseDaoProvider);
    final names = <int, String>{};
    for (final pr in prs) {
      try {
        final exercise = await dao.getExerciseById(pr.exerciseId);
        names[pr.exerciseId] = exercise.name;
      } catch (_) {
        names[pr.exerciseId] = 'Unknown';
      }
    }
    return names;
  }

  String _getWeekdayName() {
    final weekday = DateTime.now().weekday;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildShimmerCard({double height = 150}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
