# Flutter Mixpanel Analytics - Gamified Shopping POC

A Flutter + Riverpod proof-of-concept demonstrating production-grade Mixpanel analytics integration for a gamified shopping app. Focuses on event tracking, user properties, funnels, cohorts, and revenue tracking patterns that drive engagement and conversion insights.

## What this POC demonstrates

- Mixpanel SDK initialization with EU/US data residency
- Typed event taxonomy with a strict event registry (compile-time safety)
- User identity, alias, super properties, and people properties
- Funnel events: `app_open` -> `product_viewed` -> `add_to_cart` -> `checkout_started` -> `purchase_completed`
- Gamification events: `xp_earned`, `level_up`, `streak_increment`, `badge_unlocked`, `daily_quest_completed`
- Revenue tracking with `track_charge` and currency normalization
- Cohort-friendly user properties (acquisition channel, plan, country, lifetime value)
- Consent management (opt-in / opt-out flows for GDPR + ATT)
- Offline event queueing through the SDK and manual flush on reconnect

## Stack

- Flutter 3.x
- Riverpod 2.x for state management
- mixpanel_flutter for analytics
- freezed for typed events
- shared_preferences for consent persistence

## Architecture

```
lib/
├── core/
│   └── analytics/
│       ├── analytics_service.dart       # Mixpanel wrapper, identity, opt-in/out
│       ├── event_registry.dart          # Typed event names + property keys
│       └── analytics_provider.dart      # Riverpod provider + scoped tracker
├── features/
│   ├── shopping/
│   │   ├── product_list_screen.dart     # Tracks product_viewed
│   │   ├── cart_controller.dart         # Tracks add_to_cart, remove_from_cart
│   │   └── checkout_controller.dart     # Tracks checkout_started, purchase_completed
│   └── gamification/
│       ├── xp_controller.dart           # Tracks xp_earned, level_up
│       └── streak_controller.dart       # Tracks streak_increment, badge_unlocked
└── main.dart
```

## Event taxonomy

All event names live in a single `EventRegistry` so the team has one source of truth and Mixpanel dashboards stay clean. Each event has a strongly typed `properties()` builder so you can never ship a typo into a funnel.

## Why this matters for the job

The client is building a gamified shopping app and needs Mixpanel for:
- Conversion funnels from browse to purchase
- Engagement loops driven by gamification (XP, streaks, badges)
- Cohort analysis tied to acquisition channels
- Revenue and LTV reporting

This POC implements the exact patterns required, with a clean separation between the analytics layer and feature code so the same approach scales to any production app.

## Run

```bash
flutter pub get
flutter run --dart-define=MIXPANEL_TOKEN=your_token_here
```
