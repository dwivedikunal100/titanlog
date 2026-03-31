import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../database/app_database.dart';
import '../../providers/database_providers.dart';
import 'workout_editor_screen.dart'; // To be created

class WorkoutDetailScreen extends ConsumerWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutDao = ref.read(workoutDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          workout.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutEditorScreen(workoutId: workout.id),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: workoutDao.watchWorkoutExercises(workout.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final exercises = snapshot.data!;

          if (exercises.isEmpty) {
            return const Center(child: Text('No exercises found in this workout.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exc = exercises[index];
              return Card(
                color: AppColors.surfaceContainer,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exc.exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      if (exc.sets.isEmpty) const Text('No sets recorded.'),
                      ...exc.sets.map((set) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Set ${set.setNumber}', style: const TextStyle(color: AppColors.chartLine1)),
                              Text('${set.weight} kg  ×  ${set.reps} reps', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
