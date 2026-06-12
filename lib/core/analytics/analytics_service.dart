import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_registry.dart';

/// Typed analytics surface for the app.
///
/// Feature code depends only on this abstraction, never on Mixpanel directly.
/// The production binding is [MixpanelAnalyticsService]; tests and previews use
/// [NoopAnalyticsService] so screens can render without native SDK init.
///
/// Goals:
///  - All event tracking goes through typed methods, never raw strings
///  - Consent state is persisted and respected on every call
///  - Identity calls (identify, alias, reset) are funneled here so the rest
///    of the app does not have to know about Mixpanel internals
///  - Super properties (platform, app_version) are set once at startup
abstract class AnalyticsService {
  Future<void> grantConsent();
  Future<void> revokeConsent();
  Future<bool> hasConsent();

  Future<void> identify({
    required String userId,
    String? acquisitionChannel,
    String? plan,
    String? country,
  });

  Future<void> reset();

  void trackProductViewed({
    required String productId,
    required String productName,
    required String category,
    required double price,
    String currency,
    String source,
  });

  void trackAddToCart({
    required String productId,
    required int quantity,
    required double price,
    String currency,
  });

  void trackCheckoutStarted({
    required double cartValue,
    required int itemCount,
    String currency,
  });

  void trackPurchaseCompleted({
    required String orderId,
    required double cartValue,
    required int itemCount,
    required String paymentMethod,
    String currency,
  });

  void trackXpEarned({required int amount, required String source});
  void trackLevelUp({required int newLevel});
  void trackStreakIncrement({required int streakDays});
  void trackBadgeUnlocked({required String badgeId});
  void trackDailyQuestCompleted({required String questId, required int xpReward});

  Future<void> flush();
}

/// Production [AnalyticsService] backed by the Mixpanel Flutter SDK.
class MixpanelAnalyticsService implements AnalyticsService {
  MixpanelAnalyticsService._(this._mixpanel);

  final Mixpanel _mixpanel;

  static const _consentKey = 'mp_consent_granted';

  static Future<MixpanelAnalyticsService> init({
    required String token,
    bool optOutByDefault = true,
    String? appVersion,
  }) async {
    final mixpanel = await Mixpanel.init(
      token,
      trackAutomaticEvents: false,
      optOutTrackingDefault: optOutByDefault,
    );

    // Super properties are attached to every event automatically.
    await mixpanel.registerSuperProperties({
      PropertyKeys.platform: _platform(),
      if (appVersion != null) PropertyKeys.appVersion: appVersion,
    });

    return MixpanelAnalyticsService._(mixpanel);
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  // ---------------------------------------------------------------------------
  // Consent
  // ---------------------------------------------------------------------------

  @override
  Future<void> grantConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    _mixpanel.optInTracking();
    _mixpanel.track(EventRegistry.consentGranted);
  }

