import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Displays either "Auto Mode Active" badge or "Tap to count" hint
class TapInstruction extends StatelessWidget {
  final bool isAutoCountActive;

  const TapInstruction({
    super.key,
    required this.isAutoCountActive,
  });

  @override
  Widget build(BuildContext context) {
    if (isAutoCountActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.autorenew,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            Text(
              'Auto Mode Active',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app,
          size: 20,
          color: AppColors.textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          'Tap to count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
