import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/colors.dart';
import '../providers/settings_provider.dart';
import 'widgets/settings_tile.dart';

/// Settings screen with counting options and about section
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // === COUNTING OPTIONS ===
          const SettingsSection(title: 'Counting'),
          
          SettingsTile(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on each count',
            switchValue: settings.hapticEnabled,
            onSwitchChanged: (value) {
              ref.read(settingsProvider.notifier).setHapticEnabled(value);
            },
          ),
          
          SettingsTile(
            icon: Icons.volume_up,
            title: 'Volume Button Counting',
            subtitle: 'Use volume keys to count',
            switchValue: settings.volumeRockerEnabled,
            onSwitchChanged: (value) {
              ref.read(settingsProvider.notifier).setVolumeRockerEnabled(value);
            },
          ),
          
          
          SettingsTile(
            icon: Icons.light_mode,
            title: 'Keep Screen Awake',
            subtitle: 'Prevent screen from dimming',
            switchValue: settings.keepScreenAwake,
            onSwitchChanged: (value) {
              ref.read(settingsProvider.notifier).setKeepScreenAwake(value);
              // Apply wakelock immediately
              if (value) {
                WakelockPlus.enable();
              } else {
                WakelockPlus.disable();
              }
            },
          ),

          // === GOALS ===
          const SettingsSection(title: 'Goals'),
          
          SettingsTile(
            icon: Icons.flag,
            title: 'Daily Goal',
            subtitle: settings.dailyGoal > 0 
                ? '${settings.dailyGoal} malas per day'
                : 'Not set',
            onTap: () => _showDailyGoalDialog(context, ref, settings.dailyGoal),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ),

          // === ABOUT ===
          const SettingsSection(title: 'About'),
          
          SettingsTile(
            icon: Icons.info_outline,
            title: 'Smart Naam Jap',
            subtitle: 'Version 2.0.0',
          ),
          
          SettingsTile(
            icon: Icons.code,
            title: 'Developer',
            subtitle: 'Made with ❤️ for spiritual practice',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showDailyGoalDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    int selectedGoal = currentGoal;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Daily Goal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set your daily mala goal',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedGoal > 0
                        ? () => setState(() => selectedGoal--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedGoal == 0 ? 'Off' : '$selectedGoal',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => setState(() => selectedGoal++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'malas per day',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
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
                ref.read(settingsProvider.notifier).setDailyGoal(selectedGoal);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
