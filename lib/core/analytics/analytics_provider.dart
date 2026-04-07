import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';

/// Riverpod provider that exposes the singleton AnalyticsService.
///
/// This provider is overridden in `main.dart` after `AnalyticsService.init`
/// resolves, so feature code can read it synchronously through `ref.read`.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  throw UnimplementedError(
    'analyticsServiceProvider must be overridden in main() with the '
    'initialized AnalyticsService.',
  );
});
