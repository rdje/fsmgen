# ISF-REPEAT-ACTOR-CONSTANT-WIDTHS: Repeat Actor-Constant Widths

## Metadata

- Tree ID: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Use declared actor constants as static width evidence for transaction repeat
counts.

## Non-Goals

- Do not change repeat runtime semantics, repeat counter load semantics, or
  repeat loop-back behavior.
- Do not add parameterized repeat specialization or generated-top
  respecialization.
- Do not change dynamic repeat counts sourced from sampled signals, ports,
  storage, or runtime expressions.

## Acceptance Criteria

- `(repeat COUNT_CONST body...)` infers the repeat counter width from the
  resolved actor constant value when `COUNT_CONST` names a declared
  non-negative actor constant.
- Existing literal and sampled/runtime repeat count behavior remains unchanged.
- Actor parameters, transaction parameters, and dynamic names keep their
  current dynamic-repeat treatment; no new parameter specialization is added.
- The ISF spec, mdBook, downstream/public guidance where relevant, roadmap
  status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS`
  Status: `active`
  Goal: `ship actor constants as repeat counter width evidence`
  Children: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `select the repeat actor-constant width task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2`
  Status: `pending`
  Goal: `implement and document actor-constant repeat counter width inference`
  Acceptance: `actor constants drive repeat counter width inference; existing repeat semantics and dynamic counts are preserved; docs and focused tests are synchronized`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2` | `pending` | The tree is selected; the implementation leaf owns the lowerer, tests, and user-facing docs. |

## Decisions

- `2026-05-22`: Treat actor constants as compile-time width evidence for
  repeat counters without changing the authored repeat load token. Scheduled
  `.fsm` can still show `(<= (main_cnt COUNT_CONST))` while the counter width
  uses the resolved value.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1` | `pending this commit: ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1: select repeat actor-constant widths` | Selection commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for actor constants as repeat
  counter width evidence.
