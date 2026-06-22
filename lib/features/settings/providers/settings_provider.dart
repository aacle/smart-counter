import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/data_provider.dart';
import '../../../data/data_repository.dart';
import '../domain/settings_state.dart';

/// Provider for the settings state
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(dataRepositoryProvider));
});

/// Settings state notifier with persistence
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._repo) : super(SettingsState.defaults()) {
    _loadSettings();
  }

  final DataRepository _repo;

  /// Load saved settings from storage
  Future<void> _loadSettings() async {
    try {
      final loaded = await _repo.loadSettings();
      if (loaded != null) {
        state = loaded;
        // Theme is applied reactively by app.dart watching settingsProvider
      }
    } catch (e, stackTrace) {
      AppLogger.error('SettingsNotifier', 'Failed to load settings', e, stackTrace);
      state = SettingsState.defaults();
    }
  }

  /// Save current settings to storage
  Future<void> _saveSettings() async {
    try {
      await _repo.saveSettings(state);
    } catch (e, stackTrace) {
      AppLogger.error('SettingsNotifier', 'Failed to save settings', e, stackTrace);
    }
  }

  Future<void> setHapticEnabled(bool enabled) async {
    state = state.copyWith(hapticEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setVolumeRockerEnabled(bool enabled) async {
    state = state.copyWith(volumeRockerEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    state = state.copyWith(keepScreenAwake: enabled);
    await _saveSettings();
  }

  Future<void> setDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal);
    await _saveSettings();
  }

  Future<void> setDailyGoalCount(int count) async {
    state = state.copyWith(dailyGoalCount: count);
    await _saveSettings();
  }

  Future<void> setGoalType(GoalType type) async {
    state = state.copyWith(goalType: type);
    await _saveSettings();
  }

  Future<void> setInterfaceMode(InterfaceMode mode) async {
    state = state.copyWith(interfaceMode: mode);
    await _saveSettings();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    state = state.copyWith(reminderEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setReminderInterval(int minutes) async {
    state = state.copyWith(reminderIntervalMinutes: minutes);
    await _saveSettings();
  }

  Future<void> setAutoCountEnabled(bool enabled) async {
    state = state.copyWith(autoCountEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setAutoCountSpeed(double speed) async {
    state = state.copyWith(autoCountSpeed: speed);
    await _saveSettings();
  }

  Future<void> setWeeklyReportEnabled(bool enabled) async {
    state = state.copyWith(weeklyReportEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setMonthlyReportEnabled(bool enabled) async {
    state = state.copyWith(monthlyReportEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setGoalMissNotificationEnabled(bool enabled) async {
    state = state.copyWith(goalMissNotificationEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setCustomTitle(String title) async {
    state = state.copyWith(customTitle: title);
    await _saveSettings();
  }

  Future<void> setReminderSound(String sound) async {
    state = state.copyWith(reminderSound: sound);
    await _saveSettings();
  }

  Future<void> setTapSoundEnabled(bool enabled) async {
    state = state.copyWith(tapSoundEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setTheme(AppThemeColor theme) async {
    // Theme is applied reactively by app.dart watching settingsProvider
    state = state.copyWith(selectedTheme: theme);
    await _saveSettings();
  }

  Future<void> setCenterImage(String path) async {
    state = state.copyWith(centerImagePath: path);
    await _saveSettings();
  }

  Future<void> clearCenterImage() async {
    state = state.copyWith(clearCenterImage: true);
    await _saveSettings();
  }
}
