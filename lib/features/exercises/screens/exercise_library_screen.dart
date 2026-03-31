import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/core/utils/haptic_utils.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/features/providers/database_providers.dart';
import 'package:titanlog/features/exercises/providers/exercise_providers.dart';

class ExerciseLibraryScreen extends ConsumerWidget {
  final bool selectionMode;
  final int? workoutId;
  final int? routineId;

  const ExerciseLibraryScreen({
    super.key,
    this.selectionMode = false,
    this.workoutId,
    this.routineId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final selectedMuscle = ref.watch(exerciseFilterMuscleProvider);
    final selectedEquipment = ref.watch(exerciseFilterEquipmentProvider);
    final selectedIds = ref.watch(selectedExerciseIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: selectionMode
            ? Text('Add Exercises (${selectedIds.length})')
            : const Text('Exercise Library'),
        actions: [
          if (selectionMode && selectedIds.isNotEmpty)
            TextButton.icon(
              onPressed: () => _addSelectedToWorkout(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add ${selectedIds.length}'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.onSurfaceDim),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          ref
                              .read(exerciseSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(exerciseSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Muscle filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  context,
                  'All',
                  isSelected:
                      selectedMuscle == null && selectedEquipment == null,
                  onTap: () {
                    ref.read(exerciseFilterMuscleProvider.notifier).state =
                        null;
                    ref.read(exerciseFilterEquipmentProvider.notifier).state =
                        null;
                  },
                ),
                ..._muscleGroups.map((m) => _buildFilterChip(
                      context,
                      _capitalize(m),
                      isSelected: selectedMuscle == m,
                      onTap: () {
                        ref.read(exerciseFilterMuscleProvider.notifier).state =
                            selectedMuscle == m ? null : m;
                        ref
                            .read(exerciseFilterEquipmentProvider.notifier)
                            .state = null;
                      },
                      color: AppColors.muscleGroupColors[m],
                    )),
              ],
            ),
          ),

          // Equipment filter row
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _equipmentTypes
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            _capitalize(e),
                            style: TextStyle(
                              fontSize: 11,
                              color: selectedEquipment == e
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                          selected: selectedEquipment == e,
                          onSelected: (selected) {
                            ref
                                .read(
                                    exerciseFilterEquipmentProvider.notifier)
                                .state = selected ? e : null;
                            ref
                                .read(exerciseFilterMuscleProvider.notifier)
                                .state = null;
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: AppColors.onSurfaceDim),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises found',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.onSurfaceDim,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final isSelected = selectedIds.contains(exercise.id);

                    return _ExerciseTile(
                      exercise: exercise,
                      isSelected: isSelected,
                      selectionMode: selectionMode,
                      onTap: () {
                        if (selectionMode) {
                          HapticUtils.selectionClick();
                          final ids = Set<int>.from(selectedIds);
                          if (isSelected) {
                            ids.remove(exercise.id);
                          } else {
                            ids.add(exercise.id);
                          }
                          ref
                              .read(selectedExerciseIdsProvider.notifier)
                              .state = ids;
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: selectionMode && selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _addSelectedToWorkout(context, ref),
              icon: const Icon(Icons.add),
              label: Text('Add ${selectedIds.length} exercises'),
            )
          : null,
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          HapticUtils.buttonTap();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primary).withValues(alpha: 0.2)
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(
                    color:
                        (color ?? AppColors.primary).withValues(alpha: 0.5),
                    width: 1)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? (color ?? AppColors.primary)
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _addSelectedToWorkout(BuildContext context, WidgetRef ref) async {
    if (workoutId == null && routineId == null) return;
    final selectedIds = ref.read(selectedExerciseIdsProvider);
    if (selectedIds.isEmpty) return;

    HapticUtils.mediumImpact();
    
    if (workoutId != null) {
      final dao = ref.read(workoutDaoProvider);
      await dao.addMultipleExercisesToWorkout(workoutId!, selectedIds.toList());
    } else if (routineId != null) {
      final dao = ref.read(routineDaoProvider);
      await dao.addMultipleExercisesToRoutine(routineId!, selectedIds.toList());
    }

    ref.read(selectedExerciseIdsProvider.notifier).state = {};

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  static const _muscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'legs', 'hamstrings', 'glutes', 'core', 'calves',
    'forearms', 'cardio', 'full_body',
  ];

  static const _equipmentTypes = [
    'barbell', 'dumbbell', 'cable', 'machine', 'bodyweight', 'kettlebell',
  ];
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.exercise,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muscleColor =
        AppColors.muscleGroupColors[exercise.primaryMuscle] ??
            AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected
            ? AppColors.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: muscleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildTag(context, _capitalize(exercise.primaryMuscle),
                              muscleColor),
                          const SizedBox(width: 6),
                          _buildTag(
                            context,
                            _capitalize(exercise.equipmentType),
                            AppColors.onSurfaceDim,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selectionMode)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceDim,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            size: 14, color: AppColors.onPrimary)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }
}
