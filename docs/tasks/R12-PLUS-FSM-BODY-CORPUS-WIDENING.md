# R12-PLUS-FSM-BODY-CORPUS-WIDENING: Plus-FSM Body Corpus Widening

## Metadata

- Tree ID: `R12-PLUS-FSM-BODY-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused malformed legacy `+fsm` root-body failures into the
maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not alter strict-mode legacy `+fsm` root compatibility policy.
- Do not add new legacy `+fsm` root-body syntax.
- Do not cover structured `?fsm:name` root-body failures in this tree.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected malformed `+fsm` root-body
  rejection families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-PLUS-FSM-BODY-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained expected-failure corpus coverage for malformed legacy +fsm root bodies`
  Children: `R12-PLUS-FSM-BODY-CORPUS-WIDENING.1`, `R12-PLUS-FSM-BODY-CORPUS-WIDENING.2`

- ID: `R12-PLUS-FSM-BODY-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the plus-fsm body corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-PLUS-FSM-BODY-CORPUS-WIDENING.1: select plus-FSM body widening`

- ID: `R12-PLUS-FSM-BODY-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add maintained expected-failure entries for empty and scalar legacy +fsm root bodies`
  Acceptance: `named fixtures/catalog entries cover empty +fsm roots and scalar nested +fsm body items with stable diagnostics and corpus behavior checks`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-PLUS-FSM-BODY-CORPUS-WIDENING.2` | `pending` | Promotes the already-focused legacy +fsm body diagnostics after ownership is committed. |

## Decisions

- `2026-05-20`: Selected empty legacy `+fsm` root bodies and scalar nested
  `+fsm` body items as the next R12 corpus subset because both are
  user-visible source-shape diagnostics with focused coverage but no maintained
  expected-failure corpus entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-PLUS-FSM-BODY-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-PLUS-FSM-BODY-CORPUS-WIDENING.1` | `R12-PLUS-FSM-BODY-CORPUS-WIDENING.1: select plus-FSM body widening` | Selection leaf; no compiler behavior changed. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
