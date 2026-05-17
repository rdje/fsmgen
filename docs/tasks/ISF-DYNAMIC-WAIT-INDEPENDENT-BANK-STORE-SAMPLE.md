# ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE: Dynamic Wait Samples Before Independent Bank Stores

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into a
bank `store` state when that state does not read or overwrite any pending
sample alias.

## Non-Goals

- Supporting bank `store` states that read the just-sampled alias as the index
  or stored value.
- Supporting bank `store` states that overwrite the just-sampled alias through
  a scalarized bank entry.
- Supporting broader stage, contract, or loop/check-state successors.
- Changing positive-count dynamic wait timing, sampled counter behavior, or
  existing drive/await/static-wait/completion/setter/shift/assemble/extract/
  bank-load zero-bypass semantics.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (store bank idx value)` sequence
  lowers when the index, stored value, and scalarized destination entries are
  independent of the pending sample alias.
- The accepted zero-count path uses a sample-preserving bank-store clone, not a
  hidden sample-only cycle.
- Bank stores that read or overwrite pending sample aliases remain
  fail-closed.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE`
  Status: `done`
  Goal: `Ship independent bank-store zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into independent bank-store states.`
  Acceptance: `Focused wait tests prove independent bank-store zero-bypass, sample-consuming bank stores remain fail-closed, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1: allow independent bank-store zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1` | `done` | Bank store is the write-side pair to the shipped bank-load successor. |

## Decisions

- `2026-05-16`: Limit this slice to bank stores whose scalarized destination
  entries, stored value, and index guards do not touch pending sample aliases.
  Store/read collision policy remains the existing read-before-write bank
  access policy; this leaf only decides pending-sample zero-bypass eligibility.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1` | syntax checks; focused wait tests; focused wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused wait tests `Files=1, Tests=30`; focused wait/book audit tests `Files=2, Tests=129`; ISF gate `Files=227, Tests=1016`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1` | `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1: allow independent bank-store zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the independent bank-store
  pending-sample dynamic wait leaf.
- `2026-05-16`: Shipped independent bank-store zero-bypass for pending-sample
  runtime waits, kept sample-consuming bank stores fail-closed, synchronized
  the live specs/mdBook/downstream handoff/public contract, and passed focused
  plus full ISF validation.
