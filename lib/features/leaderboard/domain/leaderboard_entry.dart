class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalCounts;
  final int totalMalas;
  final int currentStreak;
  final int todayCounts;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalCounts,
    required this.totalMalas,
    required this.currentStreak,
    required this.todayCounts,
    required this.rank,
  });

  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}
