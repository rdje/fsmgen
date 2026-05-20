# R12-RHS-EXPRESSION-CORPUS-WIDENING: RHS Expression Corpus Widening

## Metadata

- Tree ID: `R12-RHS-EXPRESSION-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused RHS expression failures into the maintained
expected-failure regression corpus with stable diagnostics and public report
coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new expression operators or widen expression arity rules.
- Do not alter supported inline comparison, n-ary bitwise, or scalar RHS
  expression behavior.
- Do not claim all expression behavior is exhausted; this tree covers one
  bounded subset of already-focused RHS expression rejection behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected RHS expression rejection families
  into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-RHS-EXPRESSION-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for RHS expression failures`
  Children: `R12-RHS-EXPRESSION-CORPUS-WIDENING.1`, `R12-RHS-EXPRESSION-CORPUS-WIDENING.2`

- ID: `R12-RHS-EXPRESSION-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the RHS expression corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RHS-EXPRESSION-CORPUS-WIDENING.1: select RHS expression widening`

- ID: `R12-RHS-EXPRESSION-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for unsupported operators, malformed arity, and guard-only RHS tokens`
  Acceptance: `named fixtures/catalog entries cover unsupported RHS operators, malformed RHS operator arity, and guard-only RHS tokens with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused RHS expression tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RHS-EXPRESSION-CORPUS-WIDENING.2: widen RHS expression corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-RHS-EXPRESSION-CORPUS-WIDENING.2` shipped the selected RHS expression corpus widening. |

## Decisions

- `2026-05-20`: Selected unsupported RHS expression operators, malformed RHS
  operator arity, and guard-only RHS tokens as the next R12 corpus subset
  because each is a user-visible expression diagnostic with focused parser,
  pipeline, and CLI coverage but no maintained expected-failure corpus entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-RHS-EXPRESSION-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-RHS-EXPRESSION-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused RHS expression tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-RHS-EXPRESSION-CORPUS-WIDENING.1` | `R12-RHS-EXPRESSION-CORPUS-WIDENING.1: select RHS expression widening` | Selection leaf; no compiler behavior changed. |
| `R12-RHS-EXPRESSION-CORPUS-WIDENING.2` | `R12-RHS-EXPRESSION-CORPUS-WIDENING.2: widen RHS expression corpus` | Adds three maintained RHS expression expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected RHS expression corpus widening and closed
  the task tree.
