import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/providers/auth_provider.dart';
import 'cloud_data_repository.dart';
import 'data_repository.dart';
import 'hybrid_data_repository.dart';
import 'local_data_repository.dart';
import 'sync_service.dart';

/// Provides the active [DataRepository] implementation.
///
/// - Unauthenticated → [LocalDataRepository] (pure offline)
/// - Authenticated → [HybridDataRepository] (local-first + cloud write-through)
///
/// When the auth state changes, this provider is invalidated and all
/// downstream providers (counter, settings, insights) are recreated
/// with the new repository.
final dataRepositoryProvider = Provider<DataRepository>((ref) {
  final authState = ref.watch(authProvider);

  if (authState.isAuthenticated && authState.user != null) {
    final userId = authState.user!.id;
    final cloudRepo = CloudDataRepository.forUser(userId);

    return HybridDataRepository(
      local: LocalDataRepository.instance,
      cloud: cloudRepo,
    );
  }

  return LocalDataRepository.instance;
});

/// Provides the [CloudDataRepository] for the current user.
/// Returns `null` if not authenticated.
final cloudRepositoryProvider = Provider<CloudDataRepository?>((ref) {
  final authState = ref.watch(authProvider);

  if (authState.isAuthenticated && authState.user != null) {
    return CloudDataRepository.forUser(authState.user!.id);
  }

  return null;
});

/// Provides the [SyncService] singleton.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});

/// Provides a stream of [SyncResult] for UI status updates.
final syncStatusProvider = StreamProvider<SyncResult>((ref) {
  return SyncService.instance.statusStream;
});
