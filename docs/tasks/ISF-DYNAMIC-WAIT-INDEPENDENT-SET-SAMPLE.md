# ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE: Dynamic Wait Samples Before Independent Setters

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into a
scalar setter state when that state does not read or overwrite any pending
sample alias.

## Non-Goals

- Supporting setter states that read the just-sampled alias.
- Supporting setter states that overwrite the just-sampled alias.
- Supporting broader data-operation successors such as shift, assemble,
  extract, bank load/store, stage, contract, or loop/check states.
- Changing positive-count dynamic wait timing, sampled counter behavior, or
  existing drive/await/static-wait/completion zero-bypass semantics.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (set out expr)` sequence lowers when
  `expr` does not reference the pending sample alias and the target is not the
  pending sample alias.
- Shipped branch and repeat-body contexts use the same safe zero-count clone
  behavior for an independent selected setter successor.
- Setter successors that read or overwrite pending sample aliases remain
  fail-closed.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE`
  Status: `done`
  Goal: `Ship independent setter zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into independent scalar setters.`
  Acceptance: `Focused wait tests prove top-level, branch, and repeat-body independent setters, sample-consuming setters remain fail-closed, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1: allow independent setter zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1` | `done` | Independent scalar setters now carry pending samples through a zero-count clone when they neither read nor overwrite the pending sample alias. |

## Decisions

- `2026-05-16`: Limit the first data-operation successor slice to scalar
  `set`/`update` states that are independent of pending sample aliases.
  Setters that read or overwrite a pending sample alias still need a separate
  timing rule because the clone would otherwise combine sampling and data
  consumption in one state.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1` | syntax checks; focused wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused `Files=2, Tests=118`; ISF gate `Files=227, Tests=1005`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1` | `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1: allow independent setter zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the independent setter
  pending-sample dynamic wait leaf.
- `2026-05-16`: Completed the leaf by accepting top-level, shipped branch, and
  repeat-body independent scalar setter successors for pending-sample runtime
  wait zero-bypass while keeping sample-consuming setters fail-closed.
