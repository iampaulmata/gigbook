# Phase 0 Research: Live Manual Scroll Sync

No `[NEEDS CLARIFICATION]` markers remain in the spec or Technical Context — the scope-defining ambiguity (whether followers can independently scroll away) was already resolved with the user before the spec was written. This document instead records the technical decisions made while translating the spec into a concrete approach, each grounded in the existing `live_session_service.dart` / `live_session_provider.dart` / `song_view_screen.dart` / `app.dart` code already reviewed.

## Decision: Extend the existing `LiveSessionMessage`, don't add a new message type

**Rationale**: The host already broadcasts one JSON message per state change (song, play/pause, speed) over the existing Nearby Connections bytes payload channel. Adding a `scrollFraction` field to that same message keeps a single wire format and a single decode path on the follower side — every existing broadcast site (song change, speed-panel edit) automatically carries the current scroll position for free.

**Alternatives considered**: A separate `ScrollPositionMessage` type multiplexed on the same channel — rejected as unnecessary complexity for a single small, app-owned protocol with no external consumers (Simplicity & YAGNI).

## Decision: Sync scroll position as a proportional fraction (`pixels / maxScrollExtent`), not raw pixels

**Rationale**: Connected devices differ in screen size and in font size / chord-visibility display settings, so the host's and a follower's `maxScrollExtent` for the same song will generally differ. A proportional fraction (0.0–1.0) maps to "how far through the song," which stays meaningful across devices — this is what FR-002/SC-004 require.

**Alternatives considered**: Syncing a "current section index" (verse/chorus boundary) instead of a continuous fraction — rejected as materially more code (requires section-boundary bookkeeping already owned by the renderer) for no acceptance-criteria benefit over the simpler continuous fraction.

## Decision: Throttle the host's broadcast while actively dragging (~100–150ms interval), don't broadcast every frame

**Rationale**: The transport is a low-bandwidth, same-room P2P link (BLE for discovery, WiFi Direct/Hotspot for data). A message per scroll-frame/pixel-delta risks contending with existing traffic and violating FR-008 ("must not degrade existing live session features"). A ~100–150ms interval keeps updates well inside the 1-second SC-001 budget while cutting message volume by roughly an order of magnitude versus per-frame.

**Alternatives considered**: Broadcasting on every `ScrollUpdateNotification` — rejected as unnecessary chatter for movement that's imperceptible at sub-100ms granularity anyway.

## Decision: Apply synced position via `jumpTo`, not `animateTo`

**Rationale**: A throttled stream of updates arriving every ~100–150ms would cause repeated `animateTo` calls to interrupt/queue each other, producing visible jitter. `jumpTo` is also what the existing auto-scroll timer (`_startAutoScroll`) and song-switch (`_goTo`) code already use, so this stays consistent with the codebase's existing pattern — and the update cadence itself is fast enough to read as smooth motion without an animation curve on top.

**Alternatives considered**: `animateTo` per update — rejected for the jitter/queueing risk described above.

## Decision: Lock follower scrolling with `NeverScrollableScrollPhysics`, not gesture interception

**Rationale**: FR-003 requires a follower's own drag gestures to have no effect while following. Swapping in `NeverScrollableScrollPhysics` for the `SingleChildScrollView` when `liveFollowing` is true guarantees the framework never applies a user-driven scroll delta in the first place — the simplest, most idiomatic Flutter approach (Principle VI), and it composes cleanly with the existing `NotificationListener<UserScrollNotification>` (which already does nothing meaningful for a follower, since followers have no auto-scroll to stop).

**Alternatives considered**: Leaving scrolling enabled and snapping back via a `UserScrollNotification`/drag-end listener — rejected as more code and prone to a visible flicker (the user's drag applies, then gets reverted) versus never applying it at all.

## Decision: Host caches its last-broadcast message and resends it directly to a newly-connected endpoint

**Rationale**: FR-006/US2 require a joining-or-reconnecting follower to land on the host's current position immediately rather than waiting for the next scroll movement. `LiveSessionHost.onConnectionResult` is already the place connection events are observed; caching the last `LiveSessionMessage` there and sending it directly to the specific endpoint that just connected (in addition to the normal all-endpoints `broadcast()`) satisfies this uniformly for song, play-state, and scroll position, with the fix isolated to the transport layer.

**Important downstream detail found while tracing this**: this resend alone isn't sufficient for a *brand-new* follower. `app.dart`'s `_onLiveSessionChange` only applies `message.isPlaying`/`message.scrollSpeedPxPerSec` from that very message as `initial*` constructor parameters when it pushes the new `SongViewScreen` route (see `app.dart:143-154`) — the screen's own `_onLiveFollowUpdate` listener isn't attached yet at that point, since `initState` runs after the push. So `scrollFraction` must be threaded through the same `initial*` parameter path (`initialScrollFraction`) alongside the existing `initialAutoScrollActive`/`initialLiveScrollSpeed`, applied once `_scrollController.hasClients` (post-first-frame). For a *reconnecting* follower who never left the matching song's screen, the route isn't rebuilt (`isNewSong` is false), so the already-attached `_onLiveFollowUpdate` listener picks up the resent message normally — no special-casing needed there.

**Alternatives considered**: Having `SongViewScreen`/`LiveSessionProvider` watch `connectedDeviceCount` and manually re-broadcast — rejected as spreading connection-lifecycle handling across more layers than a transport-level concern needs.

## Finding: "Pause following" already scopes correctly with no new gating code

FR-005 requires scroll sync to be suppressed the same way other live updates are suppressed for a paused follower. Tracing the existing code: `paused` only gates whether `app.dart` auto-navigates a follower onto the host's `SongViewScreen` route at all (`app.dart:113`) — it does not gate in-screen updates once already there, because a paused follower is, by construction, browsing their own library and not on that route in the first place. `scrollFraction` updates flow through the same `_onLiveFollowUpdate` listener as the existing play/speed updates, so they're automatically unreachable while paused, with no additional check required.
