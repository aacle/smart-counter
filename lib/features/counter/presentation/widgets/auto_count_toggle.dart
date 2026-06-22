import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../settings/providers/settings_provider.dart';

/// Auto-count toggle bar — collapsed by default, expands to show speed controls.
class AutoCountToggle extends ConsumerStatefulWidget {
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onInfoTap;

  const AutoCountToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
    required this.onInfoTap,
  });

  /// Available speed steps
  static const List<double> speedSteps = [0.25, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];

  /// Format speed for display (e.g., 0.25s, 0.5s, 1s, 1.5s)
  static String formatSpeed(double speed) {
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()}s';
    }
    return '${speed}s';
  }

  /// Decrease speed to the previous step
  static double decreaseSpeed(double currentSpeed) {
    final currentIndex = speedSteps.indexOf(currentSpeed);
    if (currentIndex == -1) {
      for (int i = speedSteps.length - 1; i >= 0; i--) {
        if (speedSteps[i] < currentSpeed) return speedSteps[i];
      }
      return speedSteps.first;
    }
    return currentIndex > 0 ? speedSteps[currentIndex - 1] : speedSteps.first;
  }

  /// Increase speed to the next step
  static double increaseSpeed(double currentSpeed) {
    final currentIndex = speedSteps.indexOf(currentSpeed);
    if (currentIndex == -1) {
      for (int i = 0; i < speedSteps.length; i++) {
        if (speedSteps[i] > currentSpeed) return speedSteps[i];
      }
      return speedSteps.last;
    }
    return currentIndex < speedSteps.length - 1 ? speedSteps[currentIndex + 1] : speedSteps.last;
  }

  @override
  ConsumerState<AutoCountToggle> createState() => _AutoCountToggleState();
}

class _AutoCountToggleState extends ConsumerState<AutoCountToggle>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant AutoCountToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when auto-count becomes active
    if (widget.isActive && !oldWidget.isActive) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isActive = widget.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsed header — always visible
          GestureDetector(
            onTap: isActive ? null : () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew,
                    size: 20,
                    color: isActive ? AppColors.success : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isActive
                          ? 'Auto Chant \u2022 Every ${AutoCountToggle.formatSpeed(settings.autoCountSpeed)}'
                          : 'Auto Chant',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isActive ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!_isExpanded && !isActive)
                    Icon(
                      Icons.expand_more,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  if (_isExpanded || isActive) ...[
                    // Start/Stop button in header when expanded
                    ElevatedButton(
                      onPressed: widget.onToggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.red.shade400
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        isActive ? 'Stop' : 'Start',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded controls — speed selector + info
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onInfoTap,
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Speed:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Speed controls (only when not active to prevent mid-session changes)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: isActive
                        ? null
                        : settings.autoCountSpeed > 0.25
                            ? () => ref.read(settingsProvider.notifier)
                                .setAutoCountSpeed(AutoCountToggle.decreaseSpeed(settings.autoCountSpeed))
                            : null,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      AutoCountToggle.formatSpeed(settings.autoCountSpeed),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    color: AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: isActive
                        ? null
                        : settings.autoCountSpeed < 5.0
                            ? () => ref.read(settingsProvider.notifier)
                                .setAutoCountSpeed(AutoCountToggle.increaseSpeed(settings.autoCountSpeed))
                            : null,
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded || isActive
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
