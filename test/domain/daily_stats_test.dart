import 'package:flutter_test/flutter_test.dart';
import 'package:smrt_counter/features/insights/domain/daily_stats.dart';

void main() {
  group('DailyStats', () {
    group('empty', () {
      test('should create stats with all zeros', () {
        final stats = DailyStats.empty('2026-06-14');
        expect(stats.date, '2026-06-14');
        expect(stats.counts, 0);
        expect(stats.malas, 0);
        expect(stats.sessions, 0);
        expect(stats.durationSeconds, 0);
      });
    });

    group('computed properties', () {
      test('duration returns Duration from seconds', () {
        final stats = DailyStats(
          date: '2026-06-14',
          counts: 540,
          malas: 5,
          sessions: 2,
          durationSeconds: 600,
        );
        expect(stats.duration, const Duration(seconds: 600));
        expect(stats.duration, const Duration(minutes: 10));
      });
    });

    group('copyWith', () {
      test('should update specified fields only', () {
        final stats = DailyStats(
          date: '2026-06-14',
          counts: 100,
          malas: 0,
          sessions: 1,
          durationSeconds: 300,
        );

        final updated = stats.copyWith(counts: 200, malas: 1);
        expect(updated.counts, 200);
        expect(updated.malas, 1);
        expect(updated.sessions, 1); // unchanged
        expect(updated.durationSeconds, 300); // unchanged
        expect(updated.date, '2026-06-14'); // unchanged
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected map', () {
        final stats = DailyStats(
          date: '2026-06-14',
          counts: 540,
          malas: 5,
          sessions: 3,
          durationSeconds: 1200,
        );

        final json = stats.toJson();
        expect(json['date'], '2026-06-14');
        expect(json['counts'], 540);
        expect(json['malas'], 5);
        expect(json['sessions'], 3);
        expect(json['durationSeconds'], 1200);
      });

      test('fromJson round-trips correctly', () {
        final original = DailyStats(
          date: '2026-01-01',
          counts: 1080,
          malas: 10,
          sessions: 5,
          durationSeconds: 3600,
        );

        final json = original.toJson();
        final restored = DailyStats.fromJson(json);

        expect(restored, equals(original));
      });

      test('fromJson handles missing numeric fields with defaults', () {
        final stats = DailyStats.fromJson({'date': '2026-06-14'});
        expect(stats.date, '2026-06-14');
        expect(stats.counts, 0);
        expect(stats.malas, 0);
        expect(stats.sessions, 0);
        expect(stats.durationSeconds, 0);
      });
    });

    group('equality', () {
      test('two stats with same values are equal', () {
        final a = DailyStats(
          date: '2026-06-14',
          counts: 100,
          malas: 0,
          sessions: 1,
          durationSeconds: 60,
        );
        final b = DailyStats(
          date: '2026-06-14',
          counts: 100,
          malas: 0,
          sessions: 1,
          durationSeconds: 60,
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different dates are not equal', () {
        final a = DailyStats.empty('2026-06-14');
        final b = DailyStats.empty('2026-06-15');
        expect(a, isNot(equals(b)));
      });
    });
  });

  group('PeriodStats', () {
    test('empty factory creates all-zero stats', () {
      final stats = PeriodStats.empty();
      expect(stats.totalCounts, 0);
      expect(stats.totalMalas, 0);
      expect(stats.totalSessions, 0);
      expect(stats.totalDurationSeconds, 0);
      expect(stats.daysActive, 0);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 0);
    });

    test('averages handle zero active days gracefully', () {
      final stats = PeriodStats.empty();
      expect(stats.avgCountsPerDay, 0.0);
      expect(stats.avgMalasPerDay, 0.0);
      expect(stats.avgSessionDuration, Duration.zero);
      expect(stats.avgCountsPerSession, 0.0);
    });

    test('averages compute correctly with data', () {
      final stats = PeriodStats(
        totalCounts: 1080,
        totalMalas: 10,
        totalSessions: 5,
        totalDurationSeconds: 3000,
        daysActive: 3,
        currentStreak: 3,
        bestStreak: 5,
      );

      expect(stats.avgCountsPerDay, 360.0);
      expect(stats.avgMalasPerDay, closeTo(3.33, 0.01));
      expect(stats.avgSessionDuration, const Duration(seconds: 600));
      expect(stats.avgCountsPerSession, 216.0);
      expect(stats.totalDuration, const Duration(seconds: 3000));
    });
  });
}
