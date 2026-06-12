import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analytics/analytics_provider.dart';
import 'core/analytics/analytics_service.dart';
import 'features/home_shell.dart';

const _mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN', defaultValue: '');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final analytics = await MixpanelAnalyticsService.init(
    token: _mixpanelToken,
    optOutByDefault: true,
    appVersion: '0.1.0',
  );

  // Demo: grant consent immediately so events flow. In production this would
  // be wired to an explicit consent screen.
  await analytics.grantConsent();
  await analytics.identify(
    userId: 'demo-user-001',
    acquisitionChannel: 'organic',
    plan: 'free',
    country: 'US',
  );

  runApp(
    ProviderScope(
      overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
      child: const GamifiedShopApp(),
    ),
  );
}

class GamifiedShopApp extends StatelessWidget {
  const GamifiedShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamified Shop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
