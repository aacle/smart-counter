import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'haptic_service.dart';
import '../core/utils/app_logger.dart';

/// Service for playing sounds and coordinating audio + haptic feedback
/// All vibration is delegated to HapticService
class SoundService {
  static final SoundService instance = SoundService._();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final HapticService _hapticService = HapticService.instance;

  SoundService._();

  Future<void> initialize() async {
    try {
      // Configure audio player for low latency and set release mode
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      // Preload the tap sound to reduce latency
      await _audioPlayer.setSource(AssetSource('sounds/tap.mp3'));
    } catch (e, stackTrace) {
      AppLogger.error('SoundService', 'Failed to preload tap sound', e, stackTrace);
    }
  }

  /// Play tap sound
  Future<void> playTapSound() async {
    try {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();
      }
      
      // Use low latency mode and don't await the completion to prevent blocking/timeouts
      // on fast successive taps
      _audioPlayer.play(
        AssetSource('sounds/tap.mp3'), 
        mode: PlayerMode.lowLatency,
      ).catchError((e) {
        SystemSound.play(SystemSoundType.click);
      });
    } catch (e, stackTrace) {
      AppLogger.error('SoundService', 'Failed to play tap sound, falling back to system click', e, stackTrace);
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play a short tick feedback for auto-count
  /// Delegates vibration to HapticService
  Future<void> playTick() async {
    await _hapticService.autoCountTick();
  }

  /// Play completion feedback for mala
  /// Note: Haptic vibration for mala completion is handled directly by HapticService.onCount()
  /// to ensure perfect timing with the 108th tap. This function is currently unused but
  /// kept for future sound integration.
  Future<void> playComplete() async {
    // We explicitly do NOT call _hapticService.celebrationFeedback() here anymore
    // to prevent double/early vibrations.
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
