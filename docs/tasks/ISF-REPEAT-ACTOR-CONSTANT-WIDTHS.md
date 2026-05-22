# ISF-REPEAT-ACTOR-CONSTANT-WIDTHS: Repeat Actor-Constant Widths

## Metadata

- Tree ID: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS`
- Status: `completed`
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
  Status: `completed`
  Goal: `ship actor constants as repeat counter width evidence`
  Children: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `select the repeat actor-constant width task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `730c3d84 ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1: select repeat actor-constant widths`

- ID: `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `implement and document actor-constant repeat counter width inference`
  Acceptance: `actor constants drive repeat counter width inference; existing repeat semantics and dynamic counts are preserved; docs and focused tests are synchronized`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1102-isf-repeat-counter-widths.t`; `prove -Iperl t/1102-isf-repeat-counter-widths.t t/1202-isf-repeat-clause-boundary.t t/1244-isf-wait-clause-lowering.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2` | `done` | Actor-constant repeat width evidence is shipped and the tree is closed. |

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
| 2026-05-22 | `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1102-isf-repeat-counter-widths.t`; focused repeat tests; public/doc audits; `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with `Files=238, Tests=1590`; `git diff --check` | Pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1` | `730c3d84 ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1: select repeat actor-constant widths` | Selection commit. |
| `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2` | `pending this commit: ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2: ship repeat actor-constant widths` | Implementation commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for actor constants as repeat
  counter width evidence.
- `2026-05-22`: Shipped actor constants as repeat counter width evidence
  while preserving authored repeat load tokens and existing runtime repeat
  semantics.
