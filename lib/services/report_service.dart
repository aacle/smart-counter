import 'package:shared_preferences/shared_preferences.dart';
import '../features/insights/domain/daily_stats.dart';
import '../features/settings/domain/settings_state.dart';

/// Service to manage progress reports and goal notifications
class ReportService {
  static const String _lastWeeklyReportKey = 'last_weekly_report';
  static const String _lastMonthlyReportKey = 'last_monthly_report';
  static const String _lastGoalMissCheckKey = 'last_goal_miss_check';
  
  static ReportService? _instance;
  static ReportService get instance => _instance ??= ReportService._();
  
  ReportService._();

  /// Check if weekly report should be shown
  /// Shows every Monday (if not already shown this Monday)
  Future<bool> shouldShowWeeklyReport() async {
    final now = DateTime.now();
    
    // Only show on Monday (weekday == 1)
    if (now.weekday != DateTime.monday) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_lastWeeklyReportKey);
    
    if (lastShown == null) return true;
    
    final lastDate = DateTime.tryParse(lastShown);
    if (lastDate == null) return true;
    
    // Check if already shown today (this Monday)
    final today = DateTime(now.year, now.month, now.day);
    final lastShownDate = DateTime(lastDate.year, lastDate.month, lastDate.day);
    
    return today.isAfter(lastShownDate);
  }

  /// Check if monthly report should be shown
  /// Shows on the 1st day of each month (if not already shown this month)
  Future<bool> shouldShowMonthlyReport() async {
    final now = DateTime.now();
    
    // Only show on the 1st day of the month
    if (now.day != 1) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_lastMonthlyReportKey);
    
    if (lastShown == null) return true;
    
    final lastDate = DateTime.tryParse(lastShown);
    if (lastDate == null) return true;
    
    // Check if already shown this month
    return now.month != lastDate.month || now.year != lastDate.year;
  }

  /// Mark weekly report as shown
  Future<void> markWeeklyReportShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastWeeklyReportKey, DateTime.now().toIso8601String());
  }

  /// Mark monthly report as shown
  Future<void> markMonthlyReportShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastMonthlyReportKey, DateTime.now().toIso8601String());
  }

  /// Check if yesterday's goal was missed and not yet notified
  Future<bool> shouldShowGoalMissNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString(_lastGoalMissCheckKey);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastCheck != null) {
      final lastDate = DateTime.tryParse(lastCheck);
      if (lastDate != null) {
        final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
        // Already checked today
        if (lastDateOnly == today) return false;
      }
    }
    
    return true;
  }

  /// Mark goal miss as checked for today
  Future<void> markGoalMissChecked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastGoalMissCheckKey, DateTime.now().toIso8601String());
  }

  /// Get yesterday's goal achievement info
  GoalMissInfo? checkYesterdayGoal(
    List<DailyStats> recentStats,
    SettingsState settings,
  ) {
    if (recentStats.length < 2) return null;
    
    // Index 0 is today, index 1 is yesterday
    final yesterday = recentStats[1];
    
    final bool isCountGoal = settings.goalType == GoalType.counts;
    final int goalValue = isCountGoal ? settings.dailyGoalCount : settings.dailyGoal;
    
    if (goalValue <= 0) return null; // No goal set
    
    final int achieved = isCountGoal ? yesterday.counts : yesterday.malas;
    
    if (achieved >= goalValue) return null; // Goal was met
    
    final double percentage = (achieved / goalValue * 100);
    final int missing = goalValue - achieved;
    
    return GoalMissInfo(
      achieved: achieved,
      goal: goalValue,
      percentage: percentage,
      missing: missing,
      isCountGoal: isCountGoal,
    );
  }

  /// Generate weekly report data (backward compatible)
  WeeklyReportData generateWeeklyReport(
    List<DailyStats> lastNDays,
    SettingsState settings,
  ) {
    return generateReport(lastNDays, settings, days: 7);
  }

  /// Generate report data for any period (7 for weekly, 30 for monthly)
  WeeklyReportData generateReport(
    List<DailyStats> stats,
    SettingsState settings, {
    required int days,
  }) {
    final bool isCountGoal = settings.goalType == GoalType.counts;
    final int goalValue = isCountGoal ? settings.dailyGoalCount : settings.dailyGoal;
    
    int daysGoalMet = 0;
    int bestDayIndex = -1;
    int worstDayIndex = -1;
    int bestValue = 0;
    int worstValue = 999999999;  // Large value for comparison
    int totalValue = 0;
    
    final List<DayProgress> dailyProgress = [];
    
    // Reverse so index 0 is N days ago, last index is yesterday
    final reversed = stats.reversed.toList();
    
    for (int i = 0; i < reversed.length && i < days; i++) {
      final day = reversed[i];
      final value = isCountGoal ? day.counts : day.malas;
      final progress = goalValue > 0 ? (value / goalValue).clamp(0.0, 1.5) : 0.0;
      
      totalValue += value;
      
      if (goalValue > 0 && value >= goalValue) {
        daysGoalMet++;
      }
      
      if (day.counts > 0) { // Only consider active days for best/worst
        if (value > bestValue) {
          bestValue = value;
          bestDayIndex = i;
        }
        if (value < worstValue) {
          worstValue = value;
          worstDayIndex = i;
        }
      }
      
      dailyProgress.add(DayProgress(
        date: DateTime.now().subtract(Duration(days: days - i - 1)),
        value: value,
        progress: progress,
        goalMet: goalValue > 0 && value >= goalValue,
      ));
    }
    
    // Pad to required days if needed
    while (dailyProgress.length < days) {
      dailyProgress.insert(0, DayProgress(
        date: DateTime.now().subtract(Duration(days: dailyProgress.length)),
        value: 0,
        progress: 0,
        goalMet: false,
      ));
    }
    
    final achievementRate = goalValue > 0 ? daysGoalMet / days : 0.0;
    
    return WeeklyReportData(
      dailyProgress: dailyProgress,
      daysGoalMet: daysGoalMet,
      achievementRate: achievementRate,
      bestDayIndex: bestDayIndex,
      worstDayIndex: worstValue >= 999999999 ? -1 : worstDayIndex,
      totalValue: totalValue,
      averageValue: days > 0 ? totalValue ~/ days : 0,
      isCountGoal: isCountGoal,
      goalValue: goalValue,
      totalDays: days,
    );
  }
}

