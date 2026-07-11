# Implementation Plan: Live Manual Scroll Sync

**Branch**: `003-live-scroll-sync` | **Date**: 2026-07-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-live-scroll-sync/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

When a live session host manually drags/flicks their screen, connected followers currently see no effect at all — only auto-scroll (play/pause/speed) syncs today. This feature extends the existing peer-to-peer "now playing" broadcast (`LiveSessionMessage`, sent host → followers over Nearby Connections) with a proportional scroll-position field, applies it on followers via a locked (non-interactive) scroll view, and has the host resend its latest snapshot to any endpoint that just connected so late joiners and reconnecting followers catch up immediately instead of waiting for the host's next scroll.

## Technical Context

**Language/Version**: Dart, Flutter SDK `^3.9.2` (per `pubspec.yaml`)

**Primary Dependencies**: `nearby_connections` (existing P2P transport, unchanged), `provider` (existing state management), Flutter's `ScrollController`/`ScrollPhysics` (framework, no new package)

**Storage**: N/A — scroll position is transient live-session state broadcast in-memory, like the existing play/speed fields; nothing is persisted to `sqflite`

**Testing**: `flutter test` (package `flutter_test`), following the existing `test/services/` convention

**Target Platform**: Android (primary), iPad (secondary) — matches the app's existing targets; no new platform-specific code

**Project Type**: Mobile app — single Flutter project (Option 1 structure, unchanged)

**Performance Goals**: Followers reflect the host's stopped scroll position within 1s (SC-001); a ~100–150ms broadcast throttle while the host is actively dragging comfortably fits that budget

**Constraints**: Must not flood the existing low-bandwidth P2P channel (BLE for discovery, WiFi Direct/Hotspot for data) with a message per frame/pixel; must not degrade existing song-navigation or auto-scroll sync reliability (FR-008)

**Scale/Scope**: Band-sized live session (a handful of connected devices), one song in view at a time — same scale as the existing feature

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Offline-First & Local Data Ownership** — PASS. Reuses the existing opt-in, peer-to-peer live session; no network/account dependency introduced; nothing about offline core functionality changes.
- **II. ChordPro Standard Fidelity** — N/A. No parser/renderer changes.
- **III. Stage-Ready UX** — PASS. Followers lose direct manual scroll control while following (per the approved spec), but the existing "Pause following" setting remains their escape hatch to browse independently, exactly as it already is for auto-scroll. No new menus or buried controls.
- **IV. Test-First for Core Logic (NON-NEGOTIABLE)** — APPLIES. The `LiveSessionMessage` JSON encode/decode change (new `scrollFraction` field) is UI-free service logic and gets a failing-first unit test in `test/services/`, consistent with the existing `chordpro_parser_test.dart` pattern. The scroll-application/throttle logic lives inside `SongViewScreen` (a widget) and the connect/resend logic inside `LiveSessionHost` (tightly coupled to the `nearby_connections` plugin, same as all existing host/client code, which has no unit tests today) — both fall under the constitution's carve-out for UI/plugin-in-the-loop code verified via manual/device testing (the `run`/`verify` skills) rather than exhaustive tests.
- **V. Simplicity & YAGNI** — PASS. Extends the existing single message type and existing provider/broadcast methods rather than introducing a new message type, new transport, or new state-management pattern.
- **VI. Flutter & Material Idioms** — PASS. Uses standard `ScrollPhysics` (`NeverScrollableScrollPhysics` while following) instead of hand-rolled gesture interception; no new state-management paradigm.

No violations — Complexity Tracking is not needed.

*Post-design re-check (after Phase 1): unchanged — the data-model and contract additions below are a single field on an existing DTO, not a new abstraction. Gate still PASS.*

## Project Structure

### Documentation (this feature)

```text
specs/003-live-scroll-sync/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── services/
│   └── live_session_service.dart     # LiveSessionMessage: add scrollFraction field;
│                                      # LiveSessionHost: cache + resend last message to
│                                      # newly-connected endpoints
├── providers/
│   └── live_session_provider.dart    # broadcastNowPlaying gains a scrollFraction param
├── screens/
│   └── song_view_screen.dart         # host: throttled scroll-position broadcast on manual
│                                      # drag; follower: NeverScrollableScrollPhysics + apply
│                                      # synced fraction via jumpTo (both on live-follow-update
│                                      # and on initial route push)
└── app.dart                          # thread initialScrollFraction into the SongViewScreen
                                       # route it pushes for a newly/reconnecting follower

test/
└── services/
    └── live_session_service_test.dart   # new: scrollFraction encode/decode round-trip
                                          # + backward-compatible default when field absent
```

**Structure Decision**: Single Flutter project (Option 1), matching the app's existing layout — no new top-level directories. All changes land in the four existing files already responsible for live-session state (`live_session_service.dart`, `live_session_provider.dart`, `song_view_screen.dart`, `app.dart`), plus one new test file alongside the existing `test/services/chordpro_parser_test.dart`.

## Complexity Tracking

*No Constitution Check violations — this section is not needed.*
