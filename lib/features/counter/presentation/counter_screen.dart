import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../services/volume_rocker_service.dart';
import '../../../services/reminder_service.dart';
import '../../../services/haptic_service.dart';
import '../../../services/sound_service.dart';
import '../providers/counter_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/presentation/reminder_setup_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/domain/settings_state.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../insights/providers/insights_provider.dart';
import '../../insights/presentation/widgets/weekly_report_dialog.dart';
import '../../insights/presentation/widgets/goal_miss_banner.dart';
import '../../common/rate_us_dialog.dart';
import '../../../services/report_service.dart';
import '../../../services/feedback_service.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import 'widgets/mala_beads.dart';
import 'widgets/counter_display.dart';
import 'widgets/session_stats.dart';

/// Main counter screen - the heart of the app
class CounterScreen extends ConsumerStatefulWidget {
  const CounterScreen({super.key});

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen>
    with WidgetsBindingObserver {
  final VolumeRockerService _volumeService = VolumeRockerService.instance;
  final ReminderService _reminderService = ReminderService.instance;
  final HapticService _hapticService = HapticService.instance;
  final SoundService _soundService = SoundService.instance;
  final FeedbackService _feedbackService = FeedbackService.instance;
  
  StreamSubscription<void>? _volumeSubscription;
  
  Timer? _sessionTimer;
  Timer? _autoCountTimer;
  Duration _sessionDuration = Duration.zero;
  bool _showCelebration = false;
  bool _isAutoCountActive = false;
  GoalMissInfo? _goalMissInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSessionTimer();
    _initServices();
    _reminderService.initialize();
    
    // Set system UI style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _initServices() async {
    await _hapticService.initialize();
    await _soundService.initialize();
    await _feedbackService.initialize();
    
    // Apply initial settings
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = ref.read(settingsProvider);
      _applySettings(settings);

      await OnboardingScreen.checkAndShow(context, ref);

      _checkForReports();
    });
  }

  /// Check for pending reports to show
  Future<void> _checkForReports() async {
    final settings = ref.read(settingsProvider);
    var insights = ref.read(insightsProvider);
    final reportService = ReportService.instance;
    
    // Wait for insights data to finish loading before checking reports
    // This prevents showing incorrect "0 malas" when data hasn't loaded yet
    int attempts = 0;
    while (insights.isLoading && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      insights = ref.read(insightsProvider);
      attempts++;
    }
    
    // If still loading after 2 seconds, skip checks for now
    if (insights.isLoading) return;
    
    // Priority: Monthly > Weekly > Goal Miss
    
    // Check monthly report (priority)
    if (settings.monthlyReportEnabled && await reportService.shouldShowMonthlyReport()) {
      final last7Days = insights.getStatsForDays(7);
      if (last7Days.any((d) => d.counts > 0)) {
        _showWeeklyReportDialog();
        await reportService.markMonthlyReportShown();
        return;
      }
    }
    
    // Check weekly report
    if (settings.weeklyReportEnabled && await reportService.shouldShowWeeklyReport()) {
      final last7Days = insights.getStatsForDays(7);
      if (last7Days.any((d) => d.counts > 0)) {
        _showWeeklyReportDialog();
        await reportService.markWeeklyReportShown();
        return;
      }
    }
    
    // Check goal miss
    if (settings.goalMissNotificationEnabled && await reportService.shouldShowGoalMissNotification()) {
      final last7Days = insights.getStatsForDays(7);
      final missInfo = reportService.checkYesterdayGoal(last7Days, settings);
      if (missInfo != null) {
        setState(() {
          _goalMissInfo = missInfo;
        });
      }
      await reportService.markGoalMissChecked();
    }
    // Show rate-us dialog if eligible
    // Set debugForceShow: true to test the popup in debug mode
    if (_goalMissInfo == null && mounted) {
      final totalMalas = insights.lifetimeStats.totalMalas;
      final shouldShow = await _feedbackService.shouldShowRateUsDialog(
        totalMalas,
        debugForceShow: false, // Set to true to test
      );
      if (shouldShow && mounted) {
        await RateUsDialog.show(context);
      }
    }
  }

  void _showWeeklyReportDialog() {
    final settings = ref.read(settingsProvider);
    final insights = ref.read(insightsProvider);
    final reportService = ReportService.instance;
    final last7Days = insights.getStatsForDays(7);
    final reportData = reportService.generateWeeklyReport(last7Days, settings);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WeeklyReportDialog(
        reportData: reportData,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  void _applySettings(settings) {
    // Apply wakelock
    if (settings.keepScreenAwake) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    
    // Apply volume rocker
    if (settings.volumeRockerEnabled) {
      _initVolumeRocker();
    } else {
      _volumeSubscription?.cancel();
      _volumeService.stopListening();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _autoCountTimer?.cancel();
    _volumeSubscription?.cancel();
    _volumeService.stopListening();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Pause jap timer and flush accumulated time to insights
      ref.read(counterProvider.notifier).pauseJapTimer();
      _flushJapTimeToInsights();
      ref.read(counterProvider.notifier).saveNow();
      ref.read(insightsProvider.notifier).saveNow();
      _stopAutoCount();
    }
  }

  /// Flush current jap time to daily insights stats
  void _flushJapTimeToInsights() {
    final japSeconds = ref.read(counterProvider.notifier).japDurationSeconds;
    if (japSeconds > 0) {
      ref.read(insightsProvider.notifier).recordJapTime(japSeconds);
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _sessionDuration = ref.read(counterProvider).sessionDuration;
        });
      }
    });
  }

  Future<void> _initVolumeRocker() async {
    final settings = ref.read(settingsProvider);
    if (!settings.volumeRockerEnabled) return;
    
    final isAvailable = await _volumeService.isAvailable();
    if (isAvailable) {
      await _volumeService.startListening();
      _volumeSubscription?.cancel();
      _volumeSubscription = _volumeService.countStream.listen((_) {
        _onCount();
      });
    }
  }

  void _onCount() {
    final settings = ref.read(settingsProvider);
    final currentState = ref.read(counterProvider);
    final currentMalas = currentState.count ~/ kMalaSize;
    
    // Increment state first
    ref.read(counterProvider.notifier).increment();
    
    // Record count for daily insights
    ref.read(insightsProvider.notifier).recordCount();
    
    // Synchronously predict new count to ensure instantaneous feedback.
    // The previous state was reading the provider asynchronously which caused timing mismatches.
    final newCount = currentState.count + 1;
    final newMalas = newCount ~/ kMalaSize;
    
    // Flush jap time to insights periodically (every 5 counts)
    if (newCount % 5 == 0) {
      _flushJapTimeToInsights();
    }
    
    // Trigger haptic feedback IMMEDIATELY (no frame delay).
    // We ALWAYS want the 108th (mala complete) tap to vibrate even if standard haptics are off.
    _hapticService.onCount(newCount, hapticEnabled: settings.hapticEnabled);
    
    // Play tap sound if enabled
    if (settings.tapSoundEnabled) {
      _soundService.playTapSound();
    }
    
    // Trigger the visual UI celebration animation
    if (newMalas > currentMalas) {
      _showMalaCelebration();
    }
  }

  void _onAutoCount() {
    _soundService.playTick();
    _onCount();
  }

  void _startAutoCount() {
    if (_isAutoCountActive) return;
    
    final settings = ref.read(settingsProvider);
    final intervalMs = (settings.autoCountSpeed * 1000).round();
    
    setState(() => _isAutoCountActive = true);
    
    _autoCountTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _onAutoCount(),
    );
  }

  void _stopAutoCount() {
    _autoCountTimer?.cancel();
    _autoCountTimer = null;
    if (mounted) {
      setState(() => _isAutoCountActive = false);
    }
  }

  void _toggleAutoCount() {
    if (_isAutoCountActive) {
      _stopAutoCount();
    } else {
      _startAutoCount();
    }
  }

  /// Show info dialog explaining Auto Chant feature
  void _showAutoChantInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.autorenew, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              'How Auto Chant Works',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Enable this to set a continuous rhythm. The app will vibrate or play a tap sound at your set speed, allowing you to chant the mantra internally without needing to touch the screen.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Format speed for display (e.g., 0.25s, 0.5s, 1s, 1.5s)
  String _formatSpeed(double speed) {
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()}s';
    }
    return '${speed}s';
  }

  /// Get the available speed steps
  static const List<double> _speedSteps = [0.25, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];

  /// Decrease speed to the previous step
  double _decreaseSpeed(double currentSpeed) {
    final currentIndex = _speedSteps.indexOf(currentSpeed);
    if (currentIndex == -1) {
      // Find nearest lower step
      for (int i = _speedSteps.length - 1; i >= 0; i--) {
        if (_speedSteps[i] < currentSpeed) return _speedSteps[i];
      }
      return _speedSteps.first;
    }
    return currentIndex > 0 ? _speedSteps[currentIndex - 1] : _speedSteps.first;
  }

  /// Increase speed to the next step
  double _increaseSpeed(double currentSpeed) {
    final currentIndex = _speedSteps.indexOf(currentSpeed);
    if (currentIndex == -1) {
      // Find nearest higher step
      for (int i = 0; i < _speedSteps.length; i++) {
        if (_speedSteps[i] > currentSpeed) return _speedSteps[i];
      }
      return _speedSteps.last;
    }
    return currentIndex < _speedSteps.length - 1 ? _speedSteps[currentIndex + 1] : _speedSteps.last;
  }

  void _showMalaCelebration() {
    setState(() => _showCelebration = true);
    // Note: We intentionally do NOT call `_soundService.playComplete()` here anymore.
    // The playComplete() function triggers `_hapticService.celebrationFeedback()`,
    // which was causing a massive duplicate/out-of-sync vibration right as the 108th 
    // count was tapped. The `_hapticService.onCount()` already handles the 
    // exact perfectly-timed 108th vibration.
    
    Future.delayed(kMalaCompleteAnimationDuration, () {
      if (mounted) {
        setState(() => _showCelebration = false);
      }
    });
  }

  void _handleReminderTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderSetupScreen()),
    );
  }

  void _onResetTap() {
    _stopAutoCount();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Reset Counter?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          'This will reset your current session back to zero. Your daily total in the Insights tab will remain intact.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset the counter internally
              ref.read(counterProvider.notifier).resetSession();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counterState = ref.watch(counterProvider);
    final insightsState = ref.watch(insightsProvider);
    final settings = ref.watch(settingsProvider);
    
    // Watch settings changes and apply them
    ref.listen(settingsProvider, (previous, next) {
      _applySettings(next);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: AppColors.textMuted,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                  ),
                  // Title
                  Text(
                    settings.customTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                  ),
                  // Reminder Button
                  _buildReminderButton(),
                ],
              ),
            ),

            // Goal miss banner (if applicable)
            if (_goalMissInfo != null)
              GoalMissBanner(
                info: _goalMissInfo!,
                onDismiss: () {
                  setState(() {
                    _goalMissInfo = null;
                  });
                },
              ),

            // Main tappable area with mala beads
            Expanded(
              child: GestureDetector(
                onTap: _isAutoCountActive ? null : _onCount,
                behavior: HitTestBehavior.opaque,
                child: settings.interfaceMode == InterfaceMode.malaWise
                    ? _buildMalaWiseContent(counterState, insightsState, settings)
                    : _buildCountWiseContent(counterState, insightsState, settings),
              ),
            ),

            // Auto Count Toggle
            _buildAutoCountToggle(settings),
            
            const SizedBox(height: 8),

            // Session stats bar
            SessionStats(
              sessionDuration: _sessionDuration,
              onInsightsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InsightsScreen()),
              ),
              onResetTap: _onResetTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCountToggle(settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isAutoCountActive 
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAutoCountActive 
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.autorenew,
            color: _isAutoCountActive ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Auto Chant',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showAutoChantInfoDialog,
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  _isAutoCountActive 
                      ? 'Every ${_formatSpeed(settings.autoCountSpeed)}'
                      : 'Automatic chanting mode',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Speed selector (only when not active)
          if (!_isAutoCountActive) ...[
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: AppColors.textMuted,
              onPressed: settings.autoCountSpeed > 0.25 
                  ? () => ref.read(settingsProvider.notifier)
                      .setAutoCountSpeed(_decreaseSpeed(settings.autoCountSpeed))
                  : null,
            ),
            Text(
              _formatSpeed(settings.autoCountSpeed),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              color: AppColors.textMuted,
              onPressed: settings.autoCountSpeed < 5.0
                  ? () => ref.read(settingsProvider.notifier)
                      .setAutoCountSpeed(_increaseSpeed(settings.autoCountSpeed))
                  : null,
            ),
          ],
          const SizedBox(width: 8),
          // Start/Stop button
          ElevatedButton(
            onPressed: _toggleAutoCount,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAutoCountActive 
                  ? Colors.red.shade400
                  : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(_isAutoCountActive ? 'Stop' : 'Start'),
          ),
        ],
      ),
    );
  }

  /// Reminder toggle button
  Widget _buildReminderButton() {
    final settings = ref.watch(settingsProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: settings.reminderEnabled 
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.reminderEnabled 
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleReminderTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  settings.reminderEnabled 
                      ? Icons.notifications_active 
                      : Icons.notifications_none,
                  color: settings.reminderEnabled 
                      ? AppColors.primary 
                      : AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mala-wise interface - shows 108 bead circle prominently
  Widget _buildMalaWiseContent(counterState, insightsState, settings) {
    // Reduce size when banner is shown to prevent overflow
    final beadSize = _goalMissInfo != null
        ? MediaQuery.of(context).size.height * 0.28
        : MediaQuery.of(context).size.height * 0.35;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated mala beads - responsive size
        MalaBeads(
          currentCount: insightsState.todayStats.counts,
          showCelebration: _showCelebration,
          size: beadSize,
          centerImagePath: settings.centerImagePath,
        ),
        
        const SizedBox(height: 16),
        
        // Main Counter Display
        CounterDisplay(
          count: insightsState.todayStats.counts,
          malasCompleted: insightsState.todayStats.malas,
          interfaceMode: InterfaceMode.malaWise,
        ),
        
        const SizedBox(height: 16),
        
        _buildTapInstruction(),
      ],
    );
  }

  /// Count-wise interface - shows total count prominently
  Widget _buildCountWiseContent(counterState, insightsState, settings) {
    // Reduce size when banner is shown to prevent overflow
    final beadSize = _goalMissInfo != null
        ? MediaQuery.of(context).size.height * 0.18
        : MediaQuery.of(context).size.height * 0.22;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Smaller mala beads or just a progress indicator
        MalaBeads(
          currentCount: insightsState.todayStats.counts,
          showCelebration: _showCelebration,
          size: beadSize,
          centerImagePath: settings.centerImagePath,
        ),
        
        const SizedBox(height: 24),
        
        // Main Counter Display - count-wise style
        CounterDisplay(
          count: insightsState.todayStats.counts,
          malasCompleted: insightsState.todayStats.malas,
          interfaceMode: InterfaceMode.countWise,
        ),
        
        const SizedBox(height: 16),
        
        _buildTapInstruction(),
      ],
    );
  }

  /// Common tap instruction widget
  Widget _buildTapInstruction() {
    if (_isAutoCountActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.autorenew,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            Text(
              'Auto Mode Active',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.touch_app,
          size: 20,
          color: AppColors.textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          'Tap to count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
