import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/daily_stats.dart';

/// Calendar heat map showing daily practice intensity
class CalendarHeatMap extends StatefulWidget {
  final Map<String, DailyStats> dailyStats;
  final int goalMalas;

  const CalendarHeatMap({
    super.key,
    required this.dailyStats,
    this.goalMalas = 3,
  });

  @override
  State<CalendarHeatMap> createState() => _CalendarHeatMapState();
}

class _CalendarHeatMapState extends State<CalendarHeatMap> {
  late DateTime _currentMonth;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() {
        _currentMonth = nextMonth;
        _selectedDay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header: Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _previousMonth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_left, color: AppColors.textMuted, size: 18),
                ),
              ),
              Text(
                _monthYearString(_currentMonth),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: isCurrentMonth ? null : _nextMonth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: isCurrentMonth ? AppColors.surface : AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Day labels
          Row(
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 6),

          // Calendar grid
          ..._buildWeekRows(),

          // Selected day tooltip
          if (_selectedDay != null) ...[
            const SizedBox(height: 10),
            _buildTooltip(),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  List<Widget> _buildWeekRows() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1=Mon
    final now = DateTime.now();

    final List<Widget> rows = [];
    int dayNum = 1;

    // Up to 6 weeks per month
    for (int week = 0; week < 6 && dayNum <= daysInMonth; week++) {
      final List<Widget> cells = [];

      for (int col = 0; col < 7; col++) {
        if ((week == 0 && col < firstWeekday - 1) || dayNum > daysInMonth) {
          cells.add(Expanded(child: SizedBox(height: 32)));
        } else {
          final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
          final dateKey = _dateKey(date);
          final stats = widget.dailyStats[dateKey];
          final isFuture = date.isAfter(now);
          final isSelected = _selectedDay == dateKey;
          final currentDayNum = dayNum;

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        setState(() {
                          _selectedDay = _selectedDay == dateKey ? null : dateKey;
                        });
                      },
                child: Container(
                  height: 32,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: isFuture
                        ? Colors.transparent
                        : _getCellColor(stats),
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$currentDayNum',
                      style: TextStyle(
                        color: isFuture
                            ? AppColors.textMuted.withValues(alpha: 0.3)
                            : _getTextColor(stats),
                        fontSize: 11,
                        fontWeight: (stats?.malas ?? 0) >= 3
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          dayNum++;
        }
      }

      rows.add(Row(children: cells));
    }

    return rows;
  }

  Color _getCellColor(DailyStats? stats) {
    if (stats == null || stats.counts == 0) {
      return AppColors.surface;
    }
    final malas = stats.malas;
    if (malas >= 3) {
      return AppColors.primary.withValues(alpha: 0.85);
    } else if (malas >= 1) {
      return AppColors.primary.withValues(alpha: 0.45);
    } else {
      return AppColors.primary.withValues(alpha: 0.2);
    }
  }

  Color _getTextColor(DailyStats? stats) {
    if (stats == null || stats.counts == 0) {
      return AppColors.textMuted;
    }
    final malas = stats.malas;
    if (malas >= 3) {
      return Colors.white;
    }
    return AppColors.textPrimary;
  }

  Widget _buildTooltip() {
    final stats = widget.dailyStats[_selectedDay];
    final day = _selectedDay!.split('-');
    final date = DateTime(int.parse(day[0]), int.parse(day[1]), int.parse(day[2]));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${months[date.month - 1]} ${date.day}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            stats != null && stats.counts > 0
                ? '${stats.malas} Malas  •  ${stats.counts} Chants'
                : 'No practice',
            style: TextStyle(
              color: stats != null && stats.counts > 0
                  ? AppColors.primary
                  : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  String _monthYearString(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
