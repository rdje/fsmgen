# ISF-COMPATIBILITY: Legacy Handshake And Removed Assign Surface

## Metadata

- Tree ID: `ISF-COMPATIBILITY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Decide and document the fate of legacy or removed ISF surfaces, especially
deprecated `(handshake ...)` metadata and the removed transaction `(assign ...)`
keyword, so compatibility behavior remains intentional rather than accidental.

## Non-Goals

- Do not make legacy forms semantic by default.
- Do not widen rule expression assignments here; that belongs to
  `ISF-RULE-ACTIONS`.
- Do not remove compatibility forms without migration diagnostics and docs.

## Acceptance Criteria

- Current parsing, validation, ignored behavior, and fail-closed diagnostics
  for legacy/removed forms are inventoried.
- Each compatibility surface has an explicit decision: keep ignored, make
  semantic, remove, or keep fail-closed with migration guidance.
- Diagnostics and docs match the decision for each surface.
- Tests cover accepted compatibility behavior, rejected behavior, migration
  hints, and CLI/in-process parity.
- ISF spec, public contract, mdBook, roadmap, and live docs agree.

## Task Tree

- ID: `ISF-COMPATIBILITY`
  Status: `active`
  Goal: `Resolve legacy handshake and removed assign compatibility policy.`
  Children: `ISF-COMPATIBILITY.1`, `ISF-COMPATIBILITY.2`,
  `ISF-COMPATIBILITY.3`, `ISF-COMPATIBILITY.4`, `ISF-COMPATIBILITY.5`

- ID: `ISF-COMPATIBILITY.1`
  Status: `pending`
  Goal: `Inventory current legacy handshake and removed assign behavior.`
  Acceptance: `The task file lists parser behavior, validation behavior,
  diagnostics, ignored metadata, fail-closed cases, tests, and docs.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPATIBILITY.2`
  Status: `pending`
  Goal: `Decide legacy handshake policy.`
  Acceptance: `The tree records whether the handshake metadata remains ignored,
  gains semantics, becomes rejected, or gets a migration path, with rationale.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPATIBILITY.3`
  Status: `pending`
  Goal: `Decide removed transaction assign policy.`
  Acceptance: `The tree records whether transaction assign stays rejected, gains a
  replacement, or maps to another construct, with migration diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPATIBILITY.4`
  Status: `pending`
  Goal: `Implement selected compatibility diagnostics or semantics.`
  Acceptance: `The selected policy is enforced consistently across parser,
  scheduler, CLI, and in-process facades.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-COMPATIBILITY.5`
  Status: `pending`
  Goal: `Add tests and synchronize docs/contracts.`
  Acceptance: `Focused tests and docs cover compatibility policy, rejected
  cases, migration hints, and public contract wording.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-COMPATIBILITY.1` | `pending` | Existing compatibility behavior must be inventoried before removal or semantic decisions are made. |

## Decisions

- `2026-05-14`: Legacy handshake and removed transaction `assign` are tracked
  together because both are compatibility surfaces whose policy should be
  explicit before further ISF feature widening.

## Open Questions

- Is keeping `(handshake ...)` as validated ignored metadata still useful, or
  should it become a strict rejection with migration guidance?
- Should transaction `(assign ...)` remain removed permanently, or should a
  new explicit construct replace its original intent?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-COMPATIBILITY` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COMPATIBILITY` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF compatibility-surface task tree.
