# R12-STATE-DTE-GUARD-CORPUS-WIDENING: State DTE Guard Corpus Widening

## Metadata

- Tree ID: `R12-STATE-DTE-GUARD-CORPUS-WIDENING`
- Status: `done`
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
  Status: `done`
  Goal: `widen maintained supported-smoke corpus coverage for state-DT header activation guards`
  Children: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1`, `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2`

- ID: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the state-DT header guard corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1: select state-DTE guard widening`

- ID: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add a maintained supported-smoke entry for state-DT header guards`
  Acceptance: `named fixture/catalog entry covers scalar and expression state-DT header guards with strict-supported checks and HDL-shape expectations`
  Verification: `perl -Iperl -c` for touched support/tests; focused state-DT DTE guard tests; supported language-feature corpus tests; supported corpus behavior/check-json/semantic-json gates; capability manifest gate; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2: widen state-DTE guard corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2` shipped the selected state-DTE guard corpus widening. |

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
| `2026-05-20` | `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused state-DT DTE guard tests; supported language-feature corpus tests; supported corpus behavior/check-json/semantic-json gates; capability manifest gate; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1` | `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1: select state-DTE guard widening` | Selection leaf; no compiler behavior changed. |
| `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2` | `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2: widen state-DTE guard corpus` | Adds one maintained supported state-DTE guard smoke entry. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Added a maintained supported-smoke entry for regular-state
  header DTE guards, then closed the tree.
