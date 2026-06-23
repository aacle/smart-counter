/// One-time setup script: creates the Appwrite database, collections,
/// attributes, indexes, and permissions for Smart Naam Jap 2.0.
///
/// Usage:
///   cd tool && dart pub get && dart run setup_appwrite.dart
///
/// Requires `dart_appwrite` (server SDK) — see tool/pubspec.yaml.
library;

import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart';
import 'package:dart_appwrite/src/enums.dart' as internal;

// ── Configuration ────────────────────────────────────────────────────────────
const _endpoint = 'https://sgp.cloud.appwrite.io/v1';
const _projectId = '6a38c0ea003bacdeabb9';
const _apiKey =
    'standard_21bdba02ed2c6a8645734b3dd49a95de5296614f95715f5ac5dd04f3c6b8fa9d'
    'd9eca69313a5bd19e463dda62ee4d17a88732edb3631936ebcafc4300717bd1237c7a1fd8'
    'cee4720f0cf7a9ff744eed2b6e93eb74dc1b5065f52999e91e59c3162ae1f8cb97ce7cf3e'
    '73ce50ae53c3dcd579c5234ddcb72f5bcb9975d1ecf638';

// IDs we'll assign (deterministic so re-runs are idempotent)
const _databaseId = 'smart_naam_jap';
const _dailyStatsId = 'daily_stats';
const _userSettingsId = 'user_settings';
const _userProfilesId = 'user_profiles';

// ── Main ─────────────────────────────────────────────────────────────────────
Future<void> main() async {
  final client = Client()
    ..setEndpoint(_endpoint)
    ..setProject(_projectId)
    ..setKey(_apiKey)
    ..setSelfSigned(status: false);

  final databases = Databases(client);

  // 1. Create database
  await _createDatabase(databases);

  // 2. Create collections + attributes + indexes
  await _createDailyStatsCollection(databases);
  await _createUserSettingsCollection(databases);
  await _createUserProfilesCollection(databases);
  await _backfillUserProfiles(databases);

  print('\n=== Setup complete! ===');
  print('Database ID : $_databaseId');
  print('Collections : $_dailyStatsId, $_userSettingsId, $_userProfilesId');
  print('\nCopy these IDs into lib/core/constants/appwrite_constants.dart');
}

// ── Database ─────────────────────────────────────────────────────────────────
Future<void> _createDatabase(Databases db) async {
  try {
    await db.get(databaseId: _databaseId);
    print('[✓] Database "$_databaseId" already exists');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      await db.create(
        databaseId: _databaseId,
        name: 'Smart Naam Jap',
        enabled: true,
      );
      print('[+] Created database "$_databaseId"');
    } else {
      rethrow;
    }
  }
}

