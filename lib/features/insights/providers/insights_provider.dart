import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/data_provider.dart';
import '../../../data/data_repository.dart';
import '../../../data/sync_service.dart';
import '../../../services/home_widget_service.dart';
import '../domain/daily_stats.dart';

/// Provider for insights/statistics
final insightsProvider = StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  final notifier = InsightsNotifier(ref.watch(dataRepositoryProvider));
  
  // Listen to sync completions to instantly update UI from cloud data
  ref.listen(syncStatusProvider, (previous, next) {
    if (next is AsyncData && next.value?.status == SyncStatus.success) {
      notifier.reloadFromRepository();
    }
  });

  return notifier;
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
  InsightsNotifier(this._repo) : super(InsightsState.initial()) {
    _loadData();
  }

  final DataRepository _repo;

  Future<void> _loadData() async {
    try {
      // Load daily stats
      final dailyStats = await _repo.loadDailyStats();
      
      // Load streak data
      final currentStreak = await _repo.loadCurrentStreak();
      final bestStreak = await _repo.loadBestStreak();
      final lastActiveDate = await _repo.loadLastActiveDate();
      
      // Check and update streak
      await _checkAndUpdateStreak(dailyStats, currentStreak, bestStreak, lastActiveDate);
      
    } catch (e, stackTrace) {
      AppLogger.error('InsightsNotifier', 'Failed to load insights data', e, stackTrace);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Reloads data directly from the repository. Called when SyncService finishes downloading.
  Future<void> reloadFromRepository() async {
    AppLogger.info('InsightsNotifier', 'Reloading data from repository after sync');
    await _loadData();
  }

  Future<void> _checkAndUpdateStreak(
    Map<String, DailyStats> dailyStats,
    int currentStreak,
    int bestStreak,
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
    
    await _repo.saveCurrentStreak(newStreak);
    
    state = InsightsState(
      dailyStats: dailyStats,
      currentStreak: newStreak,
      bestStreak: bestStreak,
      lastActiveDate: lastActiveDate,
      isLoading: false,
    );
  }

  Future<void> _saveData() async {
    try {
      await _repo.saveInsightsData(
        dailyStats: state.dailyStats,
        currentStreak: state.currentStreak,
        bestStreak: state.bestStreak,
        lastActiveDate: state.lastActiveDate,
      );
    } catch (e, stackTrace) {
      AppLogger.error('InsightsNotifier', 'Failed to save insights data', e, stackTrace);
    }
  }

  /// Record a count increment.
  ///
  /// [dailyGoal] is passed from the caller (who has access to settings)
  /// to avoid cross-domain data reads.
  Future<void> recordCount({int dailyGoal = 0}) async {
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
    
    // Batch save: persist every 10 counts to reduce I/O overhead
    // Data is also saved on app background via saveNow()
    if (updatedStats.counts % 10 == 0 || currentStats.counts == 0) {
      await _saveData();
    }
    
    // Update home widget periodically (every 5 counts)
    if (updatedStats.counts % 5 == 0) {
      await updateHomeWidget(dailyGoal: dailyGoal);
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

  /// Record jap time (absolute seconds from counter state)
  /// This sets today's duration to the given value (not additive)
  /// since the counter state tracks the total accumulated jap time
  Future<void> recordJapTime(int totalJapSeconds) async {
    final todayKey = InsightsState.todayKey;
    
    final currentStats = state.dailyStats[todayKey] ?? DailyStats.empty(todayKey);
    final updatedStats = currentStats.copyWith(
      durationSeconds: totalJapSeconds,
    );
    
    final newDailyStats = Map<String, DailyStats>.from(state.dailyStats);
    newDailyStats[todayKey] = updatedStats;
    
    state = state.copyWith(dailyStats: newDailyStats);
    // Don't save on every call - let saveNow() handle persistence
  }

  /// Force save current data
  Future<void> saveNow({int dailyGoal = 0}) async {
    await _saveData();
    await updateHomeWidget(dailyGoal: dailyGoal);
  }

  /// Update home screen widget with current stats.
  ///
  /// The [dailyGoal] parameter should be provided by the caller
  /// (typically from SettingsState) to avoid cross-domain data reads.
  Future<void> updateHomeWidget({int? dailyGoal}) async {
    final todayStats = state.todayStats;
    
    await HomeWidgetService.updateWidget(
      todayCount: todayStats.counts,
      todayMalas: todayStats.malas,
      currentStreak: state.currentStreak,
      dailyGoal: dailyGoal ?? 0,
    );
  }

  /// Clear all data (for reset)
  Future<void> clearAllData() async {
    await _repo.clearInsightsData();
    state = InsightsState.initial().copyWith(isLoading: false);
  }
}
