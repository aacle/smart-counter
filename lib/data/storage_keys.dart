/// Centralized registry of all SharedPreferences keys.
///
/// Every key used anywhere in the app MUST be listed here.
/// This prevents typos, documents ownership, and makes migration easy.
class StorageKeys {
  StorageKeys._();

  // ── Counter (owned by CounterNotifier) ──
  static const counterState = 'counter_state';

  // ── Insights (owned by InsightsNotifier) ──
  static const dailyStats = 'daily_stats';
  static const currentStreak = 'current_streak';
  static const bestStreak = 'best_streak';
  static const lastActiveDate = 'last_active_date';

  // ── Settings (owned by SettingsNotifier) ──
  static const appSettings = 'app_settings';

  // ── Reports (owned by ReportService) — local-only ──
  static const lastWeeklyReport = 'last_weekly_report';
  static const lastMonthlyReport = 'last_monthly_report';
  static const lastGoalMissCheck = 'last_goal_miss_check';

  // ── Feedback (owned by FeedbackService) — local-only ──
  static const feedbackFirstLaunch = 'feedback_first_launch';
  static const feedbackLastPrompt = 'feedback_last_prompt';
  static const feedbackNeverAsk = 'feedback_never_ask';
  static const feedbackHasRated = 'feedback_has_rated';

  // ── Reminders (owned by ReminderService) — local-only ──
  static const reminderEnabled = 'reminder_enabled';
  static const reminderIntervalMinutes = 'reminder_interval_minutes';
  static const reminderSound = 'reminder_sound';

  // ── Auth & Migration (owned by app layer) ──
  static const hasSeenMigrationPopup = 'has_seen_migration_popup';

  // ── DEPRECATED — scheduled for removal ──
  // These are redundant with daily_stats aggregation.
  // Kept for backward compatibility during migration.
  static const lifetimeCounts = 'lifetime_counts';
  static const lifetimeMalas = 'lifetime_malas';
  static const lifetimeSessions = 'lifetime_sessions';
}
