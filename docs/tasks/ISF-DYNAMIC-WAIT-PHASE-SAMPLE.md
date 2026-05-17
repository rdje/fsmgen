# ISF-DYNAMIC-WAIT-PHASE-SAMPLE: Phase Successor Pending-Sample Dynamic Waits

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-PHASE-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass into
transaction-level `(phase ...)` pass-through states.

## Non-Goals

- Changing actor-level phase metadata semantics.
- Changing transaction phase syntax, report metadata, or pass-through
  scheduling outside this zero-count clone path.
- Generalizing every empty sequential state into a sample-compatible
  successor.

## Acceptance Criteria

- `(sample SRC as HOLD) (wait count) (phase name ...)` lowers with a
  zero-count clone that materializes `HOLD` and preserves the phase state's
  pass-through transition.
- Positive-count paths still sample in the first active wait state and then
  enter the original phase state without double-sampling.
- The original transaction phase state remains the positive-count successor
  reported for the runtime wait.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-PHASE-SAMPLE`
  Status: `done`
  Goal: `Ship transaction phase pending-sample zero bypass for runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1`
  Status: `done`
  Goal: `Allow transaction phase states to carry pending samples on zero-count runtime waits.`
  Acceptance: `Focused wait tests prove phase zero-count clones, docs are synchronized, and ISF gates pass.`
  Verification: `syntax checks; focused wait/book audit tests; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1: allow phase successor zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1` | `done` | Transaction phase states now zero-bypass by preserving their pass-through timing contract. |

## Decisions

- `2026-05-16`: Treat transaction-level phase states as sample-compatible
  zero-count successors because they are explicit pass-through schedule
  markers with no data assignment or guard to consume pending samples.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1244-isf-wait-clause-lowering.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `focused Files=2, Tests=144; ISF gate Files=227, Tests=1031; book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1` | `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1: allow phase successor zero-sample waits` | `pending commit hash; leaf completed and ready for COMMIT.md workflow` |

## Changelog

- `2026-05-16`: Created task tree and started the transaction phase successor
  pending-sample dynamic wait leaf.
- `2026-05-16`: Closed `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1` after shipping
  sample-preserving zero-count clones for transaction phase pass-through
  successors and synchronizing the ISF spec, downstream handoff, public
  contract, mdBook, roadmap, README, and live docs.
