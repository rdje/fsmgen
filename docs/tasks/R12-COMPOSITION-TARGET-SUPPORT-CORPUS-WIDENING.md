# R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING: Composition Target Support Corpus Widening

## Metadata

- Tree ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Promote the already-focused unsupported composition backend target diagnostic
into the maintained expected-failure regression corpus with stable diagnostics
and public support-accounting visibility.

## Non-Goals

- Do not implement VHDL composition output in this tree.
- Do not change parser acceptance or SystemVerilog/Verilog composition output.
- Do not change direct-root target-language support in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes the unsupported VHDL composition target
  diagnostic into a named expected-failure catalog entry.
- The new entry records stable diagnostic-code metadata and compiled diagnostic
  regex metadata.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for unsupported composition backend target diagnostics`
  Children: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1`, `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2`

- ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the composition target-support corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1: select target support widening`

- ID: `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained expected-failure entry for unsupported composition backend targets`
  Acceptance: `named fixture/catalog entry covers VHDL composition target rejection with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2` | `pending` | Promote focused composition target-support diagnostics into maintained corpus coverage after ownership is committed. |

## Decisions

- `2026-05-22`: Selected composition target support because
  [t/114-composition-target-support-diagnostics.t](../../t/114-composition-target-support-diagnostics.t)
  already locks the unsupported VHDL composition target diagnostic through the
  pipeline and CLI, while maintained composition-contract corpus coverage now
  accounts for child-entry, child-kind, ports shape/mapping, duplicate
  declaration, child-source, generated-child source-shape, external RTL
  source-shape, and `.rtlif` metadata boundaries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-22` | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1` | `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1: select target support widening` | `selection leaf; no compiler behavior changed` |
| `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-22`: Created task tree and selected the next implementation
  frontier.