/// Info about a missed goal
class GoalMissInfo {
  final int achieved;
  final int goal;
  final double percentage;
  final int missing;
  final bool isCountGoal;
  
  const GoalMissInfo({
    required this.achieved,
    required this.goal,
    required this.percentage,
    required this.missing,
    required this.isCountGoal,
  });
}

/// Progress for a single day
class DayProgress {
  final DateTime date;
  final int value;
  final double progress;
  final bool goalMet;
  
  const DayProgress({
    required this.date,
    required this.value,
    required this.progress,
    required this.goalMet,
  });
}

/// Report data (supports weekly and monthly)
class WeeklyReportData {
  final List<DayProgress> dailyProgress;
  final int daysGoalMet;
  final double achievementRate;
  final int bestDayIndex;
  final int worstDayIndex;
  final int totalValue;
  final int averageValue;
  final bool isCountGoal;
  final int goalValue;
  final int totalDays;  // 7 for weekly, 30 for monthly
  
  const WeeklyReportData({
    required this.dailyProgress,
    required this.daysGoalMet,
    required this.achievementRate,
    required this.bestDayIndex,
    required this.worstDayIndex,
    required this.totalValue,
    required this.averageValue,
    required this.isCountGoal,
    required this.goalValue,
    this.totalDays = 7,
  });
  
  /// Whether this is a weekly report (vs monthly)
  bool get isWeekly => totalDays <= 7;
  
  String get motivationalMessage {
    if (achievementRate >= 1.0) {
      return "Perfect week! 🌟 You're absolutely crushing it!";
    } else if (achievementRate >= 0.85) {
      return "Almost perfect! 🏆 Outstanding dedication this week!";
    } else if (achievementRate >= 0.7) {
      return "Excellent week! 💪 Keep building that consistency!";
    } else if (achievementRate >= 0.5) {
      return "Good progress! 📈 Push a little more next week!";
    } else if (achievementRate >= 0.3) {
      return "Building momentum! 🌱 Every day is a new opportunity!";
    } else {
      return "A new week awaits! 🚀 Start fresh and aim higher!";
    }
  }
  
  String get badge {
    if (achievementRate >= 1.0) return '🌟 Perfect';
    if (achievementRate >= 0.85) return '🏆 Elite';
    if (achievementRate >= 0.7) return '💪 Strong';
    if (achievementRate >= 0.5) return '📈 Growing';
    if (achievementRate >= 0.3) return '🌱 Starting';
    return '🚀 New Start';
  }
}
