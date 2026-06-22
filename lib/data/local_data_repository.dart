import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';
import '../features/counter/domain/counter_state.dart';
import '../features/insights/domain/daily_stats.dart';
import '../features/settings/domain/settings_state.dart';
import 'data_repository.dart';
import 'storage_keys.dart';

/// SharedPreferences-backed implementation of [DataRepository].
///
/// This is the only class that imports SharedPreferences for syncable data.
/// All key strings are referenced through [StorageKeys].
class LocalDataRepository implements DataRepository {
  LocalDataRepository._();
  static final LocalDataRepository instance = LocalDataRepository._();

  /// Lazily cached SharedPreferences instance.
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Counter ──

  @override
  Future<CounterState?> loadCounterState() async {
    try {
      final prefs = await _sp;
      final json = prefs.getString(StorageKeys.counterState);
      if (json == null) return null;
      return CounterState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'loadCounterState failed', e, st);
      return null;
    }
  }

  @override
  Future<void> saveCounterState(CounterState state) async {
    try {
      final prefs = await _sp;
      await prefs.setString(
        StorageKeys.counterState,
        jsonEncode(state.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveCounterState failed', e, st);
    }
  }

  // ── Lifetime stats ──

  @override
  Future<LifetimeStats> loadLifetimeStats() async {
    try {
      final prefs = await _sp;
      return LifetimeStats(
        totalCounts: prefs.getInt(StorageKeys.lifetimeCounts) ?? 0,
        totalMalas: prefs.getInt(StorageKeys.lifetimeMalas) ?? 0,
        totalSessions: prefs.getInt(StorageKeys.lifetimeSessions) ?? 0,
      );
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'loadLifetimeStats failed', e, st);
      return const LifetimeStats(totalCounts: 0, totalMalas: 0, totalSessions: 0);
    }
  }

  @override
  Future<void> saveLifetimeStats(LifetimeStats stats) async {
    try {
      final prefs = await _sp;
      await prefs.setInt(StorageKeys.lifetimeCounts, stats.totalCounts);
      await prefs.setInt(StorageKeys.lifetimeMalas, stats.totalMalas);
      await prefs.setInt(StorageKeys.lifetimeSessions, stats.totalSessions);
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveLifetimeStats failed', e, st);
    }
  }

  // ── Settings ──

  @override
  Future<SettingsState?> loadSettings() async {
    try {
      final prefs = await _sp;
      final json = prefs.getString(StorageKeys.appSettings);
      if (json == null) return null;
      return SettingsState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'loadSettings failed', e, st);
      return null;
    }
  }

  @override
  Future<void> saveSettings(SettingsState settings) async {
    try {
      final prefs = await _sp;
      await prefs.setString(
        StorageKeys.appSettings,
        jsonEncode(settings.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveSettings failed', e, st);
    }
  }

  // ── Daily stats ──

  @override
  Future<Map<String, DailyStats>> loadDailyStats() async {
    try {
      final prefs = await _sp;
      final json = prefs.getString(StorageKeys.dailyStats);
      if (json == null) return {};

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final result = <String, DailyStats>{};
      for (final entry in decoded.entries) {
        result[entry.key] =
            DailyStats.fromJson(entry.value as Map<String, dynamic>);
      }
      return result;
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'loadDailyStats failed', e, st);
      return {};
    }
  }

  @override
  Future<void> saveDailyStats(Map<String, DailyStats> stats) async {
    try {
      final prefs = await _sp;
      final map = <String, dynamic>{};
      for (final entry in stats.entries) {
        map[entry.key] = entry.value.toJson();
      }
      await prefs.setString(StorageKeys.dailyStats, jsonEncode(map));
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveDailyStats failed', e, st);
    }
  }

  // ── Streaks ──

  @override
  Future<int> loadCurrentStreak() async {
    try {
      final prefs = await _sp;
      return prefs.getInt(StorageKeys.currentStreak) ?? 0;
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'loadCurrentStreak failed', e, st);
      return 0;
    }
  }

  @override
  Future<void> saveCurrentStreak(int streak) async {
    try {
      final prefs = await _sp;
      await prefs.setInt(StorageKeys.currentStreak, streak);
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveCurrentStreak failed', e, st);
    }
  }

  @override
  Future<int> loadBestStreak() async {
    try {
      final prefs = await _sp;
      return prefs.getInt(StorageKeys.bestStreak) ?? 0;
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'loadBestStreak failed', e, st);
      return 0;
    }
  }

  @override
  Future<void> saveBestStreak(int streak) async {
    try {
      final prefs = await _sp;
      await prefs.setInt(StorageKeys.bestStreak, streak);
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveBestStreak failed', e, st);
    }
  }

  @override
  Future<DateTime?> loadLastActiveDate() async {
    try {
      final prefs = await _sp;
      final str = prefs.getString(StorageKeys.lastActiveDate);
      if (str == null) return null;
      return DateTime.tryParse(str);
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'loadLastActiveDate failed', e, st);
      return null;
    }
  }

  @override
  Future<void> saveLastActiveDate(DateTime date) async {
    try {
      final prefs = await _sp;
      await prefs.setString(StorageKeys.lastActiveDate, date.toIso8601String());
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveLastActiveDate failed', e, st);
    }
  }

  // ── Bulk operations ──

  @override
  Future<void> saveInsightsData({
    required Map<String, DailyStats> dailyStats,
    required int currentStreak,
    required int bestStreak,
    DateTime? lastActiveDate,
  }) async {
    try {
      final prefs = await _sp;

      // Daily stats
      final map = <String, dynamic>{};
      for (final entry in dailyStats.entries) {
        map[entry.key] = entry.value.toJson();
      }
      await prefs.setString(StorageKeys.dailyStats, jsonEncode(map));

      // Streaks
      await prefs.setInt(StorageKeys.currentStreak, currentStreak);
      await prefs.setInt(StorageKeys.bestStreak, bestStreak);

      // Last active date
      if (lastActiveDate != null) {
        await prefs.setString(
          StorageKeys.lastActiveDate,
          lastActiveDate.toIso8601String(),
        );
      }
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'saveInsightsData failed', e, st);
    }
  }

  @override
  Future<void> clearInsightsData() async {
    try {
      final prefs = await _sp;
      await prefs.remove(StorageKeys.dailyStats);
      await prefs.remove(StorageKeys.currentStreak);
      await prefs.remove(StorageKeys.bestStreak);
      await prefs.remove(StorageKeys.lastActiveDate);
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'clearInsightsData failed', e, st);
    }
  }

  /// Clears ALL data that is synced to the cloud.
  /// Called when the user signs out to ensure their guest mode is a blank slate.
  Future<void> clearAllSyncableData() async {
    try {
      final prefs = await _sp;
      // Counter
      await prefs.remove(StorageKeys.counterState);
      
      // Insights
      await prefs.remove(StorageKeys.dailyStats);
      await prefs.remove(StorageKeys.currentStreak);
      await prefs.remove(StorageKeys.bestStreak);
      await prefs.remove(StorageKeys.lastActiveDate);
      
      // Lifetime (deprecated but syncable)
      await prefs.remove(StorageKeys.lifetimeCounts);
      await prefs.remove(StorageKeys.lifetimeMalas);
      await prefs.remove(StorageKeys.lifetimeSessions);

      // Settings
      await prefs.remove(StorageKeys.appSettings);
      
      AppLogger.info('LocalDataRepository', 'Cleared all syncable data on sign out');
    } catch (e, st) {
      AppLogger.error('LocalDataRepository', 'clearAllSyncableData failed', e, st);
    }
  }
}
