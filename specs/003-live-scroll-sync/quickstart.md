# Quickstart: Validating Live Manual Scroll Sync

This feature needs Bluetooth/WiFi Direct between real devices (Nearby Connections doesn't work in an emulator/simulator), so validation is manual, on-device — via the `run`/`verify` skills, not `flutter test` alone. Matches this project's three-tablet/phone sideload setup (SM-P610, Samsung A13, Pixel 10 Pro).

## Prerequisites

- Two physical Android devices with GigBook installed, connected over USB (`adb devices -l`), with the same song already imported/present in both libraries.
- Build and sideload the branch to each device (`adb -s <serial> install -r build/app/outputs/flutter-apk/app-release.apk`; use `adb install -r` directly if `flutter install` fails silently).
- Bluetooth and location/nearby-WiFi permissions granted on both devices (existing live-session prerequisite, unchanged).

## Scenario 1 — Host manual scroll reaches a connected follower (US1, SC-001, SC-002)

1. On device A: open the song, start hosting a live session (existing "Start hosting" flow).
2. On device B: discover and join device A's session; confirm it auto-navigates to the same song.
3. On device A: manually drag/flick to scroll partway through the song (don't touch auto-scroll).
4. **Expected**: within about a second of A stopping, B's screen shows the same passage of the song.
5. Repeat while A's auto-scroll is running, then manually scroll A — confirm B's auto-scroll also stops and B follows A's new manual position (acceptance scenario 2).
6. If a third device is available, join it as a second follower and repeat step 3 — confirm both followers move together (acceptance scenario 3).

## Scenario 2 — Follower device is locked while following (FR-003, edge case)

1. With B still following A (from Scenario 1), attempt to manually drag B's screen.
2. **Expected**: B's screen does not move from the drag gesture; it only moves in response to A's broadcasts.

## Scenario 3 — Late join / reconnect catch-up (US2, SC-003)

1. On device A: start hosting, open a song, and manually scroll partway through it — before device B connects.
2. On device B: join the session now (first time connecting).
3. **Expected**: B's screen shows A's current passage immediately, without A needing to scroll again.
4. Toggle device B's WiFi/Bluetooth off and back on (or otherwise force a disconnect/reconnect) while A stays mid-song.
5. **Expected**: once B reconnects, its screen catches up to A's current position without A scrolling again.

## Scenario 4 — Cross-device font/screen size (US1 acceptance scenario 4, SC-004)

1. On device B, change font size and/or chord visibility in Settings so its rendered content height clearly differs from device A's.
2. Repeat Scenario 1, step 3.
3. **Expected**: B lands on the same section/lyric line as A, even though the exact pixel offset differs.

## Scenario 5 — "Pause following" suppresses sync (FR-005)

1. On device B, enable "Pause following" in Settings while connected to A's session.
2. On device A, manually scroll.
3. **Expected**: B is not pulled onto A's song/scroll position while paused (matches existing pause behavior for song navigation).

## Automated coverage

`flutter test test/services/live_session_service_test.dart` covers the `scrollFraction` JSON encode/decode round-trip and its default-on-missing-field behavior — run this before the manual pass above, not as a replacement for it.
