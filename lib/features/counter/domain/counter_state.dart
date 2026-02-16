import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

/// Immutable state for the counter
@immutable
class CounterState {
  final int count;
  final int totalMalasCompleted;
  final DateTime sessionStartTime;
  final bool isSessionActive;
  final Duration accumulatedJapDuration;
  final DateTime? lastCountTime;

  const CounterState({
    required this.count,
    required this.totalMalasCompleted,
    required this.sessionStartTime,
    required this.isSessionActive,
    this.accumulatedJapDuration = Duration.zero,
    this.lastCountTime,
  });

  /// Initial state for a new session
  factory CounterState.initial() {
    return CounterState(
      count: 0,
      totalMalasCompleted: 0,
      sessionStartTime: DateTime.now(),
      isSessionActive: true,
      accumulatedJapDuration: Duration.zero,
      lastCountTime: null,
    );
  }

  /// Current position within the mala (0-107)
  int get positionInMala => count % kMalaSize;

  /// Progress through current mala (0.0 - 1.0)
  double get malaProgress => positionInMala / kMalaSize;

  /// Total malas completed in this session (including partial)
  int get sessionMalas => count ~/ kMalaSize;

  /// Session duration - returns accumulated jap time only
  Duration get sessionDuration {
    if (lastCountTime == null) return accumulatedJapDuration;
    
    // If last count was within 5 seconds, add the tail time
    final now = DateTime.now();
    final timeSinceLastCount = now.difference(lastCountTime!);
    if (timeSinceLastCount.inSeconds <= 5) {
      return accumulatedJapDuration + timeSinceLastCount;
    }
    
    return accumulatedJapDuration;
  }

  /// Create a copy with updated values
  CounterState copyWith({
    int? count,
    int? totalMalasCompleted,
    DateTime? sessionStartTime,
    bool? isSessionActive,
    Duration? accumulatedJapDuration,
    DateTime? lastCountTime,
    bool clearLastCountTime = false,
  }) {
    return CounterState(
      count: count ?? this.count,
      totalMalasCompleted: totalMalasCompleted ?? this.totalMalasCompleted,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      accumulatedJapDuration: accumulatedJapDuration ?? this.accumulatedJapDuration,
      lastCountTime: clearLastCountTime ? null : (lastCountTime ?? this.lastCountTime),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'totalMalasCompleted': totalMalasCompleted,
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'isSessionActive': isSessionActive,
      'accumulatedJapDurationMs': accumulatedJapDuration.inMilliseconds,
      'lastCountTime': lastCountTime?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CounterState.fromJson(Map<String, dynamic> json) {
    return CounterState(
      count: json['count'] as int? ?? 0,
      totalMalasCompleted: json['totalMalasCompleted'] as int? ?? 0,
      sessionStartTime: json['sessionStartTime'] != null
          ? DateTime.parse(json['sessionStartTime'] as String)
          : DateTime.now(),
      isSessionActive: json['isSessionActive'] as bool? ?? true,
      accumulatedJapDuration: Duration(
        milliseconds: json['accumulatedJapDurationMs'] as int? ?? 0,
      ),
      lastCountTime: json['lastCountTime'] != null
          ? DateTime.parse(json['lastCountTime'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounterState &&
        other.count == count &&
        other.totalMalasCompleted == totalMalasCompleted &&
        other.sessionStartTime == sessionStartTime &&
        other.isSessionActive == isSessionActive &&
        other.accumulatedJapDuration == accumulatedJapDuration &&
        other.lastCountTime == lastCountTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      count,
      totalMalasCompleted,
      sessionStartTime,
      isSessionActive,
      accumulatedJapDuration,
      lastCountTime,
    );
  }
}
