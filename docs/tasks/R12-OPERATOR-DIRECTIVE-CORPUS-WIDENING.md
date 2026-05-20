# R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING: Operator/Directive Corpus Widening

## Metadata

- Tree ID: `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused authored operator and directive-value failures into the
maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new assignment operators or `:=` reset-value semantics.
- Do not alter strict-mode compatibility policy for legacy infix assignment
  spellings.
- Do not claim all operator/directive errors are exhausted; this tree covers
  one bounded subset of already-focused rejection behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected operator/directive rejection
  families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for authored operator and directive-value failures`
  Children: `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.1`, `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2`

- ID: `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the operator/directive corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.1: select operator-directive widening`

- ID: `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for unsupported assignment operators and unsupported := reset values`
  Acceptance: `named fixtures/catalog entries cover unsupported assignment operators and unsupported := reset values with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused operator/directive tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2: widen operator-directive corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2` shipped the selected operator/directive corpus widening. |

## Decisions

- `2026-05-20`: Selected unsupported assignment operators and unsupported
  `:=` reset values as the next R12 corpus subset because both are
  user-visible authored-source diagnostics that already have focused coverage
  but not maintained expected-failure corpus entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused operator/directive tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.1` | `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.1: select operator-directive widening` | Selection leaf; no compiler behavior changed. |
| `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2` | `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2: widen operator-directive corpus` | Adds four maintained operator/directive expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected operator/directive corpus widening and
  closed the task tree.
