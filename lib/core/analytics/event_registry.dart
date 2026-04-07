/// Single source of truth for every Mixpanel event name and property key in
/// the app. Keeping this in one file lets the team review the analytics
/// taxonomy in one place and prevents stringly-typed bugs from leaking into
/// dashboards. Add a new event by adding a constant here AND a typed builder
/// in `analytics_service.dart`.
class EventRegistry {
  EventRegistry._();

  // Lifecycle
  static const appOpen = 'app_open';
  static const appBackgrounded = 'app_backgrounded';

  // Funnel: browse -> purchase
  static const productViewed = 'product_viewed';
  static const productSearched = 'product_searched';
  static const addToCart = 'add_to_cart';
  static const removeFromCart = 'remove_from_cart';
  static const checkoutStarted = 'checkout_started';
  static const purchaseCompleted = 'purchase_completed';

  // Gamification loop
  static const xpEarned = 'xp_earned';
  static const levelUp = 'level_up';
  static const streakIncrement = 'streak_increment';
  static const badgeUnlocked = 'badge_unlocked';
  static const dailyQuestCompleted = 'daily_quest_completed';

  // Consent
  static const consentGranted = 'consent_granted';
  static const consentRevoked = 'consent_revoked';
}

/// Property keys are also centralized so reports group correctly. Mixpanel is
/// case-sensitive, so a typo here means a broken funnel.
class PropertyKeys {
  PropertyKeys._();

  // Common
  static const source = 'source';
  static const platform = 'platform';
  static const appVersion = 'app_version';

  // Product
  static const productId = 'product_id';
  static const productName = 'product_name';
  static const category = 'category';
  static const price = 'price';
  static const currency = 'currency';
  static const quantity = 'quantity';

  // Cart / checkout
  static const cartValue = 'cart_value';
  static const itemCount = 'item_count';
  static const paymentMethod = 'payment_method';
  static const orderId = 'order_id';

  // Gamification
  static const xpAmount = 'xp_amount';
  static const newLevel = 'new_level';
  static const streakDays = 'streak_days';
  static const badgeId = 'badge_id';
  static const questId = 'quest_id';

  // People (user) properties
  static const userId = 'user_id';
  static const acquisitionChannel = 'acquisition_channel';
  static const plan = 'plan';
  static const country = 'country';
  static const lifetimeValue = 'lifetime_value';
  static const totalLevel = 'total_level';
  static const totalXp = 'total_xp';
}
