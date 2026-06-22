import '../features/counter/domain/counter_state.dart';
import '../features/insights/domain/daily_stats.dart';
import '../features/settings/domain/settings_state.dart';

/// Lifetime statistics computed from daily_stats or stored separately.
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

/// Abstract data repository — the single contract for all syncable data.
///
/// Local-only concerns (feedback timestamps, report timestamps, reminder
/// prefs) are intentionally excluded. They will never sync to the cloud
/// and gain nothing from this abstraction.
///
/// Phase 3+ will add `CloudDataRepository` and `HybridDataRepository`
/// that implement this same interface.
abstract class DataRepository {
  // ── Counter ──
  Future<CounterState?> loadCounterState();
  Future<void> saveCounterState(CounterState state);

  // ── Lifetime stats (derived from daily_stats in the future) ──
  Future<LifetimeStats> loadLifetimeStats();
  Future<void> saveLifetimeStats(LifetimeStats stats);

  // ── Settings ──
  Future<SettingsState?> loadSettings();
  Future<void> saveSettings(SettingsState settings);

  // ── Daily stats & streaks ──
  Future<Map<String, DailyStats>> loadDailyStats();
  Future<void> saveDailyStats(Map<String, DailyStats> stats);

  Future<int> loadCurrentStreak();
  Future<void> saveCurrentStreak(int streak);

  Future<int> loadBestStreak();
  Future<void> saveBestStreak(int streak);

  Future<DateTime?> loadLastActiveDate();
  Future<void> saveLastActiveDate(DateTime date);

  /// Save all insights data atomically (daily stats + streaks + last active).
  Future<void> saveInsightsData({
    required Map<String, DailyStats> dailyStats,
    required int currentStreak,
    required int bestStreak,
    DateTime? lastActiveDate,
  });

  /// Clear all insights data (for reset).
  Future<void> clearInsightsData();
}
