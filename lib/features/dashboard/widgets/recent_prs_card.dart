import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/database/app_database.dart';

class RecentPRsCard extends StatelessWidget {
  final List<PersonalRecord> prs;
  final Map<int, String> exerciseNames;

  const RecentPRsCard({
    super.key,
    required this.prs,
    required this.exerciseNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.prGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.prGold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent PRs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (prs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No records yet — start lifting! 💪',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceDim,
                      ),
                ),
              ),
            )
          else
            ...prs.map((pr) => _buildPRItem(context, pr)),
        ],
      ),
    );
  }

  Widget _buildPRItem(BuildContext context, PersonalRecord pr) {
    final name = exerciseNames[pr.exerciseId] ?? 'Unknown';
    final typeLabel = _formatRecordType(pr.recordType);
    final valueStr = _formatValue(pr);
    final dateStr = DateFormat('MMM d').format(pr.achievedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.prGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceDim,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valueStr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.prGold,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRecordType(String type) {
    switch (type) {
      case 'weight':
        return 'Heaviest Lift';
      case 'volume':
        return 'Best Volume';
      case 'est_1rm':
        return 'Estimated 1RM';
      default:
        return type;
    }
  }

  String _formatValue(PersonalRecord pr) {
    switch (pr.recordType) {
      case 'weight':
        return '${pr.value.toStringAsFixed(1)} kg';
      case 'volume':
        return '${pr.value.toStringAsFixed(0)} kg';
      case 'est_1rm':
        return '${pr.value.toStringAsFixed(1)} kg';
      default:
        return pr.value.toStringAsFixed(1);
    }
  }
}
