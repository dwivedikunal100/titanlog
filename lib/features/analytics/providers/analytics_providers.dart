import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/features/providers/database_providers.dart';

// Recent PRs
final recentPRsProvider = StreamProvider<List<PersonalRecord>>((ref) {
  return ref.watch(setDaoProvider).watchRecentPRs(limit: 3);
});

// Volume over time for a specific exercise
final volumeOverTimeProvider = FutureProvider.family<
    List<MapEntry<DateTime, double>>, VolumeQueryParams>((ref, params) {
  return ref.watch(workoutDaoProvider).getVolumeOverTime(
        exerciseId: params.exerciseId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
});

class VolumeQueryParams {
  final int? exerciseId;
  final DateTime? startDate;
  final DateTime? endDate;

  VolumeQueryParams({this.exerciseId, this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeQueryParams &&
          runtimeType == other.runtimeType &&
          exerciseId == other.exerciseId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      exerciseId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

// Estimated 1RM over time
final est1rmOverTimeProvider =
    FutureProvider.family<List<MapEntry<DateTime, double>>, int>(
        (ref, exerciseId) {
  return ref.watch(setDaoProvider).getEst1RMOverTime(exerciseId);
});

// Selected exercise for analytics
final analyticsExerciseProvider = StateProvider<Exercise?>((ref) => null);

// Analytics time range
enum AnalyticsTimeRange { week, month, threeMonths, allTime }

final analyticsTimeRangeProvider =
    StateProvider<AnalyticsTimeRange>((ref) => AnalyticsTimeRange.month);

// Settings
final weightUnitProvider = StateProvider<String>((ref) => 'kg');
final restTimerDefaultProvider = StateProvider<int>((ref) => 90);
