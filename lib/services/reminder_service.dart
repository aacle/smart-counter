import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level callback with duplicate prevention
@pragma('vm:entry-point')
Future<void> alarmCallback() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Prevent duplicate notifications (within 30 seconds)
  final lastNotifyTime = prefs.getInt('last_notify_time') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  if (now - lastNotifyTime < 30000) {
    return; // Skip if notified less than 30 seconds ago
  }
  
  // Check active hours
  final activeSlots = prefs.getStringList('active_time_slots') ?? [];
  final customStart = prefs.getInt('custom_start_hour');
  final customEnd = prefs.getInt('custom_end_hour');
  
  final currentHour = DateTime.now().hour;
  bool isActiveHour = true;
  
  if (customStart != null && customEnd != null) {
    if (customEnd > customStart) {
      isActiveHour = currentHour >= customStart && currentHour < customEnd;
    } else {
      isActiveHour = currentHour >= customStart || currentHour < customEnd;
    }
  } else if (activeSlots.isNotEmpty) {
    isActiveHour = false;
    for (final slotStr in activeSlots) {
      final slot = int.tryParse(slotStr) ?? -1;
      switch (slot) {
        case 0: if (currentHour >= 6 && currentHour < 9) isActiveHour = true; break;
        case 1: if (currentHour >= 9 && currentHour < 12) isActiveHour = true; break;
        case 2: if (currentHour >= 12 && currentHour < 15) isActiveHour = true; break;
        case 3: if (currentHour >= 15 && currentHour < 18) isActiveHour = true; break;
        case 4: if (currentHour >= 18 && currentHour < 21) isActiveHour = true; break;
        case 5: if (currentHour >= 21 && currentHour < 24) isActiveHour = true; break;
        case 6: if (currentHour >= 0 && currentHour < 4) isActiveHour = true; break;
      }
    }
  }
  
  if (!isActiveHour) return;
  
  // Save last notify time
  await prefs.setInt('last_notify_time', now);
  
  // Show notification
  final notifications = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await notifications.initialize(initSettings);
  
  const channel = AndroidNotificationChannel(
    'chant_reminders',
    'Chant Reminders',
    description: 'Reminders to chant',
    importance: Importance.max,
  );
  
  await notifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  
  await notifications.show(
    1, // Fixed ID to replace previous notification
    'Time to Chant 🙏',
    'Take a moment for your Simran practice',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chant_reminders',
        'Chant Reminders',
        channelDescription: 'Reminders to chant',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      ),
    ),
  );
}

/// Reminder service
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  int _intervalMinutes = 0;
  
  static const int _alarmId = 999;
  
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
    
    const channel = AndroidNotificationChannel(
      'chant_reminders',
      'Chant Reminders',
      description: 'Reminders to chant',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    _isInitialized = true;
  }

  Future<void> startIntervalReminders({
    required int intervalMinutes,
    List<int>? activeTimeSlots,
    int? customStartHour,
    int? customEndHour,
  }) async {
    await initialize();
    await stopIntervalReminders();
    
    _intervalMinutes = intervalMinutes;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', true);
    
    if (activeTimeSlots != null && activeTimeSlots.isNotEmpty) {
      await prefs.setStringList(
        'active_time_slots', 
        activeTimeSlots.map((e) => e.toString()).toList()
      );
    }
    
    if (customStartHour != null && customEndHour != null) {
      await prefs.setInt('custom_start_hour', customStartHour);
      await prefs.setInt('custom_end_hour', customEndHour);
    } else {
      await prefs.remove('custom_start_hour');
      await prefs.remove('custom_end_hour');
    }
    
    await _showNotification('Reminders Active 🙏', 'Every $intervalMinutes min');
    
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

  Future<void> stopIntervalReminders() async {
    await AndroidAlarmManager.cancel(_alarmId);
    _intervalMinutes = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', false);
  }

  Future<void> _showNotification(String title, String body) async {
    await _notifications.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chant_reminders',
          'Chant Reminders',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  Future<void> cancelAll() async => stopIntervalReminders();
  bool get isRunning => _intervalMinutes > 0;
  int get currentInterval => _intervalMinutes;
}
