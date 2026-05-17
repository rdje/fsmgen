# ISF-DYNAMIC-WAIT-STAGE-SAMPLE: Dynamic Wait Samples Before Stage Successors

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-STAGE-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into a
top-level transaction `stage` state while preserving the stage ready/valid
barrier.

## Non-Goals

- Supporting nested stage clauses.
- Changing stage syntax, endpoint validation, or ready/valid timing.
- Supporting temporal contract or loop/check-state zero-count successors.
- Changing positive-count dynamic wait timing, sampled counter behavior, or
  existing drive/await/static-wait/completion/data-op/consecutive zero-bypass
  semantics.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (stage ...)` sequence lowers when the
  stage state is the zero-count successor.
- The accepted zero-count path uses a sample-preserving stage clone that
  drives the original `valid` signal and preserves the original ready-gated
  transition.
- Positive-count paths still sample in the first active wait state and then
  enter the original stage state without double-sampling.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-STAGE-SAMPLE`
  Status: `done`
  Goal: `Ship stage zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into stage states.`
  Acceptance: `Focused wait tests prove sample-preserving stage clones, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1: allow stage zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1` | `done` | Stage is the next bounded zero-count successor whose timing is already explicit in the scheduler IR. |

## Decisions

- `2026-05-16`: Limit this slice to top-level transaction stage states. The
  zero-count clone carries pending samples, keeps the original stage `valid`
  assignment, and preserves the ready-gated transition.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1` | syntax checks; focused stage/wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused tests `Files=3, Tests=136`; ISF gate `Files=227, Tests=1020`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1` | `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1: allow stage zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the stage successor
  pending-sample dynamic wait leaf.
- `2026-05-16`: Shipped sample-preserving stage zero-count clones for
  pending-sample runtime waits, synchronized the live specs/mdBook/downstream
  handoff/public contract, and passed focused plus full ISF validation.
