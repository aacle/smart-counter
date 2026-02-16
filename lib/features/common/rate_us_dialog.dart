import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../services/feedback_service.dart';

/// Beautiful custom Rate Us dialog
class RateUsDialog extends StatelessWidget {
  const RateUsDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RateUsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Star emojis row
                  const Text(
                    '⭐⭐⭐⭐⭐',
                    style: TextStyle(fontSize: 28),
                  ).animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 500.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 16),

                  Text(
                    'Enjoying Smart Naam Jap?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  Text(
                    'Your journey of devotion inspires us. A quick rating helps others discover this app and strengthens our community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 250.ms),

                  const SizedBox(height: 24),

                  // Rate Us button (primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        FeedbackService().openStoreForRating();
                        FeedbackService().markAsRated();
                      },
                      icon: const Icon(Icons.star_rounded, size: 20),
                      label: const Text('Rate Us on Play Store'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 350.ms)
                    .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 10),

                  // Not Now & Never row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            FeedbackService().postponeRating();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Maybe Later', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: AppColors.surface,
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            FeedbackService().neverAskAgain();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Don't Ask Again", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms, delay: 450.ms),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
