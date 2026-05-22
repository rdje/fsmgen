# R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING: Composition Endpoint Shape Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused composition endpoint-shape diagnostics into the
maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change declared same-name semantics for system ports.
- Do not infer aggregate member access for endpoints without declared aggregate
  types.
- Do not change generated HDL for already-supported composition links.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes shared system-port same-name rejection and
  aggregate-member endpoint rejection into named expected-failure catalog
  entries.
- The new entries record stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for composition endpoint-shape diagnostics`
  Children: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1`, `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition endpoint-shape corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1: select endpoint shape widening`

- ID: `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for endpoint-shape rejections`
  Acceptance: `named fixtures/catalog entries cover shared system-port same-name rejection and aggregate-member endpoint rejection with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2` | `pending` | Promote focused endpoint-shape diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected endpoint shape because
  [t/113-composition-endpoint-shape-diagnostics.t](../../t/113-composition-endpoint-shape-diagnostics.t)
  already locks declared same-name rejection on shared system ports and
  aggregate-member child endpoint rejection without declared aggregate types,
  while maintained composition-contract corpus coverage now accounts for
  child-entry, child-kind, ports shape/mapping, duplicate declaration, C1
  exposure, explicit-link topology, child-source, generated-child source-shape,
  external RTL source-shape, `.rtlif` metadata, and target-support boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1` | `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1: select endpoint shape widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
