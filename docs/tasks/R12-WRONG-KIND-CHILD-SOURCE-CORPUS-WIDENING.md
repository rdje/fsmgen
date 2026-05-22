# R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING: Wrong-Kind Child Source Corpus Widening

## Metadata

- Tree ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused generated-child wrong-kind source realization failures
into the maintained expected-failure regression corpus with stable diagnostics
and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change generated-child source resolution, search-path semantics, or
  source-kind classification.
- Do not widen missing-child-source or RTL metadata diagnostics; those already
  have dedicated corpus coverage.
- Do not claim all composition child-source failures are exhausted; this tree
  covers one bounded wrong-kind subset.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes wrong-kind generated-child source
  realization failures into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata, compiled diagnostic
  regex metadata, and any required search-path metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for wrong-kind generated-child source realization`
  Children: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1`, `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2`

- ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the wrong-kind child-source corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1: select wrong-kind child-source widening`

- ID: `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for wrong-kind generated-child source realization`
  Acceptance: `named fixtures/catalog entries cover ?fsmc resolving to a standalone-DT child and ?dtc resolving to an FSM child with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2` | `pending` | Promote focused wrong-kind generated-child source diagnostics into maintained corpus coverage after ownership was committed. |

## Decisions

- `2026-05-22`: Selected wrong-kind generated-child source realization because
  focused diagnostics already cover `?fsmc` resolving to standalone-DT source
  and `?dtc` resolving to FSM source, while maintained composition-contract
  corpus coverage currently isolates missing child sources and RTL metadata
  failures but not wrong-kind resolved generated-child files.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1` | `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1: select wrong-kind child-source widening` | `selection leaf; no compiler behavior changed` |
| `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
