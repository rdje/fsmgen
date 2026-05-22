# R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING: Composition Parser Token Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused composition parser token/shape diagnostics into
the maintained expected-failure regression corpus with stable diagnostics and
public support-accounting visibility.

## Non-Goals

- Do not change accepted `?ports`, `?wiring`, `+constants`, or `+enums`
  syntax.
- Do not add new composition top-symbol expression support in this tree.
- Do not change generated HDL for already-supported composition sources.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes malformed verbose `?ports`, invalid
  `?ports` tokens, non-positive `?ports` widths, malformed `?wiring` list
  items, unsupported `?wiring` tokens, malformed top `+constants` entries, and
  non-literal top `+enums` values into named expected-failure catalog entries.
- The new entries record stable diagnostic-code metadata and compiled
  diagnostic regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for composition parser token and shape diagnostics`
  Children: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1`, `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition parser-token corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1: select parser token widening`

- ID: `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for composition parser token and top-symbol rejections`
  Acceptance: `named fixtures/catalog entries cover the t/126 parser token diagnostic family with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2` | `pending` | Promote focused parser token diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected parser token widening because
  [t/126-composition-parser-token-diagnostics.t](../../t/126-composition-parser-token-diagnostics.t)
  already locks malformed `?ports`, malformed `?wiring`, malformed top
  symbol-token, and top symbol literal-support diagnostics through pipeline and
  CLI behavior, while maintained composition-contract corpus coverage now
  accounts for child-entry, child-kind, ports shape/mapping, duplicate
  declaration, C1 exposure, explicit-link topology, endpoint shape,
  child-source, generated-child source-shape, external RTL source-shape,
  `.rtlif` metadata, and target-support boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1` | `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1: select parser token widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
