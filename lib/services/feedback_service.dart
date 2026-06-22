import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';
import '../data/storage_keys.dart';

/// Service to manage rate-us prompts with smart frequency
class FeedbackService {
  static final FeedbackService instance = FeedbackService._();
  FeedbackService._();

  static const int _daysBeforeFirstPrompt = 3;
  static const int _daysBetweenPrompts = 7;
  static const int _minMalasRequired = 1;

  final InAppReview _inAppReview = InAppReview.instance;

  /// Initialize first launch date if not set
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(StorageKeys.feedbackFirstLaunch)) {
      await prefs.setString(StorageKeys.feedbackFirstLaunch, DateTime.now().toIso8601String());
    }
  }

  /// Check if we should show the custom rate-us dialog
  /// Set [debugForceShow] to true in debug builds to test instantly
  Future<bool> shouldShowRateUsDialog(int totalMalas, {bool debugForceShow = false}) async {
    if (debugForceShow) return true;

    final prefs = await SharedPreferences.getInstance();

    // Never show if user said "Don't ask again" or already rated
    if (prefs.getBool(StorageKeys.feedbackNeverAsk) == true || prefs.getBool(StorageKeys.feedbackHasRated) == true) {
      return false;
    }

    // Check minimum usage: at least X days since first launch and Y malas
    final firstLaunchStr = prefs.getString(StorageKeys.feedbackFirstLaunch);
    if (firstLaunchStr == null) return false;

    final firstLaunch = DateTime.parse(firstLaunchStr);
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;

    if (daysSinceFirstLaunch < _daysBeforeFirstPrompt || totalMalas < _minMalasRequired) {
      return false;
    }

    // Check cooldown since last prompt
    final lastPromptStr = prefs.getString(StorageKeys.feedbackLastPrompt);
    if (lastPromptStr != null) {
      final lastPrompt = DateTime.parse(lastPromptStr);
      final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
      if (daysSinceLastPrompt < _daysBetweenPrompts) {
        return false;
      }
    }

    // Record this prompt time
    await prefs.setString(StorageKeys.feedbackLastPrompt, DateTime.now().toIso8601String());
    return true;
  }

  /// User tapped "Maybe Later" — just let the cooldown handle it
  Future<void> postponeRating() async {
    // The cooldown is already set in shouldShowRateUsDialog
    // Next prompt will appear after _daysBetweenPrompts
  }

  /// User tapped "Don't Ask Again"
  Future<void> neverAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.feedbackNeverAsk, true);
  }

  /// User tapped "Rate Us" — mark as rated so we never ask again
  Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.feedbackHasRated, true);
  }

  /// Open Play Store listing directly
  Future<void> openStoreForRating() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: 'com.smartnaamjap.smrt_counter',
      );
    } catch (e, stackTrace) {
      AppLogger.error('FeedbackService', 'Failed to open store listing', e, stackTrace);
    }
  }
}
