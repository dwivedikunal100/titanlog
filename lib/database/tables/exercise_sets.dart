import 'package:drift/drift.dart';
import 'workout_exercises.dart';

@DataClassName('ExerciseSet')
class ExerciseSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId =>
      integer().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
