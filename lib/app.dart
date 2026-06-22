import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'core/utils/app_logger.dart';
import 'data/cloud_data_repository.dart';
import 'data/sync_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/counter/presentation/counter_screen.dart';
import 'features/settings/providers/settings_provider.dart';

/// Smart Naam Jap 2.0 - Distraction-free spiritual counter
class SmartNaamJapApp extends ConsumerStatefulWidget {
  const SmartNaamJapApp({super.key});

  @override
  ConsumerState<SmartNaamJapApp> createState() => _SmartNaamJapAppState();
}

class _SmartNaamJapAppState extends ConsumerState<SmartNaamJapApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Silently try to restore an existing Appwrite session.
    // Non-blocking — the app is fully usable while this runs.
    Future.microtask(() {
      ref.read(authProvider.notifier).restoreSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerSyncIfAuthenticated();
    }
  }

  /// Trigger a full bidirectional sync if the user is signed in.
  void _triggerSyncIfAuthenticated() {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.user != null) {
      final user = authState.user!;
      final cloudRepo = CloudDataRepository.forUser(user.id);
      SyncService.instance
          .sync(user: user, cloudRepo: cloudRepo)
          .then((_) {})
          .catchError((Object e) {
        AppLogger.error('App', 'Background sync failed', e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only watch the selectedTheme to minimize rebuilds
    final selectedTheme = ref.watch(
      settingsProvider.select((s) => s.selectedTheme),
    );

    // Listen for auth state changes to trigger sync on sign-in.
    // Using ref.listen in build is the Riverpod-recommended pattern
    // for side effects that depend on provider changes.
    ref.listen<AuthState>(authProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      if (!wasAuthenticated && next.isAuthenticated && next.user != null) {
        // Just signed in (or session restored) — run initial sync
        AppLogger.info('App', 'Auth state changed to authenticated, syncing...');
        final user = next.user!;
        final cloudRepo = CloudDataRepository.forUser(user.id);
        SyncService.instance
            .sync(user: user, cloudRepo: cloudRepo)
            .then((_) {})
            .catchError((Object e) {
          AppLogger.error('App', 'Initial sync after sign-in failed', e);
        });
      }

      if (wasAuthenticated && !next.isAuthenticated) {
        // Just signed out — reset sync state
        SyncService.instance.reset();
      }
    });

    // Apply the current theme
    AppColors.setTheme(selectedTheme);

    return MaterialApp(
      title: 'Nam Jap Counter - नाम जप',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CounterScreen(),
    );
  }
}
