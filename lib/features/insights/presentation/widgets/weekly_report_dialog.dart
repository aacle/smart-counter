import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../services/report_service.dart';

/// Weekly progress report dialog
class WeeklyReportDialog extends StatelessWidget {
  final WeeklyReportData reportData;
  final VoidCallback onDismiss;

  const WeeklyReportDialog({
    super.key,
    required this.reportData,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reportData.isWeekly ? 'Your Week in Review' : 'Your Month in Review',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _getDateRange(),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getBadgeColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getBadgeColor().withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      reportData.badge,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Bar chart - different layouts for weekly vs monthly
                  if (reportData.isWeekly)
                    // Weekly: Show 7 individual day bars with labels
                    SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          final day = reportData.dailyProgress[index];
                          return _buildDayBar(
                            context,
                            weekDays[(day.date.weekday - 1) % 7],
                            day.progress,
                            day.goalMet,
                            isBest: index == reportData.bestDayIndex,
                            isWorst: index == reportData.worstDayIndex && !day.goalMet,
                          );
                        }),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms)
                  else
                    // Monthly: Show all 30 days as compact bars grouped by week
                    _buildMonthlyChart(context).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  
                  const SizedBox(height: 20),
                  
                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStat(
                            context,
                            '${reportData.daysGoalMet}/${reportData.totalDays}',
                            'Goals Met',
                            reportData.achievementRate >= 0.7 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.cardBackground,
                        ),
                        Expanded(
                          child: _buildStat(
                            context,
                            '${(reportData.achievementRate * 100).toInt()}%',
                            'Success Rate',
                            AppColors.secondary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.cardBackground,
                        ),
                        Expanded(
                          child: _buildStat(
                            context,
                            _formatValue(reportData.totalValue),
                            reportData.isCountGoal ? 'Total' : 'Malas',
                            AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Best/Worst day highlights
                  if (reportData.bestDayIndex >= 0)
                    _buildDayHighlight(
                      context,
                      icon: Icons.star,
                      color: AppColors.secondary,
                      label: 'Best Day',
                      day: reportData.dailyProgress[reportData.bestDayIndex],
                    ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                  
                  if (reportData.worstDayIndex >= 0 && reportData.worstDayIndex != reportData.bestDayIndex)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildDayHighlight(
                        context,
                        icon: Icons.trending_down,
                        color: AppColors.textMuted,
                        label: 'Room to Grow',
                        day: reportData.dailyProgress[reportData.worstDayIndex],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Motivational message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getBadgeColor().withValues(alpha: 0.1),
                          _getBadgeColor().withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reportData.motivationalMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getBadgeColor(),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                  
                  const SizedBox(height: 20),
                  
                  // Dismiss button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue Practice'),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBar(BuildContext context, String day, double progress, bool goalMet, {
    bool isBest = false,
    bool isWorst = false,
  }) {
    final height = 60 * progress.clamp(0.0, 1.0);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isBest)
          const Icon(Icons.star, color: AppColors.secondary, size: 12),
        Container(
          width: 28,
          height: height < 4 ? 4 : height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: goalMet 
                  ? [AppColors.success.withValues(alpha: 0.8), AppColors.success]
                  : isWorst
                      ? [AppColors.textMuted.withValues(alpha: 0.3), AppColors.textMuted.withValues(alpha: 0.5)]
                      : [AppColors.primary.withValues(alpha: 0.6), AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: goalMet ? const Center(
            child: Icon(Icons.check, color: Colors.white, size: 12),
          ) : null,
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: isBest ? AppColors.secondary : AppColors.textMuted,
            fontSize: 10,
            fontWeight: isBest ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Build calendar-style monthly chart with weeks as rows
  Widget _buildMonthlyChart(BuildContext context) {
    final totalDays = reportData.dailyProgress.length;
    
    // Group days into weeks (7 days each)
    final weeks = <List<DayProgress>>[];
    for (int i = 0; i < totalDays; i += 7) {
      final end = (i + 7 > totalDays) ? totalDays : i + 7;
      weeks.add(reportData.dailyProgress.sublist(i, end));
    }
    
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          // Week labels on left
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < weeks.length; i++)
                SizedBox(
                  height: 18,
                  child: Text(
                    'W${i + 1}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Grid of days
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      for (int dayIdx = 0; dayIdx < 7; dayIdx++)
                        dayIdx < weeks[weekIndex].length
                            ? _buildGridDayBar(
                                weeks[weekIndex][dayIdx].progress,
                                weeks[weekIndex][dayIdx].goalMet,
                                isBest: (weekIndex * 7 + dayIdx) == reportData.bestDayIndex,
                              )
                            : const SizedBox(width: 38), // Empty placeholder for incomplete week
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grid day bar for calendar-style monthly chart - pill shaped
  Widget _buildGridDayBar(double progress, bool goalMet, {bool isBest = false}) {
    // Determine bar color based on status
    Color barColor;
    if (goalMet) {
      barColor = AppColors.success;
    } else if (progress > 0) {
      barColor = AppColors.primary; // Yellow for partial
    } else {
      barColor = AppColors.textMuted.withValues(alpha: 0.3); // Gray for inactive
    }
    
    return Container(
      width: 34,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(6), // Fully rounded pill
        border: isBest 
            ? Border.all(color: AppColors.secondary, width: 2) 
            : null,
        boxShadow: goalMet ? [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ] : null,
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildDayHighlight(BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required DayProgress day,
  }) {
    final dayName = _getDayName(day.date.weekday);
    final valueText = reportData.isCountGoal 
        ? '${day.value} chants'
        : '${day.value} malas';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: $dayName',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            valueText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: reportData.totalDays));
    return '${_formatDate(start)} - ${_formatDate(now)}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _formatValue(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  Color _getBadgeColor() {
    if (reportData.achievementRate >= 0.85) return AppColors.secondary;
    if (reportData.achievementRate >= 0.7) return AppColors.success;
    if (reportData.achievementRate >= 0.5) return AppColors.primary;
    return AppColors.textSecondary;
  }
}
