import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/core/utils/haptic_utils.dart';
import 'package:titanlog/database/app_database.dart';
import 'package:titanlog/features/providers/database_providers.dart';

class SetRow extends ConsumerStatefulWidget {
  final ExerciseSet set_;
  final int exerciseId;
  final int workoutExerciseId;
  final VoidCallback onCompleted;

  const SetRow({
    super.key,
    required this.set_,
    required this.exerciseId,
    required this.workoutExerciseId,
    required this.onCompleted,
  });

  @override
  ConsumerState<SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<SetRow>
    with SingleTickerProviderStateMixin {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set_.weight > 0
          ? widget.set_.weight.toStringAsFixed(
              widget.set_.weight == widget.set_.weight.roundToDouble()
                  ? 0
                  : 1)
          : '',
    );
    _repsController = TextEditingController(
      text: widget.set_.reps > 0 ? widget.set_.reps.toString() : '',
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.set_.isCompleted;

    return Dismissible(
      key: ValueKey(widget.set_.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withValues(alpha: 0.2),
        child: const Icon(Icons.delete_outline,
            color: AppColors.error, size: 20),
      ),
      onDismissed: (_) {
        HapticUtils.swipeAction();
        ref.read(setDaoProvider).deleteSet(widget.set_.id);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.successContainer.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${widget.set_.setNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceDim,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                height: 36,
                child: TextField(
                  controller: _weightController,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: isCompleted
                        ? Colors.transparent
                        : AppColors.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '0',
                    hintStyle: const TextStyle(
                        color: AppColors.onSurfaceDim, fontSize: 14),
                  ),
                  enabled: !isCompleted,
                  onChanged: (value) => _updateWeight(value),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 36,
                child: TextField(
                  controller: _repsController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: isCompleted
                        ? Colors.transparent
                        : AppColors.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '0',
                    hintStyle: const TextStyle(
                        color: AppColors.onSurfaceDim, fontSize: 14),
                  ),
                  enabled: !isCompleted,
                  onChanged: (value) => _updateReps(value),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: isCompleted ? null : () => _completeSet(),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isCompleted
                        ? const Icon(Icons.check_circle,
                            key: ValueKey('done'),
                            color: AppColors.success,
                            size: 24)
                        : const Icon(Icons.check_circle_outline,
                            key: ValueKey('pending'),
                            color: AppColors.onSurfaceDim,
                            size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateWeight(String value) {
    final weight = double.tryParse(value) ?? 0;
    ref.read(setDaoProvider).updateSet(
          widget.set_.copyWith(weight: weight),
        );
  }

  void _updateReps(String value) {
    final reps = int.tryParse(value) ?? 0;
    ref.read(setDaoProvider).updateSet(
          widget.set_.copyWith(reps: reps),
        );
  }

  void _completeSet() async {
    HapticUtils.setCompleted();
    _animController.forward().then((_) => _animController.reverse());

    final dao = ref.read(setDaoProvider);
    await dao.completeSet(widget.set_.id);

    final updatedSet = widget.set_.copyWith(
      isCompleted: true,
      completedAt: Value(DateTime.now()),
      weight:
          double.tryParse(_weightController.text) ?? widget.set_.weight,
      reps: int.tryParse(_repsController.text) ?? widget.set_.reps,
    );

    final pr =
        await dao.checkAndRecordPR(widget.exerciseId, updatedSet);

    if (pr != null && mounted) {
      HapticUtils.prAchieved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.emoji_events,
                  color: AppColors.prGold, size: 20),
              SizedBox(width: 8),
              Text('🎉 New Personal Record!'),
            ],
          ),
          backgroundColor: AppColors.prGoldContainer,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    widget.onCompleted();
  }
}
