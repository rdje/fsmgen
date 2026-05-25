# NO-RESET-SCHEDULED-FSM-HDL: No-Reset Scheduled FSM HDL

## Metadata

- Tree ID: `NO-RESET-SCHEDULED-FSM-HDL`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow explicit scheduled `.fsm` artifacts with a clock-only `+system` section
to generate Verilog-family HDL without inventing a reset port or reset branch.

## Non-Goals

- Do not change reset-bearing `sreset`, `areset`, or legacy `asreset`
  behavior.
- Do not infer a reset when an authored `+system` section omits one.
- Do not add reset initial-state semantics to reset-free HDL.
- Do not widen VHDL backend support.
- Do not add payload CDC, FIFO-like CDC, or direct cross-domain data movement.

## Acceptance Criteria

- Direct `.fsm` parsing accepts `(+system (clock NAME))` as an explicit
  no-reset system contract.
- Verilog-family HDL for no-reset scheduled `.fsm` modules exposes the clock
  but no reset port and emits clock-only sequential blocks with no reset branch.
- Existing reset-bearing HDL output and reset diagnostics remain covered.
- The ISF no-reset acknowledged-event CDC fixture reaches generated
  SystemVerilog through the generated top and concrete CDC child instead of
  failing on the domain artifact `+system` contract.
- Public docs, downstream docs, mdBook, roadmap, task tree, README index, and
  live docs are synchronized.
- Focused direct-system and ISF CDC validation passes, broader gates run
  because this changes public syntax/backend behavior, and the leaf is
  committed through `COMMIT.md`.

## Task Tree

- ID: `NO-RESET-SCHEDULED-FSM-HDL`
  Status: `done`
  Goal: `Ship reset-free scheduled .fsm HDL for explicit clock-only +system contracts.`
  Children: `NO-RESET-SCHEDULED-FSM-HDL.1`

- ID: `NO-RESET-SCHEDULED-FSM-HDL.1`
  Status: `done`
  Goal: `Implement clock-only +system HDL support and unlock the no-reset CDC fixture HDL path.`
  Acceptance: `Direct no-reset .fsm HDL, ISF no-reset CDC HDL, docs/book sync, focused and broad validation, and commit workflow are complete.`
  Verification: `syntax checks; focused direct-system/ISF CDC Files=4, Tests=24; focused public-contract/book audits Files=6, Tests=359; ./bin/ci-regression quick Files=8, Tests=145; ./bin/ci-regression isf --no-book Files=275, Tests=1756; mdbook build docs/book; git diff --check`
  Commit: `NO-RESET-SCHEDULED-FSM-HDL.1: support clock-only HDL`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `NO-RESET-SCHEDULED-FSM-HDL.1` shipped reset-free scheduled `.fsm` HDL and unlocked the no-reset CDC fixture HDL path. |

## Decisions

- `2026-05-25`: Scope the slice to explicit clock-only `+system` contracts.
  Reset-free HDL does not get an inferred reset or synthetic initial state.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `NO-RESET-SCHEDULED-FSM-HDL.1` | syntax checks; focused direct-system/ISF CDC; focused public-contract/book audits; `./bin/ci-regression quick`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused direct/CDC `Files=4, Tests=24`; public/book `Files=6, Tests=359`; quick `Files=8, Tests=145`; ISF `Files=275, Tests=1756` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `NO-RESET-SCHEDULED-FSM-HDL.1` | `NO-RESET-SCHEDULED-FSM-HDL.1: support clock-only HDL` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created and activated task tree.
- `2026-05-25`: Implemented clock-only scheduled `.fsm` HDL support,
  synchronized docs, and closed the tree.
