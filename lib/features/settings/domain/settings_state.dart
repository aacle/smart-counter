import 'package:flutter/foundation.dart';

/// Immutable state for app settings
@immutable
class SettingsState {
  final bool hapticEnabled;
  final bool volumeRockerEnabled;
  final bool keepScreenAwake;
  final int dailyGoal;
  
  // Reminder settings
  final bool reminderEnabled;
  final int reminderIntervalMinutes;
  
  // Active hours for reminders (list of enabled time slot indices)
  // 0: 6am-9am, 1: 9am-12pm, 2: 12pm-3pm, 3: 3pm-6pm, 
  // 4: 6pm-9pm, 5: 9pm-12am, 6: 12am-4am
  final List<int> activeTimeSlots;
  
  // Custom active hours (start hour, end hour) - null if using presets
  final int? customStartHour;
  final int? customEndHour;
  
  // Auto count settings
  final bool autoCountEnabled;
  final double autoCountSpeed;
  
  const SettingsState({
    required this.hapticEnabled,
    required this.volumeRockerEnabled,
    required this.keepScreenAwake,
    required this.dailyGoal,
    required this.reminderEnabled,
    required this.reminderIntervalMinutes,
    required this.activeTimeSlots,
    this.customStartHour,
    this.customEndHour,
    required this.autoCountEnabled,
    required this.autoCountSpeed,
  });

  factory SettingsState.defaults() {
    return const SettingsState(
      hapticEnabled: true,
      volumeRockerEnabled: true,
      keepScreenAwake: false,
      dailyGoal: 0,
      reminderEnabled: false,
      reminderIntervalMinutes: 30,
      activeTimeSlots: [0, 1, 2, 3, 4], // 6am to 9pm by default
      customStartHour: null,
      customEndHour: null,
      autoCountEnabled: false,
      autoCountSpeed: 2.0,
    );
  }

  SettingsState copyWith({
    bool? hapticEnabled,
    bool? volumeRockerEnabled,
    bool? keepScreenAwake,
    int? dailyGoal,
    bool? reminderEnabled,
    int? reminderIntervalMinutes,
    List<int>? activeTimeSlots,
    int? customStartHour,
    int? customEndHour,
    bool clearCustomHours = false,
    bool? autoCountEnabled,
    double? autoCountSpeed,
  }) {
    return SettingsState(
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      volumeRockerEnabled: volumeRockerEnabled ?? this.volumeRockerEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      activeTimeSlots: activeTimeSlots ?? this.activeTimeSlots,
      customStartHour: clearCustomHours ? null : (customStartHour ?? this.customStartHour),
      customEndHour: clearCustomHours ? null : (customEndHour ?? this.customEndHour),
      autoCountEnabled: autoCountEnabled ?? this.autoCountEnabled,
      autoCountSpeed: autoCountSpeed ?? this.autoCountSpeed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hapticEnabled': hapticEnabled,
      'volumeRockerEnabled': volumeRockerEnabled,
      'keepScreenAwake': keepScreenAwake,
      'dailyGoal': dailyGoal,
      'reminderEnabled': reminderEnabled,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'activeTimeSlots': activeTimeSlots,
      'customStartHour': customStartHour,
      'customEndHour': customEndHour,
      'autoCountEnabled': autoCountEnabled,
      'autoCountSpeed': autoCountSpeed,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      volumeRockerEnabled: json['volumeRockerEnabled'] as bool? ?? true,
      keepScreenAwake: json['keepScreenAwake'] as bool? ?? false,
      dailyGoal: json['dailyGoal'] as int? ?? 0,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderIntervalMinutes: json['reminderIntervalMinutes'] as int? ?? 30,
      activeTimeSlots: (json['activeTimeSlots'] as List<dynamic>?)
          ?.map((e) => e as int).toList() ?? [0, 1, 2, 3, 4],
      customStartHour: json['customStartHour'] as int?,
      customEndHour: json['customEndHour'] as int?,
      autoCountEnabled: json['autoCountEnabled'] as bool? ?? false,
      autoCountSpeed: (json['autoCountSpeed'] as num?)?.toDouble() ?? 2.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.hapticEnabled == hapticEnabled &&
        other.volumeRockerEnabled == volumeRockerEnabled &&
        other.keepScreenAwake == keepScreenAwake &&
        other.dailyGoal == dailyGoal &&
        other.reminderEnabled == reminderEnabled &&
        other.reminderIntervalMinutes == reminderIntervalMinutes &&
        listEquals(other.activeTimeSlots, activeTimeSlots) &&
        other.customStartHour == customStartHour &&
        other.customEndHour == customEndHour &&
        other.autoCountEnabled == autoCountEnabled &&
        other.autoCountSpeed == autoCountSpeed;
  }

  @override
  int get hashCode {
    return Object.hash(
      hapticEnabled,
      volumeRockerEnabled,
      keepScreenAwake,
      dailyGoal,
      reminderEnabled,
      reminderIntervalMinutes,
      Object.hashAll(activeTimeSlots),
      customStartHour,
      customEndHour,
      autoCountEnabled,
      autoCountSpeed,
    );
  }
}
