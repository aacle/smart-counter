import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../settings/domain/settings_state.dart';

/// Large counter display with breathing animation
/// Adapts layout based on InterfaceMode
class CounterDisplay extends StatefulWidget {
  final int count;
  final int malasCompleted;
  final InterfaceMode interfaceMode;

  const CounterDisplay({
    super.key,
    required this.count,
    required this.malasCompleted,
    this.interfaceMode = InterfaceMode.malaWise,
  });

  @override
  State<CounterDisplay> createState() => _CounterDisplayState();
}

class _CounterDisplayState extends State<CounterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.interfaceMode == InterfaceMode.countWise) {
      return _buildCountWiseDisplay(context);
    }
    return _buildMalaWiseDisplay(context);
  }

  /// Mala-wise display - shows mala count prominently, total count secondary
  Widget _buildMalaWiseDisplay(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Malas completed badge
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
                Icon(
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
        _buildAnimatedCount(theme, fontSize: 64),

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

  /// Count-wise display - shows total count prominently, mala info secondary
  Widget _buildCountWiseDisplay(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large prominent count with breathing animation
        _buildAnimatedCount(theme, fontSize: 80, isPrimary: true),

        const SizedBox(height: 8),

        // Total label
        Text(
          'Chants',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 3,
            fontWeight: FontWeight.w300,
          ),
        ),

        const SizedBox(height: 20),

        // Mala info as secondary
        if (widget.malasCompleted > 0 || widget.count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.all_inclusive,
                  size: 18,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.malasCompleted} ${widget.malasCompleted == 1 ? 'Mala' : 'Malas'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' + ${widget.count % 108}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedCount(ThemeData theme, {double fontSize = 64, bool isPrimary = false}) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final scale = 1.0 + (_breathingController.value * 0.02);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: _buildOdometerDigits(theme, fontSize: fontSize, isPrimary: isPrimary),
    );
  }

  /// iPhone-style odometer animation - each digit animates independently
  Widget _buildOdometerDigits(ThemeData theme, {double fontSize = 64, bool isPrimary = false}) {
    final countStr = _formatCount(widget.count);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(countStr.length, (index) {
        final char = countStr[index];
        final isDigit = RegExp(r'\d').hasMatch(char);
        
        // For non-digits (comma, K, M, etc.), just show static text
        if (!isDigit) {
          return Text(
            char,
            style: theme.textTheme.displayLarge?.copyWith(
              color: isPrimary ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isPrimary ? FontWeight.w300 : FontWeight.w200,
              fontSize: fontSize,
              letterSpacing: -2,
            ),
          );
        }
        
        // For digits, use animated switcher for that position
        return _AnimatedDigit(
          digit: char,
          style: theme.textTheme.displayLarge?.copyWith(
            color: isPrimary ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isPrimary ? FontWeight.w300 : FontWeight.w200,
            fontSize: fontSize,
            letterSpacing: -2,
          ),
        );
      }),
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

/// Single animated digit with slide-up effect
class _AnimatedDigit extends StatelessWidget {
  final String digit;
  final TextStyle? style;

  const _AnimatedDigit({
    required this.digit,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          // Determine if this is the entering or exiting widget
          final isEntering = child.key == ValueKey(digit);
          
          final slideAnimation = Tween<Offset>(
            begin: isEntering 
                ? const Offset(0, 1.0)   // New digit slides up from below
                : const Offset(0, -1.0), // Old digit slides up and out
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          
          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.8), // Fade slightly faster
              ),
              child: child,
            ),
          );
        },
        child: Text(
          digit,
          key: ValueKey(digit),
          style: style,
        ),
      ),
    );
  }
}
