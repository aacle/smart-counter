import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/colors.dart';
import '../../../services/reminder_service.dart';
import '../providers/settings_provider.dart';

class ReminderSetupScreen extends ConsumerStatefulWidget {
  const ReminderSetupScreen({super.key});

  @override
  ConsumerState<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends ConsumerState<ReminderSetupScreen> {
  final ReminderService _reminderService = ReminderService();
  
  // Custom hours
  int _customStartHour = 6;
  int _customEndHour = 21;
  bool _showCustomPicker = false;
  
  static const List<int> _intervalOptions = [1, 5, 10, 15, 30, 60];
  
  // Time slot definitions
  static const List<Map<String, dynamic>> _timeSlots = [
    {'label': '6 AM - 9 AM', 'start': 6, 'end': 9, 'icon': Icons.wb_sunny_outlined},
    {'label': '9 AM - 12 PM', 'start': 9, 'end': 12, 'icon': Icons.light_mode},
    {'label': '12 PM - 3 PM', 'start': 12, 'end': 15, 'icon': Icons.wb_sunny},
    {'label': '3 PM - 6 PM', 'start': 15, 'end': 18, 'icon': Icons.wb_twilight},
    {'label': '6 PM - 9 PM', 'start': 18, 'end': 21, 'icon': Icons.nights_stay_outlined},
    {'label': '9 PM - 12 AM', 'start': 21, 'end': 24, 'icon': Icons.nightlight_round},
    {'label': '12 AM - 4 AM', 'start': 0, 'end': 4, 'icon': Icons.dark_mode},
  ];

  @override
  void initState() {
    super.initState();
    _reminderService.initialize();
    
    // Load custom hours if set
    final settings = ref.read(settingsProvider);
    if (settings.customStartHour != null) {
      _customStartHour = settings.customStartHour!;
      _customEndHour = settings.customEndHour ?? 21;
    }
  }

  @override
  void dispose() {
    super.dispose();
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
      _reminderService.startIntervalReminders(
        intervalMinutes: settings.reminderIntervalMinutes,
        activeTimeSlots: settings.activeTimeSlots,
        customStartHour: settings.customStartHour,
        customEndHour: settings.customEndHour,
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
      _reminderService.stopIntervalReminders();
    }
  }

  String _formatInterval(int minutes) {
    if (minutes >= 60) {
      return '${minutes ~/ 60} hour${minutes >= 120 ? 's' : ''}';
    }
    return '$minutes min';
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
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
          // Enable/Disable Toggle
          _buildMainToggle(settings),
          
          const SizedBox(height: 24),
          
          // Interval Selection
          _buildIntervalSection(settings),
          
          const SizedBox(height: 24),
          
          // Active Hours Section
          _buildActiveHoursSection(settings),
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
            activeColor: AppColors.primary,
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
                  _reminderService.startIntervalReminders(
                    intervalMinutes: minutes,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActiveHoursSection(settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Hours',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showCustomPicker = !_showCustomPicker),
              child: Text(
                _showCustomPicker ? 'Use Presets' : 'Custom Hours',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Reminders will only trigger during these times',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        
        if (_showCustomPicker)
          _buildCustomHoursPicker(settings)
        else
          _buildTimeSlotGrid(settings),
      ],
    );
  }

  Widget _buildTimeSlotGrid(settings) {
    return Column(
      children: List.generate(_timeSlots.length, (index) {
        final slot = _timeSlots[index];
        final isActive = settings.activeTimeSlots.contains(index);
        
        return GestureDetector(
          onTap: () {
            ref.read(settingsProvider.notifier).toggleTimeSlot(index);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive 
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  slot['icon'] as IconData,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    slot['label'] as String,
                    style: TextStyle(
                      color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  isActive ? Icons.check_circle : Icons.circle_outlined,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCustomHoursPicker(settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Time', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _customStartHour,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.cardBackground,
                        items: List.generate(24, (i) {
                          return DropdownMenuItem(
                            value: i,
                            child: Text(_formatHour(i)),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _customStartHour = value);
                            ref.read(settingsProvider.notifier)
                                .setCustomHours(_customStartHour, _customEndHour);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End Time', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _customEndHour,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.cardBackground,
                        items: List.generate(24, (i) {
                          return DropdownMenuItem(
                            value: i,
                            child: Text(_formatHour(i)),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _customEndHour = value);
                            ref.read(settingsProvider.notifier)
                                .setCustomHours(_customStartHour, _customEndHour);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Active: ${_formatHour(_customStartHour)} - ${_formatHour(_customEndHour)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
