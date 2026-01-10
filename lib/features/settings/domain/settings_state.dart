import 'package:flutter/foundation.dart';

/// Type of daily goal - either malas or individual chant counts
enum GoalType {
  malas,
  counts,
}

/// Interface mode for counter screen display
enum InterfaceMode {
  malaWise,   // Shows mala beads with X of 108 progress
  countWise,  // Shows total count prominently
}

/// Immutable state for app settings
@immutable
class SettingsState {
  final bool hapticEnabled;
  final bool volumeRockerEnabled;
  final bool keepScreenAwake;
  final int dailyGoal;  // Daily goal in malas
  final int dailyGoalCount;  // Daily goal in chant counts
  final GoalType goalType;  // Which type of goal is active
  final InterfaceMode interfaceMode;  // Counter screen display mode
  
  // Audio settings
  final bool tapSoundEnabled;
  
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
  
  // Report and notification settings
  final bool weeklyReportEnabled;
  final bool monthlyReportEnabled;
  final bool goalMissNotificationEnabled;
  final bool goalAchievementCelebrationEnabled;
  
  // Customization
  final String customTitle;  // Custom title for counter screen
  final String reminderSound;  // Selected reminder sound file name
  
  const SettingsState({
    required this.hapticEnabled,
    required this.volumeRockerEnabled,
    required this.keepScreenAwake,
    required this.dailyGoal,
    required this.dailyGoalCount,
    required this.goalType,
    required this.interfaceMode,
    required this.reminderEnabled,
    required this.reminderIntervalMinutes,
    required this.activeTimeSlots,
    this.customStartHour,
    this.customEndHour,
    required this.autoCountEnabled,
    required this.autoCountSpeed,
    required this.weeklyReportEnabled,
    required this.monthlyReportEnabled,
    required this.goalMissNotificationEnabled,
    required this.goalAchievementCelebrationEnabled,
    required this.customTitle,
    required this.reminderSound,
    required this.tapSoundEnabled,
  });

  factory SettingsState.defaults() {
    return const SettingsState(
      hapticEnabled: false,
      volumeRockerEnabled: true,
      keepScreenAwake: false,
      dailyGoal: 0,
      dailyGoalCount: 0,
      goalType: GoalType.malas,
      interfaceMode: InterfaceMode.malaWise,
      reminderEnabled: false,
      reminderIntervalMinutes: 30,
      activeTimeSlots: [0, 1, 2, 3, 4], // 6am to 9pm by default
      customStartHour: null,
      customEndHour: null,
      autoCountEnabled: false,
      autoCountSpeed: 2.0,
      weeklyReportEnabled: true,
      monthlyReportEnabled: true,
      goalMissNotificationEnabled: true,
      goalAchievementCelebrationEnabled: true,
      customTitle: 'सुमिरन',
      reminderSound: 'default',  // 'default' uses system sound
      tapSoundEnabled: true,
    );
  }

