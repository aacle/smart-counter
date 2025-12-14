import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_usage/app_usage.dart';
import '../../../core/theme/colors.dart';

/// Screen Time Reflection - Shows potential nam jap based on phone usage
class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  Duration? _todayScreenTime;
  Duration? _weekScreenTime;
  bool _isLoading = true;
  bool _hasPermission = true;

  // Nam jap rates per minute
  static const int minRate = 100; // Slow pace
  static const int maxRate = 166; // Fast pace

  @override
  void initState() {
    super.initState();
    _loadScreenTime();
  }

  Future<void> _loadScreenTime() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));
      
      // Get usage stats - will throw if no permission
      final todayUsage = await AppUsage().getAppUsage(todayStart, now);
      final weekUsage = await AppUsage().getAppUsage(weekStart, now);
      
      // Sum up total usage
      Duration todayTotal = Duration.zero;
      for (var app in todayUsage) {
        todayTotal += app.usage;
      }
      
      Duration weekTotal = Duration.zero;
      for (var app in weekUsage) {
        weekTotal += app.usage;
      }
      
      setState(() {
        _todayScreenTime = todayTotal;
        _weekScreenTime = weekTotal;
        _hasPermission = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  int _calculateMinNamJap(Duration duration) {
    return duration.inMinutes * minRate;
  }

  int _calculateMaxNamJap(Duration duration) {
    return duration.inMinutes * maxRate;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatNumber(int number) {
    if (number >= 100000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Reflection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasPermission)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadScreenTime,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : !_hasPermission
              ? _buildPermissionRequest()
              : _buildReflectionContent(),
    );
  }

  Widget _buildPermissionRequest() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.access_time_filled,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Screen Time Access Needed',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'To show your potential Nam Jap based on phone usage, please enable Usage Access permission.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to enable:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Go to Settings → Apps → Special Access\n2. Tap "Usage Access"\n3. Find "Smart Naam Jap" and enable it',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadScreenTime,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionContent() {
    return RefreshIndicator(
      onRefresh: _loadScreenTime,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.self_improvement,
                  size: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Time is Sacred',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every moment spent on the phone could have been devoted to Nam Jap',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Today's stats
          if (_todayScreenTime != null)
            _buildStatCard(
              title: "Today's Phone Usage",
              duration: _todayScreenTime!,
              icon: Icons.today,
            ),
          
          const SizedBox(height: 16),
          
          // This week's stats
          if (_weekScreenTime != null)
            _buildStatCard(
              title: 'Last 7 Days',
              duration: _weekScreenTime!,
              icon: Icons.date_range,
            ),
          
          const SizedBox(height: 24),
          
          // Motivational quote
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.format_quote,
                  size: 28,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  '"The time you spend on your phone is time you could spend connecting with the divine."',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Rate info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Calculations based on 100-166 Nam Jap per minute',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required Duration duration,
    required IconData icon,
  }) {
    final minNamJap = _calculateMinNamJap(duration);
    final maxNamJap = _calculateMaxNamJap(duration);
    final minMalas = minNamJap ~/ 108;
    final maxMalas = maxNamJap ~/ 108;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Screen time
          Row(
            children: [
              const Icon(Icons.phone_android, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                'Screen Time: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            color: AppColors.surface,
          ),
          
          const SizedBox(height: 16),
          
          // Potential Nam Jap
          Text(
            'You could have chanted:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          
          // Range display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountBox(_formatNumber(minNamJap), 'Min'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '—',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ),
              _buildCountBox(_formatNumber(maxNamJap), 'Max'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Equivalent malas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.all_inclusive,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$minMalas - $maxMalas Malas',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  Widget _buildCountBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}
