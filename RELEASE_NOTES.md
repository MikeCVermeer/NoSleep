# NoSleep 1.0

Release date: 2026-05-05

NoSleep 1.0 is the first complete V1 release of the native macOS menu-bar utility for keeping a Mac awake during important long-running work.

## Highlights

- Native Swift and SwiftUI/AppKit macOS menu-bar app.
- Menu-bar-only agent behavior, hidden from the Dock and app switcher.
- Custom NoSleep application icon.
- Start and stop awake sessions from the menu bar.
- Preset timers, until-specific-time sessions, and "Until I turn it off".
- Prevents automatic idle system sleep while active.
- Allows display sleep by default, with an optional display-awake setting.
- Battery-safe defaults, including indefinite-session protection on battery and configurable low-battery disable.
- Basic macOS notifications for timer and battery events.
- Settings window with General, Sleep Behavior, Battery, Notifications, and Advanced sections.
- Launch-at-login integration using `SMAppService.mainApp`.
- Diagnostics export for support and verification.
- Unit tests covering settings, timers, assertions, session policy, notifications, diagnostics, and until-specific-time behavior.

## Installation

Install with Homebrew:

```bash
brew install --cask MikeCVermeer/tap/nosleep
```

Or download `NoSleep-1.0.zip` from the GitHub release, unzip it, and move `NoSleep.app` to `/Applications`.

Because this initial release is built locally and not notarized for App Store distribution, macOS Gatekeeper may require opening it from Finder with Control-click, Open the first time.

## Verification

The V1.0 release was validated with:

```bash
xcodebuild -list
xcodebuild -scheme NoSleep -destination 'platform=macOS' test
xcodebuild -scheme NoSleep -configuration Release -destination 'platform=macOS' build
```

Release artifact:

- `NoSleep-1.0.zip`
- SHA-256: `82387a9c080dbb4819babc2356fc652d0442e9b1d4162ad769d00d7698faf782`

Manual smoke tests that remain recommended before wider distribution:

- Launch the release app and confirm only the menu-bar icon appears.
- Start and stop an awake session, then inspect `pmset -g assertions`.
- Exercise Settings, notifications, launch at login, charger unplug, and low-battery behavior on real hardware.

## Limitations

NoSleep prevents automatic idle system sleep while active. It does not claim to block manual sleep, lid-close sleep, forced sleep, lock screen, or screensaver behavior.

NoSleep 1.0 has no cloud sync, accounts, analytics, telemetry, process detection, or complex automation rules.
