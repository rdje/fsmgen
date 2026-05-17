# ISF-SPAWN-IN-REPEAT: Static Child Spawn Inside Repeat Bodies

## Metadata

- Tree ID: `ISF-SPAWN-IN-REPEAT`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow a repeat body to activate a lexically named static generated child
instance without implying dynamic hardware creation.

## Non-Goals

- Creating one child instance per repeat iteration.
- Supporting child activation inside nested branch/loop bodies in the first
  implementation slice.
- Supporting repeat-body `do`, repeat-body spawn parameter overrides, repeat
  body port bindings, or repeat-body cross-domain activation in the first
  implementation slice.
- Changing top-level `spawn`, `await_all`, or `await_any` semantics outside
  the repeat-body subset.

## Acceptance Criteria

- The shipped-first source contract is documented before implementation:
  top-level repeat bodies may contain plain `(spawn child as inst)` followed
  by a same-body `(await_all done)` before the repeat check can loop.
- The lexical spawn name denotes one static child instance in the generated
  top, reused across repeat iterations.
- The implementation leaf must prove the repeat loop cannot re-enter the same
  child instance before observing its fresh done pulse.
- Unsupported repeat-body child activation forms fail closed with targeted
  diagnostics.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized for any shipped behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SPAWN-IN-REPEAT`
  Status: `active`
  Goal: `Ship the first safe repeat-body spawn subset.`
  Children: `ISF-SPAWN-IN-REPEAT.1`, `ISF-SPAWN-IN-REPEAT.2`

- ID: `ISF-SPAWN-IN-REPEAT.1`
  Status: `done`
  Goal: `Select and document the first safe repeat-body spawn contract.`
  Acceptance: `Task tree and book backlog name the exact first implementation subset and exclusions.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-SPAWN-IN-REPEAT.1: select repeat spawn contract`

- ID: `ISF-SPAWN-IN-REPEAT.2`
  Status: `pending`
  Goal: `Implement top-level repeat-body spawn followed by await_all.`
  Acceptance: `Lowering, generated-top wiring, fail-closed diagnostics, docs, and ISF gates prove the safe subset.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-SPAWN-IN-REPEAT.1` | `done` | The first safe repeat-body spawn contract is selected and documented. |
| 2 | `ISF-SPAWN-IN-REPEAT.2` | `pending` | Implements the documented first subset after the policy is pinned down. |

## Decisions

- `2026-05-16`: The first implementation subset will be top-level repeat
  bodies containing plain `spawn` clauses whose pending child done ports are
  consumed by a same-body `await_all` before the repeat check can loop.
- `2026-05-16`: `await_any`, repeat-body `do`, activation parameter
  overrides, activation port bindings, activation domain overrides, and
  nested branch/loop repeat-body spawn forms remain deferred until their
  re-entry and report contracts are specified.

## Open Questions

- None for the first subset.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-05-16` | `ISF-SPAWN-IN-REPEAT.1` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SPAWN-IN-REPEAT.1` | `ISF-SPAWN-IN-REPEAT.1: select repeat spawn contract` | `pending commit hash; leaf completed and ready for COMMIT.md workflow` |

## Changelog

- `2026-05-16`: Created task tree and selected the repeat-body spawn
  re-entry contract as the next R14 PNT feature family.
- `2026-05-16`: Closed `ISF-SPAWN-IN-REPEAT.1` after documenting the first
  implementation subset and exclusions in the book backlog.
