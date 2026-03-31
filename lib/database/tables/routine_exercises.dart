import 'package:drift/drift.dart';
import 'routines.dart';
import 'exercises.dart';

class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}
