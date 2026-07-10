# Feature Specification: Live Manual Scroll Sync

**Feature Branch**: `003-live-scroll-sync`

**Created**: 2026-07-10

**Status**: Draft

**Input**: User description: "I want to expand on the host scrolling feature so that when the host device manually scrolls their screen, all connected devices will also scroll."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Host manually scrolls and the band follows along (Priority: P1)

During a live set, the bandleader manually drags/flicks their screen to move through the song (instead of using auto-scroll). Every connected bandmate's screen scrolls to show the same passage, in real time, without any of them touching their own device.

**Why this priority**: This is the entire scope of the request — today, manual scrolling by the host has no effect on connected devices at all. Auto-scroll (play/pause/speed) already syncs, but a host who scrolls by hand leaves the band behind.

**Independent Test**: Start a live session with one connected follower viewing the same song as the host. On the host device, manually drag the screen to a different section of the song. Verify the follower's screen scrolls to display that same section within about a second, without the follower touching their screen.

**Acceptance Scenarios**:

1. **Given** a live session with a connected follower viewing the same song as the host, **When** the host manually drags/scrolls to a new position in the song, **Then** the follower's screen scrolls to display the corresponding passage shortly after.
2. **Given** the host's auto-scroll is currently running, **When** the host manually scrolls (which already stops the host's own auto-scroll), **Then** any follower whose screen was auto-scrolling also stops, and instead follows the host's new manual scroll position.
3. **Given** a live session with multiple connected followers viewing the same song, **When** the host manually scrolls, **Then** every connected follower's screen scrolls together, not just one.
4. **Given** followers on devices with different screen sizes or font/chord display settings, **When** the host scrolls to a given point in the song, **Then** each follower's screen shows the corresponding passage of the song (e.g. the same section/lyric line), even though the exact pixel position differs per device.

---

### User Story 2 - A bandmate joins mid-song and lands where the host already is (Priority: P2)

A bandmate connects to (or reconnects to) the live session partway through a song the host has already scrolled into. Their screen jumps straight to the host's current position instead of sitting at the top of the song waiting for the host's next movement.

**Why this priority**: Without this, joining or reconnecting mid-song leaves a bandmate stuck at the wrong spot until the host happens to scroll again — a common and disruptive real-world case (a phone dropping connection mid-set, or someone joining late).

**Independent Test**: Start a live session and have the host scroll partway through a song before a second device connects as a follower. Verify the newly connected follower's screen shows the host's current passage immediately upon connecting, without requiring the host to scroll again.

**Acceptance Scenarios**:

1. **Given** the host has already scrolled partway through the current song, **When** a new device joins the session as a follower on that same song, **Then** that follower's screen immediately shows the host's current passage.
2. **Given** a follower's connection drops and reconnects while the host is mid-song, **When** the connection is reestablished, **Then** the follower's screen catches up to the host's current position rather than resuming from wherever it last was.

---

### Edge Cases

- The host flicks/flings rapidly through the song: followers keep up as closely as the connection and rendering allow, and correctly land on the host's final resting position even if intermediate positions are skipped.
- The host scrolls to the very top or very bottom of the song: followers reach the same boundary despite any difference in content height across devices.
- A follower manually touches/drags their own screen while following: consistent with today's behavior (followers have no auto-scroll or speed controls of their own), the follower's screen remains locked to the host's position — their manual scroll gesture does not move their view independently.
- A follower is viewing a different song than the host (e.g. they backed out, or haven't yet been auto-navigated to the host's current song): scroll sync updates for that song are ignored until the follower is viewing the matching song.
- A follower has "Pause following" enabled (existing setting): scroll sync is suppressed the same way all other live session updates already are for that follower.
- The live session connection drops mid-scroll: the follower's screen stays at the last position it received and resumes following once reconnected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST transmit the host's manual scroll position to all connected followers currently viewing the same song, in near real time as the host scrolls.
- **FR-002**: System MUST express the synced scroll position proportionally within the song (i.e., how far through the song the view is), not as a raw pixel offset, so that followers on devices with different screen sizes or display settings (font size, chord visibility) land on the corresponding passage rather than a mismatched one.
- **FR-003**: Followers' screens MUST NOT respond to their own manual scroll/drag gestures while following a live session; their screen position is driven only by the host's broadcast position, consistent with followers already having no independent auto-scroll or speed controls.
- **FR-004**: System MUST NOT sync scroll position to a follower who is not currently viewing the song the host is on; syncing MUST resume automatically once that follower is viewing the matching song.
- **FR-005**: When a follower has "Pause following" enabled, System MUST suppress scroll position sync the same way it suppresses other live session updates for that follower.
- **FR-006**: A follower who joins the session, or reconnects, while the host is already partway through a song MUST be brought to the host's current scroll position immediately, without waiting for the host's next scroll movement.
- **FR-007**: The host manually scrolling MUST continue to stop the host's own auto-scroll (existing behavior), and this state change MUST propagate so that any follower currently auto-scrolling also stops and switches to following the host's manual position.
- **FR-008**: Transmitting scroll position updates MUST NOT degrade the responsiveness or reliability of existing live session features (song navigation, auto-scroll play/pause/speed sync).

### Key Entities

- **Scroll Position Update**: A broadcast from the host to connected followers indicating how far through the currently displayed song the host's view is scrolled, expressed proportionally so it maps to the corresponding passage regardless of device screen size or display settings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When the host manually scrolls and then stops, connected followers' screens visibly reach the corresponding passage within 1 second.
- **SC-002**: In a live session with multiple connected followers on the same song, 100% of them scroll in sync with the host's manual movements, not just a subset.
- **SC-003**: A follower who joins or reconnects mid-song reaches the host's current passage within 1 second of connecting, without the host needing to scroll again.
- **SC-004**: Followers on devices with different screen sizes or font/chord display settings consistently land on the same section/passage of the song as the host, not a visually mismatched one.

## Assumptions

- This feature covers the host's *manual* (drag/fling) scrolling specifically. Auto-scroll continues to sync via the existing play/pause/speed broadcast mechanism, unchanged by this feature.
- Followers are locked to the host's scroll position while following (no independent manual scrolling), matching the existing pattern where followers already have no auto-scroll or speed panel controls of their own.
- Scroll position is synced proportionally (relative position within the song) rather than by raw pixel offset, since connected devices may differ in screen size, font size, or chord visibility settings.
- This feature reuses the existing live session connection (peer-to-peer, same-room, no shared WiFi/internet required) rather than introducing a new connection mechanism.
- "Pause following" and the existing same-song gating for live updates apply to scroll sync exactly as they already apply to song navigation and auto-scroll sync.
