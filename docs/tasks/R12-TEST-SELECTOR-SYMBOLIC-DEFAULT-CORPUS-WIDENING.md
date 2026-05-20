# R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING: Symbolic/Default Test-Selector Corpus Widening

## Metadata

- Tree ID: `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported symbolic equality selector and
`default` / `_` fallback selector behavior into the maintained supported-smoke
regression corpus with strict-supported coverage and public
support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed bare selector diagnostics or duplicate-default
  selector diagnostics.
- Do not change plain `?SIG`, relational branch-selector, or computed
  selector support-accounting.
- Do not widen unrelated guard or transition surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported symbolic equality selectors and
  fallback selectors into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for named equality comparisons, default predicate negation, and
  underscore fallback alias behavior.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for symbolic and fallback test selectors`
  Children: `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.1`, `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.2`

- ID: `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the symbolic/default selector corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.1: select symbolic/default selector widening`

- ID: `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for symbolic and fallback test selectors`
  Acceptance: `named fixture/catalog entry covers =OTHER, default, and _ selector branches with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.2` | `pending` | Promotes already-focused supported symbolic/default selector behavior after ownership is committed. |

## Decisions

- `2026-05-20`: Selected symbolic equality selectors and fallback selectors as
  the next R12 corpus subset because
  [t/42-language-contract-test-selector-boundary.t](../../t/42-language-contract-test-selector-boundary.t)
  already locks `=OTHER`, `default`, and `_` selector lowering, while the
  maintained corpus currently records malformed/duplicate default selector
  diagnostics and other supported selector families but not this supported
  symbolic/fallback selector surface.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.1` | `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.1: select symbolic/default selector widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
