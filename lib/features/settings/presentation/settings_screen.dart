import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/colors.dart';
import '../domain/settings_state.dart';
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
            icon: Icons.music_note,
            title: 'Tap Sound',
            subtitle: 'Play sound on each count',
            switchValue: settings.tapSoundEnabled,
            onSwitchChanged: (value) {
              ref.read(settingsProvider.notifier).setTapSoundEnabled(value);
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
              if (value) {
                WakelockPlus.enable();
              } else {
                WakelockPlus.disable();
              }
            },
          ),

          // === INTERFACE ===
          const SettingsSection(title: 'Interface'),

          SettingsTile(
            icon: Icons.view_comfortable,
            title: 'Display Mode',
            subtitle: settings.interfaceMode == InterfaceMode.malaWise
                ? 'Mala-wise (108 beads focus)'
                : 'Count-wise (total focus)',
            onTap: () => _showInterfaceModeDialog(context, ref, settings.interfaceMode),
            trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
          ),
          
          SettingsTile(
            icon: Icons.title,
            title: 'Custom Title',
            subtitle: settings.customTitle.isEmpty ? 'Set a custom title' : settings.customTitle,
            onTap: () => _showCustomTitleDialog(context, ref, settings.customTitle),
            trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
          ),

          // === GOALS ===
          const SettingsSection(title: 'Goals'),
          
          SettingsTile(
            icon: Icons.category,
            title: 'Goal Type',
            subtitle: settings.goalType == GoalType.malas
                ? 'Track by Malas (108 counts)'
                : 'Track by Chant Counts',
            onTap: () => _showGoalTypeDialog(context, ref, settings.goalType),
            trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
          ),
          
          SettingsTile(
            icon: Icons.flag,
            title: 'Daily Goal',
            subtitle: _getGoalSubtitle(settings),
            onTap: () => _showDailyGoalDialog(context, ref, settings),
            trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
          ),

          // === REPORTS & NOTIFICATIONS ===
          const SettingsSection(title: 'Reports & Notifications'),
          
          SettingsTile(
            icon: Icons.date_range,
            title: 'Weekly Progress Report',
            subtitle: 'Show weekly summary on app open',
            switchValue: settings.weeklyReportEnabled,
            onSwitchChanged: (value) {
              ref.read(settingsProvider.notifier).setWeeklyReportEnabled(value);
            },
          ),
          
          SettingsTile(
            icon: Icons.calendar_month,
            title: 'Monthly Progress Report',
            subtitle: 'Show monthly summary on app open',
            switchValue: settings.monthlyReportEnabled,
            onSwitchChanged: (value) {
              ref.read(settingsProvider.notifier).setMonthlyReportEnabled(value);
            },
          ),
          
          SettingsTile(
            icon: Icons.trending_down,
            title: 'Goal Miss Reminder',
            subtitle: 'Remind when yesterday\'s goal was missed',
            switchValue: settings.goalMissNotificationEnabled,
            onSwitchChanged: (value) {
              ref.read(settingsProvider.notifier).setGoalMissNotificationEnabled(value);
            },
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

  String _getGoalSubtitle(settings) {
    if (settings.goalType == GoalType.malas) {
      return settings.dailyGoal > 0 
          ? '${settings.dailyGoal} malas per day'
          : 'Not set';
    } else {
      return settings.dailyGoalCount > 0 
          ? '${_formatNumber(settings.dailyGoalCount)} chants per day'
          : 'Not set';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return number.toString();
  }

  void _showInterfaceModeDialog(BuildContext context, WidgetRef ref, InterfaceMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Display Mode', style: Theme.of(context).textTheme.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose how the counter screen displays your progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            _buildModeOption(
              context,
              title: 'Mala-wise',
              subtitle: 'Shows 108 beads circle with progress',
              icon: Icons.all_inclusive,
              isSelected: currentMode == InterfaceMode.malaWise,
              onTap: () {
                ref.read(settingsProvider.notifier).setInterfaceMode(InterfaceMode.malaWise);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildModeOption(
              context,
              title: 'Count-wise',
              subtitle: 'Shows total count prominently',
              icon: Icons.numbers,
              isSelected: currentMode == InterfaceMode.countWise,
              onTap: () {
                ref.read(settingsProvider.notifier).setInterfaceMode(InterfaceMode.countWise);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomTitleDialog(BuildContext context, WidgetRef ref, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Custom Title', style: Theme.of(context).textTheme.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set a custom title for the counter screen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter title...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(settingsProvider.notifier).setCustomTitle(newTitle);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected 
          ? AppColors.primary.withValues(alpha: 0.15) 
          : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.5) 
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalTypeDialog(BuildContext context, WidgetRef ref, GoalType currentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Goal Type', style: Theme.of(context).textTheme.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose how to track your daily goal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            _buildModeOption(
              context,
              title: 'Malas',
              subtitle: 'Track by malas (1 mala = 108 chants)',
              icon: Icons.all_inclusive,
              isSelected: currentType == GoalType.malas,
              onTap: () {
                ref.read(settingsProvider.notifier).setGoalType(GoalType.malas);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildModeOption(
              context,
              title: 'Chant Counts',
              subtitle: 'Track by individual chant counts',
              icon: Icons.numbers,
              isSelected: currentType == GoalType.counts,
              onTap: () {
                ref.read(settingsProvider.notifier).setGoalType(GoalType.counts);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyGoalDialog(BuildContext context, WidgetRef ref, settings) {
    if (settings.goalType == GoalType.malas) {
      _showMalaGoalDialog(context, ref, settings.dailyGoal);
    } else {
      _showCountGoalDialog(context, ref, settings.dailyGoalCount);
    }
  }

  void _showMalaGoalDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    int selectedGoal = currentGoal;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Daily Mala Goal', style: Theme.of(context).textTheme.headlineMedium),
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
              Text('malas per day', style: Theme.of(context).textTheme.labelMedium),
              if (selectedGoal > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '= ${selectedGoal * 108} chants',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
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

  void _showCountGoalDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    int selectedGoal = currentGoal;
    final presets = [108, 216, 540, 1080, 10800];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Daily Count Goal', style: Theme.of(context).textTheme.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set your daily chant count goal',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              // Preset buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildPresetChip(context, 0, 'Off', selectedGoal, (v) => setState(() => selectedGoal = v)),
                  ...presets.map((p) => _buildPresetChip(
                    context, p, _formatNumber(p), selectedGoal, 
                    (v) => setState(() => selectedGoal = v),
                  )),
                ],
              ),
              const SizedBox(height: 20),
              // Custom input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedGoal > 0
                        ? () => setState(() => selectedGoal = (selectedGoal - 108).clamp(0, 100000))
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedGoal == 0 ? 'Off' : _formatNumber(selectedGoal),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => selectedGoal = selectedGoal + 108),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('chants per day', style: Theme.of(context).textTheme.labelMedium),
              if (selectedGoal > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '≈ ${(selectedGoal / 108).toStringAsFixed(1)} malas',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).setDailyGoalCount(selectedGoal);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, int value, String label, int selectedValue, Function(int) onTap) {
    final isSelected = value == selectedValue;
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.background : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
