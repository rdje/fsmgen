# ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE: Dynamic Wait Samples Across Consecutive Runtime Waits

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow a pending sample before consecutive top-level runtime dynamic waits to
cross zero-count wait edges without being lost or materialized in the wrong
cycle.

## Non-Goals

- Supporting sample-consuming data operations after the final consecutive wait
  beyond the currently shipped independent-successor surface.
- Changing no-pending-sample consecutive runtime wait lowering.
- Changing positive-count timing for any runtime wait.
- Supporting unsupported stage, contract, or loop/check-state zero-count
  successors that still cannot carry pending samples.

## Acceptance Criteria

- `(sample ...) (wait first) (wait second) ...` lowers when the final
  zero-count target is sample-compatible.
- If the first wait is zero and the second wait is positive, the pending
  sample materializes in a generated second-wait entry clone, not in the
  predecessor state and not in the original second wait used by positive first
  waits.
- If both waits are zero, the pending sample materializes in a generated
  zero-count clone of the final compatible target.
- Focused tests prove both mixed zero/positive and all-zero paths, plus
  existing consecutive and independent-successor behavior.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE`
  Status: `done`
  Goal: `Ship pending-sample preservation across consecutive runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending samples to cross consecutive runtime wait zero-bypass paths.`
  Acceptance: `Focused wait tests prove carried pending samples materialize on second-wait positive paths and final all-zero compatible targets, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1: carry samples across consecutive runtime waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1` | `done` | Consecutive pending-sample runtime waits are the next documented fail-closed R14 zero-bypass gap after independent bank stores. |

## Decisions

- `2026-05-16`: Keep the slice to top-level consecutive runtime waits. A
  zero first wait carries the pending sample into a generated second-wait
  entry clone for positive second counts, or into the final compatible
  zero-count clone when all consecutive wait counts are zero.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1` | syntax checks; focused wait tests; focused wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused wait tests `Files=1, Tests=31`; focused wait/book audit tests `Files=2, Tests=131`; ISF gate `Files=227, Tests=1018`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1` | `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1: carry samples across consecutive runtime waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the consecutive pending-sample
  dynamic wait leaf.
- `2026-05-16`: Shipped pending-sample carrying across consecutive top-level
  runtime wait zero-count links, synchronized the live specs/mdBook/downstream
  handoff/public contract, and passed focused plus full ISF validation.
