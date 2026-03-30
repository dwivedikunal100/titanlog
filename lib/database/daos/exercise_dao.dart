import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/exercises.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Stream<List<Exercise>> watchAllExercises() => select(exercises).watch();

  Stream<List<Exercise>> watchExercisesByMuscle(String muscle) {
    return (select(exercises)
          ..where((e) => e.primaryMuscle.equals(muscle))
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .watch();
  }

  Stream<List<Exercise>> watchExercisesByEquipment(String equipment) {
    return (select(exercises)
          ..where((e) => e.equipmentType.equals(equipment))
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .watch();
  }

  Stream<List<Exercise>> searchExercises(String query) {
    return (select(exercises)
          ..where((e) => e.name.like('%$query%'))
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .watch();
  }

  Future<Exercise> getExerciseById(int id) {
    return (select(exercises)..where((e) => e.id.equals(id))).getSingle();
  }

  Future<int> insertExercise(ExercisesCompanion exercise) {
    return into(exercises).insert(exercise);
  }

  Future<void> insertBulkExercises(List<ExercisesCompanion> list) async {
    await batch((b) {
      b.insertAll(exercises, list, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<bool> updateExercise(Exercise exercise) {
    return update(exercises).replace(exercise);
  }

  Future<int> deleteExercise(int id) {
    return (delete(exercises)..where((e) => e.id.equals(id))).go();
  }

  /// Get all unique muscle groups from the database
  Future<List<String>> getAllMuscleGroups() async {
    final query = selectOnly(exercises, distinct: true)
      ..addColumns([exercises.primaryMuscle]);
    final rows = await query.get();
    return rows.map((row) => row.read(exercises.primaryMuscle)!).toList();
  }

  /// Get all unique equipment types
  Future<List<String>> getAllEquipmentTypes() async {
    final query = selectOnly(exercises, distinct: true)
      ..addColumns([exercises.equipmentType]);
    final rows = await query.get();
    return rows.map((row) => row.read(exercises.equipmentType)!).toList();
  }
}
