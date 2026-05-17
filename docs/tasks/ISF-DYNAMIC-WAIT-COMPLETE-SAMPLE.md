# ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE: Dynamic Wait Samples Before Completion

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into a
completion state when doing so can materialize the samples without adding a
hidden cycle or changing completion timing.

## Non-Goals

- Supporting sample-compatible zero-bypass into transaction data-operation
  states that consume the sampled alias.
- Supporting consecutive runtime waits with pending samples.
- Changing positive-count dynamic wait timing, sampled counter behavior, or
  completion pulse semantics.
- Widening dynamic wait expression width inference or predecessor-edge support.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (complete done)` sequence with a
  known-width runtime count lowers successfully and preserves the positive and
  zero-count sample timing.
- The accepted completion zero-bypass path uses a sample-preserving completion
  clone, not a hidden sample-only cycle.
- The same safe completion successor is covered inside currently shipped branch
  contexts where the selected zero-count path can land on completion.
- Existing data-operation successors that cannot carry pending samples remain
  fail-closed.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE`
  Status: `done`
  Goal: `Ship completion-state zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into completion.`
  Acceptance: `Focused wait tests prove top-level and branch completion successors, diagnostics remain fail-closed for unsafe data-operation successors, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1: allow completion zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1` | `done` | Completion successors now carry pending samples through a zero-count clone without consuming them or adding a hidden cycle. |

## Decisions

- `2026-05-16`: Limit this tree to completion successors. Data-operation
  successors still need a separate timing contract because many of them read
  the sampled alias and currently require an intervening sample state.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1` | syntax checks; focused wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused `Files=2, Tests=114`; ISF gate `Files=227, Tests=1001`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1` | `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1: allow completion zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the completion zero-bypass
  pending-sample dynamic wait leaf.
- `2026-05-16`: Completed the leaf by accepting top-level and shipped branch
  completion successors for pending-sample runtime wait zero-bypass while
  keeping unsafe data-operation successors fail-closed.
