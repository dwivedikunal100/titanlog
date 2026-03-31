import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/database/daos/workout_dao.dart';
import 'package:titanlog/features/providers/database_providers.dart';

// Active workout state
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, Workout?>((ref) {
  return ActiveWorkoutNotifier(ref);
});

class ActiveWorkoutNotifier extends StateNotifier<Workout?> {
  final Ref ref;

  ActiveWorkoutNotifier(this.ref) : super(null) {
    _loadActiveWorkout();
  }

  Future<void> _loadActiveWorkout() async {
    final dao = ref.read(workoutDaoProvider);
    state = await dao.getActiveWorkout();
  }

  Future<int> startWorkout({String name = 'Workout'}) async {
    final dao = ref.read(workoutDaoProvider);
    final id = await dao.createWorkout(
      WorkoutsCompanion.insert(
        name: Value(name),
        startedAt: DateTime.now(),
      ),
    );
    state = await dao.getWorkoutById(id);
    return id;
  }

  Future<int> startWorkoutFromRoutine(int routineId, {String? customName}) async {
    final workoutDao = ref.read(workoutDaoProvider);
    final routineDao = ref.read(routineDaoProvider);
    final setDao = ref.read(setDaoProvider);

    final routine = await routineDao.getRoutineById(routineId);
    
    final id = await workoutDao.createWorkout(
      WorkoutsCompanion.insert(
        name: Value(customName ?? routine.name),
        startedAt: DateTime.now(),
      ),
    );

    state = await workoutDao.getWorkoutById(id);

    final routineExercises = await routineDao.getRoutineExercisesAsFuture(routineId);
    
    // Auto-populate
    for (var i = 0; i < routineExercises.length; i++) {
      final exc = routineExercises[i];
      final workoutExerciseId = await workoutDao.addExerciseToWorkout(
        WorkoutExercisesCompanion.insert(
          workoutId: id,
          exerciseId: exc.exercise.id,
          orderIndex: Value(i),
        )
      );

      final prevSets = await setDao.getLastWorkoutSetsForExercise(exc.exercise.id);
      
      if (prevSets.isEmpty) {
        // Just insert 1 empty set
        await setDao.insertSet(
          ExerciseSetsCompanion.insert(
            workoutExerciseId: workoutExerciseId,
            setNumber: 1,
            weight: const Value(0.0),
            reps: const Value(0),
          ),
        );
      } else {
        // Insert history identically
        for (var j = 0; j < prevSets.length; j++) {
          final oldSet = prevSets[j];
          await setDao.insertSet(
            ExerciseSetsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              setNumber: j + 1,
              weight: Value(oldSet.weight),
              reps: Value(oldSet.reps),
            ),
          );
        }
      }
    }

    return id;
  }

  Future<void> finishWorkout() async {
    if (state == null) return;
    final dao = ref.read(workoutDaoProvider);
    await dao.finishWorkout(state!.id);
    state = null;
  }

  Future<void> cancelWorkout() async {
    if (state == null) return;
    final dao = ref.read(workoutDaoProvider);
    await dao.deleteWorkout(state!.id);
    state = null;
  }
}

// Workout exercises stream
final workoutExercisesProvider = StreamProvider.family<
    List<WorkoutExerciseWithDetails>, int>((ref, workoutId) {
  return ref.watch(workoutDaoProvider).watchWorkoutExercises(workoutId);
});

// Recent workouts
final recentWorkoutsProvider = StreamProvider<List<Workout>>((ref) {
  return ref.watch(workoutDaoProvider).watchRecentWorkouts(limit: 20);
});

// Workout dates for heatmap
final workoutDatesProvider = FutureProvider<List<DateTime>>((ref) {
  return ref.watch(workoutDaoProvider).getWorkoutDates();
});

// Workout count this month
final workoutCountThisMonthProvider = FutureProvider<int>((ref) {
  final now = DateTime.now();
  return ref
      .watch(workoutDaoProvider)
      .getWorkoutCountForMonth(now.year, now.month);
});

// Rest timer
final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 0,
    this.isRunning = false,
  });

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;

  String get displayTime {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(const RestTimerState());

  void startTimer({int? seconds}) {
    _timer?.cancel();
    final total = seconds ?? state.totalSeconds;
    state = RestTimerState(
      totalSeconds: total,
      remainingSeconds: total,
      isRunning: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  void setDefaultDuration(int seconds) {
    state = state.copyWith(totalSeconds: seconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Workout elapsed time
final workoutElapsedProvider =
    StateNotifierProvider<WorkoutElapsedNotifier, Duration>((ref) {
  return WorkoutElapsedNotifier();
});

class WorkoutElapsedNotifier extends StateNotifier<Duration> {
  Timer? _timer;
  DateTime? _startTime;

  WorkoutElapsedNotifier() : super(Duration.zero);

  void start(DateTime startTime) {
    _startTime = startTime;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null) {
        state = DateTime.now().difference(_startTime!);
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
