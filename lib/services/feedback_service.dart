import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage in-app review prompts with smart timing
/// 
/// Google's In-App Review API has built-in quota management:
/// - Automatically handles "Not now" cooldown (~28 days)
/// - Prevents showing if user already reviewed
/// - We just call requestReview() when our conditions are met
class FeedbackService {
  static const String _keyFirstLaunch = 'feedback_first_launch';
  
  static const int _daysBeforePrompt = 5;
  static const int _minMalasRequired = 1;

  final InAppReview _inAppReview = InAppReview.instance;
  
  /// Initialize first launch date if not set
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyFirstLaunch)) {
      await prefs.setString(_keyFirstLaunch, DateTime.now().toIso8601String());
    }
  }

  /// Request in-app review if minimum usage requirements are met
  /// Google handles quota internally (won't show if user already reviewed
  /// or clicked "Not now" recently)
  Future<void> requestReviewIfEligible(int totalMalas) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check minimum usage requirements
    final firstLaunchStr = prefs.getString(_keyFirstLaunch);
    if (firstLaunchStr == null) {
      return;
    }
    
    final firstLaunch = DateTime.parse(firstLaunchStr);
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
    
    // Must have used app for at least 5 days and completed 1 mala
    if (daysSinceFirstLaunch < _daysBeforePrompt || totalMalas < _minMalasRequired) {
      return;
    }
    
    // Request review - Google handles the quota
    // Will silently do nothing if user already reviewed or "Not now" recently
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      // Silent fail - don't disrupt user experience
    }
  }

  /// Open Play Store listing for manual "Rate Us" button in settings
  /// Uses in-app review if available, falls back to store listing
  Future<void> openStoreForRating() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      // Try opening store listing as fallback
      try {
        await _inAppReview.openStoreListing();
      } catch (_) {}
    }
  }
}
