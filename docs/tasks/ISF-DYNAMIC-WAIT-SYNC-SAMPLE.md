# ISF-DYNAMIC-WAIT-SYNC-SAMPLE: Sync Successor Pending-Sample Dynamic Waits

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-SYNC-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass into top-level
`await_all` and `await_any` synchronization states when the sync done ports do
not touch the pending sample aliases.

## Non-Goals

- Changing `await_all` or `await_any` syntax, done-port collection, or normal
  synchronization lowering.
- Supporting inline-body `await_all` or `await_any` clauses inside loops or
  branches.
- Allowing sync done ports that read a pending sample alias in the same
  zero-count clone.

## Acceptance Criteria

- `(sample SRC as HOLD) (wait count) (await_all done)` lowers with a
  zero-count clone that materializes `HOLD` and preserves the original
  all-done synchronization transition.
- `(sample SRC as HOLD) (wait count) (await_any done)` lowers with the same
  pending-sample materialization and any-done transition behavior.
- Positive-count paths still sample in the first active wait state and then
  enter the original sync state without double-sampling.
- Sync done ports that touch pending sample aliases remain fail-closed.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-SYNC-SAMPLE`
  Status: `done`
  Goal: `Ship sync-state pending-sample zero bypass for runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1`
  Status: `done`
  Goal: `Allow await_all/await_any states to carry pending samples on zero-count runtime waits.`
  Acceptance: `Focused wait tests prove sync zero-count clones, alias-touching sync ports reject, docs are synchronized, and ISF gates pass.`
  Verification: `syntax checks; focused wait/book audit tests; ./bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1: allow sync successor zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1` | `done` | Sync states now zero-bypass when their collected done ports are independent of pending sample aliases. |

## Decisions

- `2026-05-16`: Treat top-level `await_all` and `await_any` states as
  sample-compatible zero-count successors only when their done ports do not
  reference pending sample aliases. The zero-count clone preserves the sync
  state's collected done-port transition behavior.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1244-isf-wait-clause-lowering.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `focused Files=2, Tests=140; ISF gate Files=227, Tests=1027; book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1` | `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1: allow sync successor zero-sample waits` | `pending commit hash; leaf completed and ready for COMMIT.md workflow` |

## Changelog

- `2026-05-16`: Created task tree and started the sync successor
  pending-sample dynamic wait leaf.
- `2026-05-16`: Closed `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1` after shipping
  sample-preserving zero-count clones for top-level `await_all`/`await_any`
  sync successors and synchronizing the ISF spec, downstream handoff, public
  contract, mdBook, roadmap, README, and live docs.
