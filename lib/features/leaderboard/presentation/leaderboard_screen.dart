import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../domain/leaderboard_entry.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(leaderboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: authState.status == AuthStatus.unknown || authState.isLoading
          ? _buildShimmer()
          : !authState.isAuthenticated
              ? _buildAuthGate()
              : state.isLoading && state.topUsers.isEmpty
                  ? _buildShimmer()
                  : state.error != null && state.topUsers.isEmpty
                      ? _buildError()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.cardBackground,
                          onRefresh: () =>
                              ref.read(leaderboardProvider.notifier).load(),
                          child: _buildContent(state),
                        ),
    );
  }

  Widget _buildAuthGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_rounded,
                size: 72, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              'Join the Leaderboard',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in with Google to see how you rank\nagainst the community.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(authProvider.notifier).signInWithGoogle(),
                icon: const Icon(Icons.login),
                label: Text(
                  'Sign in with Google',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Could not load leaderboard',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(leaderboardProvider.notifier).load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),
        _CategoryBar(
          selected: LeaderboardCategory.totalCounts,
          onSelect: (_) {},
        ),
        const SizedBox(height: 24),
        for (int i = 0; i < 5; i++) _ShimmerRow(index: i),
      ],
    );
  }

  Widget _buildContent(LeaderboardState state) {
    final topUsers = state.topUsers;
    final currentUser = state.currentUser;
    final category = state.category;

    return Column(
      children: [
        _CategoryBar(
          selected: category,
          onSelect: (cat) =>
              ref.read(leaderboardProvider.notifier).setCategory(cat),
        ),
        Expanded(
          child: topUsers.isEmpty
              ? _EmptyState(category: category, currentUser: currentUser)
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    if (topUsers.length >= 3)
                      _Podium(
                          topUsers: topUsers.take(3).toList(),
                          category: category),
                    if (topUsers.length > 3) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: _SectionHeader(category: category),
                      ),
                      ...topUsers.skip(3).map((user) => _RankRow(
                            user: user,
                            category: category,
                            isCurrentUser: currentUser?.userId == user.userId,
                          )),
                    ],
                    if (topUsers.length < 3) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: _SectionHeader(category: category),
                      ),
                      ...topUsers.map((user) => _RankRow(
                            user: user,
                            category: category,
                            isCurrentUser: currentUser?.userId == user.userId,
                          )),
                    ],
                  ],
                ),
        ),
        if (currentUser != null &&
            topUsers.every((u) => u.userId != currentUser.userId))
          _CurrentUserBanner(user: currentUser, category: category),
      ],
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final int index;
  const _ShimmerRow({required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2A2A3A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ).animate().shimmer(
          duration: const Duration(milliseconds: 1500),
          delay: (index * 100).ms,
          color: AppColors.primary.withValues(alpha: 0.05),
        );
  }
}

class _EmptyState extends StatelessWidget {
  final LeaderboardCategory category;
  final LeaderboardEntry? currentUser;