// ── daily_stats ──────────────────────────────────────────────────────────────
Future<void> _createDailyStatsCollection(Databases db) async {
  await _ensureCollection(
    db,
    collectionId: _dailyStatsId,
    name: 'Daily Stats',
    permissions: [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    documentSecurity: true,
  );

  // Attributes
  await _ensureStringAttr(db, _dailyStatsId, 'user_id', 36, required: true);
  await _ensureStringAttr(db, _dailyStatsId, 'date', 10, required: true);
  await _ensureIntAttr(db, _dailyStatsId, 'counts', required: true);
  await _ensureIntAttr(db, _dailyStatsId, 'malas', required: true);
  await _ensureIntAttr(db, _dailyStatsId, 'sessions', required: true);
  await _ensureIntAttr(db, _dailyStatsId, 'duration_seconds', required: true);
  await _ensureStringAttr(db, _dailyStatsId, 'updated_at', 30, required: true);

  // Wait for attributes to be available before creating indexes
  await _waitForAttributes(db, _dailyStatsId);

  // Indexes
  await _ensureIndex(
    db,
    _dailyStatsId,
    key: 'user_date',
    type: IndexType.unique,
    attributes: ['user_id', 'date'],
  );
  await _ensureIndex(
    db,
    _dailyStatsId,
    key: 'user_id_idx',
    type: IndexType.key,
    attributes: ['user_id'],
  );
}

// ── user_settings ────────────────────────────────────────────────────────────
Future<void> _createUserSettingsCollection(Databases db) async {
  await _ensureCollection(
    db,
    collectionId: _userSettingsId,
    name: 'User Settings',
    permissions: [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    documentSecurity: true,
  );

  await _ensureStringAttr(db, _userSettingsId, 'user_id', 36, required: true);
  await _ensureStringAttr(db, _userSettingsId, 'settings_json', 16000,
      required: true);
  await _ensureStringAttr(db, _userSettingsId, 'updated_at', 30,
      required: true);

  await _waitForAttributes(db, _userSettingsId);

  await _ensureIndex(
    db,
    _userSettingsId,
    key: 'user_id_unique',
    type: IndexType.unique,
    attributes: ['user_id'],
  );
}

// ── user_profiles ────────────────────────────────────────────────────────────
Future<void> _createUserProfilesCollection(Databases db) async {
  await _ensureCollection(
    db,
    collectionId: _userProfilesId,
    name: 'User Profiles',
    permissions: [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    documentSecurity: true,
  );

  await _ensureStringAttr(db, _userProfilesId, 'user_id', 36, required: true);
  await _ensureStringAttr(db, _userProfilesId, 'display_name', 100,
      required: true);
  await _ensureStringAttr(db, _userProfilesId, 'avatar_url', 500,
      required: false);
  await _ensureIntAttr(db, _userProfilesId, 'total_counts', required: true);
  await _ensureIntAttr(db, _userProfilesId, 'total_malas', required: true);
  await _ensureIntAttr(db, _userProfilesId, 'total_sessions', required: true);
  await _ensureIntAttr(db, _userProfilesId, 'current_streak', required: true);
  await _ensureIntAttr(db, _userProfilesId, 'best_streak', required: true);
  await _ensureIntAttr(
    db,
    _userProfilesId,
    'today_counts',
    defaultValue: 0,
  );
  await _ensureIntAttr(
    db,
    _userProfilesId,
    'best_daily_malas',
    defaultValue: 0,
  );
  await _ensureStringAttr(db, _userProfilesId, 'last_sync_at', 30,
      required: true);

  await _waitForAttributes(db, _userProfilesId);

  await _ensureIndex(
    db,
    _userProfilesId,
    key: 'user_id_unique',
    type: IndexType.unique,
    attributes: ['user_id'],
  );
  // Indexes for leaderboard queries
  await _ensureIndex(
    db,
    _userProfilesId,
    key: 'total_counts_desc',
    type: IndexType.key,
    attributes: ['total_counts'],
    orders: ['DESC'],
  );
  await _ensureIndex(
    db,
    _userProfilesId,
    key: 'today_counts_desc',
    type: IndexType.key,
    attributes: ['today_counts'],
    orders: ['DESC'],
  );
  await _ensureIndex(
    db,
    _userProfilesId,
    key: 'current_streak_desc',
    type: IndexType.key,
    attributes: ['current_streak'],
    orders: ['DESC'],
  );
}

Future<void> _backfillUserProfiles(Databases db) async {
  print('\n[~] Backfilling user_profiles from daily_stats...');

  final todayKey = _dateKey(DateTime.now());
  final totalsByUser = <String, _ProfileTotals>{};
  String? cursor;

  while (true) {
    final docs = await _listDocumentsRaw(
      db,
      _dailyStatsId,
      queries: [
        Query.limit(100),
        if (cursor != null) Query.cursorAfter(cursor),
      ],
    );

    for (final doc in docs) {
      final data = doc;
      final userId = data['user_id'] as String?;
      if (userId == null || userId.isEmpty) continue;

      final totals = totalsByUser.putIfAbsent(userId, _ProfileTotals.new);
      final counts = data['counts'] as int? ?? 0;
      final malas = data['malas'] as int? ?? 0;
      totals.totalCounts += counts;
      totals.totalMalas += malas;
      totals.totalSessions += data['sessions'] as int? ?? 0;

      if (malas > totals.bestDailyMalas) {
        totals.bestDailyMalas = malas;
      }

      if (data['date'] == todayKey) {
        totals.todayCounts = counts;
      }
    }

    if (docs.length < 100) break;
    cursor = docs.last[r'$id'] as String?;
  }

  for (final entry in totalsByUser.entries) {
    final userId = entry.key;
    final totals = entry.value;
    Map<String, dynamic> existing = const {};

    try {
      final doc = await _getDocumentRaw(db, _userProfilesId, userId);
      existing = doc;
    } on AppwriteException catch (e) {
      if (e.code != 404) rethrow;
    }

    final data = {
      'user_id': userId,
      'display_name': existing['display_name'] as String? ?? '',
      'avatar_url': existing['avatar_url'] as String? ?? '',
      'total_counts': totals.totalCounts,
      'total_malas': totals.totalMalas,
      'total_sessions': totals.totalSessions,
      'current_streak': existing['current_streak'] as int? ?? 0,
      'best_streak': existing['best_streak'] as int? ?? 0,
      'today_counts': totals.todayCounts,
      'best_daily_malas': totals.bestDailyMalas,
      'last_sync_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (existing.isEmpty) {
      await _createDocumentRaw(
        db,
        _userProfilesId,
        userId,
        data: data,
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
    } else {
      await _updateDocumentRaw(db, _userProfilesId, userId, data: data);
    }
  }

  print('  [✓] Backfilled ${totalsByUser.length} user profile(s)');
}

Future<List<Map<String, dynamic>>> _listDocumentsRaw(
  Databases db,
  String collectionId, {
  List<String> queries = const [],
}) async {
  final response = await db.client.call(
    internal.HttpMethod.get,
    path: '/databases/$_databaseId/collections/$collectionId/documents',
    params: {'queries': queries},
    headers: {'content-type': 'application/json'},
  );

  final data = (response as dynamic).data as Map<String, dynamic>;
  final documents = data['documents'] as List<dynamic>? ?? const [];
  return documents.cast<Map<String, dynamic>>();
}

Future<Map<String, dynamic>> _getDocumentRaw(
  Databases db,
  String collectionId,
  String documentId,
) async {
  final response = await db.client.call(
    internal.HttpMethod.get,
    path:
        '/databases/$_databaseId/collections/$collectionId/documents/$documentId',
    headers: {'content-type': 'application/json'},
  );
  return (response as dynamic).data as Map<String, dynamic>;
}

Future<void> _createDocumentRaw(
  Databases db,
  String collectionId,
  String documentId, {
  required Map<String, dynamic> data,
  List<String> permissions = const [],
}) async {
  await db.client.call(
    internal.HttpMethod.post,
    path: '/databases/$_databaseId/collections/$collectionId/documents',
    params: {
      'documentId': documentId,
      'data': data,
      'permissions': permissions,
    },
    headers: {'content-type': 'application/json'},
  );
}

Future<void> _updateDocumentRaw(
  Databases db,
  String collectionId,
  String documentId, {
  required Map<String, dynamic> data,
}) async {
  await db.client.call(
    internal.HttpMethod.patch,
    path:
        '/databases/$_databaseId/collections/$collectionId/documents/$documentId',
    params: {'data': data},
    headers: {'content-type': 'application/json'},
  );
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _ProfileTotals {
  int totalCounts = 0;
  int totalMalas = 0;
  int totalSessions = 0;
  int todayCounts = 0;
  int bestDailyMalas = 0;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Future<void> _ensureCollection(
  Databases db, {
  required String collectionId,
  required String name,
  required List<String> permissions,
  bool documentSecurity = false,
}) async {
  try {
    // Use raw client call to avoid SDK type-cast bug in Collection.fromMap
    // where List<dynamic> can't be cast to List<String>.
    final apiPath = '/databases/$_databaseId/collections/$collectionId';
    await db.client.call(
      internal.HttpMethod.get,
      path: apiPath,
      headers: {'content-type': 'application/json'},
    );
    print('[✓] Collection "$collectionId" already exists');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      final apiPath = '/databases/$_databaseId/collections';
      await db.client.call(
        internal.HttpMethod.post,
        path: apiPath,
        params: {
          'collectionId': collectionId,
          'name': name,
          'permissions': permissions,
          'documentSecurity': documentSecurity,
          'enabled': true,
        },
        headers: {'content-type': 'application/json'},
      );
      print('[+] Created collection "$collectionId"');
    } else {
      rethrow;
    }
  }
}

Future<void> _ensureStringAttr(
  Databases db,
  String collectionId,
  String key,
  int size, {
  bool required = false,
  String? defaultValue,
}) async {
  try {
    await db.getAttribute(
      databaseId: _databaseId,
      collectionId: collectionId,
      key: key,
    );
    print('  [✓] Attribute "$key" already exists in "$collectionId"');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      await db.createStringAttribute(
        databaseId: _databaseId,
        collectionId: collectionId,
        key: key,
        size: size,
        xrequired: required,
        xdefault: defaultValue,
      );
      print('  [+] Created string attribute "$key" in "$collectionId"');
    } else {
      rethrow;
    }
  }
}

Future<void> _ensureIntAttr(
  Databases db,
  String collectionId,
  String key, {
  bool required = false,
  int? defaultValue,
}) async {
  try {
    await db.getAttribute(
      databaseId: _databaseId,
      collectionId: collectionId,
      key: key,
    );
    print('  [✓] Attribute "$key" already exists in "$collectionId"');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      await db.createIntegerAttribute(
        databaseId: _databaseId,
        collectionId: collectionId,
        key: key,
        xrequired: required,
        xdefault: defaultValue,
      );
      print('  [+] Created integer attribute "$key" in "$collectionId"');
    } else {
      rethrow;
    }
  }
}

Future<void> _waitForAttributes(Databases db, String collectionId) async {
  print('  [~] Waiting for attributes to be ready in "$collectionId"...');
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(const Duration(seconds: 2));
    final attrs = await db.listAttributes(
      databaseId: _databaseId,
      collectionId: collectionId,
    );
    final allReady = attrs.attributes.every((a) {
      final map = a as Map<String, dynamic>;
      return map['status'] == 'available';
    });
    if (allReady && attrs.attributes.isNotEmpty) {
      print('  [✓] All attributes ready in "$collectionId"');
      return;
    }
  }
  print('  [!] Timed out waiting for attributes in "$collectionId"');
  exit(1);
}

Future<void> _ensureIndex(
  Databases db,
  String collectionId, {
  required String key,
  required IndexType type,
  required List<String> attributes,
  List<String>? orders,
}) async {
  try {
    // Use raw client call to avoid SDK type-cast bug in Index.fromMap
    final getPath =
        '/databases/$_databaseId/collections/$collectionId/indexes/$key';
    await db.client.call(
      internal.HttpMethod.get,
      path: getPath,
      headers: {'content-type': 'application/json'},
    );
    print('  [✓] Index "$key" already exists in "$collectionId"');
  } on AppwriteException catch (e) {
    if (e.code == 404) {
      final createPath =
          '/databases/$_databaseId/collections/$collectionId/indexes';
      await db.client.call(
        internal.HttpMethod.post,
        path: createPath,
        params: {
          'key': key,
          'type': type.value,
          'attributes': attributes,
          if (orders != null) 'orders': orders,
        },
        headers: {'content-type': 'application/json'},
      );
      print('  [+] Created index "$key" in "$collectionId"');
    } else {
      rethrow;
    }
  }
}
