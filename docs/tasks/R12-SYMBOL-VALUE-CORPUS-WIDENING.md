# R12-SYMBOL-VALUE-CORPUS-WIDENING: Symbol-Value Corpus Widening

## Metadata

- Tree ID: `R12-SYMBOL-VALUE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused symbol-definition value failures into the maintained
expected-failure regression corpus with stable diagnostics and public report
coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new symbol-value syntax.
- Do not alter supported `+constants`, `+define`, `+params`, or `+enums`
  values.
- Do not cover malformed symbol-entry structure, empty symbol sections,
  aggregate parameter arithmetic, parameter cycles, or duplicate parameter
  declarations in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected symbol-value rejection families
  into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-SYMBOL-VALUE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for symbol-definition value failures`
  Children: `R12-SYMBOL-VALUE-CORPUS-WIDENING.1`, `R12-SYMBOL-VALUE-CORPUS-WIDENING.2`

- ID: `R12-SYMBOL-VALUE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the symbol-value corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-SYMBOL-VALUE-CORPUS-WIDENING.1: select symbol-value widening`

- ID: `R12-SYMBOL-VALUE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for unresolved parameter values and ambiguous bare bitstring symbol values`
  Acceptance: `named fixtures/catalog entries cover unresolved +params value names plus ambiguous bare +constants and +params bitstring-like values with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-SYMBOL-VALUE-CORPUS-WIDENING.2` | `pending` | Promotes the already-focused symbol-value diagnostics after ownership is committed. |

## Decisions

- `2026-05-20`: Selected unresolved `+params` value names and ambiguous bare
  bitstring-like `+constants` / `+params` values as the next R12 corpus subset
  because each is a user-visible symbol-value diagnostic with focused coverage
  but no maintained expected-failure corpus entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-SYMBOL-VALUE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-SYMBOL-VALUE-CORPUS-WIDENING.1` | `R12-SYMBOL-VALUE-CORPUS-WIDENING.1: select symbol-value widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
