import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_registry.dart';

/// Thin, typed wrapper around the Mixpanel Flutter SDK.
///
/// Goals:
///  - All event tracking goes through typed methods, never raw strings
///  - Consent state is persisted and respected on every call
///  - Identity calls (identify, alias, reset) are funneled here so the rest
///    of the app does not have to know about Mixpanel internals
///  - Super properties (platform, app_version) are set once at startup
class AnalyticsService {
  AnalyticsService._(this._mixpanel);

  final Mixpanel _mixpanel;

  static const _consentKey = 'mp_consent_granted';

  static Future<AnalyticsService> init({
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

    return AnalyticsService._(mixpanel);
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

  Future<void> grantConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    await _mixpanel.optInTracking();
    await _mixpanel.track(EventRegistry.consentGranted);
  }

  Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, false);
    await _mixpanel.track(EventRegistry.consentRevoked);
    await _mixpanel.optOutTracking();
  }

  Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

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

  Future<void> reset() => _mixpanel.reset();

  // ---------------------------------------------------------------------------
  // Funnel events
  // ---------------------------------------------------------------------------

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

  void trackXpEarned({required int amount, required String source}) {
    _mixpanel.track(EventRegistry.xpEarned, properties: {
      PropertyKeys.xpAmount: amount,
      PropertyKeys.source: source,
    });
    _mixpanel.getPeople().increment(PropertyKeys.totalXp, amount.toDouble());
  }

  void trackLevelUp({required int newLevel}) {
    _mixpanel.track(EventRegistry.levelUp, properties: {
      PropertyKeys.newLevel: newLevel,
    });
    _mixpanel.getPeople().set(PropertyKeys.totalLevel, newLevel);
  }

  void trackStreakIncrement({required int streakDays}) {
    _mixpanel.track(EventRegistry.streakIncrement, properties: {
      PropertyKeys.streakDays: streakDays,
    });
  }

  void trackBadgeUnlocked({required String badgeId}) {
    _mixpanel.track(EventRegistry.badgeUnlocked, properties: {
      PropertyKeys.badgeId: badgeId,
    });
  }

  void trackDailyQuestCompleted({required String questId, required int xpReward}) {
    _mixpanel.track(EventRegistry.dailyQuestCompleted, properties: {
      PropertyKeys.questId: questId,
      PropertyKeys.xpAmount: xpReward,
    });
  }

  // Force a flush, e.g. before logout or app termination.
  Future<void> flush() => _mixpanel.flush();
}
