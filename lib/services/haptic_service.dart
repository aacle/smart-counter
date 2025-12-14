import 'package:vibration/vibration.dart';
import '../core/constants/app_constants.dart';

/// Haptic feedback service for spiritual counting
/// Provides tactile feedback so users can count without looking
class HapticService {
  static HapticService? _instance;
  bool _hasVibrator = false;
  bool _hasAmplitudeControl = false;

  HapticService._();

  static HapticService get instance {
    _instance ??= HapticService._();
    return _instance!;
  }

  /// Initialize and check device vibration capabilities
  Future<void> initialize() async {
    _hasVibrator = await Vibration.hasVibrator() == true;
    _hasAmplitudeControl = await Vibration.hasAmplitudeControl() == true;
  }

  /// Trigger haptic feedback based on count position
  Future<void> onCount(int count) async {
    if (!_hasVibrator) return;

    final positionInMala = count % kMalaSize;

    if (positionInMala == 0 && count > 0) {
      // 🎉 MALA COMPLETE! Strong celebration pattern
      await _malaCompleteVibration();
    } else if (positionInMala % kQuarterMala == 0 && positionInMala > 0) {
      // Quarter mala (27, 54, 81) - medium feedback
      await _quarterMalaVibration();
    } else if (count % kHapticMilestone == 0) {
      // Every 10th count - noticeable feedback
      await _milestoneVibration();
    } else {
      // Normal count - subtle tap
      await _countVibration();
    }
  }

  /// Light tap for each count
  Future<void> _countVibration() async {
    if (_hasAmplitudeControl) {
      await Vibration.vibrate(duration: 10, amplitude: 64);
    } else {
      await Vibration.vibrate(duration: 10);
    }
  }

  /// Medium feedback for every 10th count
  Future<void> _milestoneVibration() async {
    if (_hasAmplitudeControl) {
      await Vibration.vibrate(duration: 30, amplitude: 128);
    } else {
      await Vibration.vibrate(duration: 30);
    }
  }

  /// Strong feedback for quarter mala (27, 54, 81)
  Future<void> _quarterMalaVibration() async {
    if (_hasAmplitudeControl) {
      await Vibration.vibrate(duration: 50, amplitude: 192);
    } else {
      await Vibration.vibrate(duration: 50);
    }
  }

  /// Celebration pattern for completing a mala (108)
  Future<void> _malaCompleteVibration() async {
    // Pattern: short-pause-short-pause-long
    final intensities = _hasAmplitudeControl 
        ? [0, 255, 0, 255, 0, 255] 
        : <int>[];
    await Vibration.vibrate(
      pattern: [0, 100, 50, 100, 50, 300],
      intensities: intensities,
    );
  }

  /// Simple vibration for button feedback
  Future<void> buttonFeedback() async {
    if (!_hasVibrator) return;
    if (_hasAmplitudeControl) {
      await Vibration.vibrate(duration: 5, amplitude: 64);
    } else {
      await Vibration.vibrate(duration: 5);
    }
  }
}
