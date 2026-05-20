# R12-CONDITION-EXPRESSION-CORPUS-WIDENING: Condition-Expression Corpus Widening

## Metadata

- Tree ID: `R12-CONDITION-EXPRESSION-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused malformed condition-expression failures into the
maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new guard shorthand or inline comparison syntax.
- Do not alter supported guard/test expression behavior.
- Do not claim all condition-expression behavior is exhausted; this tree
  covers one bounded subset of already-focused rejection behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected guard shorthand and inline
  comparison rejection families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-CONDITION-EXPRESSION-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for malformed condition-expression failures`
  Children: `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.1`, `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2`

- ID: `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the condition-expression corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.1: select condition-expression widening`

- ID: `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for malformed guard shorthand and inline comparison tokens`
  Acceptance: `named fixtures/catalog entries cover malformed guard shorthand payloads and malformed inline comparison tokens with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused condition-expression tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2: widen condition-expression corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2` shipped the selected condition-expression corpus widening. |

## Decisions

- `2026-05-20`: Selected malformed guard shorthand payloads and malformed
  inline comparison tokens as the next R12 corpus subset because both are
  user-visible condition-expression diagnostics with focused coverage but no
  maintained expected-failure corpus entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused condition-expression tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.1` | `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.1: select condition-expression widening` | Selection leaf; no compiler behavior changed. |
| `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2` | `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2: widen condition-expression corpus` | Adds four maintained condition-expression expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected condition-expression corpus widening and
  closed the task tree.
