---

description: "Task list for Live Manual Scroll Sync implementation"
---

# Tasks: Live Manual Scroll Sync

**Input**: Design documents from `/specs/003-live-scroll-sync/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/live-session-message.md, quickstart.md (all present)

**Tests**: The project constitution (Principle IV, Test-First for Core Logic, NON-NEGOTIABLE) requires a failing-first unit test for the `LiveSessionMessage` JSON serialization change, since that's UI-free service logic. The scroll-throttling/lock/apply logic lives in a widget and the connection-resend logic is tightly coupled to the `nearby_connections` plugin — both fall under the constitution's existing carve-out for UI/plugin-in-the-loop code, verified via the manual Quickstart scenarios instead of widget tests (consistent with the rest of the live-session code, which has no widget tests today either).

**Organization**: Tasks are grouped by user story (US1, US2, from spec.md) to enable independent implementation and testing of each.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Exact file paths are included in every task description

## Path Conventions

Single Flutter project (existing app) — `lib/` for source, `test/` for tests. No new top-level directories; every task touches one of the four files `plan.md` identified as already owning live-session state.

---

## Phase 1: Setup

**Purpose**: Confirm the feature needs no new project setup before touching code

- [X] T001 Confirm no new `pubspec.yaml` dependencies are needed: this feature reuses the existing `nearby_connections` and `provider` packages only (per `plan.md`'s Technical Context) — run `flutter pub get` to confirm the current lockfile is clean before starting.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend the shared `LiveSessionMessage` DTO both user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] Write a failing unit test for the new `scrollFraction` field in `test/services/live_session_service_test.dart` (new file): assert `LiveSessionMessage(...).toJson()` includes `scrollFraction`, assert `LiveSessionMessage.fromJson(...)` round-trips a given value, and assert `fromJson` defaults `scrollFraction` to `0.0` when the key is absent from the JSON map (backward-compatibility case from `contracts/live-session-message.md`). Run `flutter test test/services/live_session_service_test.dart` and confirm it fails (the field doesn't exist yet).
- [X] T003 Add `scrollFraction` (`double`, default `0.0`) to `LiveSessionMessage` in `lib/services/live_session_service.dart`: constructor field, `toJson`, and `fromJson` (with `?? 0.0` default, matching the existing pattern for `scrollSpeedPxPerSec`). Run `flutter test test/services/live_session_service_test.dart` and confirm T002 now passes.
- [X] T004 Add a `scrollFraction` parameter (default `0.0`) to `LiveSessionProvider.broadcastNowPlaying(...)` in `lib/providers/live_session_provider.dart`, passing it through to the constructed `LiveSessionMessage` (depends on T003).

**Checkpoint**: `LiveSessionMessage` carries scroll position end-to-end through the provider — both user stories can now build on it.

---

## Phase 3: User Story 1 - Host manually scrolls and the band follows along (Priority: P1) 🎯 MVP

**Goal**: While host and follower are already connected and viewing the same song, the host's manual drag/flick broadcasts a throttled, proportional scroll position that already-connected followers apply in real time; followers can't scroll independently while following.

**Independent Test**: Start a live session, connect one follower to the same song, manually drag the host's screen — the follower's screen scrolls to the corresponding passage within about a second, and dragging the follower's own screen has no effect.

### Implementation for User Story 1

- [X] T005 [US1] In `lib/screens/song_view_screen.dart`, extend the host-side scroll handling around the `SingleChildScrollView`/`NotificationListener` (currently only stops auto-scroll on `UserScrollNotification`) to also compute `scrollFraction = pixels / maxScrollExtent` (clamped to `[0.0, 1.0]`) and call `_broadcastNowPlaying()` with it, throttled to at most one call per ~100–150ms while the user is actively dragging and `!widget.liveFollowing` (per `research.md`'s throttle decision).
- [ ] T006 [US1] In `lib/screens/song_view_screen.dart`, set the `SingleChildScrollView`'s `physics` to `const NeverScrollableScrollPhysics()` when `widget.liveFollowing` is true, so a follower's own drag gestures never move their view (FR-003).
- [ ] T007 [US1] In `lib/screens/song_view_screen.dart`'s `_onLiveFollowUpdate`, read `message.scrollFraction`, compute the target offset against the follower's own `_scrollController.position.maxScrollExtent`, and `jumpTo` it whenever `_scrollController.hasClients` (depends on T004 for the field to exist on the message; sequenced after T005/T006 since all three edit the same file).
- [ ] T008 [US1] Manual verification: run Quickstart Scenarios 1, 2, and 4 from `specs/003-live-scroll-sync/quickstart.md` on two physical devices (real-time sync, follower lock, cross-device font/screen-size correspondence) (depends on T005, T006, T007).

**Checkpoint**: User Story 1 is fully functional and independently testable (assumes host and follower are already connected before the host starts scrolling).

---

## Phase 4: User Story 2 - A bandmate joins mid-song and lands where the host already is (Priority: P2)

**Goal**: A follower who joins or reconnects while the host is already partway through a song is brought to the host's current scroll position immediately, without the host needing to scroll again.

**Independent Test**: Have the host scroll partway through a song before a second device connects as a follower — verify the new follower's screen shows the host's current passage immediately on connecting.

### Implementation for User Story 2

- [ ] T009 [P] [US2] In `lib/services/live_session_service.dart`, add an in-memory `LiveSessionMessage? _lastMessage` to `LiveSessionHost`, set it in `broadcast()`, and in `onConnectionResult` — when `status == Status.CONNECTED` — send `_lastMessage` (if any) directly to that specific `endpointId` in addition to the existing all-endpoints broadcasts elsewhere (depends on T003; different file from T005–T007 so can proceed in parallel with Phase 3).
- [ ] T010 [US2] In `lib/screens/song_view_screen.dart`, add an `initialScrollFraction` field to `SongViewScreen`'s constructor (alongside the existing `initialAutoScrollActive`/`initialLiveScrollSpeed`) and apply it to `_scrollController` once `hasClients` is true post-first-frame (depends on T003; sequenced after T005–T007 since it edits the same file).
- [ ] T011 [US2] In `lib/app.dart`'s `_onLiveSessionChange`, pass `initialScrollFraction: message.scrollFraction` into the `SongViewScreen(...)` route construction, alongside the existing `initialAutoScrollActive`/`initialLiveScrollSpeed` arguments (depends on T010).
- [ ] T012 [US2] Manual verification: run Quickstart Scenario 3 from `specs/003-live-scroll-sync/quickstart.md` on two physical devices (first-time late join, then forced disconnect/reconnect) (depends on T009, T011).

**Checkpoint**: User Stories 1 and 2 both work independently — a follower is caught up whether they were already connected or just joined/reconnected.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Confirm the feature doesn't regress existing behavior or violate project quality gates

- [ ] T013 [P] Run `flutter analyze` from the repo root and confirm no new warnings (constitution's Technology Constraints gate).
- [ ] T014 Run Quickstart Scenario 5 from `specs/003-live-scroll-sync/quickstart.md` ("Pause following" suppresses scroll sync) to confirm the existing pause behavior isn't regressed — per `research.md`'s finding, this needs no new code, only verification.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup. BLOCKS both user stories (T003/T004 must land before any US1/US2 task).
- **User Story 1 (Phase 3)**: Depends on Foundational only.
- **User Story 2 (Phase 4)**: Depends on Foundational only — independent of US1's tasks, though T010 is sequenced after US1's `song_view_screen.dart` edits (T005–T007) purely to avoid concurrent edits to the same file, not a functional dependency.
- **Polish (Phase 5)**: Depends on both user stories being complete.

### Within Each User Story

- US1: T005 → T006 → T007 (same file, sequenced) → T008 (verification).
- US2: T009 can start as soon as Foundational is done (different file). T010 → T011 → T012 (verification).

### Parallel Opportunities

- T002 (test) can be written while T001 runs.
- T009 (`live_session_service.dart`) can proceed in parallel with all of Phase 3 (`song_view_screen.dart`), since they're different files with no shared dependency beyond T003.
- T013 (`flutter analyze`) can run any time after all implementation tasks land.

---

## Parallel Example: Foundational + early User Story 2

```bash
# After T001:
Task: "Write failing scrollFraction serialization test in test/services/live_session_service_test.dart"  # T002

