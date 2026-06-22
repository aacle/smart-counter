import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/colors.dart';

/// 108-bead mala visualization with smooth animated glow
/// Uses CustomPainter for smooth rendering
class MalaBeads extends StatefulWidget {
  final int currentCount;
  final double size;
  final bool showCelebration;
  final String? centerImagePath;

  const MalaBeads({
    super.key,
    required this.currentCount,
    this.size = 300,
    this.showCelebration = false,
    this.centerImagePath,
  });

  @override
  State<MalaBeads> createState() => _MalaBeadsState();
}

class _MalaBeadsState extends State<MalaBeads>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  int _previousBead = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _previousBead = widget.currentCount % kMalaSize;
    _positionAnimation = AlwaysStoppedAnimation(_previousBead.toDouble());
  }

  @override
  void didUpdateWidget(MalaBeads oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newBead = widget.currentCount % kMalaSize;

    if (newBead != _previousBead) {
      double startPos = _previousBead.toDouble();
      double endPos = newBead.toDouble();

      // Handle wrap-around: when going from 107 to 0, continue forward
      if (_previousBead > 100 && newBead == 0) {
        // Complete the circle by going to 108 (same as 0)
        endPos = kMalaSize.toDouble();
      }

      _positionAnimation = Tween<double>(
        begin: startPos,
        end: endPos,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));

      _animationController.forward(from: 0).then((_) {
        // After animation completes, reset to actual position
        if (endPos >= kMalaSize) {
          _positionAnimation = AlwaysStoppedAnimation(0);
        }
      });

      _previousBead = newBead;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          // Smooth animated glow ball
          AnimatedBuilder(
            animation: _positionAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _BeadGlowPainter(
                  currentBead: currentBead,
                  animatedPosition: _positionAnimation.value % kMalaSize,
                  glowIntensity: 0.6,
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
          // Center content with optional deity image
          _buildCenterContent(context, currentBead),
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

  Widget _buildCenterContent(BuildContext context, int currentBead) {
    final hasImage = widget.centerImagePath != null &&
        File(widget.centerImagePath!).existsSync();

    // Calculate the inner circle size - fills the bead circle
    final innerSize = widget.size * 0.72;

    // If image is set, show only the image (no count text)
    if (hasImage) {
      return Container(
        width: innerSize,
        height: innerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(File(widget.centerImagePath!)),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }

    // Default: show count text (no image)
    return SizedBox(
      width: innerSize,
      height: innerSize,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    // Slightly tighter circle
    final radius = (size.width / 2) - 16;
    // Slightly smaller beads for cleaner look
    final beadRadius = (radius * math.pi * 2) / (kMalaSize * 3.5);
    final completedInCurrentMala =
        completedBeads > 0 && completedBeads % kMalaSize == 0
            ? kMalaSize
            : completedBeads % kMalaSize;

    // Paint each bead
    for (int i = 0; i < kMalaSize; i++) {
      final angle = (i / kMalaSize) * 2 * math.pi - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final isCurrentBead = i == currentBead;
      final isCompleted = i < completedInCurrentMala;
      final isQuarterMark = i % kQuarterMala == 0;

      // Bead paint
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isCurrentBead
            ? AppColors.beadActive
            : isCompleted
                ? AppColors.beadActive.withValues(alpha: 0.6)
                : AppColors.beadInactive;

      // Draw bead - subtle quarter marks (only 10% larger, not 30%)
      final actualBeadRadius = isQuarterMark ? beadRadius * 1.1 : beadRadius;
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
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(
        Rect.fromCircle(
            center: Offset(center.dx, center.dy - radius),
            radius: beadRadius * 2),
      );

    // Draw the Sumeru bead (head bead) at the top - smaller
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius),
      beadRadius * 1.5,
      sumeruPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MalaBeadsPainter oldDelegate) {
    return oldDelegate.currentBead != currentBead ||
        oldDelegate.completedBeads != completedBeads;
  }
}

/// Custom painter for the glow effect with smooth animation
class _BeadGlowPainter extends CustomPainter {
  final int currentBead;
  final double animatedPosition;
  final double glowIntensity;

  _BeadGlowPainter({
    required this.currentBead,
    this.animatedPosition = 0,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Match radius from beads painter
    final radius = (size.width / 2) - 16;

    // Use animatedPosition for smooth movement
    final position = animatedPosition;
    final angle = (position / kMalaSize) * 2 * math.pi - (math.pi / 2);
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);

    // Outer glow
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppColors.glow.withValues(alpha: glowIntensity),
          AppColors.glow.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(x, y), radius: 18),
      );
    canvas.drawCircle(Offset(x, y), 18, glowPaint);

    // Border ring around the glow ball
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppColors.primary;
    canvas.drawCircle(Offset(x, y), 10, borderPaint);

    // Solid center dot
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary;
    canvas.drawCircle(Offset(x, y), 5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _BeadGlowPainter oldDelegate) {
    return oldDelegate.currentBead != currentBead ||
        oldDelegate.animatedPosition != animatedPosition ||
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
    );
  }
}
