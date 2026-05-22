# R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING: Composition Ports Shape Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote already-focused composition `?ports` shape-gate diagnostics into the
maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change port token parsing, duplicate-port detection, explicit-link,
  endpoint-shape, or topology diagnostics in this tree.
- Do not narrow the already-shipped inferable omitted-`?ports` success cases;
  this tree only records the multi-child non-inferable shape failures already
  locked by focused tests.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes multiple `?ports` blocks, omitted `?ports`
  outside inferable lanes, and empty `?ports` outside inferable lanes into
  named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for composition ports shape-gate diagnostics`
  Children: `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.1`, `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the ports-shape corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.1: select ports shape widening`

- ID: `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for composition ports shape-gate failures`
  Acceptance: `named fixtures/catalog entries cover multiple ports blocks, omitted ports outside inferable lanes, and empty ports outside inferable lanes with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.2` | `pending` | Promote focused composition ports shape-gate diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected composition ports shape gates because
  [t/110-composition-shape-gate-diagnostics.t](../../t/110-composition-shape-gate-diagnostics.t)
  already locks multiple `?ports`, omitted `?ports`, and empty `?ports`
  rejection wording for non-inferable composition lanes, while maintained
  composition-contract corpus coverage now accounts for child-entry,
  child-kind, ports-mapping, duplicate declaration, child-source,
  generated-child source-shape, external RTL source-shape, and `.rtlif`
  metadata boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.1` | `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.1: select ports shape widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
