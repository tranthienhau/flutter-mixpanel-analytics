import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shopping/gamification_controller.dart';

/// Player-facing gamification dashboard.
///
/// Renders the current XP/level progress, daily streak, and unlocked badges.
/// Every interaction here funnels into typed Mixpanel events (xp_earned,
/// level_up, streak_increment, badge_unlocked) through the controller.
class GamificationDashboardScreen extends ConsumerWidget {
  const GamificationDashboardScreen({super.key});

  static const _badgeMeta = {
    'streak_week': ('Week Warrior', Icons.local_fire_department, Colors.orange),
    'streak_month': ('Month Master', Icons.emoji_events, Colors.amber),
    'first_buy': ('First Purchase', Icons.shopping_bag, Colors.green),
    'big_spender': ('Big Spender', Icons.diamond, Colors.blue),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gamificationControllerProvider);
    final xpInLevel = state.xp % 100;
    final progress = xpInLevel / 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LevelCard(level: state.level, xp: state.xp, progress: progress),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                  label: 'Day Streak',
                  value: '${state.streakDays}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.bolt,
                  color: Colors.deepPurple,
                  label: 'Total XP',
                  value: '${state.xp}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Badges', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _badgeMeta.entries.map((e) {
              final unlocked = state.unlockedBadges.contains(e.key);
              final (name, icon, color) = e.value;
              return _BadgeChip(
                name: name,
                icon: icon,
                color: color,
                unlocked: unlocked,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Daily Quests', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const _QuestTile(
            title: 'Browse 5 products',
            reward: '+20 XP',
            done: true,
          ),
          const _QuestTile(
            title: 'Add an item to your cart',
            reward: '+15 XP',
            done: true,
          ),
          const _QuestTile(
            title: 'Complete a checkout',
            reward: '+50 XP',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.xp,
    required this.progress,
  });

  final int level;
  final int xp;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level $level',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('$xp XP earned',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.deepPurple.shade100,
              ),
            ),
            const SizedBox(height: 6),
            Text('${(progress * 100).round()}% to level ${level + 1}'),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.name,
    required this.icon,
    required this.color,
    required this.unlocked,
  });

  final String name;
  final IconData icon;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: unlocked ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked ? color : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: unlocked ? color : Colors.grey, size: 30),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: unlocked ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.title,
    required this.reward,
    required this.done,
  });

  final String title;
  final String reward;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? Colors.green : Colors.grey,
      ),
      title: Text(title),
      trailing: Text(
        reward,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
