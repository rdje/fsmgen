# ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE: Dynamic Wait Samples Before Contract Successors

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into a
top-level bounded eventual `contract` arm state while preserving the monitor
arm pulse.

## Non-Goals

- Changing temporal contract syntax, monitor storage, assertion projection, or
  schedule-report schema.
- Supporting nested contract clauses or broader temporal operators.
- Supporting loop/check-state zero-count successors.
- Changing positive-count dynamic wait timing or existing compatible
  zero-bypass behavior.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (contract ...)` sequence lowers when
  the contract arm state is the zero-count successor.
- The accepted zero-count path uses a sample-preserving contract clone that
  emits the original one-cycle arm request and advances like the original
  contract state.
- Positive-count paths still sample in the first active wait state and then
  enter the original contract state without double-sampling.
- The contract monitor DT remains the sole owner of pending/age/fail storage.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE`
  Status: `done`
  Goal: `Ship contract zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into contract arm states.`
  Acceptance: `Focused wait/contract tests prove sample-preserving contract clones, docs are synchronized, and ISF gates pass.`
  Verification: `syntax checks; focused contract/wait/book audit tests; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1: allow contract zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1` | `done` | Contract arm states now zero-bypass when the bounded-eventual arm state is independent of pending samples. |

## Decisions

- `2026-05-16`: Limit this slice to top-level bounded eventual contract arm
  states. The zero-count clone carries pending samples, emits the same
  combinational arm request, and leaves the existing monitor DT unchanged.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `perl -Iperl -c t/1224-isf-contract-lowering.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1224-isf-contract-lowering.t t/1244-isf-wait-clause-lowering.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `focused Files=3, Tests=140; ISF gate Files=227, Tests=1022; book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1` | `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1: allow contract zero-sample waits` | `pending commit hash; leaf completed and ready for COMMIT.md workflow` |

## Changelog

- `2026-05-16`: Created task tree and started the contract successor
  pending-sample dynamic wait leaf.
- `2026-05-16`: Completed contract successor pending-sample dynamic wait leaf.
  Top-level bounded-eventual contract arm states can now be zero-count
  successors when they do not touch pending sample aliases; the clone
  materializes pending samples, emits the same one-cycle arm request, and
  leaves monitor pending/age/fail storage under the original monitor DT.