  @override
  Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, false);
    _mixpanel.track(EventRegistry.consentRevoked);
    _mixpanel.optOutTracking();
  }

  @override
  Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  @override
  Future<void> identify({
    required String userId,
    String? acquisitionChannel,
    String? plan,
    String? country,
  }) async {
    await _mixpanel.identify(userId);
    final people = _mixpanel.getPeople();
    people.set(PropertyKeys.userId, userId);
    if (acquisitionChannel != null) {
      people.set(PropertyKeys.acquisitionChannel, acquisitionChannel);
    }
    if (plan != null) people.set(PropertyKeys.plan, plan);
    if (country != null) people.set(PropertyKeys.country, country);
  }

  @override
  Future<void> reset() => _mixpanel.reset();

  // ---------------------------------------------------------------------------
  // Funnel events
  // ---------------------------------------------------------------------------

  @override
  void trackProductViewed({
    required String productId,
    required String productName,
    required String category,
    required double price,
    String currency = 'USD',
    String source = 'list',
  }) {
    _mixpanel.track(EventRegistry.productViewed, properties: {
      PropertyKeys.productId: productId,
      PropertyKeys.productName: productName,
      PropertyKeys.category: category,
      PropertyKeys.price: price,
      PropertyKeys.currency: currency,
      PropertyKeys.source: source,
    });
  }

  @override
  void trackAddToCart({
    required String productId,
    required int quantity,
    required double price,
    String currency = 'USD',
  }) {
    _mixpanel.track(EventRegistry.addToCart, properties: {
      PropertyKeys.productId: productId,
      PropertyKeys.quantity: quantity,
      PropertyKeys.price: price,
      PropertyKeys.currency: currency,
    });
  }

  @override
  void trackCheckoutStarted({
    required double cartValue,
    required int itemCount,
    String currency = 'USD',
  }) {
    _mixpanel.track(EventRegistry.checkoutStarted, properties: {
      PropertyKeys.cartValue: cartValue,
      PropertyKeys.itemCount: itemCount,
      PropertyKeys.currency: currency,
    });
  }

  @override
  void trackPurchaseCompleted({
    required String orderId,
    required double cartValue,
    required int itemCount,
    required String paymentMethod,
    String currency = 'USD',
  }) {
    _mixpanel.track(EventRegistry.purchaseCompleted, properties: {
      PropertyKeys.orderId: orderId,
      PropertyKeys.cartValue: cartValue,
      PropertyKeys.itemCount: itemCount,
      PropertyKeys.paymentMethod: paymentMethod,
      PropertyKeys.currency: currency,
    });

    // Mixpanel revenue tracking lives on the People profile.
    _mixpanel.getPeople().trackCharge(cartValue, properties: {
      PropertyKeys.orderId: orderId,
      PropertyKeys.currency: currency,
    });
    _mixpanel.getPeople().increment(PropertyKeys.lifetimeValue, cartValue);
  }

  // ---------------------------------------------------------------------------
  // Gamification events
  // ---------------------------------------------------------------------------

  @override
  void trackXpEarned({required int amount, required String source}) {
    _mixpanel.track(EventRegistry.xpEarned, properties: {
      PropertyKeys.xpAmount: amount,
      PropertyKeys.source: source,
    });
    _mixpanel.getPeople().increment(PropertyKeys.totalXp, amount.toDouble());
  }

  @override
  void trackLevelUp({required int newLevel}) {
    _mixpanel.track(EventRegistry.levelUp, properties: {
      PropertyKeys.newLevel: newLevel,
    });
    _mixpanel.getPeople().set(PropertyKeys.totalLevel, newLevel);
  }

  @override
  void trackStreakIncrement({required int streakDays}) {
    _mixpanel.track(EventRegistry.streakIncrement, properties: {
      PropertyKeys.streakDays: streakDays,
    });
  }

  @override
  void trackBadgeUnlocked({required String badgeId}) {
    _mixpanel.track(EventRegistry.badgeUnlocked, properties: {
      PropertyKeys.badgeId: badgeId,
    });
  }

  @override
  void trackDailyQuestCompleted({required String questId, required int xpReward}) {
    _mixpanel.track(EventRegistry.dailyQuestCompleted, properties: {
      PropertyKeys.questId: questId,
      PropertyKeys.xpAmount: xpReward,
    });
  }

  // Force a flush, e.g. before logout or app termination.
  @override
  Future<void> flush() => _mixpanel.flush();
}

/// No-op [AnalyticsService] for tests, widget previews, and screenshot capture.
///
/// Lets every screen render without booting the native Mixpanel SDK.
class NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> grantConsent() async {}
  @override
  Future<void> revokeConsent() async {}
  @override
  Future<bool> hasConsent() async => true;
  @override
  Future<void> identify({
    required String userId,
    String? acquisitionChannel,
    String? plan,
    String? country,
  }) async {}
  @override
  Future<void> reset() async {}
  @override
  void trackProductViewed({
    required String productId,
    required String productName,
    required String category,
    required double price,
    String currency = 'USD',
    String source = 'list',
  }) {}
  @override
  void trackAddToCart({
    required String productId,
    required int quantity,
    required double price,
    String currency = 'USD',
  }) {}
  @override
  void trackCheckoutStarted({
    required double cartValue,
    required int itemCount,
    String currency = 'USD',
  }) {}
  @override
  void trackPurchaseCompleted({
    required String orderId,
    required double cartValue,
    required int itemCount,
    required String paymentMethod,
    String currency = 'USD',
  }) {}
  @override
  void trackXpEarned({required int amount, required String source}) {}
  @override
  void trackLevelUp({required int newLevel}) {}
  @override
  void trackStreakIncrement({required int streakDays}) {}
  @override
  void trackBadgeUnlocked({required String badgeId}) {}
  @override
  void trackDailyQuestCompleted({required String questId, required int xpReward}) {}
  @override
  Future<void> flush() async {}
}