  const _EmptyState({required this.category, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final remaining = _remainingCountsToQualify(category, currentUser);
    final title = switch (category) {
      LeaderboardCategory.totalCounts => 'Enter the all-time board',
      LeaderboardCategory.todayCounts => 'Enter today\'s leaderboard',
      LeaderboardCategory.currentStreak => 'Start your streak',
    };
    final message = switch (category) {
      LeaderboardCategory.totalCounts => remaining > 0
          ? 'Complete 3 malas to enter. $remaining counts left.'
          : 'You qualify. Pull down to refresh the leaderboard.',
      LeaderboardCategory.todayCounts => remaining > 0
          ? 'Complete 3 malas today to enter. $remaining counts left.'
          : 'You qualify for today. Pull down to refresh.',
      LeaderboardCategory.currentStreak =>
        currentUser != null && currentUser!.currentStreak > 0
            ? 'Your streak qualifies. Pull down to refresh.'
            : 'Complete 3 malas in a day to begin your streak.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22),
                    AppColors.primary.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: Icon(_categoryIcon(category),
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0);
  }
}

class _CategoryBar extends StatelessWidget {
  final LeaderboardCategory selected;
  final ValueChanged<LeaderboardCategory> onSelect;

  const _CategoryBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: LeaderboardCategory.values.map((cat) {
          final isSelected = cat == selected;
          final icon = switch (cat) {
            LeaderboardCategory.totalCounts => Icons.history_rounded,
            LeaderboardCategory.todayCounts => Icons.today_rounded,
            LeaderboardCategory.currentStreak =>
              Icons.local_fire_department_rounded,
          };
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onSelect(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cat.label,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> topUsers;
  final LeaderboardCategory category;

  const _Podium({required this.topUsers, required this.category});

  @override
  Widget build(BuildContext context) {
    final entries = <_PodiumEntry>[
      _PodiumEntry(
          rank: 1, user: topUsers[0], height: 150, color: AppColors.primary),
      if (topUsers.length > 1)
        _PodiumEntry(
            rank: 2,
            user: topUsers[1],
            height: 110,
            color: const Color(0xFFC0C4CC)),
      if (topUsers.length > 2)
        _PodiumEntry(
            rank: 3,
            user: topUsers[2],
            height: 80,
            color: const Color(0xFFCD7F55)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (entries.length > 1)
            _PodiumCard(entry: entries[1], category: category),
          const SizedBox(width: 12),
          _PodiumCard(entry: entries[0], category: category),
          const SizedBox(width: 12),
          if (entries.length > 2)
            _PodiumCard(entry: entries[2], category: category),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0);
  }
}

class _PodiumEntry {
  final int rank;
  final LeaderboardEntry user;
  final double height;
  final Color color;
  const _PodiumEntry({
    required this.rank,
    required this.user,
    required this.height,
    required this.color,
  });
}

class _PodiumCard extends StatelessWidget {
  final _PodiumEntry entry;
  final LeaderboardCategory category;

  const _PodiumCard({required this.entry, required this.category});

  @override
  Widget build(BuildContext context) {
    final isFirst = entry.rank == 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AvatarWidget(
          avatarUrl: entry.user.avatarUrl,
          initial: entry.user.initial,
          size: isFirst ? 52 : 40,
          badge: true,
          badgeColor: entry.color,
          badgeIcon: entry.rank == 1 ? Icons.emoji_events : Icons.military_tech,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: Text(
            entry.user.displayName.split(' ').first,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: isFirst ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category == LeaderboardCategory.currentStreak)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Icon(Icons.local_fire_department_rounded,
                    size: 12, color: Colors.orangeAccent),
              ),
            Text(
              _formatMetric(entry.user, category),
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: entry.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: entry.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                entry.color.withValues(alpha: 0.3),
                entry.color.withValues(alpha: 0.16),
                entry.color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: entry.color.withValues(alpha: 0.18)),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: entry.color.withValues(alpha: 0.28)),
              ),
              child: Text(
                '#${entry.rank}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: entry.color,
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms, delay: (entry.rank * 70).ms).scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final double size;
  final bool badge;
  final Color? badgeColor;
  final IconData? badgeIcon;

  const _AvatarWidget({
    required this.avatarUrl,
    required this.initial,
    required this.size,
    this.badge = false,
    this.badgeColor,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: badge
                ? Border.all(color: badgeColor ?? AppColors.primary, width: 2)
                : null,
            boxShadow: badge
                ? [
                    BoxShadow(
                      color: (badgeColor ?? AppColors.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, __, ___) => _defaultAvatar(size),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _defaultAvatar(size);
                    },
                  )
                : _defaultAvatar(size),
          ),
        ),
        if (badge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor ?? AppColors.primary,
              ),
              child: Icon(
                badgeIcon ?? Icons.emoji_events,
                size: 12,
                color: AppColors.background,
              ),
            ),
          ),
      ],
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2A2A3A),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final LeaderboardCategory category;

  const _SectionHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            '#',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Name',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Text(
          _metricLabel(category),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry user;
  final LeaderboardCategory category;
  final bool isCurrentUser;

  const _RankRow({
    required this.user,
    required this.category,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isCurrentUser
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.26))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#${user.rank}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: user.rank <= 3
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AvatarWidget(
                avatarUrl: user.avatarUrl,
                initial: user.initial,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCurrentUser ? 'You' : user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight:
                        isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category == LeaderboardCategory.currentStreak &&
                      user.currentStreak > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.local_fire_department_rounded,
                          size: 14, color: Colors.orangeAccent),
                    ),
                  Text(
                    _formatMetric(user, category),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCurrentUser
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (isCurrentUser)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'YOU',
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (user.rank * 30).ms);
  }
}

class _CurrentUserBanner extends StatelessWidget {
  final LeaderboardEntry user;
  final LeaderboardCategory category;

  const _CurrentUserBanner({required this.user, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${user.rank}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _AvatarWidget(
              avatarUrl: user.avatarUrl,
              initial: user.initial,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category == LeaderboardCategory.currentStreak &&
                    user.currentStreak > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.local_fire_department_rounded,
                        size: 14, color: Colors.orangeAccent),
                  ),
                Text(
                  _formatMetric(user, category),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMetric(LeaderboardEntry user, LeaderboardCategory category) {
  final count = switch (category) {
    LeaderboardCategory.totalCounts => user.totalCounts,
    LeaderboardCategory.todayCounts => user.todayCounts,
    LeaderboardCategory.currentStreak => user.currentStreak,
  };

  if (category == LeaderboardCategory.currentStreak) {
    return '${count}d';
  }

  if (count >= 100000) {
    return '${(count / 100000).toStringAsFixed(1)}L';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}

String _metricLabel(LeaderboardCategory category) {
  return switch (category) {
    LeaderboardCategory.totalCounts => 'Counts',
    LeaderboardCategory.todayCounts => 'Today',
    LeaderboardCategory.currentStreak => 'Days',
  };
}

IconData _categoryIcon(LeaderboardCategory category) {
  return switch (category) {
    LeaderboardCategory.totalCounts => Icons.emoji_events_rounded,
    LeaderboardCategory.todayCounts => Icons.today_rounded,
    LeaderboardCategory.currentStreak => Icons.local_fire_department_rounded,
  };
}

int _remainingCountsToQualify(
  LeaderboardCategory category,
  LeaderboardEntry? currentUser,
) {
  if (currentUser == null || category == LeaderboardCategory.currentStreak) {
    return 0;
  }

  final count = switch (category) {
    LeaderboardCategory.totalCounts => currentUser.totalCounts,
    LeaderboardCategory.todayCounts => currentUser.todayCounts,
    LeaderboardCategory.currentStreak => currentUser.currentStreak,
  };
  final minCounts = kMalaSize * kMinStreakMalas;
  return (minCounts - count).clamp(0, minCounts).toInt();
}
