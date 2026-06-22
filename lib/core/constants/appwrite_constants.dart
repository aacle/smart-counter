/// Appwrite backend configuration for Smart Naam Jap 2.0.
///
/// These values are NOT secrets — they identify the project.
/// The Google OAuth client secret is stored server-side in Appwrite,
/// never in the app.
class AppwriteConstants {
  AppwriteConstants._();

  static const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '6a38c0ea003bacdeabb9';

  /// OAuth callback scheme for Android deeplink redirect.
  /// Format: `appwrite-callback-PROJECT_ID`
  static const String oauthCallbackScheme =
      'appwrite-callback-$projectId';

  // ── Database ──────────────────────────────────────────────────
  static const String databaseId = 'smart_naam_jap';

  // ── Collections ───────────────────────────────────────────────
  static const String dailyStatsCollection = 'daily_stats';
  static const String userSettingsCollection = 'user_settings';
  static const String userProfilesCollection = 'user_profiles';
}
