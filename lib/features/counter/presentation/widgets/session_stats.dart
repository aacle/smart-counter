import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Session statistics bar at the bottom of the screen
class SessionStats extends StatelessWidget {
  final Duration sessionDuration;
  final bool pocketModeActive;
  final VoidCallback onInsightsTap;
  final VoidCallback onResetTap;

  const SessionStats({
    super.key,
    required this.sessionDuration,
    required this.pocketModeActive,
    required this.onInsightsTap,
    required this.onResetTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.cardBackground,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Session timer
            _StatItem(
              icon: Icons.timer_outlined,
              label: _formatDuration(sessionDuration),
              color: AppColors.textSecondary,
            ),

            const Spacer(),

            // Pocket mode indicator
            if (pocketModeActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.back_hand_outlined,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pocket Mode',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Action buttons
            IconButton(
              onPressed: onResetTap,
              icon: const Icon(Icons.refresh_outlined),
              color: AppColors.textMuted,
              tooltip: 'Reset Session',
            ),
            IconButton(
              onPressed: onInsightsTap,
              icon: const Icon(Icons.bar_chart_rounded),
              color: AppColors.textMuted,
              tooltip: 'Insights',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '0:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
