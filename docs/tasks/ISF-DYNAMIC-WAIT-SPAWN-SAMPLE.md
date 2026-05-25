# ISF-DYNAMIC-WAIT-SPAWN-SAMPLE: Spawn Successor Pending-Sample Dynamic Waits

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass into top-level
`spawn` states when the generated spawn start handoff does not touch the
pending sample aliases.

## Non-Goals

- Changing `spawn` syntax, generated child specialization, generated-top
  wiring, or child lifetime semantics.
- Supporting blocking `do` successors; that has input/output binding and
  completion-wait behavior and remains a separate slice.
- Supporting `spawn` inside inline branch or loop bodies.

## Acceptance Criteria

- `(sample SRC as HOLD) (wait count) (spawn child as inst)` lowers with a
  zero-count clone that materializes `HOLD` and asserts the original
  `inst_start` spawn handoff.
- Positive-count paths still sample in the first active wait state and then
  enter the original spawn state without double-sampling.
- Spawn states whose generated start handoff touches a pending sample alias
  remain fail-closed.
- Generated-top and HDL reachability for the accepted shape stay intact.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE`
  Status: `done`
  Goal: `Ship spawn-state pending-sample zero bypass for runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1`
  Status: `done`
  Goal: `Allow independent spawn states to carry pending samples on zero-count runtime waits.`
  Acceptance: `Focused wait tests prove spawn zero-count clones, alias-touching spawn starts reject, docs are synchronized, and ISF gates pass.`
  Verification: `syntax checks; focused wait/book audit tests; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1: allow spawn successor zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1` | `done` | Spawn states now zero-bypass when their generated start handoff is independent of pending sample aliases. |

## Decisions

- `2026-05-16`: Treat top-level spawn states as sample-compatible zero-count
  successors only when their generated `spawn_start` assignment does not read
  or overwrite pending sample aliases. Blocking `do` remains separate because
  it also owns input/output bindings and a completion guard.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1244-isf-wait-clause-lowering.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `focused Files=2, Tests=142; ISF gate Files=227, Tests=1029; book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1` | `2fdd09b3 ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1: allow spawn successor zero-sample waits` | `completion commit` |

## Changelog

- `2026-05-16`: Created task tree and started the spawn successor
  pending-sample dynamic wait leaf.
- `2026-05-16`: Closed `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1` after shipping
  sample-preserving zero-count clones for top-level `spawn` successors and
  synchronizing the ISF spec, downstream handoff, public contract, mdBook,
  roadmap, README, and live docs.
