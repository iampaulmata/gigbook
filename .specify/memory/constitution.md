<!--
Sync Impact Report
Version change: (template) → 1.0.0
Bump rationale: Initial ratification — first concrete constitution filled in from template placeholders.
Modified principles: n/a (all six were placeholder slots, now defined)
Added sections:
  - Core Principles I–VI (Offline-First & Local Data Ownership, ChordPro Standard Fidelity,
    Stage-Ready UX, Test-First for Core Logic, Simplicity & YAGNI, Flutter & Material Idioms)
  - Technology Constraints
  - Development Workflow & Quality Gates
  - Governance
Removed sections: none
Templates requiring updates:
  ✅ .specify/templates/plan-template.md (Constitution Check section — generic, already references
     "Constitution Check" gate; no principle-specific rewording needed)
  ✅ .specify/templates/spec-template.md (no constitution-specific references to reconcile)
  ✅ .specify/templates/tasks-template.md (task categorization is generic; test-first and simplicity
     principles map to existing "Tests" and "Polish" phases without structural changes)
  ✅ .specify/templates/commands/*.md (n/a — no commands directory with agent-specific references
     found under .specify/templates)
Follow-up TODOs: none
-->

# GigBook Constitution

## Core Principles

### I. Offline-First & Local Data Ownership
GigBook MUST function fully with no network connection: importing, browsing, editing, and
performing from a setlist all work offline. All song and setlist data is owned by the user and
stored locally (sqflite) by default; any sync or sharing feature (e.g. Drive sync, nearby
transfer) MUST be opt-in, additive, and never a prerequisite for core functionality. Features
MUST NOT silently require connectivity or a remote account to read or perform an already-imported
song.

**Rationale**: The app exists because musicians need reliable access to lyrics on stage, often in
venues with poor or no signal. A dependency on network availability at the wrong moment is a
functional regression, not a minor inconvenience.

### II. ChordPro Standard Fidelity
The ChordPro parser and renderer MUST track the published ChordPro standard (chordpro.org) for
directives, chord notation (`[Chord]`), and section markup (`{soc}`/`{eoc}`, `{start_of_verse}`,
etc.), treating unsupported directives as no-ops rather than parse failures. Import MUST accept
`.cho`, `.crd`, `.pro`, and plain `.txt` files without data loss: unrecognized syntax is preserved
in the raw text and displayed, never silently dropped. Any deviation from the standard (custom
directives, GigBook-specific extensions) MUST be clearly isolated in the parser and documented as
an extension, not mixed into standard-directive handling.

**Rationale**: ChordPro is a widely-used interchange format; users bring in files authored in
other tools (OnSong, Songbook Pro, plain text archives). Fidelity to the standard is what makes
import trustworthy — a song that looks wrong on stage is worse than one that fails to import.

### III. Stage-Ready UX
Every screen reachable during a performance (song view, setlist navigation, autoscroll, chord
toggle) MUST prioritize legibility and speed of interaction over visual density: large adjustable
text, high-contrast dark mode, and no more than one tap/swipe to move between songs in a setlist.
Chords are secondary to lyrics by default — the chords on/off toggle MUST remain a first-class,
always-reachable control, not buried in settings. Destructive actions (delete song, delete
setlist) MUST require explicit confirmation; navigation and viewing actions MUST NOT.

**Rationale**: The primary use case is a performer reading a screen mid-song, often in low light,
with no time to hunt through menus. UX decisions are graded against "can I read this at a glance
on a dark stage," not general mobile design trends.

### IV. Test-First for Core Logic (NON-NEGOTIABLE)
Logic with no UI in the loop — the ChordPro parser, database access layer, import/matching
services, and setlist/library providers — MUST have tests written and failing before the
implementation that makes them pass, following Red-Green-Refactor. Widget/screen code MAY be
verified through manual/device testing (per the project's `run`/`verify` skills) instead of
exhaustive widget tests, but a parser or data-layer change without a corresponding test is not
complete. Regressions in parsing or data integrity are higher-severity than UI polish issues and
MUST block merging.

**Rationale**: The parser and database are the app's contract with the user's data; a silent
parsing bug or data-loss bug is far more costly than a layout glitch, and only tests catch these
before they reach a live gig.

### V. Simplicity & YAGNI
Prefer the simplest implementation that satisfies the current spec. Do not add abstractions,
configuration flags, or speculative extension points for features not yet specified (see the
project's deferred-features list — transpose, chord diagrams, cloud sync, tags, PDF export — as
examples of things to *not* build ahead of need). When a deferred feature is eventually specified,
its plan MUST justify any new abstraction introduced to support it rather than assuming one is
warranted.

**Rationale**: GigBook is a small, focused personal tool. Premature abstraction for hypothetical
future features has repeatedly cost more than the rework of adding them later would.

### VI. Flutter & Material Idioms
UI code follows standard Flutter composition patterns (small, focused widgets under `lib/widgets/`
and `lib/screens/`; no business logic embedded in build methods beyond trivial formatting). State
management uses `ChangeNotifier` providers (via the `provider` package) exclusively — no
introduction of a second state-management paradigm (Bloc, Riverpod, GetX, etc.) without a
constitution amendment. Visual design follows Material 3 conventions via the app's
`AppTheme.light`/`AppTheme.dark`, with any deviation (e.g. stage-mode high-contrast overrides)
implemented as an explicit theme variant rather than ad hoc per-widget styling.

**Rationale**: A single consistent state-management approach keeps a small codebase navigable;
mixing paradigms is a common source of confusion in Flutter apps that this project deliberately
avoids.

## Technology Constraints

- **Platform**: Flutter/Dart, SDK constraint `^3.9.2` as declared in `pubspec.yaml`; Android is the
  primary target, iPad is a secondary target — features MUST NOT assume Android-only APIs without
  a documented fallback or platform check.
- **Persistence**: `sqflite` for structured song/setlist data, `shared_preferences` for user
  settings only (theme, font size, scroll speed, chord visibility). Do not introduce a second
  persistence mechanism (e.g. Hive, Isar) for data that already fits the relational model.
- **Dependencies**: New third-party packages MUST be justified by a capability the Flutter SDK or
  an existing dependency cannot reasonably provide, and MUST support both Android and iOS unless
  the feature itself is platform-specific (e.g. SAF/storage-access-framework packages are
  Android-only by nature and acceptable as such).
- **Linting**: `flutter_lints` rules are the baseline; code MUST pass `flutter analyze` with no new
  warnings before merge.

## Development Workflow & Quality Gates

- Features follow the Spec-Driven Development flow already established by this project's tooling:
  `/speckit-specify` → `/speckit-clarify` (as needed) → `/speckit-plan` → `/speckit-tasks` →
  `/speckit-implement`, with `/speckit-analyze` available to check spec/plan/tasks consistency
  before implementation begins.
- Every plan produced by `/speckit-plan` MUST include a Constitution Check against the principles
  above; any violation MUST be justified in the plan's Complexity Tracking section or the
  simpler alternative adopted instead.
- Non-trivial code changes MUST be exercised end-to-end (via the `run` or `verify` skills) before
  being reported complete — passing tests alone do not confirm a feature behaves correctly on
  device.
- Code review (via `/code-review` or manual review) checks for adherence to these principles,
  especially Test-First for Core Logic and Simplicity & YAGNI, before a change is considered done.

## Governance

This constitution supersedes ad hoc practice for all work in this repository. Amendments are made
via `/speckit-constitution` and MUST:

1. State the change and rationale explicitly.
2. Bump `CONSTITUTION_VERSION` per semantic versioning: MAJOR for incompatible principle removals
   or redefinitions, MINOR for new principles or materially expanded guidance, PATCH for wording
   and clarification fixes.
3. Propagate to `.specify/templates/plan-template.md`, `spec-template.md`, and `tasks-template.md`
   if those templates reference affected principles, recording the outcome in a Sync Impact Report
   at the top of this file.

All plans and reviews MUST verify compliance with this constitution; unresolved violations block
merge. Complexity that violates Simplicity & YAGNI (Principle V) must be justified in writing in
the relevant plan before it is accepted.

**Version**: 1.0.0 | **Ratified**: 2026-07-08 | **Last Amended**: 2026-07-08
