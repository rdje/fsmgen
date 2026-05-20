# R12-STATE-BODY-CORPUS-WIDENING: State-Body Corpus Widening

## Metadata

- Tree ID: `R12-STATE-BODY-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused malformed state/DT body failures into the maintained
expected-failure regression corpus with stable diagnostics and public report
coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new state, DT, DTE, or guard syntax.
- Do not alter supported state and standalone-DT body forms.
- Do not claim all state/DT behavior is exhausted; this tree covers one
  bounded subset of already-focused empty-body rejection behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected state/DT empty-body rejection
  families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-STATE-BODY-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for malformed state/DT body failures`
  Children: `R12-STATE-BODY-CORPUS-WIDENING.1`, `R12-STATE-BODY-CORPUS-WIDENING.2`

- ID: `R12-STATE-BODY-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the state-body corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STATE-BODY-CORPUS-WIDENING.1: select state-body widening`

- ID: `R12-STATE-BODY-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for empty state and standalone-DT bodies`
  Acceptance: `named fixtures/catalog entries cover empty regular state bodies and empty standalone-DT bodies with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused state-body tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STATE-BODY-CORPUS-WIDENING.2: widen state-body corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-STATE-BODY-CORPUS-WIDENING.2` shipped the selected state-body corpus widening. |

## Decisions

- `2026-05-20`: Selected empty regular state bodies and empty standalone-DT
  bodies as the next R12 corpus subset because both are user-visible
  state/DT-shape diagnostics with focused coverage but no maintained
  expected-failure corpus entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-STATE-BODY-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-STATE-BODY-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused state-body tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-STATE-BODY-CORPUS-WIDENING.1` | `R12-STATE-BODY-CORPUS-WIDENING.1: select state-body widening` | Selection leaf; no compiler behavior changed. |
| `R12-STATE-BODY-CORPUS-WIDENING.2` | `R12-STATE-BODY-CORPUS-WIDENING.2: widen state-body corpus` | Adds two maintained state-body expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected state-body corpus widening and closed the
  task tree.
