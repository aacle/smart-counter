import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/colors.dart';
import '../../../../data/storage_keys.dart';
import '../../providers/auth_provider.dart';

/// A carousel dialog shown to existing offline users to encourage them
/// to sign in and back up their data to the cloud.
class MigrationDialog extends ConsumerStatefulWidget {
  const MigrationDialog({super.key});

  /// Check if the dialog should be shown and show it if necessary.
  static Future<void> checkAndShow(BuildContext context, WidgetRef ref) async {
    // 1. Must be unauthenticated
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) return;

    // 2. Check if already seen
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(StorageKeys.hasSeenMigrationPopup) ?? false;
    if (hasSeen) return;

    // 3. Check if they have significant local data
    // (We only show this to existing users, not brand new installs)
    final lifetimeCounts = prefs.getInt(StorageKeys.lifetimeCounts) ?? 0;
    if (lifetimeCounts < 50) return;

    // Show dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false, // Force them to interact
        builder: (context) => const MigrationDialog(),
      );
      
      // Mark as seen
      await prefs.setBool(StorageKeys.hasSeenMigrationPopup, true);
    }
  }

  @override
  ConsumerState<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends ConsumerState<MigrationDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.cloud_sync_rounded,
      title: 'Never Lose Your Progress',
      description:
          'Smart Naam Jap now supports cloud sync! Sign in to automatically back up your counts and streaks.',
    ),
    _OnboardingPage(
      icon: Icons.leaderboard_rounded,
      title: 'Global Leaderboard',
      description:
          'Join the community! See how others are doing and stay motivated with the upcoming leaderboard.',
    ),
    _OnboardingPage(
      icon: Icons.security_rounded,
      title: 'Your Data is Safe',
      description:
          'Sign in with Google securely. Your existing offline data will be instantly migrated to your new account.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Carousel
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        page.icon,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Buttons
            if (_currentPage == _pages.length - 1) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    // Trigger sign in
                    await ref.read(authProvider.notifier).signInWithGoogle();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Continue Offline',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
