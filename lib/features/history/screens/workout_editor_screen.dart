import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../database/app_database.dart';
import '../../providers/database_providers.dart';
import '../../../database/daos/workout_dao.dart';
import '../../../database/app_database.dart';
import '../../workout/widgets/set_row.dart'; // We can reuse set row if we pass id
import 'package:drift/drift.dart' as drift;
import '../../workout/providers/workout_providers.dart';
import '../../exercises/screens/exercise_library_screen.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final int workoutId;
  const WorkoutEditorScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final workoutDao = ref.read(workoutDaoProvider);
    final setDao = ref.read(setDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.success),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ref.watch(workoutExercisesProvider(widget.workoutId)).when(
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseLibraryScreen(selectionMode: true, workoutId: widget.workoutId),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Exercises'),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length + 1,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              if (oldIndex == exercises.length || newIndex == exercises.length) return;

              final list = List<WorkoutExerciseWithDetails>.from(exercises);
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);

              final orderedIds = list.map((e) => e.workoutExercise.id).toList();
              await workoutDao.updateExerciseOrder(widget.workoutId, orderedIds);
              ref.invalidate(workoutExercisesProvider(widget.workoutId));
            },
            itemBuilder: (context, index) {
              if (index == exercises.length) {
                return SizedBox(
                  key: const ValueKey('add_exercise_button'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseLibraryScreen(selectionMode: true, workoutId: widget.workoutId),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                );
              }

              final exc = exercises[index];
              return Card(
                key: ValueKey(exc.workoutExercise.id),
                color: AppColors.surfaceContainer,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exc.exercise.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...exc.sets.map((set) {
                        return _EditorSetRow(
                          key: ValueKey(set.id),
                          exerciseSet: set,
                          onUpdate: (weight, reps) async {
                            await setDao.updateSet(
                              set.copyWith(weight: weight, reps: reps, isCompleted: true),
                            );
                            ref.invalidate(workoutExercisesProvider(widget.workoutId));
                          },
                          onDelete: () async {
                            await setDao.deleteSet(set.id);
                            ref.invalidate(workoutExercisesProvider(widget.workoutId));
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final newSetNumber = exc.sets.length + 1;
                          await setDao.insertSet(
                            ExerciseSetsCompanion.insert(
                              workoutExerciseId: exc.workoutExercise.id,
                              setNumber: newSetNumber,
                              weight: const drift.Value(0.0),
                              reps: const drift.Value(0),
                            ),
                          );
                          ref.invalidate(workoutExercisesProvider(widget.workoutId));
                        },
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        label: const Text('Add Set', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EditorSetRow extends StatefulWidget {
  final ExerciseSet exerciseSet;
  final Function(double weight, int reps) onUpdate;
  final VoidCallback onDelete;

  const _EditorSetRow({
    super.key,
    required this.exerciseSet,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_EditorSetRow> createState() => _EditorSetRowState();
}

class _EditorSetRowState extends State<_EditorSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.exerciseSet.weight.toString());
    _repsController = TextEditingController(text: widget.exerciseSet.reps.toString());
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _save() {
    final w = double.tryParse(_weightController.text) ?? widget.exerciseSet.weight;
    final r = int.tryParse(_repsController.text) ?? widget.exerciseSet.reps;
    widget.onUpdate(w, r);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('Set ${widget.exerciseSet.setNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.chartLine2)),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'kg', isDense: true),
              onEditingComplete: _save,
              onTapOutside: (_) => _save(),
            ),
          ),
          const SizedBox(width: 8),
          const Text('×', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'reps', isDense: true),
              onEditingComplete: _save,
              onTapOutside: (_) => _save(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: widget.onDelete,
          )
        ],
      ),
    );
  }
}
