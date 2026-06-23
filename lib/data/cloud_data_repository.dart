import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../core/constants/app_constants.dart';
import '../core/constants/appwrite_constants.dart';
import '../core/utils/app_logger.dart';
import '../features/auth/auth_service.dart';
import '../features/counter/domain/counter_state.dart';
import '../features/insights/domain/daily_stats.dart';
import '../../features/leaderboard/domain/leaderboard_entry.dart';
import '../features/settings/domain/settings_state.dart';
import 'data_repository.dart';

enum LeaderboardSort { totalCounts, todayCounts, currentStreak }

const _tag = 'CloudDataRepository';

/// Appwrite Databases-backed implementation of [DataRepository].
///
/// Every method talks directly to Appwrite. This class does NOT cache
/// anything locally — that's the job of [HybridDataRepository] which
/// wraps this together with [LocalDataRepository].
///
/// Document ID strategy:
///   - daily_stats : `{userId}_{date}` (e.g. `abc123_2025-06-22`)
///   - user_settings : `{userId}` (one doc per user)
///   - user_profiles : `{userId}` (one doc per user)
///
/// All methods silently return defaults on failure so the app never
/// crashes due to network issues.
class CloudDataRepository implements DataRepository {
  CloudDataRepository._(this._userId);

  final String _userId;
  late final Databases _databases;
  bool _initialized = false;

  /// Create a [CloudDataRepository] for the given user.
  static CloudDataRepository forUser(String userId) {
    final repo = CloudDataRepository._(userId);
    repo._init();
    return repo;
  }

  void _init() {
    if (_initialized) return;
    _databases = Databases(AuthService.instance.client);
    _initialized = true;
  }

  // ── Helpers ────────────────────────────────────────────────────

  String get _db => AppwriteConstants.databaseId;
  String get _dailyStats => AppwriteConstants.dailyStatsCollection;
  String get _userSettings => AppwriteConstants.userSettingsCollection;
  String get _userProfiles => AppwriteConstants.userProfilesCollection;

  String _dailyStatsDocId(String date) => '${_userId}_$date';

  /// Upsert a document. Uses Appwrite's `upsertDocument` which creates
  /// or updates in one call.
  Future<models.Document?> _upsert({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // ignore: deprecated_member_use
      return await _databases.upsertDocument(
        databaseId: _db,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
        permissions: [
          Permission.read(Role.user(_userId)),
          Permission.update(Role.user(_userId)),
          Permission.delete(Role.user(_userId)),
        ],
      );
    } on AppwriteException catch (e, st) {
      AppLogger.error(_tag, 'Upsert failed ($collectionId/$documentId)', e, st);
      return null;
    }
  }

