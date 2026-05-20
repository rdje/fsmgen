# R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING: Test-Selector Default Corpus Widening

## Metadata

- Tree ID: `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused duplicate default test-selector failure into the
maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change supported `default` or `_` selector lowering when only one
  default branch exists.
- Do not change operator-prefixed selector semantics.
- Do not widen computed test-selector failures in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes duplicate default selector rejection into a
  named expected-failure catalog entry.
- The new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for duplicate default test selectors`
  Children: `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.1`, `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.2`

- ID: `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the duplicate default test-selector corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.1: select duplicate default selector widening`

- ID: `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained expected-failure entry for duplicate default selector branches`
  Acceptance: `named fixture/catalog entry covers duplicate default and underscore selector branches with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.2` | `pending` | Promotes the already-focused duplicate default selector diagnostic after ownership is committed. |

## Decisions

- `2026-05-20`: Selected duplicate `default` / `_` selector rejection as the
  next R12 corpus subset because
  [t/42-language-contract-test-selector-boundary.t](../../t/42-language-contract-test-selector-boundary.t)
  already locks the fail-closed behavior, while the maintained corpus accounts
  for bare selector labels but not duplicate default selector branches.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.1` | `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.1: select duplicate default selector widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
