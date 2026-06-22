import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../data/data_provider.dart';
import '../../../../data/sync_service.dart';
import '../../providers/auth_provider.dart';

/// Account section shown at the top of the Settings screen.
///
/// - Signed out: shows a "Sign in with Google" card with benefits
/// - Loading: shows a spinner
/// - Signed in: shows user info + sign-out option
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          ),
          // Content based on auth state
          if (authState.isLoading)
            _buildLoadingState(context)
          else if (authState.isAuthenticated)
            _buildSignedInState(context, ref, authState)
          else
            _buildSignedOutState(context, ref, authState),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildSignedInState(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    final user = authState.user!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // User info row
          Row(
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  user.initial,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Dynamic sync status indicator
              _SyncStatusBadge(),
            ],
          ),
          const SizedBox(height: 14),
          // Sign out button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
              label: Text(
                'Sign Out',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedOutState(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Benefits text
          Text(
            'Sign in to sync your progress across devices and join the leaderboard.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          // Error message if sign-in failed
          if (authState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              authState.error!,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Google sign-in button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleSignIn(context, ref),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // "Continue offline" note
          Center(
            child: Text(
              'Your data stays on this device until you sign in',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signInWithGoogle();
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          'Your local data will be kept. You can sign in again anytime to resume syncing.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

/// Reactive sync status badge.
///
/// Shows: spinning indicator while syncing, green check on success,
/// orange warning on error, grey cloud when idle.
class _SyncStatusBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncAsync = ref.watch(syncStatusProvider);

    return syncAsync.when(
      data: (result) => _buildBadge(result),
      loading: () => _buildBadge(SyncResult.idle()),
      error: (_, __) => _buildBadge(SyncResult.error('Sync error')),
    );
  }

  Widget _buildBadge(SyncResult result) {
    final IconData icon;
    final Color color;
    final String label;
    final bool spinning;

    switch (result.status) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = AppColors.primary;
        label = 'Syncing';
        spinning = true;
      case SyncStatus.success:
        icon = Icons.check_circle;
        color = AppColors.success;
        label = 'Synced';
        spinning = false;
      case SyncStatus.error:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        label = 'Retry';
        spinning = false;
      case SyncStatus.idle:
        icon = Icons.cloud_outlined;
        color = AppColors.textMuted;
        label = 'Cloud';
        spinning = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinning)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
