import 'package:drift/drift.dart';

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('Workout'))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
}
