# Screenshot capture flow

Real captures from the iOS Simulator via an integration-test driver (no mockups).

## Steps

1. Boot the simulator:
   ```bash
   xcrun simctl boot "iPhone 17"
   open -a Simulator
   ```
2. Scaffold the iOS platform folder (lib-only project) and get dependencies:
   ```bash
   flutter create . --platforms=ios --project-name flutter_mixpanel_analytics
   flutter pub get
   ```
3. Drive the screenshot test:
   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "iPhone 17"
   ```
4. Build the demo GIF from the PNGs:
   ```bash
   cd screenshots
   ffmpeg -y -framerate 1 -pattern_type glob -i '*.png' \
     -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 demo.gif
   ```

PNGs + `demo.gif` are written to `screenshots/` and embedded in `README.md`.

## How it works

- `test_driver/integration_test.dart` - `integrationDriver(onScreenshot:)` writes each PNG to `screenshots/<name>.png`.
- `integration_test/screenshot_test.dart` - pumps the `HomeShell` (bottom-nav Shop + Progress) inside a `ProviderScope` with two overrides:
  - `analyticsServiceProvider` is overridden with `NoopAnalyticsService` so screens render without booting the native Mixpanel SDK.
  - `gamificationControllerProvider` is seeded with a realistic profile (Level 19, 1840 XP, 12-day streak, unlocked badges) so the dashboard looks alive.
- The test then drives the real funnel: it shoots the shop catalog (`01-shop`), taps `Add` to push an item into the cart (`02-add-to-cart`), taps the `Progress` tab to reveal the gamification dashboard (`03-progress-dashboard`), and scrolls the `ListView` to expose badges and daily quests (`04-badges-quests`). Each shot calls `binding.convertFlutterSurfaceToImage()` + `binding.takeScreenshot('NN-name')`.
