import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: !authState.isAuthenticated
          ? _buildAuthGate()
              : state.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
              : state.error != null
                  ? _buildError()
                  : _buildContent(state),
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
                onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                icon: const Icon(Icons.login),
                label: Text(
                  'Sign in with Google',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
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

  Widget _buildContent(LeaderboardState state) {
    final topUsers = state.topUsers;
    final currentUser = state.currentUser;

    return Column(
      children: [
        _CategoryBar(
          selected: state.category,
          onSelect: (cat) => ref.read(leaderboardProvider.notifier).setCategory(cat),
        ),
        Expanded(
          child: topUsers.isEmpty
              ? Center(
                  child: Text(
                    'No users yet. Start chanting!',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    if (topUsers.length >= 3) _Podium(topUsers: topUsers.take(3).toList()),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: _SectionHeader(),
                    ),
                    ...topUsers.skip(3).map((user) => _RankRow(user: user)),
                    if (topUsers.length <= 3)
                      ...topUsers.map((user) => _RankRow(user: user)),
                  ],
                ),
        ),
        if (currentUser != null) _CurrentUserBanner(user: currentUser),
      ],
    );
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
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onSelect(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Text(
                    cat.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
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

  const _Podium({required this.topUsers});

  @override
  Widget build(BuildContext context) {
    final entries = <_PodiumEntry>[
      _PodiumEntry(rank: 1, user: topUsers[0], height: 150, color: AppColors.primary),
      if (topUsers.length > 1)
        _PodiumEntry(rank: 2, user: topUsers[1], height: 110,
            color: AppColors.textSecondary.withValues(alpha: 0.6)),
      if (topUsers.length > 2)
        _PodiumEntry(rank: 3, user: topUsers[2], height: 80,
            color: AppColors.textMuted.withValues(alpha: 0.5)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (entries.length > 1) _PodiumCard(entry: entries[1]),
          const SizedBox(width: 12),
          _PodiumCard(entry: entries[0]),
          const SizedBox(width: 12),
          if (entries.length > 2) _PodiumCard(entry: entries[2]),
        ],
      ),
    );
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

  const _PodiumCard({required this.entry});

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
          badge: isFirst,
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
        Text(
          _formatCount(entry.user.totalCounts),
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: entry.color,
            fontWeight: FontWeight.w500,
          ),
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
                entry.color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: entry.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final double size;
  final bool badge;

  const _AvatarWidget({
    required this.avatarUrl,
    required this.initial,
    required this.size,
    this.badge = false,
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
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            boxShadow: badge
                ? [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  )]
                : null,
          ),
          child: avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultAvatar(),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : _defaultAvatar(),
                  ),
                )
              : _defaultAvatar(),
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
                color: AppColors.primary,
              ),
              child: Icon(Icons.emoji_events, size: 12, color: AppColors.background),
            ),
          ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return CircleAvatar(
      backgroundColor: AppColors.cardBackground,
      child: Text(
        initial,
        style: GoogleFonts.outfit(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

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
          'Count',
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

  const _RankRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${user.rank}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: user.rank <= 3 ? AppColors.primary : AppColors.textMuted,
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
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _formatCount(user.totalCounts),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentUserBanner extends StatelessWidget {
  final LeaderboardEntry user;

  const _CurrentUserBanner({required this.user});

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
            Text(
              _formatCount(user.totalCounts),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCount(int count) {
  if (count >= 100000) {
    return '${(count / 100000).toStringAsFixed(1)}L';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}
