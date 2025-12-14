import 'package:flutter/foundation.dart';

/// Data model for daily statistics
@immutable
class DailyStats {
  final String date; // 'YYYY-MM-DD' format
  final int counts;
  final int malas;
  final int sessions;
  final int durationSeconds;

  const DailyStats({
    required this.date,
    required this.counts,
    required this.malas,
    required this.sessions,
    required this.durationSeconds,
  });

  factory DailyStats.empty(String date) {
    return DailyStats(
      date: date,
      counts: 0,
      malas: 0,
      sessions: 0,
      durationSeconds: 0,
    );
  }

  Duration get duration => Duration(seconds: durationSeconds);

  DailyStats copyWith({
    String? date,
    int? counts,
    int? malas,
    int? sessions,
    int? durationSeconds,
  }) {
    return DailyStats(
      date: date ?? this.date,
      counts: counts ?? this.counts,
      malas: malas ?? this.malas,
      sessions: sessions ?? this.sessions,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'counts': counts,
      'malas': malas,
      'sessions': sessions,
      'durationSeconds': durationSeconds,
    };
  }

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] as String,
      counts: json['counts'] as int? ?? 0,
      malas: json['malas'] as int? ?? 0,
      sessions: json['sessions'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyStats &&
        other.date == date &&
        other.counts == counts &&
        other.malas == malas &&
        other.sessions == sessions &&
        other.durationSeconds == durationSeconds;
  }

  @override
  int get hashCode {
    return Object.hash(date, counts, malas, sessions, durationSeconds);
  }
}

/// Aggregated statistics for a period
@immutable
class PeriodStats {
  final int totalCounts;
  final int totalMalas;
  final int totalSessions;
  final int totalDurationSeconds;
  final int daysActive;
  final int currentStreak;
  final int bestStreak;

  const PeriodStats({
    required this.totalCounts,
    required this.totalMalas,
    required this.totalSessions,
    required this.totalDurationSeconds,
    required this.daysActive,
    required this.currentStreak,
    required this.bestStreak,
  });

  factory PeriodStats.empty() {
    return const PeriodStats(
      totalCounts: 0,
      totalMalas: 0,
      totalSessions: 0,
      totalDurationSeconds: 0,
      daysActive: 0,
      currentStreak: 0,
      bestStreak: 0,
    );
  }

  Duration get totalDuration => Duration(seconds: totalDurationSeconds);

  /// Average counts per day (only counting active days)
  double get avgCountsPerDay =>
      daysActive > 0 ? totalCounts / daysActive : 0;

  /// Average malas per day
  double get avgMalasPerDay =>
      daysActive > 0 ? totalMalas / daysActive : 0;

  /// Average session duration
  Duration get avgSessionDuration => totalSessions > 0
      ? Duration(seconds: totalDurationSeconds ~/ totalSessions)
      : Duration.zero;

  /// Average counts per session
  double get avgCountsPerSession =>
      totalSessions > 0 ? totalCounts / totalSessions : 0;
}
