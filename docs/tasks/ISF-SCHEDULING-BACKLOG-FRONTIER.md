# ISF-SCHEDULING-BACKLOG-FRONTIER

Status: active

Roadmap lane: R14 / ISF scheduling, activation, CDC, ATL, actor-network, and generated-child surfaces

Created: 2026-06-10

Current frontier: `ISF-SCHEDULING-BACKLOG-FRONTIER.2.1`

## Goal

Own the seven deferred ISF scheduling/control-flow areas called out from the
user-facing book backlog and drive them one exact, recoverable implementation
leaf at a time.

This tree exists because the book backlog text is intentionally broad. It is
not direct permission to edit code. Each branch below must select a specific
leaf with an explicit contract, acceptance criteria, tests, and book/spec sync
before any source, test, generated-artifact, or config change starts.

## Source Backlog

This tree owns these book-deferred areas:

- direct `(on ...)` activation parameter overrides; currently `(on ...)` is an
  entry guard, not a generated activation site
- deeper or more general nested repeat-body `do` / `spawn` combinations
- broader outstanding-child lifetime rules beyond the current "must drain
  before repeat re-entry" model
- repeated/nested ATL triggers and waits
- fan-in/fan-out event joins
- broader actor-network scheduling and group scheduling
- generated-child top surfaces beyond the covered spawn, generated `do`, and
  rule-trigger cases

Primary book anchors at creation time:

- `docs/book/src/14-feature-backlog.md`, around the deferred activation and
  scheduling backlog entries
- `docs/book/src/13d-control-flow.md`, around the shipped child-activation
  surfaces and deferred boundaries

## Non-Goals

- Do not implement all seven surfaces in one slice.
- Do not broaden runtime semantics without a focused leaf and explicit tests.
- Do not invent hidden dynamic behavior for a surface whose source syntax has
  no generated activation site; record or improve the fail-closed contract
  instead.
- Do not edit frozen legacy prose logs (`CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`,
  `LIVE_ACHIEVEMENT_STATUS.md`).

## Acceptance

- Every user-requested bullet has a named task-tree branch.
- The first implementation branch is selected and made recoverable from the
  task tree plus `MEMORY.md`.
- For each implementation leaf:
  - current shipped behavior is reproduced or audited first;
  - source/test/book/spec changes are kept inside the selected leaf;
  - mdBook and public contract wording match the resulting behavior;
  - focused checks plus broader gates appropriate to the blast radius pass;
  - commit subject starts with the work-unit id.

## Task Tree

### ISF-SCHEDULING-BACKLOG-FRONTIER.1 — Create Frontier And Select First Leaf

Status: done

Goal: Convert the seven deferred scheduling/control-flow bullets into an
active, owned R14 task tree and select the first exact branch.

Acceptance:

- Task-tree index links this file as active.
- Each deferred bullet has a child branch below.
- First executable leaf is selected without source/test edits.

Evidence:

- Selected `ISF-SCHEDULING-BACKLOG-FRONTIER.2.1` because it is the first
  source-order backlog item and has the largest semantic ambiguity: direct
  `(on ...)` currently names an entry guard, while parameter overrides require
  a generated activation site. The first implementation slice must either
  implement a narrow explicit activation contract or preserve the boundary with
  tests, diagnostics, and book wording.

### ISF-SCHEDULING-BACKLOG-FRONTIER.2 — Direct `(on ...)` Activation Parameter Overrides

Status: active

Goal: Resolve the deferred question of parameter overrides on direct
`(on ...)` entries, where the current surface is an entry guard rather than a
generated child activation.

#### ISF-SCHEDULING-BACKLOG-FRONTIER.2.1 — Direct-On Override Contract Slice

Status: pending

Goal: Audit the parser/lowerer/runtime contract for override-like direct
`(on ...)` forms and make one signoff-level change: either ship the smallest
explicitly testable generated activation surface if the architecture supports
it, or tighten the fail-closed diagnostic and book/spec wording if the current
surface cannot carry call-site values.

Acceptance:

- Reproduce current behavior for at least one override-like direct `(on ...)`
  example.
- If implementation is viable, add the smallest supported syntax/lowering path
  and a runnable example proving typed override value propagation.
- If implementation is not viable without a new source surface, add or tighten
  the targeted diagnostic and document why direct `(on ...)` remains an entry
  guard rather than a call site.
- Update `docs/book/` and any public spec text impacted by the result.
- Run focused ISF tests and the memory-architecture gate before commit.

### ISF-SCHEDULING-BACKLOG-FRONTIER.3 — Deeper Nested Repeat-Body `do` / `spawn`

Status: pending

Goal: Extend or close the remaining deeper/general nested repeat-body child
activation combinations beyond the currently covered local, generated, loop,
and branch forms.

Acceptance:

- Select exact syntax/context pair before implementation, such as a specific
  repeat-contained branch/loop/control body.
- Prove no regression to current repeat drain/re-entry guarantees.
- Sync the 13d control-flow examples and backlog matrix.

### ISF-SCHEDULING-BACKLOG-FRONTIER.4 — Outstanding-Child Lifetime Rules

Status: pending

Goal: Define and implement exact outstanding-child lifetime semantics beyond
the current repeat re-entry drain rule.

Acceptance:

- Select one exact lifetime rule first: e.g. cancellation, generation-tagged
  completion, parent-exit drain, or explicit detach.
- Prove behavior under local and generated child activation where applicable.
- Document the resulting hardware scheduling contract.

### ISF-SCHEDULING-BACKLOG-FRONTIER.5 — Repeated/Nested ATL Triggers And Waits

Status: pending

Goal: Extend ATL trigger/wait lowering for repeated and nested transaction
flows without breaking existing single-trigger behavior.

Acceptance:

- Select one exact repeated or nested ATL pattern before implementation.
- Prove trigger pulse ordering and wait completion with focused tests.
- Sync ATL and control-flow book examples.

### ISF-SCHEDULING-BACKLOG-FRONTIER.6 — Fan-In/Fan-Out Event Joins

Status: pending

Goal: Add or close exact fan-in/fan-out event join semantics across the ISF
event/trigger surfaces.

Acceptance:

- Select a precise join surface first, such as all-of/any-of completion over
  named events or child completions.
- Prove deterministic lowering and failure behavior for malformed joins.
- Document example use cases and limits.

### ISF-SCHEDULING-BACKLOG-FRONTIER.7 — Actor-Network And Group Scheduling

Status: pending

Goal: Broaden actor-network and group scheduling only through exact, testable
increments.

Acceptance:

- Select one scheduling primitive or grouping rule before implementation.
- Prove arbitration, ordering, or CDC behavior as applicable.
- Keep actor-network docs aligned with generated HDL behavior.

### ISF-SCHEDULING-BACKLOG-FRONTIER.8 — Generated-Child Top Surface Widening

Status: pending

Goal: Cover generated-child top surfaces beyond the currently documented spawn,
generated `do`, and rule-trigger cases.

Acceptance:

- Select one generated-child source surface before implementation.
- Prove naming, interface, and completion semantics.
- Document how the surface relates to existing generated child activation.

## Verification Log

- 2026-06-10 (`.1`): task-tree owner created; implementation not started yet.
  `scripts/check_memory_architecture.sh`, `git diff --check`, and
  `prove -Iperl t/1414-docs-relative-paths-audit.t` pass.

## Commit Log

- Pending: `ISF-SCHEDULING-BACKLOG-FRONTIER.1`.
