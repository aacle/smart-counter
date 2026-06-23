import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/appwrite_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/storage_keys.dart';
import 'domain/app_user.dart';

const _tag = 'AuthService';

/// Manages authentication via Appwrite + Google OAuth.
///
/// Responsibilities:
/// - Initialize the Appwrite [Client] (singleton)
/// - Sign in with Google OAuth
/// - Restore existing sessions silently
/// - Sign out
/// - Convert Appwrite [models.User] → [AppUser]
///
/// Design notes:
/// - Singleton so the Appwrite [Client] is created once and shared
/// - The [Account] object is derived from the shared client
/// - No Riverpod dependency — pure Dart service, provided via Riverpod elsewhere
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  late final Client _client;
  late final Account _account;
  bool _initialized = false;

  /// The shared Appwrite [Client]. Available after [initialize].
  Client get client {
    assert(_initialized, 'AuthService.initialize() must be called first');
    return _client;
  }

  // ── Initialization ──────────────────────────────────────────────

  /// Must be called once at app startup (in main.dart).
  void initialize() {
    if (_initialized) return;

    _client = Client()
      ..setEndpoint(AppwriteConstants.endpoint)
      ..setProject(AppwriteConstants.projectId)
      ..setSelfSigned(status: false);

    _account = Account(_client);
    _initialized = true;
    AppLogger.info(_tag, 'Appwrite client initialized');
  }

  // ── Session Management ──────────────────────────────────────────

  /// Try to restore the current session. Returns [AppUser] if a valid
  /// session exists, `null` otherwise. This is a silent check — no
  /// browser/webview is opened.
  Future<AppUser?> restoreSession() async {
    final cachedUser = await cachedUserOrNull();

    try {
      final user = await _account.get();
      final avatarUrl = await _cachedAvatarUrl(user.$id);
      final appUser = _mapUser(user, avatarUrl: avatarUrl);
      await _cacheAuthUser(appUser);
      AppLogger.info(_tag, 'Session restored for ${appUser.displayName}');
      return appUser;
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        AppLogger.info(_tag, 'No active session');
        await _clearAuthUserCache();
        await _clearAvatarCache(cachedUser?.id);
      } else {
        AppLogger.error(_tag, 'Session restore failed', e);
        if (cachedUser != null) {
          AppLogger.info(_tag, 'Using cached auth user while offline');
          return cachedUser;
        }
      }
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Unexpected error restoring session', e);
      if (cachedUser != null) {
        AppLogger.info(_tag, 'Using cached auth user after restore error');
        return cachedUser;
      }
      return null;
    }
  }

  /// Returns the last known authenticated user without touching the network.
  Future<AppUser?> cachedUserOrNull() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeys.cachedAuthUser);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final user = AppUser.fromJson(data);
      return user.id.isEmpty || user.email.isEmpty ? null : user;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load cached auth user', e);
      return null;
    }
  }

  // ── Google OAuth ────────────────────────────────────────────────

  /// Launch Google OAuth sign-in flow.
  ///
  /// Opens an in-app browser/webview → Google consent → Appwrite creates
  /// a session → redirects back to the app via deeplink.
  ///
  /// Returns [AppUser] on success, `null` if the user cancels or an
  /// error occurs.
  Future<AppUser?> signInWithGoogle() async {
    try {
      AppLogger.info(_tag, 'Starting Google OAuth flow...');

      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        scopes: ['profile', 'email'],
      );

      final user = await _account.get();
      final avatarUrl = await _fetchGoogleAvatar();
      if (avatarUrl != null) {
        await _cacheAvatarUrl(user.$id, avatarUrl);
      }
      final appUser = _mapUser(user, avatarUrl: avatarUrl);
      await _cacheAuthUser(appUser);
      AppLogger.info(_tag, 'Signed in as ${appUser.displayName}');
      return appUser;
    } on AppwriteException catch (e) {
      AppLogger.error(_tag, 'Google sign-in failed', e);
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Unexpected error during sign-in', e);
      return null;
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────

  /// Delete the current session (sign out).
  /// Returns `true` on success, `false` on failure.
  Future<bool> signOut() async {
    final userId = await _currentUserIdOrNull();
    try {
      await _account.deleteSession(sessionId: 'current');
      await _clearAuthUserCache();
      await _clearAvatarCache(userId);
      AppLogger.info(_tag, 'Signed out successfully');
      return true;
    } on AppwriteException catch (e) {
      await _clearAvatarCache(userId);
      await _clearAuthUserCache();
      AppLogger.error(_tag, 'Sign-out failed', e);
      return false;
    } catch (e) {
      await _clearAvatarCache(userId);
      await _clearAuthUserCache();
      AppLogger.error(_tag, 'Unexpected error during sign-out', e);
      return false;
    }
  }

  // ── Get Current User ────────────────────────────────────────────

  /// Fetch the currently authenticated user. Returns `null` if no
  /// session is active.
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return _mapUser(user);
    } catch (_) {
      return null;
    }
  }

  // ── Private Helpers ─────────────────────────────────────────────

  /// Convert Appwrite [models.User] → domain [AppUser].
  AppUser _mapUser(models.User user, {String? avatarUrl}) {
    return AppUser(
      id: user.$id,
      name: user.name,
      email: user.email,
      avatarUrl: avatarUrl,
      createdAt: DateTime.parse(user.$createdAt),
    );
  }

  /// Fetch real Google profile picture URL using the OAuth access token.
  Future<String?> _fetchGoogleAvatar() async {
    try {
      final sessions = await _account.listSessions();
      final googleSession = sessions.sessions
          .cast<models.Session?>()
          .firstWhere((s) => s?.provider == 'google', orElse: () => null);
      if (googleSession == null) return null;

      final token = googleSession.providerAccessToken;
      if (token.isEmpty) return null;

      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final pic = data['picture'] as String?;
          if (pic != null && pic.isNotEmpty) {
            // Ensure HTTPS
            return pic.startsWith('http://')
                ? pic.replaceFirst('http://', 'https://')
                : pic;
          }
        }
      } finally {
        client.close();
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to fetch Google avatar', e, st);
    }
    return null;
  }

  static const _legacyAvatarCacheKey = 'cached_google_avatar_url';
  static const _avatarCachePrefix = 'cached_google_avatar_url_';

  String _avatarCacheKey(String userId) => '$_avatarCachePrefix$userId';

  Future<String?> _currentUserIdOrNull() async {
    try {
      final user = await _account.get();
      return user.$id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheAvatarUrl(String userId, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarCacheKey(userId), url);
    await prefs.remove(_legacyAvatarCacheKey);
  }

  Future<void> _cacheAuthUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        StorageKeys.cachedAuthUser, jsonEncode(user.toJson()));
  }

  Future<void> _clearAuthUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.cachedAuthUser);
  }

  Future<String?> _cachedAvatarUrl(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarCacheKey(userId));
  }

  Future<void> _clearAvatarCache(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.remove(_avatarCacheKey(userId));
    }
    await prefs.remove(_legacyAvatarCacheKey);
  }
}