  /// Get a single document, returns null if not found.
  Future<models.Document?> _getDoc({
    required String collectionId,
    required String documentId,
  }) async {
    try {
      // ignore: deprecated_member_use
      return await _databases.getDocument(
        databaseId: _db,
        collectionId: collectionId,
        documentId: documentId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      AppLogger.error(_tag, 'Get failed ($collectionId/$documentId)', e);
      return null;
    }
  }

  String _nowIso() => DateTime.now().toUtc().toIso8601String();

  // ── Counter ────────────────────────────────────────────────────
  // Counter state is session-local, not synced to cloud.
  // Cloud only stores daily_stats (aggregated counts).

  @override
  Future<CounterState?> loadCounterState() async => null;

  @override
  Future<void> saveCounterState(CounterState state) async {
    // Counter state is session-local, not synced.
  }

  // ── Lifetime stats ─────────────────────────────────────────────
  // Lifetime stats are computed from the user_profiles doc in cloud.

  @override
  Future<LifetimeStats> loadLifetimeStats() async {
    final doc = await _getDoc(
      collectionId: _userProfiles,
      documentId: _userId,
    );
    if (doc == null) {
      return const LifetimeStats(
        totalCounts: 0,
        totalMalas: 0,
        totalSessions: 0,
      );
    }
    return LifetimeStats(
      totalCounts: doc.data['total_counts'] as int? ?? 0,
      totalMalas: doc.data['total_malas'] as int? ?? 0,
      totalSessions: doc.data['total_sessions'] as int? ?? 0,
    );
  }

  @override
  Future<void> saveLifetimeStats(LifetimeStats stats) async {
    final existing = await _getDoc(
      collectionId: _userProfiles,
      documentId: _userId,
    );

    await _upsertProfile(
      {
        'user_id': _userId,
        'display_name': existing?.data['display_name'] as String? ?? '',
        'avatar_url': existing?.data['avatar_url'] as String? ?? '',
        'total_counts': stats.totalCounts,
        'total_malas': stats.totalMalas,
        'total_sessions': stats.totalSessions,
        'current_streak': existing?.data['current_streak'] as int? ?? 0,
        'best_streak': existing?.data['best_streak'] as int? ?? 0,
        'today_counts': existing?.data['today_counts'] as int? ?? 0,
        'last_sync_at': _nowIso(),
      },
    );
  }

  // ── Settings ───────────────────────────────────────────────────

  @override
  Future<SettingsState?> loadSettings() async {
    final doc = await _getDoc(
      collectionId: _userSettings,
      documentId: _userId,
    );
    if (doc == null) return null;

    try {
      final json = jsonDecode(doc.data['settings_json'] as String)
          as Map<String, dynamic>;
      return SettingsState.fromJson(json);
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to parse cloud settings', e, st);
      return null;
    }
  }

  @override
  Future<void> saveSettings(SettingsState settings) async {
    await _upsert(
      collectionId: _userSettings,
      documentId: _userId,
      data: {
        'user_id': _userId,
        'settings_json': jsonEncode(settings.toJson()),
        'updated_at': _nowIso(),
      },
    );
  }

  // ── Daily stats ────────────────────────────────────────────────

  @override
  Future<Map<String, DailyStats>> loadDailyStats() async {
    try {
      final result = <String, DailyStats>{};
      String? lastId;
      bool hasMore = true;

      // Paginate through all documents for this user
      while (hasMore) {
        final queries = <String>[
          Query.equal('user_id', _userId),
          Query.limit(100),
          if (lastId != null) Query.cursorAfter(lastId),
        ];

        // ignore: deprecated_member_use
        final docs = await _databases.listDocuments(
          databaseId: _db,
          collectionId: _dailyStats,
          queries: queries,
        );

        for (final doc in docs.documents) {
          final date = doc.data['date'] as String;
          result[date] = DailyStats(
            date: date,
            counts: doc.data['counts'] as int? ?? 0,
            malas: doc.data['malas'] as int? ?? 0,
            sessions: doc.data['sessions'] as int? ?? 0,
            durationSeconds: doc.data['duration_seconds'] as int? ?? 0,
          );
        }

        hasMore = docs.documents.length == 100;
        if (docs.documents.isNotEmpty) {
          lastId = docs.documents.last.$id;
        }
      }

      AppLogger.info(_tag, 'Loaded ${result.length} daily stats from cloud');
      return result;
    } catch (e, st) {
      AppLogger.error(_tag, 'loadDailyStats failed', e, st);
      return {};
    }
  }

  @override
  Future<void> saveDailyStats(Map<String, DailyStats> stats) async {
    // Batch upsert all daily stats
    for (final entry in stats.entries) {
      await _upsertDailyStatsDoc(entry.key, entry.value);
    }
  }

  /// Upsert a single daily stats document.
  Future<void> _upsertDailyStatsDoc(String date, DailyStats stats) async {
    await _upsert(
      collectionId: _dailyStats,
      documentId: _dailyStatsDocId(date),
      data: {
        'user_id': _userId,
        'date': date,
        'counts': stats.counts,
        'malas': stats.malas,
        'sessions': stats.sessions,
        'duration_seconds': stats.durationSeconds,
        'updated_at': _nowIso(),
      },
    );
  }

  // ── Streaks ────────────────────────────────────────────────────
  // Streaks are stored in the user_profiles document.

  @override
  Future<int> loadCurrentStreak() async {
    final doc = await _getDoc(
      collectionId: _userProfiles,
      documentId: _userId,
    );
    return doc?.data['current_streak'] as int? ?? 0;
  }

  @override
  Future<void> saveCurrentStreak(int streak) async {
    // Will be saved as part of the full profile update in sync
  }

  @override
  Future<int> loadBestStreak() async {
    final doc = await _getDoc(
      collectionId: _userProfiles,
      documentId: _userId,
    );
    return doc?.data['best_streak'] as int? ?? 0;
  }

  @override
  Future<void> saveBestStreak(int streak) async {
    // Will be saved as part of the full profile update in sync
  }

  @override
  Future<DateTime?> loadLastActiveDate() async {
    final doc = await _getDoc(
      collectionId: _userProfiles,
      documentId: _userId,
    );
    if (doc == null) return null;
    final syncAt = doc.data['last_sync_at'] as String?;
    if (syncAt == null || syncAt.isEmpty) return null;
    return DateTime.tryParse(syncAt);
  }

  @override
  Future<void> saveLastActiveDate(DateTime date) async {
    // Will be saved as part of the full profile update in sync
  }

  // ── Bulk operations ────────────────────────────────────────────

  @override
  Future<void> saveInsightsData({
    required Map<String, DailyStats> dailyStats,
    required int currentStreak,
    required int bestStreak,
    DateTime? lastActiveDate,
  }) async {
    // Save daily stats
    await saveDailyStats(dailyStats);

    final totals = _aggregateDailyStats(dailyStats);
    await upsertFullProfile(
      totalCounts: totals.totalCounts,
      totalMalas: totals.totalMalas,
      totalSessions: totals.totalSessions,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      todayCounts: dailyStats[_todayKey()]?.counts ?? 0,
    );
  }

  @override
  Future<void> clearInsightsData() async {
    // Delete all daily stats for this user
    try {
      bool hasMore = true;
      while (hasMore) {
        // ignore: deprecated_member_use
        final docs = await _databases.listDocuments(
          databaseId: _db,
          collectionId: _dailyStats,
          queries: [
            Query.equal('user_id', _userId),
            Query.limit(100),
          ],
        );

        for (final doc in docs.documents) {
          // ignore: deprecated_member_use
          await _databases.deleteDocument(
            databaseId: _db,
            collectionId: _dailyStats,
            documentId: doc.$id,
          );
        }

        hasMore = docs.documents.length == 100;
      }

      // Reset profile streaks
      await _upsertUserProfile(currentStreak: 0, bestStreak: 0);
    } catch (e, st) {
      AppLogger.error(_tag, 'clearInsightsData failed', e, st);
    }
  }

  // ── Profile helpers ────────────────────────────────────────────

  /// Upsert the user profile document with all aggregated data.
  Future<void> upsertFullProfile({
    String? displayName,
    String? avatarUrl,
    required int totalCounts,
    required int totalMalas,
    required int totalSessions,
    required int currentStreak,
    required int bestStreak,
    required int todayCounts,
  }) async {
    final existing = await _getDoc(
      collectionId: _userProfiles,
      documentId: _userId,
    );

    await _upsertProfile(
      {
        'user_id': _userId,
        'display_name':
            displayName ?? existing?.data['display_name'] as String? ?? '',
        'avatar_url':
            avatarUrl ?? existing?.data['avatar_url'] as String? ?? '',
        'total_counts': totalCounts,
        'total_malas': totalMalas,
        'total_sessions': totalSessions,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'today_counts': todayCounts,
        'last_sync_at': _nowIso(),
      },
    );
  }

  Future<void> _upsertProfile(Map<String, dynamic> data) async {
    try {
      // ignore: deprecated_member_use
      await _databases.upsertDocument(
        databaseId: _db,
        collectionId: _userProfiles,
        documentId: _userId,
        data: data,
        permissions: [
          Permission.read(Role.user(_userId)),
          Permission.update(Role.user(_userId)),
          Permission.delete(Role.user(_userId)),
        ],
      );
      AppLogger.info(_tag, 'Updated user profile aggregates');
    } on AppwriteException catch (e, st) {
      final message = e.message ?? '';
      final canRetryWithoutNewFields =
          message.contains('avatar_url') || message.contains('today_counts');

      if (!canRetryWithoutNewFields) {
        AppLogger.error(_tag, 'Profile upsert failed', e, st);
        return;
      }

      final fallback = Map<String, dynamic>.from(data)
        ..remove('avatar_url')
        ..remove('today_counts');

      try {
        // Keep all-time leaderboard totals updating even before the Appwrite
        // schema migration has been run for newer optional profile fields.
        // ignore: deprecated_member_use
        await _databases.upsertDocument(
          databaseId: _db,
          collectionId: _userProfiles,
          documentId: _userId,
          data: fallback,
          permissions: [
            Permission.read(Role.user(_userId)),
            Permission.update(Role.user(_userId)),
            Permission.delete(Role.user(_userId)),
          ],
        );
        AppLogger.info(
          _tag,
          'Updated user profile aggregates without new optional fields',
        );
      } on AppwriteException catch (fallbackError, fallbackStack) {
        AppLogger.error(
          _tag,
          'Profile fallback upsert failed',
          fallbackError,
          fallbackStack,
        );
      }
    }
  }

  Future<void> _upsertUserProfile({
    required int currentStreak,
    required int bestStreak,
  }) async {
    // Read existing profile to preserve other fields
    final existing = await _getDoc(
      collectionId: _userProfiles,
      documentId: _userId,
    );

    await _upsertProfile(
      {
        'user_id': _userId,
        'display_name': existing?.data['display_name'] as String? ?? '',
        'avatar_url': existing?.data['avatar_url'] as String? ?? '',
        'total_counts': existing?.data['total_counts'] as int? ?? 0,
        'total_malas': existing?.data['total_malas'] as int? ?? 0,
        'total_sessions': existing?.data['total_sessions'] as int? ?? 0,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'today_counts': existing?.data['today_counts'] as int? ?? 0,
        'last_sync_at': _nowIso(),
      },
    );
  }

  LifetimeStats _aggregateDailyStats(Map<String, DailyStats> dailyStats) {
    var totalCounts = 0;
    var totalMalas = 0;
    var totalSessions = 0;

    for (final day in dailyStats.values) {
      totalCounts += day.counts;
      totalMalas += day.malas;
      totalSessions += day.sessions;
    }

    return LifetimeStats(
      totalCounts: totalCounts,
      totalMalas: totalMalas,
      totalSessions: totalSessions,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Load a single daily stats document from cloud for a given date.
  /// Used by SyncService for per-day conflict resolution.
  Future<DailyStats?> loadDailyStatsForDate(String date) async {
    final doc = await _getDoc(
      collectionId: _dailyStats,
      documentId: _dailyStatsDocId(date),
    );
    if (doc == null) return null;
    return DailyStats(
      date: date,
      counts: doc.data['counts'] as int? ?? 0,
      malas: doc.data['malas'] as int? ?? 0,
      sessions: doc.data['sessions'] as int? ?? 0,
      durationSeconds: doc.data['duration_seconds'] as int? ?? 0,
    );
  }

  /// Save a single daily stats entry. Used by SyncService.
  Future<void> saveSingleDailyStats(String date, DailyStats stats) async {
    await _upsertDailyStatsDoc(date, stats);
  }

  // ── Leaderboard ─────────────────────────────────────────────────

  Future<List<LeaderboardEntry>> getTopUsers({
    int limit = 50,
    LeaderboardSort sortBy = LeaderboardSort.totalCounts,
  }) async {
    final sortAttr = switch (sortBy) {
      LeaderboardSort.totalCounts => 'total_counts',
      LeaderboardSort.todayCounts => 'today_counts',
      LeaderboardSort.currentStreak => 'current_streak',
    };

    final minMalasCount = kMalaSize * kMinStreakMalas; // 324

    try {
      final queries = <String>[
        if (sortBy == LeaderboardSort.todayCounts)
          Query.greaterThan('today_counts', minMalasCount - 1),
        if (sortBy == LeaderboardSort.currentStreak)
          Query.greaterThan('current_streak', 0),
        Query.orderDesc(sortAttr),
        Query.limit(limit),
      ];

      final result = await _databases.listDocuments(
        databaseId: _db,
        collectionId: _userProfiles,
        queries: queries,
      );

      return result.documents.asMap().entries.map((entry) {
        final idx = entry.key;
        final doc = entry.value;
        final data = doc.data;
        return LeaderboardEntry(
          userId: data['user_id'] as String? ?? '',
          displayName: data['display_name'] as String? ?? 'Anonymous',
          avatarUrl: data['avatar_url'] as String?,
          totalCounts: data['total_counts'] as int? ?? 0,
          totalMalas: data['total_malas'] as int? ?? 0,
          currentStreak: data['current_streak'] as int? ?? 0,
          todayCounts: data['today_counts'] as int? ?? 0,
          rank: idx + 1,
        );
      }).toList();
    } on AppwriteException catch (e, st) {
      AppLogger.error(_tag, 'getTopUsers failed', e, st);
      return [];
    }
  }

  Future<int> getUserRank({
    required int totalCounts,
    LeaderboardSort sortBy = LeaderboardSort.totalCounts,
  }) async {
    final sortAttr = switch (sortBy) {
      LeaderboardSort.totalCounts => 'total_counts',
      LeaderboardSort.todayCounts => 'today_counts',
      LeaderboardSort.currentStreak => 'current_streak',
    };

    final minMalasCount = kMalaSize * kMinStreakMalas;

    try {
      final queries = <String>[
        if (sortBy == LeaderboardSort.todayCounts)
          Query.greaterThan('today_counts', minMalasCount - 1),
        Query.greaterThan(sortAttr, totalCounts),
        Query.limit(1),
      ];
      final result = await _databases.listDocuments(
        databaseId: _db,
        collectionId: _userProfiles,
        queries: queries,
      );
      return result.total + 1;
    } on AppwriteException catch (e, st) {
      AppLogger.error(_tag, 'getUserRank failed', e, st);
      return 0;
    }
  }
}
