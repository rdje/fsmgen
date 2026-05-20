# R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING: Computed Test-Selector Corpus Widening

## Metadata

- Tree ID: `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported computed test-selector behavior into the
maintained supported-smoke regression corpus with strict-supported coverage and
public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change malformed computed test-selector diagnostics in this tree.
- Do not change plain `?SIG` selector or relational branch-selector semantics.
- Do not widen unrelated guard or expression-operator surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported `?(expr)` computed selectors into
  a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for computed-selector intermediate generation and branch reuse.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for computed test selectors`
  Children: `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.1`, `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2`

- ID: `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the computed test-selector corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.1: select computed selector widening`

- ID: `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for computed test selectors`
  Acceptance: `named fixture/catalog entry covers computed selector intermediate generation, explicit selector branches, and default branch reuse with strict-supported checks and HDL-shape expectations`
  Verification: `perl -Iperl -c` for touched support/tests; focused computed test-selector tests; supported language-feature corpus tests; supported corpus behavior/check-json/semantic-json gates; capability manifest gate; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2: widen computed selector corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2` shipped the selected computed test-selector corpus widening. |

## Decisions

- `2026-05-20`: Selected computed test selectors as the next R12 corpus subset
  because
  [t/37-language-contract-computed-test-selector.t](../../t/37-language-contract-computed-test-selector.t)
  already locks computed-selector intermediate generation and branch reuse,
  while the maintained corpus currently accounts for malformed computed
  selectors but not the supported `?(expr)` surface.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused computed test-selector tests; supported language-feature corpus tests; supported corpus behavior/check-json/semantic-json gates; capability manifest gate; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.1` | `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.1: select computed selector widening` | Selection leaf; no compiler behavior changed. |
| `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2` | `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2: widen computed selector corpus` | Adds one maintained supported computed selector smoke entry. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Added a maintained supported-smoke entry for computed test
  selectors, then closed the tree.
