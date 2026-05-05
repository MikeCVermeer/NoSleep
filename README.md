# NoSleep

NoSleep is a native macOS menu-bar utility that keeps the Mac awake while important work is running. It is intended for developers and power users running long-running AI agents, terminal commands, builds, scripts, local servers, downloads, and background jobs.

Current release: **NoSleep 1.0**.

V1 is intentionally local-only and minimal: no cloud, no accounts, no analytics, no telemetry, no process detection, and no complex automation rules.

## Current Status

V1 implementation is complete. The repository contains a native Swift macOS app scaffold named `NoSleep`, typed settings/state models, duration helpers, a time remaining formatter, an IOKit-backed sleep assertion manager, an IOKit-backed power monitor, session controller and timer logic, app sleep/wake handling, app-termination assertion release wiring, diagnostics models, a menu-bar UI, a five-section Settings window, UserNotifications delivery, ServiceManagement launch-at-login integration, and a unit-test target.

The menu-bar UI can start indefinite, preset-duration, and until-specific-time awake sessions, and can stop the active session. NoSleep is configured as a menu-bar-only agent, so it stays out of the Dock and app switcher. The app ships with a custom NoSleep icon. Power-source detection, battery safety enforcement, notification delivery, launch-at-login integration, and post-sleep behavior are wired into the app.

## Install

With Homebrew:

```bash
brew install --cask MikeCVermeer/tap/nosleep
```

Or install manually:

Download `NoSleep-1.0.zip` from the GitHub release, unzip it, and move `NoSleep.app` to `/Applications`.

NoSleep 1.0 is built locally and is not notarized for App Store distribution. On first launch, macOS Gatekeeper may require opening it from Finder with Control-click, Open.

## What NoSleep Will Do

- Let the user start and stop an awake session from the menu bar.
- Prevent automatic idle system sleep while active.
- Allow display sleep by default.
- Optionally keep the display awake.
- Support timer presets, until-specific-time sessions, and "Until I turn it off".
- Apply battery-safe defaults.
- Release power assertions when a session ends or the app quits.

## What NoSleep Will Not Do

- It will not claim to block all manual, lid-close, forced, or system-initiated sleep paths.
- It will not interfere with lock screen or screensaver behavior.
- It will not detect specific apps, terminals, containers, or processes in V1.
- It will not use cloud services, accounts, analytics, telemetry, or tracking.

## Requirements

- macOS with Xcode installed.
- Xcode command line tools available through `xcodebuild`.

## Build

Discover schemes:

```bash
xcodebuild -list
```

Build the debug app:

```bash
xcodebuild -scheme NoSleep -configuration Debug -destination 'platform=macOS' build
```

Build the release app:

```bash
xcodebuild -scheme NoSleep -configuration Release -destination 'platform=macOS' build
```

Current validation:

- `xcodebuild -list` passes and lists scheme `NoSleep`.
- `xcodebuild -scheme NoSleep -destination 'platform=macOS' test` passes with 47 tests.
- `xcodebuild -scheme NoSleep -configuration Debug -destination 'platform=macOS' build` passes.
- `xcodebuild -scheme NoSleep -configuration Release -destination 'platform=macOS' build` passes.

## Release Packaging

After a Release build, package the app from Xcode DerivedData:

```bash
ditto -c -k --keepParent path/to/NoSleep.app NoSleep-1.0.zip
```

The GitHub V1.0 release artifact is `NoSleep-1.0.zip`.

V1.0 SHA-256:

```text
82387a9c080dbb4819babc2356fc652d0442e9b1d4162ad769d00d7698faf782  NoSleep-1.0.zip
```

## Run

From Xcode, open `NoSleep.xcodeproj`, select the `NoSleep` scheme, and run the app. From the command line, build with `xcodebuild`, then launch the generated `NoSleep.app` from Xcode DerivedData or Xcode's Products group.

NoSleep appears in the macOS menu bar as a power icon and is hidden from the Dock/app switcher. Use the menu to start a timed session, start “Until I turn it off”, open Settings, or quit.

## Tests

Run unit tests:

```bash
xcodebuild -scheme NoSleep -destination 'platform=macOS' test
```

Current validation:

- `xcodebuild -scheme NoSleep -destination 'platform=macOS' test` passes.
- Current tests cover settings defaults/persistence/reset, duration presets, time remaining formatting, sleep assertion manager state transitions, session controller state/timer behavior, post-sleep behavior, battery safety policy, notification events, settings labels, diagnostics text formatting, and until-specific-time date calculation.

## Settings

Open Settings from the NoSleep menu. Current sections:

- General: start-at-login integration, menu timer display, active icon state, and default duration.
- Sleep Behavior: system-sleep prevention, display-sleep prevention, and post-sleep behavior.
- Battery: battery warning, indefinite-session plug-in requirement, unplug auto-disable, low-battery disable, and threshold percentage.
- Notifications: persisted notification preferences for V1 events.
- Advanced: reset all settings, export diagnostics to the clipboard, notification authorization status, and launch-at-login status.

The start-at-login toggle uses `SMAppService.mainApp`. Registration can fail depending on signing, installation location, or macOS policy; the last error is shown in Advanced settings.

## Sleep Behavior

While active, NoSleep prevents automatic idle system sleep with an IOKit system-sleep assertion. Display sleep is allowed by default. Enabling “Also prevent display sleep” creates a separate display-sleep assertion.

NoSleep does not try to block manual sleep, lid-close sleep, forced sleep, lock screen, or screensaver behavior. By default, when macOS sleeps, NoSleep turns off and releases assertions. Settings can request resume after wake or previous-state behavior; both paths still re-check battery safety before restarting assertions.

## Notifications

NoSleep uses macOS UserNotifications for enabled V1 events:

- Timer ended: “NoSleep timer ended. Your Mac can sleep normally again.”
- Battery low: “NoSleep disabled at the configured battery threshold.”
- Unplugged while active: “NoSleep is still active on battery.”
- Auto-disabled when unplugged: “NoSleep disabled because your Mac was unplugged.”

Notification permission is requested only when NoSleep first needs to send a notification. Low-battery notifications are suppressed until the low-battery condition clears.

## Power Assertion Verification

The IOKit assertion manager, session controller, and menu actions are implemented. After launching the app and starting an awake session from the menu bar, use:

```bash
pmset -g assertions
```

Manual verification checklist:

- No NoSleep assertion appears before enabling an awake session.
- A system sleep assertion appears after enabling an awake session.
- Display sleep remains allowed by default.
- A display assertion appears only when the display-awake setting is enabled.
- Assertions are released after stopping the session or quitting the app.

This manual `pmset` smoke test has not been performed in this session.

## Battery Safety Defaults

The V1 defaults are:

- Only allow "Until I turn it off" while plugged in.
- Warn before running on battery.
- Do not auto-disable when unplugged unless the user enables that setting.
- Disable at or below the configured battery threshold.
- Default battery threshold: 20%.

Implemented behavior:

- Indefinite sessions are blocked while on battery by default.
- Timed sessions can run on battery after an in-menu confirmation when warnings are enabled.
- Active sessions release assertions and become disabled when the configured battery threshold is reached.
- Unplugging during an indefinite session leaves NoSleep active and visible on battery by default.
- Enabling auto-disable when unplugged releases assertions and disables the session.

## Limitations

NoSleep V1 prevents automatic idle system sleep while active. It does not promise to block manual sleep, lid-close sleep, forced sleep, lock screen, or screensaver behavior.

Manual smoke testing that was not performed in this session: menu-bar interaction, Settings window interaction, notification permission/delivery, launch-at-login registration, charger unplug, and low-battery behavior.
