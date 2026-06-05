# ISF-REMAINING-BROAD-FRONTIER: Remaining Broad ISF Frontier

## Metadata

- Tree ID: `ISF-REMAINING-BROAD-FRONTIER`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Own the broad ISF/R14 backlog items named in the 2026-06-05 remaining-work
inventory that are not already the active frontier of a narrower ISF tree.

## Non-Goals

- Do not supersede existing active ISF trees for their current frontier leaves.
- Do not implement ISF behavior before the exact leaf is selected and placed in
  the current frontier.
- Do not widen downstream-visible syntax, diagnostics, report keys, generated
  artifacts, or public contracts without activating a concrete leaf.

## Acceptance Criteria

- Each broad ISF backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- ISF public sync rules in `docs/TASK_TREE.md` apply to every activated leaf.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REMAINING-BROAD-FRONTIER`
  Status: `active`
  Goal: `Track broad remaining ISF/R14 backlog directions.`
  Children: `ISF-REMAINING-BROAD-FRONTIER.1`,
    `ISF-REMAINING-BROAD-FRONTIER.2`,
    `ISF-REMAINING-BROAD-FRONTIER.3`,
    `ISF-REMAINING-BROAD-FRONTIER.4`,
    `ISF-REMAINING-BROAD-FRONTIER.5`,
    `ISF-REMAINING-BROAD-FRONTIER.6`,
    `ISF-REMAINING-BROAD-FRONTIER.7`,
    `ISF-REMAINING-BROAD-FRONTIER.8`,
    `ISF-REMAINING-BROAD-FRONTIER.9`,
    `ISF-REMAINING-BROAD-FRONTIER.10`,
    `ISF-REMAINING-BROAD-FRONTIER.11`,
    `ISF-REMAINING-BROAD-FRONTIER.12`

- ID: `ISF-REMAINING-BROAD-FRONTIER.1`
  Status: `done`
  Goal: `Select the next executable broad ISF leaf from active evidence and backlog text.`
  Acceptance: `Activated this broad R14 tree after the previous active ISF frontier exhausted; selected the stage/wait/loop category and split its first exact executable leaf as ISF-REMAINING-BROAD-FRONTIER.7.1.`
  Verification: `Selection only: read docs/TASK_TREE.md, this task file, dynamic-wait backlog text, existing dynamic-wait task files, loop-control docs/tests, and LoweringIR loop_exit_when linking. No code/source behavior changed.`
  Commit: `this slice`

- ID: `ISF-REMAINING-BROAD-FRONTIER.2`
  Status: `pending`
  Goal: `Broaden ATL actor-network orchestration beyond the shipped bounded v0 contract.`
  Acceptance: `One exact ATL expansion is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.3`
  Status: `pending`
  Goal: `Explore and, if selected, specify IAL2 protocol/platform intent.`
  Acceptance: `IAL2 is either kept as horizon exploration or one executable design slice is selected.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.4`
  Status: `pending`
  Goal: `Broaden ISF enum, type, and aggregate parity.`
  Acceptance: `One exact enum/type/aggregate parity surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.5`
  Status: `pending`
  Goal: `Broaden resource kinds and arbiter policies.`
  Acceptance: `One exact resource kind or arbiter policy is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.6`
  Status: `pending`
  Goal: `Broaden priority-resolution cases.`
  Acceptance: `One exact same-cycle or same-target priority case is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.7`
  Status: `active`
  Goal: `Broaden transaction stages, waits, and dynamic loop combinations.`
  Children: `ISF-REMAINING-BROAD-FRONTIER.7.1`

- ID: `ISF-REMAINING-BROAD-FRONTIER.7.1`
  Status: `pending`
  Goal: `Support runtime waits immediately after loop-control decision states: (exit-when ...) / (continue-when ...) false edges must split a following runtime (wait ...) while true edges keep their exit/continue target.`
  Acceptance: `A while/until loop body with (exit-when COND) or (continue-when COND) followed by runtime (wait COUNT) lowers with the false edge sampling/entering/bypassing the generated dynamic wait, while the true edge still exits or continues. Focused tests cover exit-when and continue-when, docs/spec/public surfaces are synchronized, and ISF gates pass.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.8`
  Status: `pending`
  Goal: `Broaden transaction ports, pin access, report, and output surfaces.`
  Acceptance: `One exact port/report/output surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.9`
  Status: `pending`
  Goal: `Broaden temporal/property forms beyond the shipped formal/simulable subsets.`
  Acceptance: `One exact temporal/property form is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.10`
  Status: `pending`
  Goal: `Broaden schedule-report storage classes and fixture/library coverage.`
  Acceptance: `One exact report class, fixture promotion, or reusable-library surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.11`
  Status: `pending`
  Goal: `Broaden CDC semantics, including cross-domain spawn and payload movement.`
  Acceptance: `One exact CDC activation/payload/reset/remap surface is selected, implemented or deferred, synchronized, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-REMAINING-BROAD-FRONTIER.12`
  Status: `pending`
  Goal: `Confirm whether the full-width inference terminal remains closed or a new decidable subcase exists.`
  Acceptance: `A decidable width-inference subcase is selected for implementation or the existing fail-closed terminal is reaffirmed.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REMAINING-BROAD-FRONTIER.1` | `done` | Broad R14 frontier selected after the previous active ISF tree closed. |
| 2 | `ISF-REMAINING-BROAD-FRONTIER.7.1` | `pending` | First exact executable leaf: loop-control decision states currently link before dynamic-wait predecessor splitting, so a following runtime wait needs an owned splitter slice. |

## Decisions

- `2026-06-05`: Keep this tree proposed while the user-selected active focus is
  Composition/type. Immediate active ISF frontier leaves remain owned by their
  existing narrower task trees.
- `2026-06-05`: Activated after the active ISF frontier exhausted and selected the
  stage/wait/loop category first. Evidence: existing dynamic-wait zero-bypass owners are
  done, but `loop_exit_when` states created by `(exit-when ...)` / `(continue-when ...)`
  are linked before the generic dynamic-wait predecessor splitter in `LoweringIR`, making
  a following runtime wait a small exact executable gap.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `ISF-REMAINING-BROAD-FRONTIER.1` | Selection audit/read: `docs/TASK_TREE.md`, this task file, dynamic-wait backlog text, existing dynamic-wait task files, loop-control docs/tests, and `LoweringIR.pm` loop-control linking | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REMAINING-BROAD-FRONTIER.1` | `ISF-REMAINING-BROAD-FRONTIER.1: select loop-control dynamic waits` | this slice |
| `ISF-REMAINING-BROAD-FRONTIER.7.1` | `pending` | `pending` |

## Changelog

- `2026-06-05`: Created proposed broad ISF frontier owner tree.
- `2026-06-05`: `.1` activated the tree and selected `.7.1`, a loop-control
  dynamic-wait predecessor leaf for `(exit-when ...)` / `(continue-when ...)` followed by
  runtime `(wait ...)`.
