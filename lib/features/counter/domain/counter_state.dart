import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

/// Immutable state for the counter
@immutable
class CounterState {
  final int count;
  final int totalMalasCompleted;
  final DateTime sessionStartTime;
  final bool isSessionActive;

  const CounterState({
    required this.count,
    required this.totalMalasCompleted,
    required this.sessionStartTime,
    required this.isSessionActive,
  });

  /// Initial state for a new session
  factory CounterState.initial() {
    return CounterState(
      count: 0,
      totalMalasCompleted: 0,
      sessionStartTime: DateTime.now(),
      isSessionActive: true,
    );
  }

  /// Current position within the mala (0-107)
  int get positionInMala => count % kMalaSize;

  /// Progress through current mala (0.0 - 1.0)
  double get malaProgress => positionInMala / kMalaSize;

  /// Total malas completed in this session (including partial)
  int get sessionMalas => count ~/ kMalaSize;

  /// Session duration
  Duration get sessionDuration => DateTime.now().difference(sessionStartTime);

  /// Create a copy with updated values
  CounterState copyWith({
    int? count,
    int? totalMalasCompleted,
    DateTime? sessionStartTime,
    bool? isSessionActive,
  }) {
    return CounterState(
      count: count ?? this.count,
      totalMalasCompleted: totalMalasCompleted ?? this.totalMalasCompleted,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      isSessionActive: isSessionActive ?? this.isSessionActive,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'totalMalasCompleted': totalMalasCompleted,
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'isSessionActive': isSessionActive,
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounterState &&
        other.count == count &&
        other.totalMalasCompleted == totalMalasCompleted &&
        other.sessionStartTime == sessionStartTime &&
        other.isSessionActive == isSessionActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      count,
      totalMalasCompleted,
      sessionStartTime,
      isSessionActive,
    );
  }
}
