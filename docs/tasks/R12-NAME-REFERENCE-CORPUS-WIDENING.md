# R12-NAME-REFERENCE-CORPUS-WIDENING: Name/Reference Corpus Widening

## Metadata

- Tree ID: `R12-NAME-REFERENCE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused source-name, state/DT-name, and transition-target
language-contract failures into the maintained expected-failure regression
corpus with stable diagnostics and public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not rename existing focused tests or collapse their current coverage.
- Do not widen the composition wiring/name-resolution contract in this tree.
- Do not claim all name/reference behavior is exhausted; this tree covers one
  bounded subset of already-focused language-contract rejections.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected name/reference rejection families
  into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-NAME-REFERENCE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for name/reference language-contract failures`
  Children: `R12-NAME-REFERENCE-CORPUS-WIDENING.1`, `R12-NAME-REFERENCE-CORPUS-WIDENING.2`

- ID: `R12-NAME-REFERENCE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the name/reference corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-NAME-REFERENCE-CORPUS-WIDENING.1: select name-reference widening`

- ID: `R12-NAME-REFERENCE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for source-name, state/DT-name, and transition-target rejection families`
  Acceptance: `named fixtures/catalog entries cover malformed source roots, malformed state/DT names, malformed transition targets, and unknown transition targets with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-NAME-REFERENCE-CORPUS-WIDENING.2` | `pending` | Focused tests already cover these language-contract failures; the maintained corpus does not yet carry them as stable support-accounting entries. |

## Decisions

- `2026-05-20`: Selected name/reference failures as the next R12 corpus subset
  because malformed source names, malformed state/DT names, malformed
  transition targets, and unknown transition targets are user-visible
  diagnostics that already have focused coverage but not maintained
  expected-failure corpus entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-NAME-REFERENCE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-NAME-REFERENCE-CORPUS-WIDENING.1` | `R12-NAME-REFERENCE-CORPUS-WIDENING.1: select name-reference widening` | Selection leaf; no compiler behavior changed. |
| `R12-NAME-REFERENCE-CORPUS-WIDENING.2` | `pending` | Implementation leaf pending. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
