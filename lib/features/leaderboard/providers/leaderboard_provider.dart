import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/cloud_data_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../insights/providers/insights_provider.dart';
import '../../counter/providers/counter_provider.dart';
import '../domain/leaderboard_entry.dart';

enum LeaderboardCategory {
  totalCounts,
  todayCounts,
  currentStreak,
}

extension LeaderboardCategoryX on LeaderboardCategory {
  String get label {
    switch (this) {
      case LeaderboardCategory.totalCounts:
        return 'All Time';
      case LeaderboardCategory.todayCounts:
        return 'Today';
      case LeaderboardCategory.currentStreak:
        return 'Streak';
    }
  }
}

class LeaderboardState {
  final List<LeaderboardEntry> topUsers;
  final LeaderboardEntry? currentUser;
  final bool isLoading;
  final String? error;
  final LeaderboardCategory category;

  const LeaderboardState({
    required this.topUsers,
    this.currentUser,
    required this.isLoading,
    this.error,
    required this.category,
  });

  factory LeaderboardState.initial() => const LeaderboardState(
        topUsers: [],
        isLoading: true,
        category: LeaderboardCategory.totalCounts,
      );

  LeaderboardState copyWith({
    List<LeaderboardEntry>? topUsers,
    LeaderboardEntry? currentUser,
    bool? isLoading,
    String? error,
    LeaderboardCategory? category,
    bool clearError = false,
  }) {
    return LeaderboardState(
      topUsers: topUsers ?? this.topUsers,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      category: category ?? this.category,
    );
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;

  LeaderboardNotifier(this._ref) : super(LeaderboardState.initial());

  Future<void> load({LeaderboardCategory? category}) async {
    final cat = category ?? state.category;
    state = state.copyWith(isLoading: true, category: cat, clearError: true);

    try {
      final authState = _ref.read(authProvider);
      if (!authState.isAuthenticated || authState.user == null) {
        state = state.copyWith(
          topUsers: [],
          currentUser: null,
          isLoading: false,
        );
        return;
      }

      final user = authState.user!;
      final cloudRepo = CloudDataRepository.forUser(user.id);

      final users = await cloudRepo.getTopUsers(
        limit: 50,
        sortBy: _sortBy(cat),
      );

      final currentUserCount = _getUserCount(cat);
      final rank = await cloudRepo.getUserRank(
        totalCounts: currentUserCount,
        sortBy: _sortBy(cat),
      );

      final currentUserEntry = LeaderboardEntry(
        userId: user.id,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        totalCounts: _getTotalCounts(),
        totalMalas: 0,
        currentStreak: _getStreak(),
        todayCounts: _getTodayCounts(),
        rank: rank,
      );

      state = state.copyWith(
        topUsers: users,
        currentUser: currentUserEntry,
        isLoading: false,
      );
    } catch (e, st) {
      AppLogger.error('LeaderboardNotifier', 'Failed to load', e, st);
      state = state.copyWith(isLoading: false, error: 'Failed to load leaderboard');
    }
  }

  LeaderboardSort _sortBy(LeaderboardCategory cat) {
    switch (cat) {
      case LeaderboardCategory.totalCounts:
        return LeaderboardSort.totalCounts;
      case LeaderboardCategory.todayCounts:
        return LeaderboardSort.todayCounts;
      case LeaderboardCategory.currentStreak:
        return LeaderboardSort.currentStreak;
    }
  }

  int _getUserCount(LeaderboardCategory cat) {
    switch (cat) {
      case LeaderboardCategory.totalCounts:
        return _getTotalCounts();
      case LeaderboardCategory.todayCounts:
        return _getTodayCounts();
      case LeaderboardCategory.currentStreak:
        return _getStreak();
    }
  }

  int _getTotalCounts() {
    final counter = _ref.read(counterProvider);
    return counter.count;
  }

  int _getTodayCounts() {
    final insights = _ref.read(insightsProvider);
    final today = insights.dailyStats[_todayKey()];
    if (today != null && today.counts > 0) return today.counts;
    final counter = _ref.read(counterProvider);
    return counter.count;
  }

  int _getStreak() {
    final insights = _ref.read(insightsProvider);
    return insights.currentStreak;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void setCategory(LeaderboardCategory category) {
    if (category != state.category) {
      load(category: category);
    }
  }
}
