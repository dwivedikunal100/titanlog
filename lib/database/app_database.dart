import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/exercises.dart';
import 'tables/workouts.dart';
import 'tables/workout_exercises.dart';
import 'tables/exercise_sets.dart';
import 'tables/personal_records.dart';
import 'tables/progress_photos.dart';
import 'daos/exercise_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/set_dao.dart';
import 'daos/photo_dao.dart';
import 'daos/routine_dao.dart';
import 'tables/routines.dart';
import 'tables/routine_exercises.dart';
import 'seed/exercise_seed_data.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Exercises, Workouts, WorkoutExercises, ExerciseSets, PersonalRecords, ProgressPhotos, Routines, RoutineExercises],
  daos: [ExerciseDao, WorkoutDao, SetDao, PhotoDao, RoutineDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'titanlog_db');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedExercises();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(progressPhotos);
        }
        if (from < 3) {
          // Trigger seeding process to inject newly added exercises.
          await _seedExercises();
        }
        if (from < 4) {
          await m.createTable(routines);
          await m.createTable(routineExercises);
        }
      },
    );
  }

  Future<void> _seedExercises() async {
    await batch((b) {
      for (final exercise in ExerciseSeedData.exercises) {
        b.insert(
          exercises,
          ExercisesCompanion.insert(
            name: exercise[0]!,
            primaryMuscle: exercise[1]!,
            secondaryMuscle: Value(exercise[2]),
            equipmentType: exercise[3]!,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
