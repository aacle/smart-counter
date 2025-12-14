import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

/// Service for playing tick sounds/feedback during auto-count
class SoundService {
  static SoundService? _instance;
  
  bool _hasVibrator = false;

  SoundService._();

  static SoundService get instance {
    _instance ??= SoundService._();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator() == true;
    } catch (e) {
      _hasVibrator = false;
    }
  }

  /// Play a short tick feedback for auto-count
  /// Uses vibration + system haptic for noticeable feedback
  Future<void> playTick() async {
    try {
      // Strong vibration that user can feel and hear
      if (_hasVibrator) {
        await Vibration.vibrate(duration: 30, amplitude: 200);
      }
      // Also trigger haptic feedback
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Fallback to light impact
      await HapticFeedback.lightImpact();
    }
  }

  /// Play a completion feedback for mala
  Future<void> playComplete() async {
    try {
      if (_hasVibrator) {
        // Celebration pattern
        await Vibration.vibrate(
          pattern: [0, 100, 50, 100, 50, 200],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
      await HapticFeedback.heavyImpact();
    } catch (e) {
      await HapticFeedback.heavyImpact();
    }
  }

  void dispose() {
    // Nothing to dispose
  }
}
