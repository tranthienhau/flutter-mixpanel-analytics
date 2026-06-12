import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_mixpanel_analytics/core/analytics/analytics_provider.dart';
import 'package:flutter_mixpanel_analytics/core/analytics/analytics_service.dart';
import 'package:flutter_mixpanel_analytics/features/home_shell.dart';
import 'package:flutter_mixpanel_analytics/features/shopping/gamification_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  testWidgets('capture gamified shopping + analytics flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // No-op analytics so screens render without the native Mixpanel SDK.
          analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
          // Seed a realistic gamification profile so the dashboard looks alive.
          gamificationControllerProvider.overrideWith(
            (ref) => GamificationController(
              ref,
              initial: GamificationState(
                xp: 1840,
                level: 19,
                streakDays: 12,
                unlockedBadges: const ['streak_week', 'first_buy'],
              ),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Gamified Shop',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 01 - Shopping funnel (product catalog).
    await shoot(tester, '01-shop');

    // Add an item to the cart to show the funnel state change.
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    await shoot(tester, '02-add-to-cart');

    // Switch to the gamification dashboard tab.
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    await shoot(tester, '03-progress-dashboard');

    // Scroll the dashboard to reveal badges + daily quests.
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await shoot(tester, '04-badges-quests');
  });
}