  SettingsState copyWith({
    bool? hapticEnabled,
    bool? volumeRockerEnabled,
    bool? keepScreenAwake,
    int? dailyGoal,
    int? dailyGoalCount,
    GoalType? goalType,
    InterfaceMode? interfaceMode,
    bool? reminderEnabled,
    int? reminderIntervalMinutes,
    List<int>? activeTimeSlots,
    int? customStartHour,
    int? customEndHour,
    bool clearCustomHours = false,
    bool? autoCountEnabled,
    double? autoCountSpeed,
    bool? weeklyReportEnabled,
    bool? monthlyReportEnabled,
    bool? goalMissNotificationEnabled,
    bool? goalAchievementCelebrationEnabled,
    String? customTitle,
    String? reminderSound,
    bool? tapSoundEnabled,
  }) {
    return SettingsState(
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      volumeRockerEnabled: volumeRockerEnabled ?? this.volumeRockerEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      dailyGoalCount: dailyGoalCount ?? this.dailyGoalCount,
      goalType: goalType ?? this.goalType,
      interfaceMode: interfaceMode ?? this.interfaceMode,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      activeTimeSlots: activeTimeSlots ?? this.activeTimeSlots,
      customStartHour: clearCustomHours ? null : (customStartHour ?? this.customStartHour),
      customEndHour: clearCustomHours ? null : (customEndHour ?? this.customEndHour),
      autoCountEnabled: autoCountEnabled ?? this.autoCountEnabled,
      autoCountSpeed: autoCountSpeed ?? this.autoCountSpeed,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      monthlyReportEnabled: monthlyReportEnabled ?? this.monthlyReportEnabled,
      goalMissNotificationEnabled: goalMissNotificationEnabled ?? this.goalMissNotificationEnabled,
      goalAchievementCelebrationEnabled: goalAchievementCelebrationEnabled ?? this.goalAchievementCelebrationEnabled,
      customTitle: customTitle ?? this.customTitle,
      reminderSound: reminderSound ?? this.reminderSound,
      tapSoundEnabled: tapSoundEnabled ?? this.tapSoundEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hapticEnabled': hapticEnabled,
      'volumeRockerEnabled': volumeRockerEnabled,
      'keepScreenAwake': keepScreenAwake,
      'dailyGoal': dailyGoal,
      'dailyGoalCount': dailyGoalCount,
      'goalType': goalType.name,
      'interfaceMode': interfaceMode.name,
      'reminderEnabled': reminderEnabled,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'activeTimeSlots': activeTimeSlots,
      'customStartHour': customStartHour,
      'customEndHour': customEndHour,
      'autoCountEnabled': autoCountEnabled,
      'autoCountSpeed': autoCountSpeed,
      'weeklyReportEnabled': weeklyReportEnabled,
      'monthlyReportEnabled': monthlyReportEnabled,
      'goalMissNotificationEnabled': goalMissNotificationEnabled,
      'goalAchievementCelebrationEnabled': goalAchievementCelebrationEnabled,
      'customTitle': customTitle,
      'reminderSound': reminderSound,
      'tapSoundEnabled': tapSoundEnabled,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      volumeRockerEnabled: json['volumeRockerEnabled'] as bool? ?? true,
      keepScreenAwake: json['keepScreenAwake'] as bool? ?? false,
      dailyGoal: json['dailyGoal'] as int? ?? 0,
      dailyGoalCount: json['dailyGoalCount'] as int? ?? 0,
      goalType: GoalType.values.firstWhere(
        (e) => e.name == json['goalType'],
        orElse: () => GoalType.malas,
      ),
      interfaceMode: InterfaceMode.values.firstWhere(
        (e) => e.name == json['interfaceMode'],
        orElse: () => InterfaceMode.malaWise,
      ),
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderIntervalMinutes: json['reminderIntervalMinutes'] as int? ?? 30,
      activeTimeSlots: (json['activeTimeSlots'] as List<dynamic>?)
          ?.map((e) => e as int).toList() ?? [0, 1, 2, 3, 4],
      customStartHour: json['customStartHour'] as int?,
      customEndHour: json['customEndHour'] as int?,
      autoCountEnabled: json['autoCountEnabled'] as bool? ?? false,
      autoCountSpeed: (json['autoCountSpeed'] as num?)?.toDouble() ?? 2.0,
      weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? true,
      monthlyReportEnabled: json['monthlyReportEnabled'] as bool? ?? true,
      goalMissNotificationEnabled: json['goalMissNotificationEnabled'] as bool? ?? true,
      goalAchievementCelebrationEnabled: json['goalAchievementCelebrationEnabled'] as bool? ?? true,
      customTitle: json['customTitle'] as String? ?? 'सुमिरन',
      reminderSound: json['reminderSound'] as String? ?? 'default',
      tapSoundEnabled: json['tapSoundEnabled'] as bool? ?? false,
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
        other.dailyGoalCount == dailyGoalCount &&
        other.goalType == goalType &&
        other.interfaceMode == interfaceMode &&
        other.reminderEnabled == reminderEnabled &&
        other.reminderIntervalMinutes == reminderIntervalMinutes &&
        listEquals(other.activeTimeSlots, activeTimeSlots) &&
        other.customStartHour == customStartHour &&
        other.customEndHour == customEndHour &&
        other.autoCountEnabled == autoCountEnabled &&
        other.autoCountSpeed == autoCountSpeed &&
        other.weeklyReportEnabled == weeklyReportEnabled &&
        other.monthlyReportEnabled == monthlyReportEnabled &&
        other.goalMissNotificationEnabled == goalMissNotificationEnabled &&
        other.goalAchievementCelebrationEnabled == goalAchievementCelebrationEnabled &&
        other.customTitle == customTitle &&
        other.reminderSound == reminderSound &&
        other.tapSoundEnabled == tapSoundEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      hapticEnabled,
      volumeRockerEnabled,
      keepScreenAwake,
      dailyGoal,
      dailyGoalCount,
      goalType,
      interfaceMode,
      reminderEnabled,
      reminderIntervalMinutes,
      Object.hashAll(activeTimeSlots),
      customStartHour,
      customEndHour,
      autoCountEnabled,
      autoCountSpeed,
      weeklyReportEnabled,
      monthlyReportEnabled,
      goalMissNotificationEnabled,
      goalAchievementCelebrationEnabled,
      Object.hash(
        customTitle,
        reminderSound,
        tapSoundEnabled,
      ),
    );
  }
}
