# ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS: Watchdog Actor-Constant Limits

## Metadata

- Tree ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow watchdog limits to use declared actor constants anywhere the shipped
positive literal watchdog limit is accepted.

## Non-Goals

- Do not accept actor parameters, transaction parameters, runtime signals, or
  arbitrary expressions as watchdog limits.
- Do not change omitted watchdog defaults, watchdog counter decrement/timeout
  semantics, reset behavior, or schedule-report schema shape.
- Do not add cross-domain watchdog policy or parameterized generated-top
  watchdog specialization.

## Acceptance Criteria

- Actor-level `(watchdog LIMIT_CONST)` lowers when `LIMIT_CONST` is a declared
  actor constant whose resolved value is positive.
- Await-local `(await ready (watchdog LIMIT_CONST))` lowers through the same
  watchdog counter path as a literal override.
- Literal watchdog limits keep existing behavior and diagnostics.
- Unknown, zero-valued, parameter-backed, runtime, and expression watchdog
  limit tokens remain fail-closed with targeted diagnostics.
- The ISF spec, mdBook, downstream/public guidance where relevant, roadmap
  status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS`
  Status: `active`
  Goal: `ship positive actor constants as watchdog limits`
  Children: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1`,
  `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2`

- ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1`
  Status: `done`
  Goal: `select the watchdog actor-constant limits task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2`
  Status: `pending`
  Goal: `implement and document actor-constant watchdog limits`
  Acceptance: `positive actor constants lower as literal watchdog limits; unsupported watchdog tokens fail closed; docs and focused tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2` | `pending` | The tree is selected; the implementation leaf owns the parser/lowerer, tests, and user-facing docs. |

## Decisions

- `2026-05-22`: Treat actor constants as static compile-time evidence for
  watchdog limits, matching transaction wait counts, transaction latency
  bounds, and temporal contract windows. Parameters remain out of scope
  because they are overrideable specialization values.
- `2026-05-22`: Preserve the public watchdog scalar as the resolved integer
  limit. The authored constant remains visible through `actor_constants[]`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1` | `mdbook build docs/book`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1` | `pending this commit: ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1: select watchdog actor-constant limits` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for positive actor constants in
  actor-level and await-local watchdog limits.
