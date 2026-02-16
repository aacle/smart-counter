import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Beautiful branded card widget for sharing practice progress
class ShareableReportCard extends StatelessWidget {
  final String periodTitle;
  final int totalChants;
  final int totalMalas;
  final int streak;
  final int daysGoalMet;
  final int totalDays;
  final double achievementRate;
  final bool isCountGoal;

  const ShareableReportCard({
    super.key,
    required this.periodTitle,
    required this.totalChants,
    required this.totalMalas,
    this.streak = 0,
    this.daysGoalMet = 0,
    this.totalDays = 7,
    this.achievementRate = 0,
    this.isCountGoal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App branding header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🙏', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Smart Naam Jap',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Period title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              periodTitle,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: AppColors.surface,
          ),

          const SizedBox(height: 20),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('📿', '$totalMalas', 'Malas'),
              _buildStat('🔢', _formatNumber(totalChants), 'Chants'),
              if (streak > 0) _buildStat('🔥', '$streak', 'Streak'),
            ],
          ),

          if (daysGoalMet > 0) ...[
            const SizedBox(height: 20),
            // Goal achievement
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: achievementRate >= 0.7
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    achievementRate >= 0.85 ? '🏆' : (achievementRate >= 0.7 ? '⭐' : '🎯'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Goal Met $daysGoalMet/$totalDays days  •  ${(achievementRate * 100).toInt()}%',
                    style: TextStyle(
                      color: achievementRate >= 0.7 ? AppColors.success : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Footer
          Text(
            'smartnaamjap.app',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
