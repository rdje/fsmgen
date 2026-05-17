# ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE: Dynamic Wait Samples Before Independent Shifts

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into a
shift state when that state does not read or overwrite any pending sample
alias.

## Non-Goals

- Supporting shift states that read the just-sampled alias as the shifted
  register or inserted bit.
- Supporting shift states that overwrite the just-sampled alias.
- Supporting broader data-operation successors such as assemble, extract, bank
  load/store, stage, contract, or loop/check states.
- Changing positive-count dynamic wait timing, sampled counter behavior, or
  existing drive/await/static-wait/completion/setter zero-bypass semantics.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (shift_left reg bit ...)` sequence
  lowers when `reg` and `bit` are independent of the pending sample alias.
- The accepted zero-count path uses a sample-preserving shift clone, not a
  hidden sample-only cycle.
- Shift successors that read or overwrite pending sample aliases remain
  fail-closed.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE`
  Status: `done`
  Goal: `Ship independent shift zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into independent shift states.`
  Acceptance: `Focused wait tests prove independent shift zero-bypass, sample-consuming shifts remain fail-closed, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1: allow independent shift zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1` | `done` | Independent shifts now carry pending samples through a zero-count clone when they neither read nor overwrite the pending sample alias. |

## Decisions

- `2026-05-16`: Limit this data-operation successor slice to shift states
  whose target and RHS expression do not touch pending sample aliases.
  Sample-consuming shifts need a separate timing rule because a zero-count
  clone would otherwise combine sampling and shifting the sampled value in one
  state.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1` | syntax checks; focused wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused `Files=2, Tests=121`; ISF gate `Files=227, Tests=1008`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1` | `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1: allow independent shift zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the independent shift
  pending-sample dynamic wait leaf.
- `2026-05-16`: Completed the leaf by accepting independent shift successors
  for pending-sample runtime wait zero-bypass while keeping sample-consuming
  shifts fail-closed.
