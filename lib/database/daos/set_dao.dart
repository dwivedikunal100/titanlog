import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/exercise_sets.dart';
import '../tables/workout_exercises.dart';
import '../tables/personal_records.dart';
import '../tables/exercises.dart';

part 'set_dao.g.dart';

@DriftAccessor(
    tables: [ExerciseSets, WorkoutExercises, PersonalRecords, Exercises])
class SetDao extends DatabaseAccessor<AppDatabase> with _$SetDaoMixin {
  SetDao(super.db);

  // ── Set CRUD ──────────────────────────────────────────────

  Future<int> insertSet(ExerciseSetsCompanion set_) {
    return into(exerciseSets).insert(set_);
  }

  Future<bool> updateSet(ExerciseSet set_) {
    return update(exerciseSets).replace(set_);
  }

  Future<int> deleteSet(int id) {
    return (delete(exerciseSets)..where((s) => s.id.equals(id))).go();
  }

  Stream<List<ExerciseSet>> watchSetsForWorkoutExercise(
      int workoutExerciseId) {
    return (select(exerciseSets)
          ..where((s) => s.workoutExerciseId.equals(workoutExerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .watch();
  }

  Future<List<ExerciseSet>> getSetsForWorkoutExercise(
      int workoutExerciseId) {
    return (select(exerciseSets)
          ..where((s) => s.workoutExerciseId.equals(workoutExerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .get();
  }

  Future<void> completeSet(int setId) async {
    await (update(exerciseSets)..where((s) => s.id.equals(setId))).write(
      ExerciseSetsCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get the last workout's sets for a specific exercise (for smart defaults)
  Future<List<ExerciseSet>> getLastWorkoutSetsForExercise(
      int exerciseId) async {
    // Find the most recent workout_exercise entry for this exercise
    final query = select(workoutExercises).join([
      innerJoin(exerciseSets,
          exerciseSets.workoutExerciseId.equalsExp(workoutExercises.id)),
    ])
      ..where(workoutExercises.exerciseId.equals(exerciseId))
      ..where(exerciseSets.isCompleted.equals(true))
      ..orderBy([OrderingTerm.desc(exerciseSets.completedAt)])
      ..limit(20);

    final rows = await query.get();

    if (rows.isEmpty) return [];

    // Get the workoutExerciseId of the most recent one
    final lastWeId = rows.first.readTable(workoutExercises).id;

    // Return all sets from that workout exercise
    return rows
        .where((r) => r.readTable(workoutExercises).id == lastWeId)
        .map((r) => r.readTable(exerciseSets))
        .toList();
  }

  // ── Personal Records ──────────────────────────────────────

  Future<int> insertPR(PersonalRecordsCompanion pr) {
    return into(personalRecords).insert(pr);
  }

  /// Check if a set is a new PR and record it
  Future<PersonalRecord?> checkAndRecordPR(
    int exerciseId,
    ExerciseSet set_,
  ) async {
    // Check weight PR
    final currentWeightPR = await _getBestPR(exerciseId, 'weight');
    if (currentWeightPR == null || set_.weight > currentWeightPR.value) {
      final prId = await insertPR(PersonalRecordsCompanion.insert(
        exerciseId: exerciseId,
        recordType: 'weight',
        value: set_.weight,
        setId: set_.id,
      ));
      return (select(personalRecords)..where((p) => p.id.equals(prId)))
          .getSingle();
    }

    // Check volume PR (weight × reps)
    final volume = set_.weight * set_.reps;
    final currentVolumePR = await _getBestPR(exerciseId, 'volume');
    if (currentVolumePR == null || volume > currentVolumePR.value) {
      final prId = await insertPR(PersonalRecordsCompanion.insert(
        exerciseId: exerciseId,
        recordType: 'volume',
        value: volume,
        setId: set_.id,
      ));
      return (select(personalRecords)..where((p) => p.id.equals(prId)))
          .getSingle();
    }

    // Check est 1RM PR (Epley)
    final est1rm = set_.reps > 1
        ? set_.weight * (1 + set_.reps / 30.0)
        : set_.weight;
    final current1rmPR = await _getBestPR(exerciseId, 'est_1rm');
    if (current1rmPR == null || est1rm > current1rmPR.value) {
      final prId = await insertPR(PersonalRecordsCompanion.insert(
        exerciseId: exerciseId,
        recordType: 'est_1rm',
        value: est1rm,
        setId: set_.id,
      ));
      return (select(personalRecords)..where((p) => p.id.equals(prId)))
          .getSingle();
    }

    return null;
  }

  Future<PersonalRecord?> _getBestPR(int exerciseId, String type) async {
    final query = select(personalRecords)
      ..where(
          (p) => p.exerciseId.equals(exerciseId) & p.recordType.equals(type))
      ..orderBy([(p) => OrderingTerm.desc(p.value)])
      ..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  /// Get recent PRs across all exercises
  Stream<List<PersonalRecord>> watchRecentPRs({int limit = 3}) {
    return (select(personalRecords)
          ..orderBy([(p) => OrderingTerm.desc(p.achievedAt)])
          ..limit(limit))
        .watch();
  }

  /// Get all PRs for a specific exercise
  Future<Map<String, PersonalRecord>> getBestPRsForExercise(
      int exerciseId) async {
    final result = <String, PersonalRecord>{};
    for (final type in ['weight', 'volume', 'est_1rm']) {
      final pr = await _getBestPR(exerciseId, type);
      if (pr != null) result[type] = pr;
    }
    return result;
  }

  /// Get estimated 1RM over time for a specific exercise (for charts)
  Future<List<MapEntry<DateTime, double>>> getEst1RMOverTime(
      int exerciseId) async {
    final query = select(personalRecords)
      ..where((p) =>
          p.exerciseId.equals(exerciseId) & p.recordType.equals('est_1rm'))
      ..orderBy([(p) => OrderingTerm.asc(p.achievedAt)]);
    final rows = await query.get();
    return rows.map((r) => MapEntry(r.achievedAt, r.value)).toList();
  }
}