# After T003/T004 (Foundational complete), these can run at the same time:
Task: "Throttled scroll-position broadcast in lib/screens/song_view_screen.dart"                          # T005 (US1)
Task: "Cache + resend last message to new endpoints in lib/services/live_session_service.dart"            # T009 (US2)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (T002–T004).
3. Complete Phase 3: User Story 1 (T005–T008).
4. **STOP and VALIDATE**: run Quickstart Scenarios 1, 2, 4 on two physical devices.
5. This alone delivers the feature's entire stated request — "when the host manually scrolls, connected devices scroll too" — for devices that are already connected when scrolling starts.

### Incremental Delivery

1. Setup + Foundational → shared `scrollFraction` field ready.
2. Add User Story 1 → validate independently → this is the MVP.
3. Add User Story 2 → validate independently → adds late-join/reconnect catch-up on top.
4. Polish → `flutter analyze` clean, pause-suppression regression check.

---

## Notes

- [P] tasks touch different files with no unmet dependency.
- [US1]/[US2] labels map every implementation task to its spec.md user story for traceability.
- No contract tests or data-model migration tasks are needed beyond T002/T003 — this feature adds one field to one existing transient DTO; see `data-model.md` for why no persisted entities are involved.
- Commit after each task or logical group; stop at either checkpoint to validate a story independently before continuing.
