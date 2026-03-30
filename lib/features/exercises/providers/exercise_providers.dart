import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/features/providers/database_providers.dart';

// All exercises stream
final allExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseDaoProvider).watchAllExercises();
});

// Exercises filtered by muscle group
final exercisesByMuscleProvider =
    StreamProvider.family<List<Exercise>, String>((ref, muscle) {
  return ref.watch(exerciseDaoProvider).watchExercisesByMuscle(muscle);
});

// Search exercises
final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

final exerciseFilterMuscleProvider = StateProvider<String?>((ref) => null);
final exerciseFilterEquipmentProvider = StateProvider<String?>((ref) => null);

final filteredExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final dao = ref.watch(exerciseDaoProvider);
  final query = ref.watch(exerciseSearchQueryProvider);
  final muscle = ref.watch(exerciseFilterMuscleProvider);
  final equipment = ref.watch(exerciseFilterEquipmentProvider);

  if (query.isNotEmpty) {
    return dao.searchExercises(query);
  } else if (muscle != null) {
    return dao.watchExercisesByMuscle(muscle);
  } else if (equipment != null) {
    return dao.watchExercisesByEquipment(equipment);
  }
  return dao.watchAllExercises();
});

// Selected exercises for multi-add
final selectedExerciseIdsProvider = StateProvider<Set<int>>((ref) => {});
