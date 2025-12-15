import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/home_widget_service.dart';
import '../domain/daily_stats.dart';

/// Provider for insights/statistics
final insightsProvider = StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  return InsightsNotifier();
});

/// State containing all insights data
class InsightsState {
  final Map<String, DailyStats> dailyStats;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastActiveDate;
  final bool isLoading;

  const InsightsState({
    required this.dailyStats,
    required this.currentStreak,
    required this.bestStreak,
    this.lastActiveDate,
    this.isLoading = false,
  });

  factory InsightsState.initial() {
    return const InsightsState(
      dailyStats: {},
      currentStreak: 0,
      bestStreak: 0,
      isLoading: true,
    );
  }

  InsightsState copyWith({
    Map<String, DailyStats>? dailyStats,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastActiveDate,
    bool? isLoading,
  }) {
    return InsightsState(
      dailyStats: dailyStats ?? this.dailyStats,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get today's date string
  static String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get today's stats
  DailyStats get todayStats =>
      dailyStats[todayKey] ?? DailyStats.empty(todayKey);

  /// Get stats for last N days
  List<DailyStats> getStatsForDays(int days) {
    final result = <DailyStats>[];
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result.add(dailyStats[key] ?? DailyStats.empty(key));
    }
    
    return result;
  }

  /// Calculate period stats for given days
  PeriodStats getPeriodStats(int days) {
    final stats = getStatsForDays(days);
    
    int totalCounts = 0;
    int totalMalas = 0;
    int totalSessions = 0;
    int totalDuration = 0;
    int daysActive = 0;
    
    for (final day in stats) {
      totalCounts += day.counts;
      totalMalas += day.malas;
      totalSessions += day.sessions;
      totalDuration += day.durationSeconds;
      if (day.counts > 0) daysActive++;
    }
    
    return PeriodStats(
      totalCounts: totalCounts,
      totalMalas: totalMalas,
      totalSessions: totalSessions,
      totalDurationSeconds: totalDuration,
      daysActive: daysActive,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  /// Get lifetime stats
  PeriodStats get lifetimeStats {
    int totalCounts = 0;
    int totalMalas = 0;
    int totalSessions = 0;
    int totalDuration = 0;
    int daysActive = 0;
    
    for (final day in dailyStats.values) {
      totalCounts += day.counts;
      totalMalas += day.malas;
      totalSessions += day.sessions;
      totalDuration += day.durationSeconds;
      if (day.counts > 0) daysActive++;
    }
    
    return PeriodStats(
      totalCounts: totalCounts,
      totalMalas: totalMalas,
      totalSessions: totalSessions,
      totalDurationSeconds: totalDuration,
      daysActive: daysActive,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}

/// Notifier for managing insights state
class InsightsNotifier extends StateNotifier<InsightsState> {
  InsightsNotifier() : super(InsightsState.initial()) {
    _loadData();
  }

  static const String _dailyStatsKey = 'daily_stats';
  static const String _currentStreakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';
  static const String _lastActiveDateKey = 'last_active_date';

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load daily stats
      final statsJson = prefs.getString(_dailyStatsKey);
      final Map<String, DailyStats> dailyStats = {};
      
      if (statsJson != null) {
        final decoded = jsonDecode(statsJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          dailyStats[entry.key] = DailyStats.fromJson(entry.value as Map<String, dynamic>);
        }
      }
      
      // Load streak data
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      final bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
      final lastActiveDateStr = prefs.getString(_lastActiveDateKey);
      final lastActiveDate = lastActiveDateStr != null 
          ? DateTime.tryParse(lastActiveDateStr) 
          : null;
      
      // Check and update streak
      await _checkAndUpdateStreak(dailyStats, currentStreak, lastActiveDate);
      
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _checkAndUpdateStreak(
    Map<String, DailyStats> dailyStats,
    int currentStreak,
    DateTime? lastActiveDate,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = currentStreak;
    
    if (lastActiveDate != null) {
      final lastActive = DateTime(
        lastActiveDate.year,
        lastActiveDate.month,
        lastActiveDate.day,
      );
      final difference = today.difference(lastActive).inDays;
      
      // If more than 1 day has passed, reset streak
      if (difference > 1) {
        newStreak = 0;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStreakKey, newStreak);
    
    state = InsightsState(
      dailyStats: dailyStats,
      currentStreak: newStreak,
      bestStreak: prefs.getInt(_bestStreakKey) ?? 0,
      lastActiveDate: lastActiveDate,
      isLoading: false,
    );
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save daily stats
      final statsMap = <String, dynamic>{};
      for (final entry in state.dailyStats.entries) {
        statsMap[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_dailyStatsKey, jsonEncode(statsMap));
      
      // Save streak data
      await prefs.setInt(_currentStreakKey, state.currentStreak);
      await prefs.setInt(_bestStreakKey, state.bestStreak);
      if (state.lastActiveDate != null) {
        await prefs.setString(_lastActiveDateKey, state.lastActiveDate!.toIso8601String());
      }
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Record a count increment
  Future<void> recordCount() async {
    final todayKey = InsightsState.todayKey;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final currentStats = state.dailyStats[todayKey] ?? DailyStats.empty(todayKey);
    final updatedStats = currentStats.copyWith(
      counts: currentStats.counts + 1,
      malas: (currentStats.counts + 1) ~/ 108,
    );
    
    final newDailyStats = Map<String, DailyStats>.from(state.dailyStats);
    newDailyStats[todayKey] = updatedStats;
    
    // Update streak if this is first count today
    int newStreak = state.currentStreak;
    int newBestStreak = state.bestStreak;
    DateTime newLastActive = today;
    
    if (currentStats.counts == 0) {
      // First count today, check streak
      if (state.lastActiveDate != null) {
        final lastActive = DateTime(
          state.lastActiveDate!.year,
          state.lastActiveDate!.month,
          state.lastActiveDate!.day,
        );
        final difference = today.difference(lastActive).inDays;
        
        if (difference == 1) {
          // Consecutive day, increment streak
          newStreak = state.currentStreak + 1;
        } else if (difference == 0) {
          // Same day, keep streak
          newStreak = state.currentStreak;
        } else {
          // Streak broken, start from 1
          newStreak = 1;
        }
      } else {
        // First ever count
        newStreak = 1;
      }
      
      if (newStreak > newBestStreak) {
        newBestStreak = newStreak;
      }
    }
    
    state = state.copyWith(
      dailyStats: newDailyStats,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      lastActiveDate: newLastActive,
    );
    
    // Save on every count to prevent data loss
    await _saveData();
    
    // Update home widget periodically (every 5 counts)
    if (updatedStats.counts % 5 == 0) {
      await updateHomeWidget();
    }
  }

  /// Record a session completion
  Future<void> recordSession(Duration duration) async {
    final todayKey = InsightsState.todayKey;
    
    final currentStats = state.dailyStats[todayKey] ?? DailyStats.empty(todayKey);
    final updatedStats = currentStats.copyWith(
      sessions: currentStats.sessions + 1,
      durationSeconds: currentStats.durationSeconds + duration.inSeconds,
    );
    
    final newDailyStats = Map<String, DailyStats>.from(state.dailyStats);
    newDailyStats[todayKey] = updatedStats;
    
    state = state.copyWith(dailyStats: newDailyStats);
    await _saveData();
  }

  /// Force save current data
  Future<void> saveNow() async {
    await _saveData();
    await updateHomeWidget();
  }

  /// Update home screen widget with current stats
  Future<void> updateHomeWidget({int? dailyGoal}) async {
    final todayStats = state.todayStats;
    
    // Get daily goal from SharedPreferences if not provided
    int goal = dailyGoal ?? 0;
    if (goal == 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final settingsJson = prefs.getString('settings_state');
        if (settingsJson != null) {
          final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
          goal = settings['dailyGoal'] as int? ?? 0;
        }
      } catch (_) {}
    }
    
    await HomeWidgetService.updateWidget(
      todayCount: todayStats.counts,
      todayMalas: todayStats.malas,
      currentStreak: state.currentStreak,
      dailyGoal: goal,
    );
  }

  /// Clear all data (for reset)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dailyStatsKey);
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_bestStreakKey);
    await prefs.remove(_lastActiveDateKey);
    
    state = InsightsState.initial().copyWith(isLoading: false);
  }
}
