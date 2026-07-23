# IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT: Audit Sequential Wrap Address Updates

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT`
- Status: `proposed`
- Roadmap lane: `IAL2 / AHB requester correctness`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
- Owner: repo-local workflow

## Goal

Determine whether the generated AHB requester advances a wrapping burst to
`wrap_base_q + addr_step_q` instead of `wrap_base_q` at the wrap boundary, and
select the smallest proven repair if runtime evidence confirms the risk.

## Origin And Evidence

Inspection during `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.2` found the
same sequential-clause mutation pattern that caused the terminal count
underflow. Inside `when wrap_mode_q`, the first clause compares
`addr_q + addr_step_q` with `wrap_high_q` and may write `addr_q = wrap_base_q`;
the following negated-equality clause can then re-evaluate using the newly
written address and write `addr_q = addr_q + addr_step_q`.

This is a latent risk established by source/FSM semantics, not yet a
runtime-proven defect. It is recorded rather than folded into the terminal
counter repair because `.2` owns only `SINGLE`/`INCR4` completion and the
pending BUSY-insertion slice must not expand into unselected WRAP behavior.

## Non-Goals

- Do not activate this direction while the current AHB BUSY-insertion task is
  still in flight.
- Do not change wrap arithmetic, burst admission, or public surfaces without a
  generated-HDL reproduction and selected contract.
- Do not alter non-wrap address progression.

## Acceptance Criteria (when activated)

- Add a generated-HDL `WRAP4` boundary probe that records every accepted-beat
  address and distinguishes `wrap_base_q` from `wrap_base_q + addr_step_q`.
- Trace the emitted IAL1/FSM states to confirm or disprove re-evaluation after
  the first address write.
- If confirmed, select and implement a mutually exclusive wrap/non-wrap
  progression that preserves `SINGLE`/`INCR4` and other shipped behavior.
- Synchronize the requester behavior record, mdBook, Knowledge Map, tests,
  task/Memory, and all relevant gates before commit.

## Task Tree

- ID: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT`
  Status: `proposed`
  Goal: `Runtime-prove or disprove the suspected sequential WRAP address-update defect before selecting any repair.`
  Children: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1`

- ID: `IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT.1`
  Status: `pending`
  Goal: `Probe generated-HDL WRAP4 boundary progression and select a repair only if the risk reproduces.`
  Acceptance: `Build a deterministic public-requester WRAP4 runtime probe, record accepted-beat addresses through the boundary, correlate any wrong base-plus-step result with the sequential generated states, and either close the concern with evidence or select a bounded implementation leaf. Make no behavior change in the audit.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-23`: Keep this tree proposed and inactive. It is a distinct
  unproven WRAP concern, not part of the terminal-count prerequisite or the
  already-selected requester BUSY-insertion contract.

## Blockers

- Activation/order follows the task-tree pivot doctrine after ongoing active
  work dries out.
