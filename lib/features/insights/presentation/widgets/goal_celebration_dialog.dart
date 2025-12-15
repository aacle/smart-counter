import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';

/// Celebration dialog when daily goal is achieved
class GoalCelebrationDialog extends StatelessWidget {
  final int achieved;
  final int goal;
  final bool isCountGoal;
  final int currentStreak;
  final VoidCallback onDismiss;

  const GoalCelebrationDialog({
    super.key,
    required this.achieved,
    required this.goal,
    required this.isCountGoal,
    required this.currentStreak,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.secondary.withValues(alpha: 0.15),
              AppColors.cardBackground,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration emoji with glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Text(
                  '🎉',
                  style: TextStyle(fontSize: 48),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 800.ms,
                  ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Goal Achieved!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                _getSubtitle(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              
              const SizedBox(height: 24),
              
              // Stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(
                      context,
                      '$achieved',
                      isCountGoal ? 'Chants' : 'Malas',
                      AppColors.primary,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.cardBackground,
                    ),
                    _buildStat(
                      context,
                      '$currentStreak',
                      'Day Streak',
                      AppColors.secondary,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              
              if (currentStreak > 1) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        '$currentStreak day streak!',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              ],
              
              const SizedBox(height: 24),
              
              // Message
              Text(
                _getMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
              
              const SizedBox(height: 24),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Keep Going! 🚀',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
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

  String _getSubtitle() {
    final unit = isCountGoal ? 'chants' : 'malas';
    return 'You completed $goal $unit today!';
  }

  String _getMessage() {
    if (currentStreak >= 7) {
      return '🏆 A whole week of consistency! You\'re unstoppable!';
    } else if (currentStreak >= 3) {
      return '💪 Building an amazing habit! Keep the streak alive!';
    } else {
      return '🌟 Great work today! See you tomorrow!';
    }
  }
}
