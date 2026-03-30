import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/workouts.dart';
import '../tables/workout_exercises.dart';
import '../tables/exercises.dart';
import '../tables/exercise_sets.dart';

part 'workout_dao.g.dart';

class WorkoutWithExercises {
  final Workout workout;
  final List<WorkoutExerciseWithDetails> exercises;

  WorkoutWithExercises({required this.workout, required this.exercises});
}

class WorkoutExerciseWithDetails {
  final WorkoutExercise workoutExercise;
  final Exercise exercise;
  final List<ExerciseSet> sets;

  WorkoutExerciseWithDetails({
    required this.workoutExercise,
    required this.exercise,
    required this.sets,
  });
}

@DriftAccessor(tables: [Workouts, WorkoutExercises, Exercises, ExerciseSets])
class WorkoutDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // ── Workout CRUD ──────────────────────────────────────────

  Future<int> createWorkout(WorkoutsCompanion workout) {
    return into(workouts).insert(workout);
  }

  Future<Workout> getWorkoutById(int id) {
    return (select(workouts)..where((w) => w.id.equals(id))).getSingle();
  }

  Stream<List<Workout>> watchAllWorkouts() {
    return (select(workouts)
          ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
        .watch();
  }

  Stream<List<Workout>> watchRecentWorkouts({int limit = 10}) {
    return (select(workouts)
          ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
          ..limit(limit))
        .watch();
  }

  Future<bool> updateWorkout(Workout workout) {
    return update(workouts).replace(workout);
  }

  Future<void> finishWorkout(int workoutId) async {
    final now = DateTime.now();
    final workout = await getWorkoutById(workoutId);
    final duration = now.difference(workout.startedAt).inSeconds;
    await (update(workouts)..where((w) => w.id.equals(workoutId))).write(
      WorkoutsCompanion(
        finishedAt: Value(now),
        durationSeconds: Value(duration),
      ),
    );
  }

  Future<int> deleteWorkout(int id) {
    return (delete(workouts)..where((w) => w.id.equals(id))).go();
  }

  // ── Workout Exercises ─────────────────────────────────────

  Future<int> addExerciseToWorkout(WorkoutExercisesCompanion we) {
    return into(workoutExercises).insert(we);
  }

  Future<void> addMultipleExercisesToWorkout(
    int workoutId,
    List<int> exerciseIds,
  ) async {
    final currentCount = await _getExerciseCount(workoutId);
    await batch((b) {
      for (var i = 0; i < exerciseIds.length; i++) {
        b.insert(
          workoutExercises,
          WorkoutExercisesCompanion.insert(
            workoutId: workoutId,
            exerciseId: exerciseIds[i],
            orderIndex: Value(currentCount + i),
          ),
        );
      }
    });
  }

  Future<int> _getExerciseCount(int workoutId) async {
    final count = workoutExercises.id.count();
    final query = selectOnly(workoutExercises)
      ..addColumns([count])
      ..where(workoutExercises.workoutId.equals(workoutId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> removeExerciseFromWorkout(int workoutExerciseId) {
    return (delete(workoutExercises)
          ..where((we) => we.id.equals(workoutExerciseId)))
        .go();
  }

  Stream<List<WorkoutExerciseWithDetails>> watchWorkoutExercises(
    int workoutId,
  ) {
    final query = select(workoutExercises).join([
      innerJoin(
          exercises, exercises.id.equalsExp(workoutExercises.exerciseId)),
    ])
      ..where(workoutExercises.workoutId.equals(workoutId))
      ..orderBy([OrderingTerm.asc(workoutExercises.orderIndex)]);

    return query.watch().asyncMap((rows) async {
      final results = <WorkoutExerciseWithDetails>[];
      for (final row in rows) {
        final we = row.readTable(workoutExercises);
        final ex = row.readTable(exercises);
        final sets = await (select(exerciseSets)
              ..where((s) => s.workoutExerciseId.equals(we.id))
              ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
            .get();
        results.add(WorkoutExerciseWithDetails(
          workoutExercise: we,
          exercise: ex,
          sets: sets,
        ));
      }
      return results;
    });
  }

  // ── Stats queries ─────────────────────────────────────────

  /// Get workout dates for all completed workouts (for heatmap)
  Future<List<DateTime>> getWorkoutDates() async {
    final query = selectOnly(workouts)
      ..addColumns([workouts.startedAt])
      ..where(workouts.finishedAt.isNotNull())
      ..orderBy([OrderingTerm.desc(workouts.startedAt)]);
    final rows = await query.get();
    return rows.map((r) => r.read(workouts.startedAt)!).toList();
  }

  /// Get workout count for a specific month
  Future<int> getWorkoutCountForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final count = workouts.id.count();
    final query = selectOnly(workouts)
      ..addColumns([count])
      ..where(workouts.startedAt.isBiggerOrEqualValue(start) &
          workouts.startedAt.isSmallerOrEqualValue(end) &
          workouts.finishedAt.isNotNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Check if there's an active (unfinished) workout
  Future<Workout?> getActiveWorkout() async {
    final query = select(workouts)
      ..where((w) => w.finishedAt.isNull())
      ..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  /// Get total volume for a date range (for charts)
  Future<List<MapEntry<DateTime, double>>> getVolumeOverTime({
    int? exerciseId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = select(workouts).join([
      innerJoin(workoutExercises,
          workoutExercises.workoutId.equalsExp(workouts.id)),
      innerJoin(exerciseSets,
          exerciseSets.workoutExerciseId.equalsExp(workoutExercises.id)),
    ]);

    query.where(workouts.finishedAt.isNotNull());
    query.where(exerciseSets.isCompleted.equals(true));

    if (exerciseId != null) {
      query.where(workoutExercises.exerciseId.equals(exerciseId));
    }
    if (startDate != null) {
      query.where(workouts.startedAt.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(workouts.startedAt.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([OrderingTerm.asc(workouts.startedAt)]);

    final rows = await query.get();

    // Group by date and sum volume
    final volumeByDate = <DateTime, double>{};
    for (final row in rows) {
      final date = row.readTable(workouts).startedAt;
      final dateKey = DateTime(date.year, date.month, date.day);
      final set = row.readTable(exerciseSets);
      final volume = set.weight * set.reps;
      volumeByDate[dateKey] = (volumeByDate[dateKey] ?? 0) + volume;
    }

    return volumeByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }
}
