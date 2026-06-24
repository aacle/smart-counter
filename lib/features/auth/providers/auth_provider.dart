import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/local_data_repository.dart';
import '../auth_service.dart';
import '../domain/app_user.dart';

/// The possible states of the auth system.
enum AuthStatus {
  /// Initial state — haven't checked for a session yet.
  unknown,

  /// Currently checking for an existing session.
  loading,

  /// User is authenticated.
  authenticated,

  /// No active session / user chose to stay offline.
  unauthenticated,
}

/// Auth state — holds the current status and optional user.
class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }

  @override
  String toString() => 'AuthState($status, user: ${user?.displayName})';
}

/// Notifier that manages auth state transitions.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  /// Called when sign-in discovers local data from a different user.
  /// The UI sets this before calling [signInWithGoogle] to show a confirmation
  /// dialog. Returns `true` to wipe the stale data, `false` to keep it.
  /// If unset, defaults to wiping (safe).
  Future<bool> Function()? onConfirmCrossUserDataWipe;

  AuthNotifier(this._authService) : super(const AuthState()) {
    // When the session is revoked server-side (e.g. another device logged
    // in with max sessions = 1), any Appwrite API call returns 401 and
    // triggers this callback — transitions the UI to unauthenticated and
    // clears local state so the app doesn't hold stale user data.
    _authService.onSessionExpired = () {
      LocalDataRepository.instance.clearAllSyncableData();
      PaintingBinding.instance.imageCache.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    };
  }

  /// Called once at app startup to silently check for an existing session.
  Future<void> restoreSession() async {
    final cachedUser = await _authService.cachedUserOrNull();
    if (cachedUser != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: cachedUser,
      );
    } else {
      state = state.copyWith(status: AuthStatus.loading);
    }

    final user = await _authService.restoreSession();
    if (user != null) {
      // Tag that this user's data is in local storage. Since restoreSession
      // runs silently at app start (no user interaction), cross-user data
      // can't occur here — the session can only be restored for the same user.
      await LocalDataRepository.instance.saveLastUserId(user.id);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Trigger Google OAuth sign-in.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);

    final user = await _authService.signInWithGoogle();
    if (user != null) {
      final localRepo = LocalDataRepository.instance;

      // Detect stale local data from a different user — critical guard
      // against leaderboard corruption when devices are shared.
      final lastUserId = await localRepo.loadLastUserId();
      final isCrossUser = lastUserId != null && lastUserId != user.id;

      if (isCrossUser) {
        final shouldWipe =
            await onConfirmCrossUserDataWipe?.call() ?? false;
        if (shouldWipe) {
          await localRepo.clearAllSyncableData();
          AppLogger.info(
            'AuthNotifier',
            'User confirmed — wiped stale local data from '
            'previous user $lastUserId',
          );
        } else {
          // User declined to wipe stale data — abort sign-in to protect
          // the leaderboard from cross-user contamination.
          AppLogger.info(
            'AuthNotifier',
            'User declined wipe — sign-in aborted',
          );
          state = const AuthState(status: AuthStatus.unauthenticated);
          return false;
        }
      }

      // Tag local data as belonging to this user going forward.
      await localRepo.saveLastUserId(user.id);

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Sign-in was cancelled or failed. Please try again.',
      );
      return false;
    }
  }

  /// Sign out and return to unauthenticated state.
  Future<void> signOut() async {
    final success = await _authService.signOut();
    if (success) {
      // Clear local data so guest mode starts fresh (0 counts)
      await LocalDataRepository.instance.clearAllSyncableData();
      PaintingBinding.instance.imageCache.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      // Even if server-side sign-out fails, clear local state
      // so the user isn't stuck in a broken state.
      await LocalDataRepository.instance.clearAllSyncableData();
      PaintingBinding.instance.imageCache.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

/// Provides the [AuthNotifier] and [AuthState] to the widget tree.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService.instance);
});

/// Convenience provider — the current [AppUser] or `null`.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider — whether the user is signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
