# R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING: Generated Child Source Shape Corpus Widening

## Metadata

- Tree ID: `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused generated-child source count and source-shape
diagnostics into the maintained expected-failure regression corpus with stable
diagnostics and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change generated-child source resolution, root-kind realization, or
  search-path semantics.
- Do not widen `?ports`, `?wiring`, `?rtl`, or `.rtlif` diagnostics.
- Do not claim all composition parser failures are exhausted; this tree covers
  the bounded generated-child source-count/source-shape subset.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes representative malformed generated-child
  source count and nested payload shape failures into named expected-failure
  catalog entries.
- Each new entry records stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for generated-child source count and payload shape diagnostics`
  Children: `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1`, `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`

- ID: `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the generated-child source-shape corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1: select generated-child source-shape widening`

- ID: `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for malformed generated-child source count and nested payload shape`
  Acceptance: `named fixtures/catalog entries cover at least one ?fsmc source-count failure, one ?dtc source-count failure, one ?fsmc nested payload failure, and one ?dtc nested payload failure with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2` | `pending` | Promote focused generated-child source-count/source-shape diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected generated-child source count and nested payload shape
  because
  [t/130-composition-generated-child-source-shape-diagnostics.t](../../t/130-composition-generated-child-source-shape-diagnostics.t)
  already locks explicit diagnostics for malformed `?fsmc` and `?dtc` payloads,
  while maintained composition-contract corpus coverage currently includes
  missing and wrong-kind external child sources but not malformed child source
  payload shapes.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1` | `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1: select generated-child source-shape widening` | `selection leaf; no compiler behavior changed` |
| `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
