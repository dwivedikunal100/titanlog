import 'package:drift/drift.dart';
import 'exercises.dart';
import 'exercise_sets.dart';

@DataClassName('PersonalRecord')
class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get recordType => text()(); // 'weight', 'volume', 'est_1rm'
  RealColumn get value => real()();
  IntColumn get setId => integer().references(ExerciseSets, #id)();
  DateTimeColumn get achievedAt => dateTime().withDefault(currentDateAndTime)();
}
