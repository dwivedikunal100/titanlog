import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/routines.dart';
import '../tables/routine_exercises.dart';
import '../tables/exercises.dart';

part 'routine_dao.g.dart';

class RoutineExerciseWithDetails {
  final RoutineExercise routineExercise;
  final Exercise exercise;

  RoutineExerciseWithDetails({
    required this.routineExercise,
    required this.exercise,
  });
}

@DriftAccessor(tables: [Routines, RoutineExercises, Exercises])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);

  // ── Routines CRUD ──────────────────────────────────────────

  Future<int> createRoutine(RoutinesCompanion routine) {
    return into(routines).insert(routine);
  }

  Future<Routine> getRoutineById(int id) {
    return (select(routines)..where((r) => r.id.equals(id))).getSingle();
  }

  Stream<List<Routine>> watchAllRoutines() {
    return (select(routines)..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).watch();
  }

  Future<bool> updateRoutine(Routine routine) {
    return update(routines).replace(routine);
  }

  Future<int> deleteRoutine(int id) {
    return (delete(routines)..where((r) => r.id.equals(id))).go();
  }

  // ── Routine Exercises ─────────────────────────────────────

  Future<int> addExerciseToRoutine(RoutineExercisesCompanion re) {
    return into(routineExercises).insert(re);
  }

  Future<void> addMultipleExercisesToRoutine(int routineId, List<int> exerciseIds) async {
    final currentCount = await _getRoutineExerciseCount(routineId);
    await batch((b) {
      for (var i = 0; i < exerciseIds.length; i++) {
        b.insert(
          routineExercises,
          RoutineExercisesCompanion.insert(
            routineId: routineId,
            exerciseId: exerciseIds[i],
            orderIndex: Value(currentCount + i),
          ),
        );
      }
    });
  }

  Future<int> _getRoutineExerciseCount(int routineId) async {
    final count = routineExercises.id.count();
    final query = selectOnly(routineExercises)
      ..addColumns([count])
      ..where(routineExercises.routineId.equals(routineId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> updateRoutineExerciseOrder(int routineId, List<int> orderedRoutineExerciseIds) async {
    await batch((b) {
      for (int i = 0; i < orderedRoutineExerciseIds.length; i++) {
        b.update(
          routineExercises,
          RoutineExercisesCompanion(orderIndex: Value(i)),
          where: (t) => t.id.equals(orderedRoutineExerciseIds[i]),
        );
      }
    });
  }

  Future<int> removeExerciseFromRoutine(int routineExerciseId) {
    return (delete(routineExercises)..where((re) => re.id.equals(routineExerciseId))).go();
  }

  Stream<List<RoutineExerciseWithDetails>> watchRoutineExercises(int routineId) {
    final query = select(routineExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(routineExercises.exerciseId)),
    ])
      ..where(routineExercises.routineId.equals(routineId))
      ..orderBy([OrderingTerm.asc(routineExercises.orderIndex)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return RoutineExerciseWithDetails(
          routineExercise: row.readTable(routineExercises),
          exercise: row.readTable(exercises),
        );
      }).toList();
    });
  }

  Future<List<RoutineExerciseWithDetails>> getRoutineExercisesAsFuture(int routineId) async {
    final query = select(routineExercises).join([
      innerJoin(exercises, exercises.id.equalsExp(routineExercises.exerciseId)),
    ])
      ..where(routineExercises.routineId.equals(routineId))
      ..orderBy([OrderingTerm.asc(routineExercises.orderIndex)]);

    final rows = await query.get();
    return rows.map((row) {
      return RoutineExerciseWithDetails(
        routineExercise: row.readTable(routineExercises),
        exercise: row.readTable(exercises),
      );
    }).toList();
  }
}
