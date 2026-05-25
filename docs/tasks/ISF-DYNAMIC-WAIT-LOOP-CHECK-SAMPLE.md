# ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE: Dynamic Wait Samples Before Loop Decisions

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into
independent loop decision states when the wait is the last state-producing
clause in a repeat, while, or until body.

## Non-Goals

- Changing repeat, while, or until source syntax.
- Changing positive-count dynamic wait timing.
- Supporting loop decision states that read or overwrite a pending sample
  alias.
- Supporting unrelated remaining dynamic-wait predecessor kinds.

## Acceptance Criteria

- Repeat-body `(sample ...) (wait count)` sequences lower when the zero-count
  successor is the repeat check state and the check is independent of the
  pending sample alias.
- While-body and until-body `(sample ...) (wait count)` sequences lower when
  the zero-count successor is the loop decision state and the loop condition
  is independent of the pending sample alias.
- Zero-count clones materialize pending samples and preserve the original loop
  decision/check behavior.
- Loop decision states whose condition or assignments touch the pending sample
  alias remain fail-closed.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE`
  Status: `done`
  Goal: `Ship independent loop decision zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into independent loop decision states.`
  Acceptance: `Focused wait tests prove repeat/while/until sample-preserving loop decision clones, docs are synchronized, and ISF gates pass.`
  Verification: `syntax checks; focused wait/book audit tests; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1: allow loop decision zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1` | `done` | Loop decision states now zero-bypass when independent of pending sample aliases. |

## Decisions

- `2026-05-16`: Limit this slice to loop decision/check states that are
  independent of pending sample aliases. The zero-count clone carries pending
  samples and then executes the same repeat counter decrement or loop
  condition decision as the original state.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1244-isf-wait-clause-lowering.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `focused Files=2, Tests=137; ISF gate Files=227, Tests=1024; book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1` | `6a4b0f6a ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1: allow loop decision zero-sample waits` | `completion commit` |

## Changelog

- `2026-05-16`: Created task tree and started the loop decision successor
  pending-sample dynamic wait leaf.
- `2026-05-16`: Completed loop decision successor pending-sample dynamic wait
  leaf. Repeat checks and while/until decisions can now be zero-count
  successors when their counter assignments and loop conditions do not touch
  pending sample aliases.
