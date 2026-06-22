import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import '../../core/constants/appwrite_constants.dart';
import '../../core/utils/app_logger.dart';
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
    try {
      final user = await _account.get();
      final appUser = _mapUser(user);
      AppLogger.info(_tag, 'Session restored for ${appUser.displayName}');
      return appUser;
    } on AppwriteException catch (e) {
      // 401 = no active session — expected for first-time / signed-out users
      if (e.code == 401) {
        AppLogger.info(_tag, 'No active session');
      } else {
        AppLogger.error(_tag, 'Session restore failed', e);
      }
      return null;
    } catch (e) {
      AppLogger.error(_tag, 'Unexpected error restoring session', e);
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

      // createOAuth2Session opens a browser, handles the redirect,
      // and stores the session cookie automatically.
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        scopes: ['profile', 'email'],
      );

      // After the OAuth redirect completes, fetch the user profile.
      final user = await _account.get();
      final appUser = _mapUser(user);
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
    try {
      await _account.deleteSession(sessionId: 'current');
      AppLogger.info(_tag, 'Signed out successfully');
      return true;
    } on AppwriteException catch (e) {
      AppLogger.error(_tag, 'Sign-out failed', e);
      return false;
    } catch (e) {
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
  AppUser _mapUser(models.User user) {
    return AppUser(
      id: user.$id,
      name: user.name,
      email: user.email,
      createdAt: DateTime.parse(user.$createdAt),
    );
  }
}
