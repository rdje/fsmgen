# R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING: Composition C1 Port Exposure Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused C1 passthrough exposure diagnostics into the
maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change single-child passthrough inference.
- Do not relax top/child port direction, width, or name compatibility.
- Do not change generated HDL for already-supported C1 composition sources.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes missing child exposure, unknown top-port,
  width mismatch, and direction mismatch C1 rejections into named
  expected-failure catalog entries.
- The new entries record stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for C1 passthrough exposure diagnostics`
  Children: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1`, `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition C1 port-exposure corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1: select C1 port exposure widening`

- ID: `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for C1 passthrough exposure mismatches`
  Acceptance: `named fixtures/catalog entries cover missing exposure, unknown top-port, width mismatch, and direction mismatch with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2` | `pending` | Promote focused C1 passthrough exposure diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected C1 passthrough exposure because
  [t/111-composition-c1-port-exposure-diagnostics.t](../../t/111-composition-c1-port-exposure-diagnostics.t)
  already locks missing exposure, unknown explicit top-port, width mismatch,
  and direction mismatch diagnostics, while maintained composition-contract
  corpus coverage now accounts for child-entry, child-kind, ports
  shape/mapping, duplicate declaration, explicit-link topology, child-source,
  generated-child source-shape, external RTL source-shape, `.rtlif` metadata,
  and target-support boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1` | `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1: select C1 port exposure widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
