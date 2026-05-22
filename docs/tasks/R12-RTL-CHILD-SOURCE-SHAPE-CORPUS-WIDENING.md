# R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING: RTL Child Source Shape Corpus Widening

## Metadata

- Tree ID: `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused external RTL child source count and nested payload
shape diagnostics into the maintained expected-failure regression corpus with
stable diagnostics and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change `.rtlif` metadata loading, validation, sidecar search, or
  embedded metadata precedence.
- Do not widen generated `?fsmc` / `?dtc` child-source diagnostics; those are
  handled by the generated-child source-shape tree.
- Do not claim all external RTL composition failures are exhausted; this tree
  covers the bounded `?rtl` child-declaration source-count/source-shape subset.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes representative malformed `?rtl` source
  count and nested payload shape failures into named expected-failure catalog
  entries.
- Each new entry records stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for external RTL child source count and payload shape diagnostics`
  Children: `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1`, `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`

- ID: `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the external RTL child source-shape corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1: select RTL child source-shape widening`

- ID: `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for malformed external RTL child source count and nested payload shape`
  Acceptance: `named fixtures/catalog entries cover one ?rtl multi-token source-count failure and one ?rtl unsupported nested payload failure with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2` | `pending` | Promote focused external RTL child source-count/source-shape diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected external RTL child source count and nested payload
  shape because
  [t/291-composition-rtl-child-source-shape-diagnostics.t](../../t/291-composition-rtl-child-source-shape-diagnostics.t)
  already locks explicit diagnostics for malformed `?rtl` payloads, while
  maintained composition-contract corpus coverage currently includes missing
  and malformed `.rtlif` metadata but not malformed `?rtl` child declaration
  source shapes.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1` | `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1: select RTL child source-shape widening` | `selection leaf; no compiler behavior changed` |
| `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
