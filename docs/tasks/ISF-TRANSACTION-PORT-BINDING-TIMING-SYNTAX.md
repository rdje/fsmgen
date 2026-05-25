# ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX: Transaction Port Binding Timing Syntax

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Add an explicit author-facing timing selection spelling for transaction input
bindings, bounded to the current snapshot-like activation payload and
generated-top live handoff timing classes before any behavior-changing timing
conversion is attempted.

## Non-Goals

- Do not change binding timing, generated `.fsm`, HDL, schedule-report schema,
  or runtime behavior in the selection leaf.
- Do not add direct/local rule-trigger output bindings.
- Do not add timing selection to output bindings; output timing remains owned
  by child completion or generated-top output handoff semantics.
- Do not add new storage or continuous local wiring to convert one timing mode
  into another in this tree's first implementation leaf.

## Acceptance Criteria

- The selected spelling is a fourth per-input-binding subclause:
  `(input PORT EXPR (timing snapshot))` or
  `(input PORT EXPR (timing live))`.
- `snapshot` means the transaction input sees the activation or trigger
  payload captured at the call/trigger boundary.
- `live` means the transaction input is supplied through generated-top live
  handoff wiring.
- The first implementation leaf accepts explicit spelling only where it
  matches the already-shipped timing class and rejects mismatched mode/site
  combinations fail-closed.
- Specs, downstream handoff, mdBook, task tree, roadmap status, and live docs
  describe the selected syntax and non-claims.
- Focused parser/lowering/report/public-contract validation passes; broader
  ISF validation runs when implementation blast radius warrants it.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX`
  Status: `active`
  Goal: `Add explicit bounded timing selection syntax for transaction input bindings.`
  Children: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.1`,
  `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2`

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.1`
  Status: `done`
  Goal: `Select the public input-binding timing syntax and first implementation boundary.`
  Acceptance: `The task tree, roadmap, live docs, and mdBook feature backlog select the fourth-subclause timing spelling, snapshot/live meanings, and fail-closed current-timing-only first implementation boundary.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff --check`
  Commit: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.1: select binding timing syntax`

- ID: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2`
  Status: `pending`
  Goal: `Implement explicit current-timing input binding syntax.`
  Acceptance: `Input bindings may spell timing snapshot or timing live only where the spelling matches the existing binding_timing class; unsupported or output-binding timing selections reject clearly; docs/book/tests/public metadata stay synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2` | `pending` | Selection leaf is complete; implementation is the next bounded R14 syntax slice. |

## Decisions

- `2026-05-25`: Put timing selection inside each input binding entry instead
  of as an activation-wide option, because a single activation may bind
  multiple ports and later richer modes may need per-port diagnostics.
- `2026-05-25`: Use `snapshot` for activation/trigger payload capture and
  `live` for generated-top live handoff wiring. These names match the
  user-facing timing model, while `binding_timing` keeps the more precise
  report taxonomy.
- `2026-05-25`: The first implementation must accept only current-timing
  spellings and fail closed for mismatches. Behavior-changing timing
  conversion needs a separate storage/wiring design.

## Open Questions

- None for the selected frontier. Broader timing conversion is explicitly
  outside the first implementation boundary.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.1` | `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.1: select binding timing syntax` | `selection commit` |
| `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2` | `pending` | `pending implementation` |

## Changelog

- `2026-05-25`: Created active task tree and completed the selection leaf for
  explicit input-binding timing syntax.
