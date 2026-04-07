import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_provider.dart';

class GamificationState {
  GamificationState({
    this.xp = 0,
    this.level = 1,
    this.streakDays = 0,
    this.unlockedBadges = const [],
  });

  final int xp;
  final int level;
  final int streakDays;
  final List<String> unlockedBadges;

  GamificationState copyWith({
    int? xp,
    int? level,
    int? streakDays,
    List<String>? unlockedBadges,
  }) =>
      GamificationState(
        xp: xp ?? this.xp,
        level: level ?? this.level,
        streakDays: streakDays ?? this.streakDays,
        unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      );
}

class GamificationController extends StateNotifier<GamificationState> {
  GamificationController(this._ref) : super(GamificationState());

  final Ref _ref;

  static const _xpPerLevel = 100;

  void earnXp(int amount, {required String source}) {
    final analytics = _ref.read(analyticsServiceProvider);
    analytics.trackXpEarned(amount: amount, source: source);

    final newXp = state.xp + amount;
    final newLevel = (newXp ~/ _xpPerLevel) + 1;
    state = state.copyWith(xp: newXp, level: newLevel);

    if (newLevel > state.level) {
      analytics.trackLevelUp(newLevel: newLevel);
    }
  }

  void incrementStreak() {
    final next = state.streakDays + 1;
    state = state.copyWith(streakDays: next);
    _ref.read(analyticsServiceProvider).trackStreakIncrement(streakDays: next);

    // Reward streak milestones with a badge.
    if (next == 7) unlockBadge('streak_week');
    if (next == 30) unlockBadge('streak_month');
  }

  void unlockBadge(String badgeId) {
    if (state.unlockedBadges.contains(badgeId)) return;
    state = state.copyWith(
      unlockedBadges: [...state.unlockedBadges, badgeId],
    );
    _ref.read(analyticsServiceProvider).trackBadgeUnlocked(badgeId: badgeId);
  }
}

final gamificationControllerProvider =
    StateNotifierProvider<GamificationController, GamificationState>((ref) {
  return GamificationController(ref);
});
