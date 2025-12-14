import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';

/// Service to update home screen widget with app data
class HomeWidgetService {
  static const String appGroupId = 'group.com.smartnaamjap.smrt_counter';
  static const String iOSWidgetName = 'SmartNaamWidget';
  static const String androidWidgetName = 'SmartNaamWidget';

  /// Initialize the home widget
  static Future<void> initialize() async {
    try {
      // Set app group ID for iOS
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidget init error: $e');
    }
  }

  /// Update widget with current stats
  static Future<void> updateWidget({
    required int todayCount,
    required int todayMalas,
    required int currentStreak,
    required int dailyGoal,
  }) async {
    try {
      // Save data that the native widget will read
      await HomeWidget.saveWidgetData<int>('todayCount', todayCount);
      await HomeWidget.saveWidgetData<int>('todayMalas', todayMalas);
      await HomeWidget.saveWidgetData<int>('currentStreak', currentStreak);
      await HomeWidget.saveWidgetData<int>('dailyGoal', dailyGoal);
      await HomeWidget.saveWidgetData<String>(
        'lastUpdated',
        DateTime.now().toIso8601String(),
      );

      // Trigger widget update on Android
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: 'SmartNaamWidget',
        iOSName: iOSWidgetName,
      );

      debugPrint('Home widget updated: $todayCount counts, $todayMalas malas');
    } catch (e) {
      debugPrint('HomeWidget update error: $e');
    }
  }

  /// Register callback for when widget is clicked (interactive widgets)
  static Future<void> registerInteractiveCallback(
    Future<void> Function(Uri?) callback,
  ) async {
    try {
      HomeWidget.widgetClicked.listen(callback);
    } catch (e) {
      debugPrint('HomeWidget callback error: $e');
    }
  }
}
