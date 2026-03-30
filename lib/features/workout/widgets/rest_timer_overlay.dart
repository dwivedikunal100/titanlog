import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/core/utils/haptic_utils.dart';
import 'package:titanlog/features/workout/providers/workout_providers.dart';

class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: timer.progress,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  color: timer.remainingSeconds <= 10
                      ? AppColors.warning
                      : AppColors.primary,
                  strokeWidth: 3,
                ),
                Center(
                  child: Icon(
                    Icons.timer_outlined,
                    color: timer.remainingSeconds <= 10
                        ? AppColors.warning
                        : AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rest Timer',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceDim,
                      ),
                ),
                Text(
                  timer.displayTime,
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: timer.remainingSeconds <= 10
                                ? AppColors.warning
                                : AppColors.onSurface,
                            fontFeatures: [
                              const FontFeature.tabularFigures(),
                            ],
                          ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimerButton(
                icon: Icons.remove,
                onTap: () {
                  if (timer.remainingSeconds > 15) {
                    ref.read(restTimerProvider.notifier).startTimer(
                        seconds: timer.remainingSeconds - 15);
                  }
                },
              ),
              const SizedBox(width: 8),
              _TimerButton(
                icon: Icons.add,
                onTap: () {
                  ref.read(restTimerProvider.notifier).startTimer(
                      seconds: timer.remainingSeconds + 15);
                },
              ),
              const SizedBox(width: 8),
              _TimerButton(
                icon: Icons.close,
                color: AppColors.error,
                onTap: () {
                  HapticUtils.buttonTap();
                  ref.read(restTimerProvider.notifier).stopTimer();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _TimerButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.selectionClick();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}
