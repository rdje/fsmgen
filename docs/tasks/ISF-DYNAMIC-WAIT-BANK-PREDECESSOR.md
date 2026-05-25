# ISF-DYNAMIC-WAIT-BANK-PREDECESSOR: Dynamic Waits After Bank Access

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits to follow transaction bank `load` and `store`
states by splitting the bank state's unconditional advance edge into
positive-count counter load and zero-count bypass paths.

## Non-Goals

- Changing bank access syntax, scalarized bank storage, or load/store
  assignment semantics.
- Changing pending-sample successor compatibility for bank states.
- Supporting unrelated remaining dynamic-wait predecessor kinds.

## Acceptance Criteria

- `(load BANK IDX as TARGET) (wait count)` lowers with a positive-count path
  that samples the runtime counter and enters the wait state.
- `(store BANK IDX VALUE) (wait count)` lowers with the same predecessor split.
- Zero-count paths bypass the wait and continue to the post-wait state.
- Bank load/store assignments remain in the predecessor state.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR`
  Status: `done`
  Goal: `Ship runtime dynamic waits after transaction bank access states.`
  Children: `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1`

- ID: `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1`
  Status: `done`
  Goal: `Allow bank load/store states to split following runtime dynamic waits.`
  Acceptance: `Focused wait tests prove load/store predecessor splits, docs are synchronized, and ISF gates pass.`
  Verification: `syntax checks, focused wait/book audit tests, full ISF gate, mdBook build, and diff check passed`
  Commit: `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1: allow bank predecessor dynamic waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1` | `done` | Bank access states now split following runtime dynamic wait edges. |

## Decisions

- `2026-05-16`: Treat transaction bank load/store states like unconditional
  sequential predecessors for following runtime wait edge splitting. This does
  not change the guarded scalarized bank assignments themselves.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1244-isf-wait-clause-lowering.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `focused Files=2, Tests=138; ISF gate Files=227, Tests=1025; book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1` | `1f400c1e ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1: allow bank predecessor dynamic waits` | `completion commit` |

## Changelog

- `2026-05-16`: Created task tree and started the dynamic wait bank-access
  predecessor leaf.
- `2026-05-16`: Closed `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1` after shipping
  runtime dynamic waits after transaction bank load/store predecessors and
  synchronizing the ISF spec, downstream handoff, public contract, mdBook,
  roadmap, README, and live docs.
