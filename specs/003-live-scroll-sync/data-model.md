# Phase 1 Data Model: Live Manual Scroll Sync

No persisted entities are added or changed — live-session state is transient, in-memory, broadcast-only (like the existing `isPlaying`/`scrollSpeedPxPerSec` fields), and is never written to `sqflite`. This feature extends one existing transient DTO.

## `LiveSessionMessage` (existing, extended)

Defined in `lib/services/live_session_service.dart`. Represents the host's current "now playing" state, broadcast to all connected followers.

| Field | Type | Status | Notes |
|---|---|---|---|
| `setlistName` | `String?` | existing | unchanged |
| `title` | `String` | existing | unchanged |
| `artist` | `String` | existing | unchanged |
| `isPlaying` | `bool` | existing | unchanged — auto-scroll play/pause state |
| `scrollSpeedPxPerSec` | `double` | existing | unchanged — auto-scroll speed |
| `scrollFraction` | `double` | **new** | How far through the song the host's view is scrolled, as `pixels / maxScrollExtent`, clamped to `[0.0, 1.0]`. `0.0` = top, `1.0` = bottom. Defaults to `0.0` when absent (e.g. a message from a not-yet-updated peer), which degrades gracefully to "top of song" rather than failing to decode. |

**Validation rules**: `scrollFraction` MUST be clamped to `[0.0, 1.0]` before being placed on a message (the host computes it from its own `ScrollController`, which can't exceed its own extent, but clamping guards against floating-point edge cases at the boundaries).

**State transitions**: None beyond "replaced by the next broadcast" — same lifecycle as the existing fields. `LiveSessionProvider.latestMessage`/`latestSeq` already model "most recent snapshot wins," which scroll position follows without change.

## `LiveSessionHost` last-broadcast cache (existing class, extended, transport-internal — not a DTO)

`LiveSessionHost` (same file) gains an in-memory `LiveSessionMessage? _lastMessage`, set whenever `broadcast()` sends a message. Not user-facing data; exists purely so a newly-connected endpoint can be sent the current snapshot immediately (see `research.md`'s host-resend decision). No new public entity or API shape beyond what's already documented in `contracts/`.
