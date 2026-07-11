# Contract: `LiveSessionMessage` wire format

This is the JSON payload GigBook sends over its peer-to-peer live session channel (Nearby Connections BYTES payload) from the session host to each connected follower device. Both peers are the same app (GigBook), so this is an internal contract between app instances rather than a public API — documented here because it's the one interface this feature crosses a device boundary through.

## Schema

```json
{
  "setlistName": "string | null",
  "title": "string",
  "artist": "string",
  "isPlaying": "boolean",
  "scrollSpeedPxPerSec": "number",
  "scrollFraction": "number"
}
```

- `scrollFraction` is **new** in this feature. Range: `0.0`–`1.0` inclusive.
- All fields except `title`/`artist` are optional on decode — a missing field falls back to its existing default (`scrollFraction` → `0.0`, i.e. top of song), so an older peer's message (without `scrollFraction`) still decodes cleanly rather than being rejected. Both host and follower in this app ship the same version in practice, but the decoder's existing `try/catch` + `??` default pattern already gives this for free.

## Producer

`LiveSessionHost.broadcast(LiveSessionMessage)` in `lib/services/live_session_service.dart` — sends the encoded message to every connected endpoint, and (new in this feature) caches it so it can also be resent to a single endpoint that just connected.

## Consumer

`LiveSessionClient.connect(...)`'s `onPayLoadRecieved` callback decodes the bytes and invokes the caller-supplied `onMessage` — wired up in `LiveSessionProvider.joinHost` to update `latestMessage`/`latestSeq` and `notifyListeners()`. Two downstream consumers act on `scrollFraction`:

1. `app.dart`'s `_onLiveSessionChange` — when pushing a brand-new `SongViewScreen` route for a follower, passes `message.scrollFraction` through as `initialScrollFraction`.
2. `SongViewScreen._onLiveFollowUpdate` — for an already-mounted follower screen, applies `message.scrollFraction` directly.

## Compatibility

No version negotiation exists or is needed today — host and follower are always the same app build in practice (this is a same-room, ad hoc session, not a long-lived service with independently-updated clients). The default-on-missing-field behavior above is a defensive minimum, not a versioning scheme.
