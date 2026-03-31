import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../database/app_database.dart';
import '../../../database/daos/routine_dao.dart';
import '../../providers/database_providers.dart';
import '../providers/routine_providers.dart';
import '../../exercises/screens/exercise_library_screen.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final Routine routine;
  const RoutineEditorScreen({super.key, required this.routine});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    if (_nameController.text == widget.routine.name) return;

    final updated = widget.routine.copyWith(name: _nameController.text);
    await ref.read(routineDaoProvider).updateRoutine(updated);
  }

  @override
  Widget build(BuildContext context) {
    final routineDao = ref.read(routineDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Routine'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              onEditingComplete: _saveName,
              onTapOutside: (_) => _saveName(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ref.watch(routineExercisesProvider(widget.routine.id)).when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExerciseLibraryScreen(
                            selectionMode: true,
                            routineId: widget.routine.id,
                          ),
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

                    final list = List<RoutineExerciseWithDetails>.from(exercises);
                    final item = list.removeAt(oldIndex);
                    list.insert(newIndex, item);

                    final orderedIds = list.map((e) => e.routineExercise.id).toList();
                    await routineDao.updateRoutineExerciseOrder(widget.routine.id, orderedIds);
                    ref.invalidate(routineExercisesProvider(widget.routine.id));
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
                                builder: (_) => ExerciseLibraryScreen(
                                  selectionMode: true,
                                  routineId: widget.routine.id,
                                ),
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
                      key: ValueKey(exc.routineExercise.id),
                      color: AppColors.surfaceContainer,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          exc.exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () async {
                                await routineDao.removeExerciseFromRoutine(exc.routineExercise.id);
                                ref.invalidate(routineExercisesProvider(widget.routine.id));
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle, color: Colors.grey),
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
          ),
        ],
      ),
    );
  }
}
