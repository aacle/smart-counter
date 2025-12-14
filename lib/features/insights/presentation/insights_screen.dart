import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../settings/providers/settings_provider.dart';
import '../../counter/providers/counter_provider.dart';
import '../providers/insights_provider.dart';
import '../domain/daily_stats.dart';

/// Comprehensive Stats/Insights screen
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Duration? _todayScreenTime;
  Duration? _weekScreenTime;
  bool _screenTimeLoading = true;
  bool _hasUsagePermission = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadScreenTime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScreenTime() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));

      final todayUsage = await AppUsage().getAppUsage(todayStart, now);
      final weekUsage = await AppUsage().getAppUsage(weekStart, now);

      Duration todayTotal = Duration.zero;
      for (var app in todayUsage) {
        todayTotal += app.usage;
      }

      Duration weekTotal = Duration.zero;
      for (var app in weekUsage) {
        weekTotal += app.usage;
      }

      if (mounted) {
        setState(() {
          _todayScreenTime = todayTotal;
          _weekScreenTime = weekTotal;
          _hasUsagePermission = true;
          _screenTimeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasUsagePermission = false;
          _screenTimeLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(insightsProvider);
    final settings = ref.watch(settingsProvider);
    final lifetimeStats = ref.watch(lifetimeStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            expandedHeight: 80,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Insights',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(lifetimeStatsProvider);
                  _loadScreenTime();
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: insights.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : Column(
                    children: [
                      // Hero Card - Today's Progress
                      _buildHeroCard(context, insights, settings),

                      const SizedBox(height: 20),

                      // Streak Card
                      _buildStreakCard(context, insights),

                      const SizedBox(height: 20),

                      // Period Stats Tabs
                      _buildPeriodTabs(context, insights, lifetimeStats),

                      const SizedBox(height: 20),

                      // Screen Time Reflection
                      _buildScreenTimeCard(context),

                      const SizedBox(height: 20),

                      // Motivational Card
                      _buildMotivationalCard(context, insights),

                      const SizedBox(height: 40),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Hero card showing today's progress with goal tracking
  Widget _buildHeroCard(
    BuildContext context,
    InsightsState insights,
    settings,
  ) {
    final todayStats = insights.todayStats;
    // todayStats.counts already includes current session via recordCount()
    final int todayTotal = todayStats.counts;
    final todayMalas = todayTotal ~/ kMalaSize;
    final goalMalas = settings.dailyGoal;
    final progress = goalMalas > 0 ? (todayMalas / goalMalas).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Today's Practice",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Big number display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeroStat(
                context,
                value: _formatNumber(todayTotal),
                label: 'Counts',
                icon: Icons.touch_app,
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.primary.withOpacity(0.3),
              ),
              _buildHeroStat(
                context,
                value: todayMalas.toString(),
                label: 'Malas',
                icon: Icons.all_inclusive,
                isPrimary: true,
              ),
            ],
          ),

          // Goal progress
          if (goalMalas > 0) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Goal',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$todayMalas / $goalMalas malas',
                            style: TextStyle(
                              color: progress >= 1.0
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress >= 1.0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
                ],
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeroStat(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isPrimary ? AppColors.primary : AppColors.textMuted,
          size: 18,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: isPrimary ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: isPrimary ? 36 : 28,
              ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Streak card with fire emoji animation
  Widget _buildStreakCard(BuildContext context, InsightsState insights) {
    final currentStreak = insights.currentStreak;
    final bestStreak = insights.bestStreak;
    final isOnFire = currentStreak >= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnFire
              ? AppColors.secondary.withOpacity(0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnFire
                  ? AppColors.secondary.withOpacity(0.2)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isOnFire ? '🔥' : '📿',
              style: const TextStyle(fontSize: 28),
            ),
          ).animate(
            onPlay: (controller) => isOnFire ? controller.repeat() : null,
          ).shake(
            duration: 1000.ms,
            delay: 500.ms,
            hz: 2,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStreak > 0
                      ? '$currentStreak Day Streak!'
                      : 'Start Your Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOnFire ? AppColors.secondary : AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentStreak > 0
                      ? 'Keep going! Best: $bestStreak days'
                      : 'Practice today to begin',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (currentStreak > 0)
            Column(
              children: [
                Text(
                  '$currentStreak',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'days',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  /// Period statistics with tabs
  Widget _buildPeriodTabs(
    BuildContext context,
    InsightsState insights,
    AsyncValue<LifetimeStats> lifetimeStats,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Day'),
                Tab(text: 'Week'),
                Tab(text: 'Month'),
                Tab(text: 'All'),
              ],
            ),
          ),

          // Tab content
          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPeriodContent(insights.getPeriodStats(1), 'Today'),
                _buildPeriodContent(insights.getPeriodStats(7), 'This Week'),
                _buildPeriodContent(insights.getPeriodStats(30), 'This Month'),
                lifetimeStats.when(
                  data: (stats) => _buildLifetimeContent(stats, insights.lifetimeStats),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (_, __) => _buildPeriodContent(insights.lifetimeStats, 'All Time'),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPeriodContent(PeriodStats stats, String periodName) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                _formatNumber(stats.totalCounts),
                'Counts',
                Icons.touch_app,
              ),
              _buildStatColumn(
                stats.totalMalas.toString(),
                'Malas',
                Icons.all_inclusive,
              ),
              _buildStatColumn(
                stats.totalSessions.toString(),
                'Sessions',
                Icons.play_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Averages
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  '${stats.avgMalasPerDay.toStringAsFixed(1)}',
                  'Avg/Day',
                ),
                Container(width: 1, height: 30, color: AppColors.cardBackground),
                _buildMiniStat(
                  _formatDuration(stats.avgSessionDuration),
                  'Avg Session',
                ),
                Container(width: 1, height: 30, color: AppColors.cardBackground),
                _buildMiniStat(
                  '${stats.daysActive}',
                  'Days Active',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeContent(LifetimeStats lifetime, PeriodStats allTime) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                _formatNumber(lifetime.totalCounts + allTime.totalCounts),
                'Total Counts',
                Icons.touch_app,
              ),
              _buildStatColumn(
                (lifetime.totalMalas + allTime.totalMalas).toString(),
                'Total Malas',
                Icons.all_inclusive,
              ),
              _buildStatColumn(
                (lifetime.totalSessions + allTime.totalSessions).toString(),
                'Sessions',
                Icons.play_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Lifetime Journey',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Screen time reflection card
  Widget _buildScreenTimeCard(BuildContext context) {
    if (_screenTimeLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!_hasUsagePermission || _todayScreenTime == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.access_time_filled, color: AppColors.textMuted, size: 32),
            const SizedBox(height: 12),
            Text(
              'Screen Time Unavailable',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enable Usage Access in Settings',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final todayMinutes = _todayScreenTime!.inMinutes;
    final potentialMinNamJap = todayMinutes * 100;
    final potentialMaxNamJap = todayMinutes * 166;
    final potentialMalas = potentialMaxNamJap ~/ 108;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_android, color: Colors.redAccent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missed Opportunity',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      "Today's phone usage",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDuration(_todayScreenTime!),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'You could have chanted',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatNumber(potentialMinNamJap),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      ' - ',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      _formatNumber(potentialMaxNamJap),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                Text(
                  'Nam Jap (~$potentialMalas malas)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  /// Motivational card based on performance
  Widget _buildMotivationalCard(BuildContext context, InsightsState insights) {
    final todayStats = insights.todayStats;
    final weekStats = insights.getPeriodStats(7);
    
    String message;
    IconData icon;
    Color color;

    if (todayStats.counts == 0) {
      message = "Every moment counts. Start your practice today! 🙏";
      icon = Icons.self_improvement;
      color = AppColors.textMuted;
    } else if (insights.currentStreak >= 7) {
      message = "Incredible devotion! A week of unbroken practice. 🌟";
      icon = Icons.stars;
      color = AppColors.success;
    } else if (insights.currentStreak >= 3) {
      message = "You're building a beautiful habit. Keep going! 🔥";
      icon = Icons.local_fire_department;
      color = AppColors.secondary;
    } else if (todayStats.malas >= 5) {
      message = "Wonderful practice today! Your dedication shines. ✨";
      icon = Icons.auto_awesome;
      color = AppColors.primary;
    } else if (weekStats.avgMalasPerDay < 1) {
      message = "Small steps lead to great journeys. Try just one mala today.";
      icon = Icons.directions_walk;
      color = AppColors.textSecondary;
    } else {
      message = "Consistency is key. You're doing great! 💪";
      icon = Icons.favorite;
      color = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 10000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
