# R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING: Composition Duplicate Declaration Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused duplicate top-port and duplicate child-instance
composition diagnostics into the maintained expected-failure regression corpus
with stable diagnostics and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change endpoint-shape, explicit-link, topology, or child-source
  diagnostics in this tree.
- Do not broaden duplicate detection beyond the already-focused top-port and
  child-instance declaration families.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes duplicate top-port and duplicate
  child-instance diagnostics into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for duplicate top-port and child-instance composition diagnostics`
  Children: `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.1`, `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the duplicate declaration corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.1: select duplicate declaration widening`

- ID: `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for duplicate top-port and child-instance declarations`
  Acceptance: `named fixtures/catalog entries cover duplicate top ports and duplicate child instance names with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.2` | `pending` | Promote focused duplicate composition declaration diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected duplicate composition declarations because
  [t/112-composition-duplicate-declaration-diagnostics.t](../../t/112-composition-duplicate-declaration-diagnostics.t)
  already locks duplicate top-port and duplicate child-instance diagnostics,
  while maintained composition-contract corpus coverage currently accounts for
  earlier child-entry/list shape, child-kind, ports-mapping, child-source,
  generated-child source-shape, external RTL source-shape, and `.rtlif`
  metadata boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.1` | `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.1: select duplicate declaration widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
