# ISF-STATIC-ZERO-REPEAT-NOOP: Static Zero-Count Repeat No-Op

## Metadata

- Tree ID: `ISF-STATIC-ZERO-REPEAT-NOOP`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Ship a bounded no-op lowering policy for statically zero transaction
`(repeat count body...)` clauses now that runtime repeat zero-bypass semantics
and pending-sample successor handling are established.

## Non-Goals

- Do not widen repeat-body clause support.
- Do not change positive static repeat counts or runtime scalar repeat counts.
- Do not silently keep generated-child composition artifacts for repeat bodies
  that are statically skipped; generated-child zero-repeat bodies remain
  fail-closed until artifact-pruning semantics are selected.
- Do not implement activation-site override-specialized repeat lowering.

## Acceptance Criteria

- Literal zero, zero-valued actor constants, zero-valued actor scalar
  parameters, zero-valued same-transaction scalar parameters, and zero-valued
  qualified package scalar constants lower as zero-iteration no-ops.
- A zero-count repeat emits no repeat init state, repeat check state, repeat
  counter, repeat body states, or `transaction_loops[]` entry.
- Surrounding transaction sequencing remains intact: work before the repeat
  still precedes work after the repeat.
- Repeat bodies that would create generated child/spawn artifacts remain
  fail-closed for statically zero counts with a targeted diagnostic.
- Existing positive static repeat and runtime scalar repeat behavior is
  unchanged.
- ISF spec, downstream handoff, public contract, mdBook, roadmap, task tree,
  README index, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STATIC-ZERO-REPEAT-NOOP`
  Status: `done`
  Goal: `Ship bounded static zero-count repeat no-op semantics.`
  Children: `ISF-STATIC-ZERO-REPEAT-NOOP.1`

- ID: `ISF-STATIC-ZERO-REPEAT-NOOP.1`
  Status: `done`
  Goal: `Implement and document static zero-count repeat no-op lowering.`
  Acceptance: `Static zero repeat counts skip the body without repeat
  counter/state emission; generated-child zero-repeat bodies fail closed;
  focused tests and public docs are synchronized.`
  Verification: `syntax checks; focused repeat/public-audit Files=7, Tests=344; ./bin/ci-regression isf --no-book Files=275, Tests=1757; mdbook build docs/book; git diff --check`
  Commit: `ISF-STATIC-ZERO-REPEAT-NOOP.1: ship zero repeat no-op`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-STATIC-ZERO-REPEAT-NOOP.1` shipped bounded static zero-count repeat no-op lowering. |

## Decisions

- `2026-05-25`: Select zero-iteration no-op semantics for statically zero
  repeat counts. This aligns static counts with the shipped runtime zero-count
  bypass while preserving the existing positive-count and runtime-count
  behavior.
- `2026-05-25`: Keep statically skipped generated-child repeat bodies
  fail-closed until generated-child discovery can distinguish unreachable
  repeat bodies without leaving stale parent/child/top artifacts.

## Open Questions

- None blocking this bounded leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-STATIC-ZERO-REPEAT-NOOP.1` | syntax checks; focused repeat/public-audit tests; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused repeat/public-audit `Files=7, Tests=344`; ISF `Files=275, Tests=1757` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STATIC-ZERO-REPEAT-NOOP.1` | `ISF-STATIC-ZERO-REPEAT-NOOP.1: ship zero repeat no-op` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created active R14 task tree for bounded static zero-count
  repeat no-op lowering.
- `2026-05-25`: Implemented zero-count no-op lowering, synchronized docs, and
  closed the tree.
