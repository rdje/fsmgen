# ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE: Dynamic Wait Samples Before Independent Bank Loads

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into a
bank `load` state when that state does not read or overwrite any pending
sample alias.

## Non-Goals

- Supporting bank `load` states that read the just-sampled alias as the index
  or a scalarized bank entry.
- Supporting bank `load` states that overwrite the just-sampled alias as the
  load target.
- Supporting bank `store` states; write-side bank timing remains a separate
  slice.
- Supporting broader stage, contract, or loop/check-state successors.
- Changing positive-count dynamic wait timing, sampled counter behavior, or
  existing drive/await/static-wait/completion/setter/shift/assemble/extract
  zero-bypass semantics.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (load bank idx as target)` sequence
  lowers when the index, scalarized source entries, and target are independent
  of the pending sample alias.
- The accepted zero-count path uses a sample-preserving bank-load clone, not a
  hidden sample-only cycle.
- Bank loads that read or overwrite pending sample aliases remain fail-closed.
- Bank stores remain fail-closed in this slice.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE`
  Status: `done`
  Goal: `Ship independent bank-load zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into independent bank-load states.`
  Acceptance: `Focused wait tests prove independent bank-load zero-bypass, sample-consuming bank loads and bank stores remain fail-closed, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1: allow independent bank-load zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1` | `done` | Independent bank loads now carry pending samples through a zero-count clone when they neither read nor overwrite the pending sample alias. |

## Decisions

- `2026-05-16`: Limit this slice to bank loads whose target, scalarized entry
  RHS values, and index guards do not touch pending sample aliases. Bank
  stores remain deferred because writes to actor-owned bank entries need their
  own timing and collision review.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1` | syntax checks; focused wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused `Files=2, Tests=127`; ISF gate `Files=227, Tests=1014`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1` | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1: allow independent bank-load zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the independent bank-load
  pending-sample dynamic wait leaf.
- `2026-05-16`: Completed the leaf by accepting independent bank-load
  successors for pending-sample runtime wait zero-bypass while keeping
  sample-consuming loads and bank stores fail-closed.
