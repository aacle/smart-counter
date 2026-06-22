import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/storage_keys.dart';

/// Top-level callback - runs even when app is closed
@pragma('vm:entry-point')
void alarmCallback() async {
  final prefs = await SharedPreferences.getInstance();
  final soundId = prefs.getString(StorageKeys.reminderSound) ?? 'default';
  
  final notifications = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
  const initSettings = InitializationSettings(android: androidSettings);
  await notifications.initialize(initSettings);
  
  // Create notification channel with custom sound if selected
  String channelId = 'chant_reminders';
  String channelName = 'Chant Reminders';
  String? rawSoundName;
  
  if (soundId == 'ram_ram') {
    channelId = 'chant_reminders_ram';
    channelName = 'Ram Nam Reminders';
    rawSoundName = 'ram_ram';
  } else if (soundId == 'radha_radha') {
    channelId = 'chant_reminders_radha';
    channelName = 'Radha Nam Reminders';
    rawSoundName = 'radha_radha';
  }
  
  final channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: 'Reminders to chant',
    importance: Importance.max,
    playSound: true,
    sound: rawSoundName != null 
        ? RawResourceAndroidNotificationSound(rawSoundName)
        : null,
  );
  
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  
  await notifications.show(
    1,
    'Time to Chant 🙏',
    'Take a moment to do Sumiran',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Reminders to chant',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: rawSoundName != null 
            ? RawResourceAndroidNotificationSound(rawSoundName)
            : null,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
      ),
    ),
  );
}

/// Simple reminder service using AndroidAlarmManager
class ReminderService {
  static final ReminderService instance = ReminderService._();
  ReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  static const int _alarmId = 999;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await AndroidAlarmManager.initialize();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    
    // Create default channel
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'chant_reminders',
            'Chant Reminders',
            description: 'Reminders to chant',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
    
    _isInitialized = true;
  }

  /// Get notification channel details based on sound ID
  Map<String, dynamic> _getChannelDetails(String soundId) {
    switch (soundId) {
      case 'ram_ram':
        return {
          'channelId': 'chant_reminders_ram',
          'channelName': 'Ram Nam Reminders',
          'rawSound': 'ram_ram',
        };
      case 'radha_radha':
        return {
          'channelId': 'chant_reminders_radha',
          'channelName': 'Radha Nam Reminders',
          'rawSound': 'radha_radha',
        };
      default:
        return {
          'channelId': 'chant_reminders',
          'channelName': 'Chant Reminders',
          'rawSound': null,
        };
    }
  }

  /// Start reminder with interval in minutes
  Future<void> startReminder({
    required int intervalMinutes,
    String soundId = 'default',
  }) async {
    await initialize();
    await stopReminder();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.reminderEnabled, true);
    await prefs.setInt(StorageKeys.reminderIntervalMinutes, intervalMinutes);
    await prefs.setString(StorageKeys.reminderSound, soundId);
    
    // Show confirmation notification with selected sound
    String label = intervalMinutes >= 60 
        ? '${intervalMinutes ~/ 60} hr${intervalMinutes >= 120 ? 's' : ''}'
        : '$intervalMinutes min';
    await _showNotificationWithSound('Reminders Active 🙏', 'Every $label', soundId);
    
    // Schedule periodic alarm
    await AndroidAlarmManager.periodic(
      Duration(minutes: intervalMinutes),
      _alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }

  /// Update only the reminder sound (without restarting the timer)
  Future<void> updateReminderSound(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.reminderSound, soundId);
  }

  /// Stop reminder
  Future<void> stopReminder() async {
    await AndroidAlarmManager.cancel(_alarmId);
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.reminderEnabled, false);
  }

  /// Restore reminders on app startup
  Future<void> restoreRemindersIfEnabled() async {
    await initialize();
    
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(StorageKeys.reminderEnabled) ?? false;
    
    if (!enabled) return;
    
    final intervalMinutes = prefs.getInt(StorageKeys.reminderIntervalMinutes) ?? 60;
    
    await AndroidAlarmManager.periodic(
      Duration(minutes: intervalMinutes),
      _alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }

  /// Show notification with custom sound
  Future<void> _showNotificationWithSound(String title, String body, String soundId) async {
    final details = _getChannelDetails(soundId);
    final channelId = details['channelId'] as String;
    final channelName = details['channelName'] as String;
    final rawSound = details['rawSound'] as String?;

    // Create channel with the custom sound
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            description: 'Reminders to chant',
            importance: Importance.max,
            playSound: true,
            sound: rawSound != null
                ? RawResourceAndroidNotificationSound(rawSound)
                : null,
          ),
        );

    await _notifications.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: rawSound != null
              ? RawResourceAndroidNotificationSound(rawSound)
              : null,
        ),
      ),
    );
  }

  // Legacy methods
  Future<void> stopIntervalReminders() async => stopReminder();
  Future<void> cancelAll() async => stopReminder();
}
