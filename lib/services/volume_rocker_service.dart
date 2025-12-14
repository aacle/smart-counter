import 'dart:async';
import 'package:volume_controller/volume_controller.dart';

/// Service to detect volume button presses for counting
/// Allows users to count with phone in pocket
class VolumeRockerService {
  static VolumeRockerService? _instance;
  
  VolumeController? _controller;
  StreamController<void>? _countStreamController;
  
  double _baseVolume = 0.5;
  bool _isListening = false;
  DateTime? _lastTrigger;
  
  /// Debounce duration to prevent rapid triggers
  static const _debounceMs = 150;

  VolumeRockerService._();

  static VolumeRockerService get instance {
    _instance ??= VolumeRockerService._();
    return _instance!;
  }

  /// Stream that emits when a volume button is pressed
  Stream<void> get countStream {
    _countStreamController ??= StreamController<void>.broadcast();
    return _countStreamController!.stream;
  }

  /// Start listening for volume button presses
  Future<void> startListening() async {
    if (_isListening) return;
    
    _isListening = true;
    
    // Create new controller instance
    _controller = VolumeController();
    
    // Hide system volume UI (may not work on all devices)
    _controller!.showSystemUI = false;
    
    // Get current volume as baseline - use middle value for best detection
    try {
      _baseVolume = await _controller!.getVolume();
      // If volume is at extremes, move it to allow detection both ways
      if (_baseVolume < 0.1) {
        _baseVolume = 0.5;
        _controller!.setVolume(_baseVolume, showSystemUI: false);
      } else if (_baseVolume > 0.9) {
        _baseVolume = 0.5;
        _controller!.setVolume(_baseVolume, showSystemUI: false);
      }
    } catch (e) {
      _baseVolume = 0.5;
    }
    
    // Listen for volume changes
    _controller!.listener((volume) {
      _onVolumeChange(volume);
    });
  }

  /// Stop listening for volume button presses
  void stopListening() {
    _isListening = false;
    
    if (_controller != null) {
      // Restore system UI
      _controller!.showSystemUI = true;
      _controller!.removeListener();
      _controller = null;
    }
  }

  void _onVolumeChange(double newVolume) {
    if (!_isListening || _controller == null) return;
    
    // Debounce rapid changes
    final now = DateTime.now();
    if (_lastTrigger != null &&
        now.difference(_lastTrigger!).inMilliseconds < _debounceMs) {
      // Still reset volume even during debounce to prevent sound changes
      _resetVolumeQuietly();
      return;
    }
    
    // Detect any volume change (up or down)
    final diff = (newVolume - _baseVolume).abs();
    if (diff > 0.005) {
      _lastTrigger = now;
      
      // Emit count event
      _countStreamController?.add(null);
      
      // Immediately reset volume to baseline
      _resetVolumeQuietly();
    }
  }

  void _resetVolumeQuietly() {
    if (_controller != null && _isListening) {
      // Reset volume without showing UI
      _controller!.setVolume(_baseVolume, showSystemUI: false);
    }
  }

  /// Check if volume rocker service is available
  Future<bool> isAvailable() async {
    try {
      final controller = VolumeController();
      await controller.getVolume();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _countStreamController?.close();
    _countStreamController = null;
  }
}
