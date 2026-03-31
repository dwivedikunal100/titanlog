import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_providers.dart';
import '../../../database/app_database.dart';

final pastWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  final workoutDao = ref.watch(workoutDaoProvider);
  return workoutDao.watchAllWorkouts().map((workouts) {
    // Filter out the active one just in case (optional)
    return workouts.where((w) => w.finishedAt != null).toList();
  });
});
