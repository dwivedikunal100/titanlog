import 'package:drift/drift.dart';
import 'workouts.dart';
import 'exercises.dart';

@DataClassName('WorkoutExercise')
class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}
