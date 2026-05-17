# ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE: Dynamic Wait Samples Before Independent Extract States

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow runtime dynamic waits with pending samples to zero-bypass directly into
an `extract` state when that state does not read or overwrite any pending
sample alias.

## Non-Goals

- Supporting `extract` states that read the just-sampled alias as the source
  word.
- Supporting `extract` states that overwrite the just-sampled alias as a
  destination field.
- Supporting broader data-operation successors such as bank load/store, stage,
  contract, or loop/check states.
- Changing positive-count dynamic wait timing, sampled counter behavior, or
  existing drive/await/static-wait/completion/setter/shift/assemble
  zero-bypass semantics.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (extract word as field...)` sequence
  lowers when the source word and destination fields are independent of the
  pending sample alias.
- The accepted zero-count path uses a sample-preserving extract clone, not a
  hidden sample-only cycle.
- Extract successors that read or overwrite pending sample aliases remain
  fail-closed.
- The ISF spec, mdBook, downstream handoff, public contract docs, roadmap,
  live docs, and focused tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE`
  Status: `done`
  Goal: `Ship independent extract zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1`

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1`
  Status: `done`
  Goal: `Allow pending-sample runtime waits to zero-bypass into independent extract states.`
  Acceptance: `Focused wait tests prove independent extract zero-bypass, sample-consuming extract states remain fail-closed, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1: allow independent extract zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1` | `done` | Independent extract states now carry pending samples through a zero-count clone when they neither read nor overwrite the pending sample alias. |

## Decisions

- `2026-05-16`: Limit this data-operation successor slice to extract states
  whose source word and destination fields do not touch pending sample aliases.
  Sample-consuming extract states need a separate timing rule because a
  zero-count clone would otherwise combine sampling and consuming the sampled
  value in one state.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1` | syntax checks; focused wait/book audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | focused `Files=2, Tests=125`; ISF gate `Files=227, Tests=1012`; book and diff gates passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1` | `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1: allow independent extract zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the independent extract
  pending-sample dynamic wait leaf.
- `2026-05-16`: Completed the leaf by accepting independent extract
  successors for pending-sample runtime wait zero-bypass while keeping
  sample-consuming extract states fail-closed.
