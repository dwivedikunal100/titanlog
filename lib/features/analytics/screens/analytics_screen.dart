import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/features/exercises/providers/exercise_providers.dart';
import 'package:titanlog/features/analytics/providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExercise = ref.watch(analyticsExerciseProvider);
    final timeRange = ref.watch(analyticsTimeRangeProvider);
    final exercisesAsync = ref.watch(allExercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            exercisesAsync.when(
              data: (exercises) => _buildExerciseDropdown(
                  context, ref, exercises, selectedExercise),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),
            _buildTimeRangeSelector(context, ref, timeRange),
            const SizedBox(height: 24),
            _buildSectionHeader(
                context, 'Volume Over Time', Icons.show_chart),
            const SizedBox(height: 12),
            _VolumeChart(
              exerciseId: selectedExercise?.id,
              timeRange: timeRange,
            ),
            const SizedBox(height: 32),
            if (selectedExercise != null) ...[
              _buildSectionHeader(
                  context, 'Estimated 1RM', Icons.trending_up),
              const SizedBox(height: 12),
              _Est1RMChart(exerciseId: selectedExercise.id),
            ] else ...[
              _buildSectionHeader(
                  context, 'Estimated 1RM', Icons.trending_up),
              const SizedBox(height: 12),
              _buildEmptyChartPlaceholder(
                  context, 'Select an exercise to view 1RM trends'),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDropdown(BuildContext context, WidgetRef ref,
      List<Exercise> exercises, Exercise? selected) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected?.id,
          hint: const Text('Select exercise',
              style: TextStyle(color: AppColors.onSurfaceDim)),
          isExpanded: true,
          dropdownColor: AppColors.surfaceContainerHighest,
          icon: const Icon(Icons.expand_more,
              color: AppColors.onSurfaceVariant),
          items: [
            const DropdownMenuItem<int>(
              value: -1,
              child: Text('All exercises',
                  style: TextStyle(color: AppColors.onSurface)),
            ),
            ...exercises.map((e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.name,
                      style:
                          const TextStyle(color: AppColors.onSurface)),
                )),
          ],
          onChanged: (id) {
            if (id == -1 || id == null) {
              ref.read(analyticsExerciseProvider.notifier).state = null;
            } else {
              final exercise =
                  exercises.firstWhere((e) => e.id == id);
              ref.read(analyticsExerciseProvider.notifier).state =
                  exercise;
            }
          },
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(
      BuildContext context, WidgetRef ref, AnalyticsTimeRange selected) {
    return Row(
      children: AnalyticsTimeRange.values.map((range) {
        final isSelected = range == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              ref.read(analyticsTimeRangeProvider.notifier).state =
                  range;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(
                        color:
                            AppColors.primary.withValues(alpha: 0.5))
                    : null,
              ),
              child: Text(
                _timeRangeLabel(range),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildEmptyChartPlaceholder(
      BuildContext context, String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart,
                size: 48, color: AppColors.onSurfaceDim),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceDim,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeRangeLabel(AnalyticsTimeRange range) {
    switch (range) {
      case AnalyticsTimeRange.week:
        return '1W';
      case AnalyticsTimeRange.month:
        return '1M';
      case AnalyticsTimeRange.threeMonths:
        return '3M';
      case AnalyticsTimeRange.allTime:
        return 'All';
    }
  }
}

class _VolumeChart extends ConsumerWidget {
  final int? exerciseId;
  final AnalyticsTimeRange timeRange;

  const _VolumeChart({this.exerciseId, required this.timeRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    DateTime? startDate;

    switch (timeRange) {
      case AnalyticsTimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
      case AnalyticsTimeRange.month:
        startDate = now.subtract(const Duration(days: 30));
      case AnalyticsTimeRange.threeMonths:
        startDate = now.subtract(const Duration(days: 90));
      case AnalyticsTimeRange.allTime:
        startDate = null;
    }

    final params = VolumeQueryParams(
      exerciseId: exerciseId,
      startDate: startDate,
      endDate: now,
    );

    final dataAsync = ref.watch(volumeOverTimeProvider(params));

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: dataAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Text(
                'No data yet — complete some workouts!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceDim,
                    ),
              ),
            );
          }

          final spots = data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.value))
              .toList();

          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calcInterval(spots),
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AppColors.surfaceContainerHigh,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _fmtVol(value),
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceDim),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval:
                        (spots.length / 5).ceilToDouble().clamp(1, 100),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('M/d')
                                .format(data[index].key),
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.onSurfaceDim),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.chartLine1,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: spots.length < 15,
                    getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.chartLine1,
                      strokeWidth: 1.5,
                      strokeColor: AppColors.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.chartGradientStart,
                        AppColors.chartGradientEnd,
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      AppColors.surfaceContainerHighest,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${_fmtVol(s.y)} kg',
                            const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ))
                      .toList(),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  double _calcInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    final maxY =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return (maxY / 4).ceilToDouble().clamp(1, double.infinity);
  }

  String _fmtVol(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _Est1RMChart extends ConsumerWidget {
  final int exerciseId;

  const _Est1RMChart({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(est1rmOverTimeProvider(exerciseId));

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: dataAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Text(
                'No 1RM data yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceDim,
                    ),
              ),
            );
          }

          final spots = data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.value))
              .toList();

          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AppColors.surfaceContainerHigh,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(0)}kg',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceDim),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval:
                        (spots.length / 5).ceilToDouble().clamp(1, 100),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('M/d')
                                .format(data[index].key),
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.onSurfaceDim),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.chartLine2,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.chartLine2,
                      strokeWidth: 1.5,
                      strokeColor: AppColors.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.chartLine2.withValues(alpha: 0.25),
                        AppColors.chartLine2.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      AppColors.surfaceContainerHighest,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(1)} kg',
                            const TextStyle(
                                color: AppColors.chartLine2,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ))
                      .toList(),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
