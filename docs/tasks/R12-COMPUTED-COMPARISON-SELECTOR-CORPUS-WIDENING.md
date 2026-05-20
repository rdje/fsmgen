# R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING: Computed Comparison Selector Corpus Widening

## Metadata

- Tree ID: `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported computed selector comparison behavior
into the maintained supported-smoke regression corpus with strict-supported
coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed computed selector diagnostics.
- Do not change existing bitwise computed selector, plain selector, or
  fallback selector support-accounting.
- Do not widen unrelated expression operator surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes computed comparison selectors into a named
  supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for comparison-expression intermediate generation and
  branch-local assignment enables.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for computed comparison selectors`
  Children: `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.1`, `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.2`

- ID: `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the computed comparison selector corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.1: select computed comparison selector widening`

- ID: `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for computed comparison selectors`
  Acceptance: `named fixture/catalog entry covers ?(== A B) computed selector lowering with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.2` | `pending` | Promotes already-focused computed comparison selector behavior after ownership is committed. |

## Decisions

- `2026-05-20`: Selected computed comparison selectors as the next R12 corpus
  subset because
  [t/37-language-contract-computed-test-selector.t](../../t/37-language-contract-computed-test-selector.t)
  already locks `?(== A B)` as an expression-valued selector rather than a
  branch marker, while the maintained corpus currently accounts for bitwise
  computed selectors but not comparison-expression computed selectors.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.1` | `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.1: select computed comparison selector widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
