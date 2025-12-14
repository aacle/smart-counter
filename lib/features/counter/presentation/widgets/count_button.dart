import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../services/haptic_service.dart';

/// Large touch area for counting - the main interaction zone
class CountButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool enabled;

  const CountButton({
    super.key,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<CountButton> createState() => _CountButtonState();
}

class _CountButtonState extends State<CountButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _rippleController.forward(from: 0);
    HapticService.instance.buttonFeedback();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isPressed
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.cardBackground,
            width: 2,
          ),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return Opacity(
                  opacity: 1 - _rippleController.value,
                  child: Transform.scale(
                    scale: 1 + (_rippleController.value * 0.3),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 48,
                  color: _isPressed ? AppColors.primary : AppColors.textMuted,
                )
                    .animate(
                      target: _isPressed ? 1 : 0,
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 100.ms,
                    ),
                const SizedBox(height: 16),
                Text(
                  'TAP TO COUNT',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _isPressed
                            ? AppColors.primary
                            : AppColors.textMuted,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'or use volume buttons',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
