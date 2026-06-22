import 'dart:async';
import '../core/constants/appwrite_constants.dart';
import '../core/utils/app_logger.dart';
import '../features/counter/domain/counter_state.dart';
import '../features/insights/domain/daily_stats.dart';
import '../features/settings/domain/settings_state.dart';
import 'cloud_data_repository.dart';
import 'data_repository.dart';
import 'local_data_repository.dart';
import 'sync_service.dart';

const _tag = 'HybridDataRepository';

/// Local-first [DataRepository] that writes through to cloud asynchronously.
///
/// Design principles:
///   - ALL reads come from local (instant, offline-safe)
///   - ALL writes go to local FIRST, then fire-and-forget to cloud
///   - The full bidirectional sync (merge, conflict resolution) is
///     handled separately by [SyncService] at specific trigger points
///   - If the cloud write fails, data is still safe in local storage
///     and will be synced on the next [SyncService.sync()] call
///
/// This class replaces [LocalDataRepository] in `dataRepositoryProvider`
/// when a user is signed in.
class HybridDataRepository implements DataRepository {
  final LocalDataRepository _local;
  final CloudDataRepository _cloud;

  Timer? _debounceTimer;

  HybridDataRepository({
    required LocalDataRepository local,
    required CloudDataRepository cloud,
  })  : _local = local,
        _cloud = cloud;

  // ── Counter (local-only, not synced) ───────────────────────────

  @override
  Future<CounterState?> loadCounterState() => _local.loadCounterState();

  @override
  Future<void> saveCounterState(CounterState state) =>
      _local.saveCounterState(state);

  // ── Lifetime stats ─────────────────────────────────────────────

  @override
  Future<LifetimeStats> loadLifetimeStats() => _local.loadLifetimeStats();

  @override
  Future<void> saveLifetimeStats(LifetimeStats stats) async {
    await _local.saveLifetimeStats(stats);
    // Don't write-through lifetime stats — they're aggregated
    // from daily_stats during sync. The profile update in SyncService
    // handles this.
  }

  // ── Settings ───────────────────────────────────────────────────

  @override
  Future<SettingsState?> loadSettings() => _local.loadSettings();

  @override
  Future<void> saveSettings(SettingsState settings) async {
    await _local.saveSettings(settings);

    if (!SyncService.instance.hasCompletedInitialSync) {
      AppLogger.info(_tag, 'Skipping cloud saveSettings: Initial sync not complete');
      return;
    }

    _fireAndForget(() => _cloud.saveSettings(settings), 'saveSettings');
  }

  // ── Daily stats ────────────────────────────────────────────────

  @override
  Future<Map<String, DailyStats>> loadDailyStats() =>
      _local.loadDailyStats();

  @override
  Future<void> saveDailyStats(Map<String, DailyStats> stats) async {
    await _local.saveDailyStats(stats);
    // Don't write-through full daily stats map — too expensive.
    // Individual day updates happen through saveInsightsData,
    // and full sync happens via SyncService.
  }

  // ── Streaks ────────────────────────────────────────────────────

  @override
  Future<int> loadCurrentStreak() => _local.loadCurrentStreak();

  @override
  Future<void> saveCurrentStreak(int streak) =>
      _local.saveCurrentStreak(streak);

  @override
  Future<int> loadBestStreak() => _local.loadBestStreak();

  @override
  Future<void> saveBestStreak(int streak) => _local.saveBestStreak(streak);

  @override
  Future<DateTime?> loadLastActiveDate() => _local.loadLastActiveDate();

  @override
  Future<void> saveLastActiveDate(DateTime date) =>
      _local.saveLastActiveDate(date);

  // ── Bulk operations ────────────────────────────────────────────

  @override
  Future<void> saveInsightsData({
    required Map<String, DailyStats> dailyStats,
    required int currentStreak,
    required int bestStreak,
    DateTime? lastActiveDate,
  }) async {
    // Save locally first (fast, synchronous-ish)
    await _local.saveInsightsData(
      dailyStats: dailyStats,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      lastActiveDate: lastActiveDate,
    );

    // Sync Guard: Do not overwrite cloud data if we haven't successfully downloaded it yet.
    if (!SyncService.instance.hasCompletedInitialSync) {
      AppLogger.info(_tag, 'Skipping cloud saveInsightsData: Initial sync not complete');
      return;
    }

    // Write-through today's stats to cloud (debounced)
    // We cancel any existing timer and start a new 3-second countdown.
    // This reduces heavy network traffic during active tapping.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      _fireAndForget(() async {
        final now = DateTime.now();
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final todayStats = dailyStats[todayKey];
        if (todayStats != null) {
          await _cloud.saveSingleDailyStats(todayKey, todayStats);
          
          // Also update the aggregated lifetime stats in the user profile so the 
          // cloud stays instantly in sync with the device's all-time counts.
          final lifetimeStats = await loadLifetimeStats();
          final displayName = AppwriteConstants.userProfilesCollection; // Temporary placeholder, SyncService does full sync
          
          // We need to re-aggregate the total counts just like SyncService does
          final allDailyStats = await _local.loadDailyStats();
          int totalCounts = 0;
          int totalMalas = 0;
          int totalSessions = 0;
          
          for (final day in allDailyStats.values) {
            totalCounts += day.counts;
            totalMalas += day.malas;
            totalSessions += day.sessions;
          }
          
          totalCounts += lifetimeStats.totalCounts;
          totalMalas += lifetimeStats.totalMalas;
          totalSessions += lifetimeStats.totalSessions;
          
          await _cloud.upsertFullProfile(
            totalCounts: totalCounts,
            totalMalas: totalMalas,
            totalSessions: totalSessions,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
          );
        }
      }, 'saveInsightsData(today)');
    });
  }

  @override
  Future<void> clearInsightsData() async {
    await _local.clearInsightsData();
    _fireAndForget(() => _cloud.clearInsightsData(), 'clearInsightsData');
  }

  // ── Helpers ────────────────────────────────────────────────────

  /// Run an async operation without awaiting it. Errors are logged
  /// but never thrown — the local write already succeeded.
  void _fireAndForget(
    Future<void> Function() operation,
    String operationName,
  ) {
    operation().catchError((Object e, StackTrace st) {
      AppLogger.error(
        _tag,
        'Cloud write-through failed: $operationName',
        e,
        st,
      );
    });
  }
}
