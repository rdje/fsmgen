# R12-STATE-DTE-GUARD-CORPUS-WIDENING: State DTE Guard Corpus Widening

## Metadata

- Tree ID: `R12-STATE-DTE-GUARD-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote the already-focused supported state-DT header activation guard behavior
into the maintained supported-smoke regression corpus with strict-supported
coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change non-state DT guard semantics in this tree.
- Do not change guard-expression parsing, factoring, or output-enable
  boundary-gating behavior.
- Do not widen unrelated state-transition or assignment surfaces.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes supported regular-state header DTE guards
  into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations for state enable and DTE boundary-gating behavior.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-STATE-DTE-GUARD-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for state-DT header activation guards`
  Children: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1`, `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2`

- ID: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the state-DT header guard corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1: select state-DTE guard widening`

- ID: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for state-DT header guards`
  Acceptance: `named fixture/catalog entry covers scalar and expression state-DT header guards with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2` | `pending` | Promotes an already-focused supported state activation surface after ownership is committed. |

## Decisions

- `2026-05-20`: Selected regular-state DTE header guards as the next R12
  corpus subset because
  [t/82-language-contract-state-dt-dte-guards.t](../../t/82-language-contract-state-dt-dte-guards.t)
  already locks scalar and expression guard lowering, while the maintained
  supported-smoke corpus does not yet carry a state-DT activation-guard entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1` | `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1: select state-DTE guard widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
