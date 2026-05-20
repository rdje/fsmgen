# R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING: Test-Branch Selector Corpus Widening

## Metadata

- Tree ID: `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported relational test-branch selector behavior
into the maintained supported-smoke regression corpus with strict-supported
coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed bare selector diagnostics in this tree.
- Do not change computed `?(expr)` selector support-accounting.
- Do not widen unrelated guard or expression-operator surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported relational test-branch selectors
  into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for nonzero reduction and relational branch-selector lowering.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for relational test-branch selectors`
  Children: `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.1`, `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.2`

- ID: `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the relational test-branch selector corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.1: select branch selector widening`

- ID: `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for relational test-branch selectors`
  Acceptance: `named fixture/catalog entry covers nonzero, greater-than, and less-or-equal branch selectors with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.2` | `pending` | Promotes an already-focused supported branch-selector surface after ownership is committed. |

## Decisions

- `2026-05-20`: Selected relational test-branch selectors as the next R12
  corpus subset because
  [t/36-language-contract-test-branch-selectors.t](../../t/36-language-contract-test-branch-selectors.t)
  already locks `!=`, `>`, and `<=` branch selector lowering, while the
  maintained corpus currently accounts for malformed selectors but not this
  supported selector surface.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.1` | `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.1: select branch selector widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
