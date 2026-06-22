import '../../../core/theme/colors.dart';

// Re-export AppThemeColor so consumers of settings_state get it automatically
export '../../../core/theme/colors.dart' show AppThemeColor;

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
  
  // Auto count settings
  final bool autoCountEnabled;
  final double autoCountSpeed;
  
  // Report and notification settings
  final bool weeklyReportEnabled;
  final bool monthlyReportEnabled;
  final bool goalMissNotificationEnabled;
  
  // Customization
  final String customTitle;  // Custom title for counter screen
  final String reminderSound;  // Selected reminder sound file name
  final AppThemeColor selectedTheme;  // Selected app theme color
  final String? centerImagePath;  // Path to custom deity image in mala center
  
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
    required this.autoCountEnabled,
    required this.autoCountSpeed,
    required this.weeklyReportEnabled,
    required this.monthlyReportEnabled,
    required this.goalMissNotificationEnabled,
    required this.customTitle,
    required this.reminderSound,
    required this.tapSoundEnabled,
    required this.selectedTheme,
    this.centerImagePath,
  });

  factory SettingsState.defaults() {
    return const SettingsState(
      hapticEnabled: false,
      volumeRockerEnabled: false,
      keepScreenAwake: false,
      dailyGoal: 0,
      dailyGoalCount: 0,
      goalType: GoalType.malas,
      interfaceMode: InterfaceMode.malaWise,
      reminderEnabled: false,
      reminderIntervalMinutes: 30,
      autoCountEnabled: false,
      autoCountSpeed: 2.0,
      weeklyReportEnabled: true,
      monthlyReportEnabled: true,
      goalMissNotificationEnabled: true,
      customTitle: '\u0938\u0941\u092E\u093F\u0930\u0928',
      reminderSound: 'default',  // 'default' uses system sound
      tapSoundEnabled: true,
      selectedTheme: AppThemeColor.divineGold,
      centerImagePath: null,
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
    bool? autoCountEnabled,
    double? autoCountSpeed,
    bool? weeklyReportEnabled,
    bool? monthlyReportEnabled,
    bool? goalMissNotificationEnabled,
    String? customTitle,
    String? reminderSound,
    bool? tapSoundEnabled,
    AppThemeColor? selectedTheme,
    String? centerImagePath,
    bool clearCenterImage = false,
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
      autoCountEnabled: autoCountEnabled ?? this.autoCountEnabled,
      autoCountSpeed: autoCountSpeed ?? this.autoCountSpeed,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      monthlyReportEnabled: monthlyReportEnabled ?? this.monthlyReportEnabled,
      goalMissNotificationEnabled: goalMissNotificationEnabled ?? this.goalMissNotificationEnabled,
      customTitle: customTitle ?? this.customTitle,
      reminderSound: reminderSound ?? this.reminderSound,
      tapSoundEnabled: tapSoundEnabled ?? this.tapSoundEnabled,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      centerImagePath: clearCenterImage ? null : (centerImagePath ?? this.centerImagePath),
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
      'autoCountEnabled': autoCountEnabled,
      'autoCountSpeed': autoCountSpeed,
      'weeklyReportEnabled': weeklyReportEnabled,
      'monthlyReportEnabled': monthlyReportEnabled,
      'goalMissNotificationEnabled': goalMissNotificationEnabled,
      'customTitle': customTitle,
      'reminderSound': reminderSound,
      'tapSoundEnabled': tapSoundEnabled,
      'selectedTheme': selectedTheme.name,
      'centerImagePath': centerImagePath,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      volumeRockerEnabled: json['volumeRockerEnabled'] as bool? ?? false,
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
      reminderIntervalMinutes: ((json['reminderIntervalMinutes'] as int?) ?? 30).clamp(15, 120),
      autoCountEnabled: json['autoCountEnabled'] as bool? ?? false,
      autoCountSpeed: (json['autoCountSpeed'] as num?)?.toDouble() ?? 2.0,
      weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? true,
      monthlyReportEnabled: json['monthlyReportEnabled'] as bool? ?? true,
      goalMissNotificationEnabled: json['goalMissNotificationEnabled'] as bool? ?? true,
      customTitle: json['customTitle'] as String? ?? '\u0938\u0941\u092E\u093F\u0930\u0928',
      reminderSound: json['reminderSound'] as String? ?? 'default',
      tapSoundEnabled: json['tapSoundEnabled'] as bool? ?? false,
      selectedTheme: AppThemeColor.values.firstWhere(
        (e) => e.name == json['selectedTheme'],
        orElse: () => AppThemeColor.divineGold,
      ),
      centerImagePath: json['centerImagePath'] as String?,
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
        other.autoCountEnabled == autoCountEnabled &&
        other.autoCountSpeed == autoCountSpeed &&
        other.weeklyReportEnabled == weeklyReportEnabled &&
        other.monthlyReportEnabled == monthlyReportEnabled &&
        other.goalMissNotificationEnabled == goalMissNotificationEnabled &&
        other.customTitle == customTitle &&
        other.reminderSound == reminderSound &&
        other.tapSoundEnabled == tapSoundEnabled &&
        other.selectedTheme == selectedTheme &&
        other.centerImagePath == centerImagePath;
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
      autoCountEnabled,
      autoCountSpeed,
      weeklyReportEnabled,
      monthlyReportEnabled,
      goalMissNotificationEnabled,
      customTitle,
      reminderSound,
      tapSoundEnabled,
      selectedTheme,
      centerImagePath,
    );
  }
}
