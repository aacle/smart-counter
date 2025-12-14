import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/colors.dart';

/// Beautiful animated 108-bead mala visualization
/// Uses CustomPainter for smooth 60fps rendering
class MalaBeads extends StatefulWidget {
  final int currentCount;
  final double size;
  final bool showCelebration;

  const MalaBeads({
    super.key,
    required this.currentCount,
    this.size = 300,
    this.showCelebration = false,
  });

  @override
  State<MalaBeads> createState() => _MalaBeadsState();
}

class _MalaBeadsState extends State<MalaBeads>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentBead = widget.currentCount % kMalaSize;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect behind current bead
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _BeadGlowPainter(
                  currentBead: currentBead,
                  glowIntensity: 0.3 + (_glowController.value * 0.4),
                ),
              );
            },
          ),
          // Main beads
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MalaBeadsPainter(
              currentBead: currentBead,
              completedBeads: widget.currentCount,
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current count within mala
              Text(
                '${currentBead == 0 && widget.currentCount > 0 ? kMalaSize : currentBead}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w300,
                    ),
              ),
              Text(
                'of $kMalaSize',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          // Celebration overlay
          if (widget.showCelebration)
            const _CelebrationOverlay()
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }
}

/// Custom painter for the mala beads
class _MalaBeadsPainter extends CustomPainter {
  final int currentBead;
  final int completedBeads;

  _MalaBeadsPainter({
    required this.currentBead,
    required this.completedBeads,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 20;
    final beadRadius = (radius * math.pi * 2) / (kMalaSize * 3);

    // Paint each bead
    for (int i = 0; i < kMalaSize; i++) {
      final angle = (i / kMalaSize) * 2 * math.pi - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final isCurrentBead = i == currentBead;
      final isCompleted = i < currentBead || completedBeads >= kMalaSize;
      final isQuarterMark = i % kQuarterMala == 0;

      // Bead paint
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isCurrentBead
            ? AppColors.beadActive
            : isCompleted
                ? AppColors.beadActive.withValues(alpha: 0.6)
                : AppColors.beadInactive;

      // Draw bead
      final actualBeadRadius =
          isQuarterMark ? beadRadius * 1.3 : beadRadius;
      canvas.drawCircle(Offset(x, y), actualBeadRadius, paint);

      // Draw highlight on current bead
      if (isCurrentBead) {
        final highlightPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: 0.3);
        canvas.drawCircle(
          Offset(x - beadRadius * 0.2, y - beadRadius * 0.2),
          beadRadius * 0.3,
          highlightPaint,
        );
      }
    }

    // Draw the Sumeru bead (head bead) at the top
    final sumeruPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(
        Rect.fromCircle(center: Offset(center.dx, center.dy - radius), radius: beadRadius * 2),
      );

    canvas.drawCircle(
      Offset(center.dx, center.dy - radius),
      beadRadius * 2,
      sumeruPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MalaBeadsPainter oldDelegate) {
    return oldDelegate.currentBead != currentBead ||
        oldDelegate.completedBeads != completedBeads;
  }
}

/// Custom painter for the glow effect
class _BeadGlowPainter extends CustomPainter {
  final int currentBead;
  final double glowIntensity;

  _BeadGlowPainter({
    required this.currentBead,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 20;

    final angle = (currentBead / kMalaSize) * 2 * math.pi - (math.pi / 2);
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppColors.glow.withValues(alpha: glowIntensity),
          AppColors.glow.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(x, y), radius: 30),
      );

    canvas.drawCircle(Offset(x, y), 30, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _BeadGlowPainter oldDelegate) {
    return oldDelegate.currentBead != currentBead ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

/// Celebration overlay for mala completion
class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.3),
            AppColors.success.withValues(alpha: 0),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppColors.success.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
