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
import '../../insights/presentation/insights_screen.dart';
import '../../insights/providers/insights_provider.dart';
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
  final ReminderService _reminderService = ReminderService();
  final HapticService _hapticService = HapticService.instance;
  final SoundService _soundService = SoundService.instance;
  
  StreamSubscription<void>? _volumeSubscription;
  
  Timer? _sessionTimer;
  Timer? _autoCountTimer;
  Duration _sessionDuration = Duration.zero;
  bool _showCelebration = false;
  bool _isAutoCountActive = false;

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
    
    // Apply initial settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _applySettings(settings);
    });
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
      ref.read(counterProvider.notifier).saveNow();
      _stopAutoCount();
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
    
    ref.read(counterProvider.notifier).increment();
    
    // Record count for daily insights
    ref.read(insightsProvider.notifier).recordCount();
    
    // Trigger haptic feedback if enabled
    if (settings.hapticEnabled) {
      _hapticService.onCount(currentState.count + 1);
    }
    
    final newState = ref.read(counterProvider);
    final newMalas = newState.count ~/ kMalaSize;
    
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

  void _showMalaCelebration() {
    setState(() => _showCelebration = true);
    _soundService.playComplete();
    
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

  String _formatInterval(int minutes) {
    if (minutes >= 60) {
      return '${minutes ~/ 60}h';
    }
    return '${minutes}m';
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
          'Reset Session?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          'Your current count will be saved to your lifetime statistics before resetting.',
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
                    'Simran',
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

            // Main tappable area with mala beads
            Expanded(
              child: GestureDetector(
                onTap: _isAutoCountActive ? null : _onCount,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated mala beads - responsive size
                    MalaBeads(
                      currentCount: counterState.count,
                      showCelebration: _showCelebration,
                      size: MediaQuery.of(context).size.height * 0.35,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Main Counter Display
                    CounterDisplay(
                      count: counterState.count,
                      malasCompleted: counterState.sessionMalas,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tap instruction or Auto mode indicator
                    if (_isAutoCountActive)
                      Container(
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
                      )
                    else
                      Row(
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
                      ),
                  ],
                ),
              ),
            ),

            // Auto Count Toggle
            _buildAutoCountToggle(settings),
            
            const SizedBox(height: 8),

            // Session stats bar
            SessionStats(
              sessionDuration: _sessionDuration,
              pocketModeActive: false,
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
                Text(
                  'Auto Count',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isAutoCountActive 
                      ? 'Every ${settings.autoCountSpeed.toStringAsFixed(1)}s'
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
              onPressed: settings.autoCountSpeed > 1.0 
                  ? () => ref.read(settingsProvider.notifier)
                      .setAutoCountSpeed(settings.autoCountSpeed - 0.5)
                  : null,
            ),
            Text(
              '${settings.autoCountSpeed.toStringAsFixed(1)}s',
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
                      .setAutoCountSpeed(settings.autoCountSpeed + 0.5)
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
}
