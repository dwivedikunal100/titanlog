import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/core/utils/haptic_utils.dart';
import 'package:titanlog/features/analytics/providers/analytics_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);
    final restDefault = ref.watch(restTimerDefaultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Units'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildUnitOption(context, ref, 'kg', unit == 'kg'),
                _buildUnitOption(context, ref, 'lbs', unit == 'lbs'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Default Rest Timer'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [60, 90, 120, 180].map((seconds) {
                final isSelected = restDefault == seconds;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticUtils.selectionClick();
                      ref.read(restTimerDefaultProvider.notifier).state =
                          seconds;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'About'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TITAN',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                    ),
                    Text(
                      'LOG',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: AppColors.onSurface,
                            letterSpacing: 2,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceDim,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Built with 💪 for lifters who demand speed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceDim,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildUnitOption(
      BuildContext context, WidgetRef ref, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtils.selectionClick();
          ref.read(weightUnitProvider.notifier).state = label;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
