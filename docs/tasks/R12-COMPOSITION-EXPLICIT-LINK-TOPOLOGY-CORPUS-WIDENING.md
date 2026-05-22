# R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING: Composition Explicit-Link Topology Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused missing explicit `?wiring` topology diagnostic into
the maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change composition lane selection.
- Do not infer wiring for multi-child composition tops in this tree.
- Do not change generated HDL for already-supported composition sources.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes the missing explicit `?wiring` rejection
  into a named expected-failure catalog entry.
- The new entry records stable diagnostic-code metadata and compiled diagnostic
  regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for missing explicit composition wiring diagnostics`
  Children: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1`, `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition explicit-link topology corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1: select explicit-link topology widening`

- ID: `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained expected-failure entry for missing explicit composition wiring`
  Acceptance: `named fixture/catalog entry covers missing explicit '?wiring' rejection with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2` | `pending` | Promote focused missing explicit `?wiring` diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected explicit-link topology because
  [t/109-composition-explicit-link-topology-diagnostics.t](../../t/109-composition-explicit-link-topology-diagnostics.t)
  already locks the missing explicit `?wiring` diagnostic, while maintained
  composition-contract corpus coverage now accounts for child-entry,
  child-kind, ports shape/mapping, duplicate declaration, child-source,
  generated-child source-shape, external RTL source-shape, `.rtlif` metadata,
  and target-support boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1` | `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1: select explicit-link topology widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
