import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/haptic_service.dart';
import '../domain/counter_state.dart';

/// Provider for the counter state
final counterProvider =
    StateNotifierProvider<CounterNotifier, CounterState>((ref) {
  return CounterNotifier();
});

/// Provider for lifetime statistics
final lifetimeStatsProvider = FutureProvider<LifetimeStats>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LifetimeStats(
    totalCounts: prefs.getInt('lifetime_counts') ?? 0,
    totalMalas: prefs.getInt('lifetime_malas') ?? 0,
    totalSessions: prefs.getInt('lifetime_sessions') ?? 0,
  );
});

/// Lifetime statistics
class LifetimeStats {
  final int totalCounts;
  final int totalMalas;
  final int totalSessions;

  const LifetimeStats({
    required this.totalCounts,
    required this.totalMalas,
    required this.totalSessions,
  });
}

/// Inactivity timeout - after this many seconds without a tap, jap timer pauses
const int kJapInactivityTimeoutSeconds = 5;

/// Counter state notifier with persistence
class CounterNotifier extends StateNotifier<CounterState> {
  CounterNotifier() : super(CounterState.initial()) {
    _loadState();
    _initHaptics();
  }

  final HapticService _haptics = HapticService.instance;

  Future<void> _initHaptics() async {
    await _haptics.initialize();
  }

  /// Load saved state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('counter_state');
      if (stateJson != null) {
        final json = jsonDecode(stateJson) as Map<String, dynamic>;
        final loadedState = CounterState.fromJson(json);
        
        // Check if session is from a previous day
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final sessionDate = DateTime(
          loadedState.sessionStartTime.year,
          loadedState.sessionStartTime.month,
          loadedState.sessionStartTime.day,
        );
        
        if (sessionDate.isBefore(today)) {
          // Session is from a previous day - save to lifetime stats and reset
          if (loadedState.count > 0) {
            final currentLifetimeCounts = prefs.getInt('lifetime_counts') ?? 0;
            final currentLifetimeMalas = prefs.getInt('lifetime_malas') ?? 0;
            final currentLifetimeSessions = prefs.getInt('lifetime_sessions') ?? 0;
            
            await prefs.setInt('lifetime_counts', currentLifetimeCounts + loadedState.count);
            await prefs.setInt('lifetime_malas', currentLifetimeMalas + loadedState.sessionMalas);
            await prefs.setInt('lifetime_sessions', currentLifetimeSessions + 1);
          }
          
          // Start fresh for today
          state = CounterState.initial();
          await _saveState();
        } else {
          // Same day - restore the session but clear lastCountTime 
          // (timer should not auto-resume from a previous app open)
          state = loadedState.copyWith(clearLastCountTime: true);
        }
      }
    } catch (e) {
      // If loading fails, start fresh
      state = CounterState.initial();
    }
  }

  /// Save current state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('counter_state', jsonEncode(state.toJson()));
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Increment the counter and track jap time
  Future<void> increment() async {
    final now = DateTime.now();
    final newCount = state.count + 1;
    final newMalas = newCount ~/ kMalaSize;
    final previousMalas = state.count ~/ kMalaSize;

    // Calculate jap time to accumulate
    Duration newAccumulated = state.accumulatedJapDuration;
    if (state.lastCountTime != null) {
      final elapsed = now.difference(state.lastCountTime!);
      // Only add time if within inactivity timeout
      if (elapsed.inSeconds <= kJapInactivityTimeoutSeconds) {
        newAccumulated += elapsed;
      }
    }

    state = state.copyWith(
      count: newCount,
      totalMalasCompleted: newMalas > previousMalas
          ? state.totalMalasCompleted + 1
          : state.totalMalasCompleted,
      accumulatedJapDuration: newAccumulated,
      lastCountTime: now,
    );

    // Auto-save periodically
    if (newCount % 10 == 0) {
      await _saveState();
    }
  }

  /// Get current jap duration in seconds (for saving to insights)
  int get japDurationSeconds => state.sessionDuration.inSeconds;

  /// Pause the jap timer (called when app is backgrounded)
  void pauseJapTimer() {
    if (state.lastCountTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(state.lastCountTime!);
      Duration newAccumulated = state.accumulatedJapDuration;
      
      // Add any remaining active time (if within timeout)
      if (elapsed.inSeconds <= kJapInactivityTimeoutSeconds) {
        newAccumulated += elapsed;
      }
      
      state = state.copyWith(
        accumulatedJapDuration: newAccumulated,
        clearLastCountTime: true,
      );
    }
  }

  /// Reset the current session
  Future<void> resetSession() async {
    // Save lifetime stats before reset
    await _updateLifetimeStats();

    state = CounterState.initial();
    await _saveState();
  }

  /// Update lifetime statistics
  Future<void> _updateLifetimeStats() async {
    final prefs = await SharedPreferences.getInstance();

    final currentLifetimeCounts = prefs.getInt('lifetime_counts') ?? 0;
    final currentLifetimeMalas = prefs.getInt('lifetime_malas') ?? 0;
    final currentLifetimeSessions = prefs.getInt('lifetime_sessions') ?? 0;

    await prefs.setInt('lifetime_counts', currentLifetimeCounts + state.count);
    await prefs.setInt(
        'lifetime_malas', currentLifetimeMalas + state.sessionMalas);
    await prefs.setInt('lifetime_sessions', currentLifetimeSessions + 1);
  }

  /// End the current session and save stats
  Future<void> endSession() async {
    pauseJapTimer();
    state = state.copyWith(isSessionActive: false);
    await _updateLifetimeStats();
    await _saveState();
  }

  /// Force save current state
  Future<void> saveNow() async {
    await _saveState();
  }
}
