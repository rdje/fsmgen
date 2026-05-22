# ISF-LATENCY-ACTOR-CONSTANT-BOUNDS: Latency Actor-Constant Bounds

## Metadata

- Tree ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow transaction latency `(min ...)` and `(max ...)` bounds to use positive
actor constants anywhere the shipped positive literal bound is accepted.

## Non-Goals

- Do not accept actor parameters, transaction parameters, runtime signals, or
  arbitrary expressions as latency bounds.
- Do not change latency counter semantics, timeout-state semantics, latency
  report/storage roles, or generated HDL behavior beyond resolving static
  actor constants before existing lowering.
- Do not add stage-local latency or actor-level stage runtime semantics.

## Acceptance Criteria

- `(latency (min MIN_CONST) (max MAX_CONST))` lowers when each token is a
  declared actor constant whose resolved value is positive.
- Literal bounds keep existing behavior and diagnostics.
- Unknown, zero-valued, parameter-backed, and dynamic bound tokens remain
  fail-closed with targeted diagnostics.
- The ISF spec, mdBook, downstream/public guidance where relevant, roadmap
  status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS`
  Status: `active`
  Goal: `ship positive actor constants as transaction latency bounds`
  Children: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1`,
  `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2`

- ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1`
  Status: `done`
  Goal: `select the latency actor-constant bounds task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2`
  Status: `pending`
  Goal: `implement and document actor-constant transaction latency bounds`
  Acceptance: `positive actor constants lower as literal latency bounds; unsupported bound tokens fail closed; docs and focused tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2` | `pending` | The tree is selected; the implementation leaf owns the lowerer, tests, and user-facing docs. |

## Decisions

- `2026-05-22`: Treat actor constants as static compile-time evidence for
  latency bounds, matching wait counts and temporal contract windows.
  Parameters remain out of scope because they are overrideable specialization
  values.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1` | `mdbook build docs/book`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1` | `pending this commit: ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1: select latency actor-constant bounds` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for positive actor constants in
  transaction latency min/max bounds.
