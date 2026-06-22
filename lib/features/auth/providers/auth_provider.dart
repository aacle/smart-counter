import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
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

  AuthNotifier(this._authService) : super(const AuthState());

  /// Called once at app startup to silently check for an existing session.
  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    final user = await _authService.restoreSession();
    if (user != null) {
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
      state = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      // Even if server-side sign-out fails, clear local state
      // so the user isn't stuck in a broken state.
      await LocalDataRepository.instance.clearAllSyncableData();
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
