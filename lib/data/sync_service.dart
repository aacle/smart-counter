import 'dart:async';
import '../core/utils/app_logger.dart';
import '../features/auth/domain/app_user.dart';
import '../features/insights/domain/daily_stats.dart';
import 'cloud_data_repository.dart';
import 'local_data_repository.dart';

const _tag = 'SyncService';

/// The current state of a sync operation.
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Result of a sync operation.
class SyncResult {
  final SyncStatus status;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final int daysUploaded;
  final int daysDownloaded;
  final int daysMerged;

  const SyncResult({
    required this.status,
    this.lastSyncAt,
    this.errorMessage,
    this.daysUploaded = 0,
    this.daysDownloaded = 0,
    this.daysMerged = 0,
  });

  factory SyncResult.idle() => const SyncResult(status: SyncStatus.idle);

  factory SyncResult.error(String message) => SyncResult(
        status: SyncStatus.error,
        errorMessage: message,
      );

  @override
  String toString() =>
      'SyncResult($status, up=$daysUploaded, down=$daysDownloaded, '
      'merged=$daysMerged, error=$errorMessage)';
}

/// Orchestrates bidirectional sync between local and cloud storage.
///
/// Conflict resolution strategy (per-day max-wins):
///   - For each date key, compare local vs cloud `DailyStats`
///   - Take the MAX of each field (counts, malas, sessions, durationSeconds)
///   - Write the merged result to both local and cloud
///
/// Settings sync: last-write-wins (cloud overwrites local if cloud is newer,
/// otherwise local overwrites cloud).
///
/// This service is stateless — it reads from local, reads from cloud,
/// merges, and writes back. It does NOT hold any cached data.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// Guards against concurrent syncs.
  bool _isSyncing = false;

  /// Tracks if the app has successfully synced from the cloud at least once
  /// during this app session. Used to prevent local data from overwriting
  /// cloud data immediately after login before the initial pull is finished.
  bool _hasCompletedInitialSync = false;
  bool get hasCompletedInitialSync => _hasCompletedInitialSync;

  /// Stream controller to broadcast sync status changes.
  final _statusController = StreamController<SyncResult>.broadcast();

  /// Stream of sync results. UI can listen to this for status updates.
  Stream<SyncResult> get statusStream => _statusController.stream;

  /// The last sync result.
  SyncResult _lastResult = SyncResult.idle();
  SyncResult get lastResult => _lastResult;

  /// Run a full bidirectional sync.
  ///
  /// - [user] : the currently authenticated user
  /// - [cloudRepo] : the cloud repository for this user
  ///
  /// Returns a [SyncResult] with counts of what was synced.
  Future<SyncResult> sync({
    required AppUser user,
    required CloudDataRepository cloudRepo,
  }) async {
    if (_isSyncing) {
      AppLogger.info(_tag, 'Sync already in progress, skipping');
      return _lastResult;
    }

    _isSyncing = true;
    _emit(const SyncResult(status: SyncStatus.syncing));

    try {
      final local = LocalDataRepository.instance;

      // ── 1. Sync daily stats (per-day max-wins merge) ──────────
      final mergeResult = await _syncDailyStats(local, cloudRepo);

      // ── 2. Sync settings (last-write-wins) ────────────────────
      await _syncSettings(local, cloudRepo);

      // ── 3. Sync streaks ───────────────────────────────────────
      await _syncStreaks(local, cloudRepo);

      // ── 4. Update user profile with aggregated data ───────────
      await _updateUserProfile(local, cloudRepo, user);

      final result = SyncResult(
        status: SyncStatus.success,
        lastSyncAt: DateTime.now(),
        daysUploaded: mergeResult.uploaded,
        daysDownloaded: mergeResult.downloaded,
        daysMerged: mergeResult.merged,
      );

      _hasCompletedInitialSync = true;
      _emit(result);
      AppLogger.info(_tag, 'Sync complete: $result');
      return result;
    } catch (e, st) {
      AppLogger.error(_tag, 'Sync failed', e, st);
      final result = SyncResult.error(e.toString());
      _emit(result);
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  void _emit(SyncResult result) {
    _lastResult = result;
    _statusController.add(result);
  }

  /// Dispose resources. Call when the user signs out.
  void reset() {
    _lastResult = SyncResult.idle();
    _isSyncing = false;
    _hasCompletedInitialSync = false;
  }

  // ── Daily Stats Merge ──────────────────────────────────────────

  Future<_MergeResult> _syncDailyStats(
    LocalDataRepository local,
    CloudDataRepository cloud,
  ) async {
    final localStats = await local.loadDailyStats();
    final cloudStats = await cloud.loadDailyStats();

    int uploaded = 0;
    int downloaded = 0;
    int merged = 0;

    // Collect all unique date keys
    final allDates = <String>{
      ...localStats.keys,
      ...cloudStats.keys,
    };

    final mergedStats = <String, DailyStats>{};

    for (final date in allDates) {
      final localDay = localStats[date];
      final cloudDay = cloudStats[date];

      if (localDay != null && cloudDay == null) {
        // Only exists locally → upload
        mergedStats[date] = localDay;
        await cloud.saveSingleDailyStats(date, localDay);
        uploaded++;
      } else if (localDay == null && cloudDay != null) {
        // Only exists in cloud → download
        mergedStats[date] = cloudDay;
        downloaded++;
      } else if (localDay != null && cloudDay != null) {
        // Exists in both → max-wins merge
        final mergedDay = _mergeDailyStats(localDay, cloudDay);
        mergedStats[date] = mergedDay;

        // Upload merged result if it differs from cloud
        if (_daysDiffer(mergedDay, cloudDay)) {
          await cloud.saveSingleDailyStats(date, mergedDay);
        }
        merged++;
      }
    }

    // Write merged result back to local
    await local.saveDailyStats(mergedStats);

    return _MergeResult(
      uploaded: uploaded,
      downloaded: downloaded,
      merged: merged,
    );
  }

  /// Per-day max-wins merge: take the MAX of each field.
  DailyStats _mergeDailyStats(DailyStats a, DailyStats b) {
    return DailyStats(
      date: a.date,
      counts: a.counts > b.counts ? a.counts : b.counts,
      malas: a.malas > b.malas ? a.malas : b.malas,
      sessions: a.sessions > b.sessions ? a.sessions : b.sessions,
      durationSeconds: a.durationSeconds > b.durationSeconds
          ? a.durationSeconds
          : b.durationSeconds,
    );
  }

  bool _daysDiffer(DailyStats a, DailyStats b) {
    return a.counts != b.counts ||
        a.malas != b.malas ||
        a.sessions != b.sessions ||
        a.durationSeconds != b.durationSeconds;
  }

  // ── Settings Sync ──────────────────────────────────────────────

  /// Settings sync: if cloud has settings, use cloud (overwrite local).
  /// If cloud is empty, push local to cloud. This means the first sync
  /// after sign-in uploads local settings, and subsequent syncs pull
  /// from cloud (so settings transfer across devices).
  Future<void> _syncSettings(
    LocalDataRepository local,
    CloudDataRepository cloud,
  ) async {
    final cloudSettings = await cloud.loadSettings();
    final localSettings = await local.loadSettings();

    if (cloudSettings != null && localSettings != null) {
      // Cloud exists — cloud wins (last device to sync wins)
      // In future we could add timestamp-based comparison,
      // but for now cloud-wins is simple and predictable.
      if (cloudSettings != localSettings) {
        await local.saveSettings(cloudSettings);
        AppLogger.info(_tag, 'Settings pulled from cloud');
      }
    } else if (cloudSettings == null && localSettings != null) {
      // Cloud empty, local has data → push to cloud
      await cloud.saveSettings(localSettings);
      AppLogger.info(_tag, 'Settings pushed to cloud');
    } else if (cloudSettings != null && localSettings == null) {
      // Local empty, cloud has data → pull to local
      await local.saveSettings(cloudSettings);
      AppLogger.info(_tag, 'Settings pulled from cloud (first sync)');
    }
    // Both null → nothing to sync
  }

  // ── Streaks Sync ───────────────────────────────────────────────

  /// Streaks: take the max of local and cloud.
  Future<void> _syncStreaks(
    LocalDataRepository local,
    CloudDataRepository cloud,
  ) async {
    final localCurrentStreak = await local.loadCurrentStreak();
    final cloudCurrentStreak = await cloud.loadCurrentStreak();
    final localBestStreak = await local.loadBestStreak();
    final cloudBestStreak = await cloud.loadBestStreak();

    final mergedCurrent = localCurrentStreak > cloudCurrentStreak
        ? localCurrentStreak
        : cloudCurrentStreak;
    final mergedBest = localBestStreak > cloudBestStreak
        ? localBestStreak
        : cloudBestStreak;

    // Write back to local
    await local.saveCurrentStreak(mergedCurrent);
    await local.saveBestStreak(mergedBest);
  }

  // ── User Profile Update ────────────────────────────────────────

  /// Aggregate all daily stats and update the user profile document
  /// in the cloud. This powers the leaderboard (Phase 7).
  Future<void> _updateUserProfile(
    LocalDataRepository local,
    CloudDataRepository cloud,
    AppUser user,
  ) async {
    final dailyStats = await local.loadDailyStats();
    final currentStreak = await local.loadCurrentStreak();
    final bestStreak = await local.loadBestStreak();

    int totalCounts = 0;
    int totalMalas = 0;
    int totalSessions = 0;

    for (final day in dailyStats.values) {
      totalCounts += day.counts;
      totalMalas += day.malas;
      totalSessions += day.sessions;
    }

    // Also add lifetime stats (from before daily_stats tracking)
    final lifetime = await local.loadLifetimeStats();
    totalCounts += lifetime.totalCounts;
    totalMalas += lifetime.totalMalas;
    totalSessions += lifetime.totalSessions;

    await cloud.upsertFullProfile(
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      totalCounts: totalCounts,
      totalMalas: totalMalas,
      totalSessions: totalSessions,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      todayCounts: dailyStats[_todayKey()]?.counts ?? 0,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _MergeResult {
  final int uploaded;
  final int downloaded;
  final int merged;

  const _MergeResult({
    required this.uploaded,
    required this.downloaded,
    required this.merged,
  });
}
