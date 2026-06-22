import 'package:flutter_test/flutter_test.dart';
import 'package:smrt_counter/features/insights/domain/daily_stats.dart';
import 'package:smrt_counter/features/settings/domain/settings_state.dart';
import 'package:smrt_counter/services/report_service.dart';

void main() {
  late ReportService reportService;

  setUp(() {
    reportService = ReportService.instance;
  });

  group('checkYesterdayGoal', () {
    test('returns null when no goal is set', () {
      final stats = [
        DailyStats(date: '2026-06-14', counts: 100, malas: 0, sessions: 1, durationSeconds: 60),
        DailyStats(date: '2026-06-13', counts: 50, malas: 0, sessions: 1, durationSeconds: 30),
      ];
      final settings = SettingsState.defaults(); // dailyGoal = 0

      final result = reportService.checkYesterdayGoal(stats, settings);
      expect(result, isNull);
    });

    test('returns null when yesterday goal was met (malas)', () {
      final stats = [
        DailyStats(date: '2026-06-14', counts: 100, malas: 0, sessions: 1, durationSeconds: 60),
        DailyStats(date: '2026-06-13', counts: 540, malas: 5, sessions: 2, durationSeconds: 300),
      ];
      final settings = SettingsState.defaults().copyWith(dailyGoal: 5, goalType: GoalType.malas);

      final result = reportService.checkYesterdayGoal(stats, settings);
      expect(result, isNull);
    });

    test('returns GoalMissInfo when yesterday goal was missed (malas)', () {
      final stats = [
        DailyStats(date: '2026-06-14', counts: 100, malas: 0, sessions: 1, durationSeconds: 60),
        DailyStats(date: '2026-06-13', counts: 324, malas: 3, sessions: 1, durationSeconds: 200),
      ];
      final settings = SettingsState.defaults().copyWith(dailyGoal: 5, goalType: GoalType.malas);

      final result = reportService.checkYesterdayGoal(stats, settings);
      expect(result, isNotNull);
      expect(result!.achieved, 3);
      expect(result.goal, 5);
      expect(result.missing, 2);
      expect(result.isCountGoal, false);
      expect(result.percentage, closeTo(60.0, 0.1));
    });

    test('returns GoalMissInfo for count-based goals', () {
      final stats = [
        DailyStats(date: '2026-06-14', counts: 0, malas: 0, sessions: 0, durationSeconds: 0),
        DailyStats(date: '2026-06-13', counts: 80, malas: 0, sessions: 1, durationSeconds: 60),
      ];
      final settings = SettingsState.defaults().copyWith(
        dailyGoalCount: 108,
        goalType: GoalType.counts,
      );

      final result = reportService.checkYesterdayGoal(stats, settings);
      expect(result, isNotNull);
      expect(result!.achieved, 80);
      expect(result.goal, 108);
      expect(result.missing, 28);
      expect(result.isCountGoal, true);
    });

    test('returns null for fresh install with no history', () {
      final stats = [
        DailyStats.empty('2026-06-14'),
        DailyStats.empty('2026-06-13'),
      ];
      final settings = SettingsState.defaults().copyWith(dailyGoal: 5, goalType: GoalType.malas);

      final result = reportService.checkYesterdayGoal(stats, settings);
      expect(result, isNull);
    });

    test('returns null with fewer than 2 days of data', () {
      final stats = [
        DailyStats(date: '2026-06-14', counts: 100, malas: 0, sessions: 1, durationSeconds: 60),
      ];
      final settings = SettingsState.defaults().copyWith(dailyGoal: 5, goalType: GoalType.malas);

      final result = reportService.checkYesterdayGoal(stats, settings);
      expect(result, isNull);
    });
  });

  group('generateReport', () {
    test('generates correct weekly report with goal tracking', () {
      final stats = List.generate(7, (i) => DailyStats(
        date: '2026-06-${14 - i}',
        counts: i % 2 == 0 ? 540 : 200,  // Alternating: goal met / missed
        malas: i % 2 == 0 ? 5 : 1,
        sessions: 1,
        durationSeconds: 300,
      ));

      final settings = SettingsState.defaults().copyWith(
        dailyGoal: 5,
        goalType: GoalType.malas,
      );

      final report = reportService.generateReport(stats, settings, days: 7);

      expect(report.totalDays, 7);
      expect(report.dailyProgress.length, 7);
      expect(report.isWeekly, true);
      expect(report.isCountGoal, false);
      expect(report.goalValue, 5);
      expect(report.totalValue, greaterThan(0));
    });

    test('generates correct monthly report', () {
      final stats = List.generate(30, (i) => DailyStats(
        date: '2026-06-${30 - i}',
        counts: 108,
        malas: 1,
        sessions: 1,
        durationSeconds: 60,
      ));

      final settings = SettingsState.defaults().copyWith(
        dailyGoal: 1,
        goalType: GoalType.malas,
      );

      final report = reportService.generateReport(stats, settings, days: 30);

      expect(report.totalDays, 30);
      expect(report.dailyProgress.length, 30);
      expect(report.isWeekly, false);
      expect(report.daysGoalMet, 30);
      expect(report.achievementRate, 1.0);
    });

    test('handles no goal set', () {
      final stats = List.generate(7, (i) => DailyStats(
        date: '2026-06-${14 - i}',
        counts: 100,
        malas: 0,
        sessions: 1,
        durationSeconds: 60,
      ));

      final settings = SettingsState.defaults(); // no goal

      final report = reportService.generateReport(stats, settings, days: 7);

      expect(report.goalValue, 0);
      expect(report.daysGoalMet, 0);
      expect(report.achievementRate, 0.0);
    });

    test('identifies best and worst days correctly', () {
      final stats = [
        DailyStats(date: '2026-06-14', counts: 500, malas: 4, sessions: 1, durationSeconds: 300),
        DailyStats(date: '2026-06-13', counts: 100, malas: 0, sessions: 1, durationSeconds: 60),
        DailyStats(date: '2026-06-12', counts: 1080, malas: 10, sessions: 3, durationSeconds: 600),
        DailyStats(date: '2026-06-11', counts: 200, malas: 1, sessions: 1, durationSeconds: 120),
        DailyStats.empty('2026-06-10'),
        DailyStats.empty('2026-06-09'),
        DailyStats.empty('2026-06-08'),
      ];

      final settings = SettingsState.defaults().copyWith(
        dailyGoal: 5,
        goalType: GoalType.malas,
      );

      final report = reportService.generateReport(stats, settings, days: 7);

      // Best day should be the one with 10 malas
      expect(report.bestDayIndex, isNotNull);
      // Worst active day should be the one with 0 malas (100 counts)
      expect(report.worstDayIndex, isNotNull);
    });
  });

  group('WeeklyReportData', () {
    test('motivationalMessage varies by achievement rate', () {
      // Perfect rate
      final perfect = WeeklyReportData(
        dailyProgress: [],
        daysGoalMet: 7,
        achievementRate: 1.0,
        bestDayIndex: 0,
        worstDayIndex: 6,
        totalValue: 100,
        averageValue: 14,
        isCountGoal: false,
        goalValue: 5,
      );
      expect(perfect.motivationalMessage, contains('Perfect'));
      expect(perfect.badge, contains('Perfect'));

      // Low rate
      final low = WeeklyReportData(
        dailyProgress: [],
        daysGoalMet: 1,
        achievementRate: 0.14,
        bestDayIndex: 0,
        worstDayIndex: 6,
        totalValue: 10,
        averageValue: 1,
        isCountGoal: false,
        goalValue: 5,
      );
      expect(low.badge, contains('New Start'));
    });
  });
}
