import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_providers.dart';
import '../../../database/app_database.dart';
import '../../../database/daos/routine_dao.dart';

final allRoutinesProvider = StreamProvider<List<Routine>>((ref) {
  final dao = ref.watch(routineDaoProvider);
  return dao.watchAllRoutines();
});

final routineExercisesProvider = StreamProvider.family<List<RoutineExerciseWithDetails>, int>((ref, routineId) {
  final dao = ref.watch(routineDaoProvider);
  return dao.watchRoutineExercises(routineId);
});
