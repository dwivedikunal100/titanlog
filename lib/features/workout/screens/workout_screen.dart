import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/core/utils/haptic_utils.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/database/daos/workout_dao.dart';
import 'package:titanlog/features/providers/database_providers.dart';
import 'package:titanlog/features/workout/providers/workout_providers.dart';
import 'package:titanlog/features/exercises/screens/exercise_library_screen.dart';
import 'package:titanlog/features/workout/widgets/set_row.dart';
import 'package:titanlog/features/workout/widgets/rest_timer_overlay.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeWorkout = ref.read(activeWorkoutProvider);
      if (activeWorkout != null) {
        ref
            .read(workoutElapsedProvider.notifier)
            .start(activeWorkout.startedAt);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final elapsed = ref.watch(workoutElapsedProvider);
    final restTimer = ref.watch(restTimerProvider);

    if (activeWorkout == null) {
      return _buildStartWorkoutView(context);
    }

    final workoutExercises =
        ref.watch(workoutExercisesProvider(activeWorkout.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activeWorkout.name,
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              _formatDuration(elapsed),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _finishWorkout(context),
            child: const Text('Finish'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'cancel') _cancelWorkout(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'cancel',
                child: Text('Cancel Workout',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          workoutExercises.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return _buildEmptyWorkout(context, activeWorkout.id);
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 120),
                itemCount: exercises.length + 1,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex -= 1;
                  // Don't allow reordering the "Add Exercise" button
                  if (oldIndex == exercises.length || newIndex == exercises.length) return;
                  
                  final list = List<WorkoutExerciseWithDetails>.from(exercises);
                  final item = list.removeAt(oldIndex);
                  list.insert(newIndex, item);

                  final orderedIds = list.map((e) => e.workoutExercise.id).toList();
                  await ref.read(workoutDaoProvider).updateExerciseOrder(activeWorkout.id, orderedIds);
                  ref.invalidate(workoutExercisesProvider(activeWorkout.id));
                },
                itemBuilder: (context, index) {
                  if (index == exercises.length) {
                    return SizedBox(
                      key: const ValueKey('add_exercise_button'),
                      child: _buildAddExerciseButton(context, activeWorkout.id),
                    );
                  }
                  return _ExerciseCard(
                    key: ValueKey(exercises[index].workoutExercise.id),
                    index: index,
                    workoutExercise: exercises[index],
                    workoutId: activeWorkout.id,
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          if (restTimer.isRunning)
            const Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: RestTimerOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildStartWorkoutView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Ready to Train?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start an empty workout and add\nexercises as you go',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startWorkout(),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Empty Workout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWorkout(BuildContext context, int workoutId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline,
              size: 64, color: AppColors.onSurfaceDim),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceDim,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                _navigateToExerciseSelection(context, workoutId),
            icon: const Icon(Icons.add),
            label: const Text('Add Exercises'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton(BuildContext context, int workoutId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: OutlinedButton.icon(
        onPressed: () =>
            _navigateToExerciseSelection(context, workoutId),
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _startWorkout() async {
    HapticUtils.mediumImpact();
    final id =
        await ref.read(activeWorkoutProvider.notifier).startWorkout();
    final workout = await ref.read(workoutDaoProvider).getWorkoutById(id);
    ref.read(workoutElapsedProvider.notifier).start(workout.startedAt);
  }

  void _finishWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout?'),
        content:
            const Text('Are you sure you want to finish this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticUtils.heavyImpact();
      ref.read(workoutElapsedProvider.notifier).stop();
      await ref.read(activeWorkoutProvider.notifier).finishWorkout();
      ref.invalidate(workoutDatesProvider);
      ref.invalidate(workoutCountThisMonthProvider);
      ref.invalidate(recentWorkoutsProvider);
    }
  }

  void _cancelWorkout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text(
            'This will delete all data for this workout. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Cancel Workout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(workoutElapsedProvider.notifier).stop();
      await ref.read(activeWorkoutProvider.notifier).cancelWorkout();
    }
  }

  void _navigateToExerciseSelection(
      BuildContext context, int workoutId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          selectionMode: true,
          workoutId: workoutId,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _ExerciseCard extends ConsumerWidget {
  final WorkoutExerciseWithDetails workoutExercise;
  final int workoutId;
  final int index;

  const _ExerciseCard({
    super.key,
    required this.index,
    required this.workoutExercise,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = workoutExercise.exercise;
    final sets = workoutExercise.sets;
    final muscleColor =
        AppColors.muscleGroupColors[exercise.primaryMuscle] ??
            AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceContainerHigh,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: muscleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.drag_indicator, color: AppColors.onSurfaceDim),
                  ),
                ),
                PopupMenuButton<String>(
                  iconSize: 20,
                  onSelected: (value) {
                    if (value == 'remove') {
                      _removeExercise(ref);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                    width: 32,
                    child: Text('SET',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceDim,
                            fontWeight: FontWeight.w600))),
                SizedBox(width: 8),
                Expanded(
                    child: Text('PREV',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurfaceDim,
                            fontWeight: FontWeight.w600))),
                SizedBox(
                  width: 80,
                  child: Text('KG',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceDim,
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text('REPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceDim,
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1),
          ...sets.map((set) => SetRow(
                set_: set,
                exerciseId: exercise.id,
                workoutExerciseId: workoutExercise.workoutExercise.id,
                onCompleted: () {
                  ref.read(restTimerProvider.notifier).startTimer();
                },
              )),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () => _addSet(ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Set'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSet(WidgetRef ref) async {
    HapticUtils.buttonTap();
    final dao = ref.read(setDaoProvider);
    final weId = workoutExercise.workoutExercise.id;
    final currentSets = workoutExercise.sets;
    final nextSetNumber =
        currentSets.isEmpty ? 1 : currentSets.last.setNumber + 1;

    double defaultWeight = 0;
    int defaultReps = 0;

    if (currentSets.isNotEmpty) {
      defaultWeight = currentSets.last.weight;
      defaultReps = currentSets.last.reps;
    } else {
      final lastSets = await dao
          .getLastWorkoutSetsForExercise(workoutExercise.exercise.id);
      if (lastSets.isNotEmpty) {
        defaultWeight = lastSets.first.weight;
        defaultReps = lastSets.first.reps;
      }
    }

    await dao.insertSet(ExerciseSetsCompanion.insert(
      workoutExerciseId: weId,
      setNumber: nextSetNumber,
      weight: Value(defaultWeight),
      reps: Value(defaultReps),
    ));

    ref.invalidate(workoutExercisesProvider(workoutId));
  }

  void _removeExercise(WidgetRef ref) async {
    HapticUtils.swipeAction();
    final dao = ref.read(workoutDaoProvider);
    await dao.removeExerciseFromWorkout(
        workoutExercise.workoutExercise.id);
    ref.invalidate(workoutExercisesProvider(workoutId));
  }
}
