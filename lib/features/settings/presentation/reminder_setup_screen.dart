import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/colors.dart';
import '../../../services/reminder_service.dart';
import '../providers/settings_provider.dart';

/// Available reminder sounds
class ReminderSound {
  final String id;
  final String name;
  final String? fileName;  // null for default system sound

  const ReminderSound({
    required this.id,
    required this.name,
    this.fileName,
  });

  static const List<ReminderSound> available = [
    ReminderSound(id: 'default', name: 'Default Sound', fileName: null),
    ReminderSound(id: 'ram_ram', name: 'Ram Nam 🙏', fileName: 'ram_ram.mp3'),
    ReminderSound(id: 'radha_radha', name: 'Radha Nam 💕', fileName: 'radha_radha.mp3'),
  ];
}

class ReminderSetupScreen extends ConsumerStatefulWidget {
  const ReminderSetupScreen({super.key});

  @override
  ConsumerState<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends ConsumerState<ReminderSetupScreen> {
  final ReminderService _reminderService = ReminderService();
  
  // Interval options in minutes
  static const List<int> _intervalOptions = [1, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _reminderService.initialize();
  }

  String _formatInterval(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '$hours hr${hours > 1 ? 's' : ''}';
    }
    return '$minutes min';
  }

  Future<void> _onReminderToggle(bool enabled) async {
    if (enabled) {
      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification permission required'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
      
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
    
    final settings = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).setReminderEnabled(enabled);
    
    if (enabled) {
      _reminderService.startReminder(
        intervalMinutes: settings.reminderIntervalMinutes,
        soundId: settings.reminderSound,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for every ${_formatInterval(settings.reminderIntervalMinutes)}'),
            backgroundColor: AppColors.cardBackground,
          ),
        );
      }
    } else {
      _reminderService.stopReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reminder Settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMainToggle(settings),
          const SizedBox(height: 24),
          _buildIntervalSection(settings),
          const SizedBox(height: 24),
          _buildSoundSection(settings),
        ],
      ),
    );
  }

  Widget _buildMainToggle(settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.reminderEnabled 
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.reminderEnabled 
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            settings.reminderEnabled 
                ? Icons.notifications_active 
                : Icons.notifications_off_outlined,
            color: settings.reminderEnabled 
                ? AppColors.primary 
                : AppColors.textMuted,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chanting Reminders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.reminderEnabled 
                      ? 'Active - Every ${_formatInterval(settings.reminderIntervalMinutes)}'
                      : 'Tap to enable reminders',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.reminderEnabled,
            onChanged: _onReminderToggle,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSection(settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Interval',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get reminded to chant at regular intervals',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _intervalOptions.map((minutes) {
            final isSelected = settings.reminderIntervalMinutes == minutes;
            return GestureDetector(
              onTap: () {
                ref.read(settingsProvider.notifier).setReminderInterval(minutes);
                if (settings.reminderEnabled) {
                  _reminderService.startReminder(intervalMinutes: minutes);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primary 
                        : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _formatInterval(minutes),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSoundSection(settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Sound',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a voice for your chanting reminder',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...ReminderSound.available.map((sound) {
          final isSelected = settings.reminderSound == sound.id;
          return GestureDetector(
            onTap: () {
              ref.read(settingsProvider.notifier).setReminderSound(sound.id);
              // Also update SharedPreferences for the alarm callback
              _reminderService.updateReminderSound(sound.id);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    sound.fileName == null ? Icons.volume_up : Icons.music_note,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      sound.name,
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        // Info about adding custom sounds
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice files should be placed in: assets/sounds/',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
