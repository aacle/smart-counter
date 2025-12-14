import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';

/// Large counter display with breathing animation
class CounterDisplay extends StatefulWidget {
  final int count;
  final int malasCompleted;

  const CounterDisplay({
    super.key,
    required this.count,
    required this.malasCompleted,
  });

  @override
  State<CounterDisplay> createState() => _CounterDisplayState();
}

class _CounterDisplayState extends State<CounterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CounterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _previousCount = oldWidget.count;
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Malas completed
        if (widget.malasCompleted > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.malasCompleted} ${widget.malasCompleted == 1 ? 'Mala' : 'Malas'}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .shimmer(
                duration: 2000.ms,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),

        const SizedBox(height: 16),

        // Main count with breathing animation
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            final scale = 1.0 + (_breathingController.value * 0.02);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              // Slide up animation for new number
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              _formatCount(widget.count),
              key: ValueKey(widget.count),
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w200,
                letterSpacing: -2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Total label
        Text(
          'Total Count',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 10000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else if (count >= 1000) {
      return count.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return count.toString();
  }
}
