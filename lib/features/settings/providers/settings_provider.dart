import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_state.dart';

/// Provider for the settings state
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Settings state notifier with persistence
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState.defaults()) {
    _loadSettings();
  }

  static const String _storageKey = 'app_settings';

  /// Load saved settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_storageKey);
      if (settingsJson != null) {
        final json = jsonDecode(settingsJson) as Map<String, dynamic>;
        state = SettingsState.fromJson(json);
      }
    } catch (e) {
      state = SettingsState.defaults();
    }
  }

  /// Save current settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {}
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

  /// Toggle a time slot on/off
  Future<void> toggleTimeSlot(int slotIndex) async {
    final currentSlots = List<int>.from(state.activeTimeSlots);
    if (currentSlots.contains(slotIndex)) {
      currentSlots.remove(slotIndex);
    } else {
      currentSlots.add(slotIndex);
      currentSlots.sort();
    }
    state = state.copyWith(activeTimeSlots: currentSlots);
    await _saveSettings();
  }

  /// Set all active time slots at once
  Future<void> setActiveTimeSlots(List<int> slots) async {
    state = state.copyWith(activeTimeSlots: slots);
    await _saveSettings();
  }

  /// Set custom hours
  Future<void> setCustomHours(int? startHour, int? endHour) async {
    if (startHour == null || endHour == null) {
      state = state.copyWith(clearCustomHours: true);
    } else {
      state = state.copyWith(customStartHour: startHour, customEndHour: endHour);
    }
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

  Future<void> setGoalAchievementCelebrationEnabled(bool enabled) async {
    state = state.copyWith(goalAchievementCelebrationEnabled: enabled);
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
}
