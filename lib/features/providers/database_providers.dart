import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final exerciseDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).exerciseDao;
});

final workoutDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).workoutDao;
});

final setDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).setDao;
});

final routineDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).routineDao;
});
