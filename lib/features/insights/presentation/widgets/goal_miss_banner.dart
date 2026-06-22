import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../services/report_service.dart';

/// Banner showing yesterday's progress — warm, encouraging tone
class GoalMissBanner extends StatelessWidget {
  final GoalMissInfo info;
  final VoidCallback onDismiss;

  const GoalMissBanner({
    super.key,
    required this.info,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Progress circle
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: info.percentage / 100,
                  strokeWidth: 3.5,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    info.percentage >= 75
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
                Text(
                  '${info.percentage.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getSubtitle(),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Dismiss
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0);
  }

  String _getTitle() {
    if (info.percentage >= 75) {
      return 'Almost there yesterday!';
    } else if (info.percentage >= 50) {
      return 'Good effort yesterday';
    } else if (info.percentage > 0) {
      return 'Every count matters';
    } else {
      return 'Fresh start today';
    }
  }

  String _getSubtitle() {
    final unit = info.isCountGoal ? 'chants' : 'malas';
    if (info.percentage >= 75) {
      return '${info.achieved}/${info.goal} $unit \u2014 so close! Finish strong today';
    } else if (info.percentage > 0) {
      return '${info.achieved}/${info.goal} $unit \u2014 keep the momentum going';
    } else {
      return 'Today is a new opportunity to practice';
    }
  }
}
