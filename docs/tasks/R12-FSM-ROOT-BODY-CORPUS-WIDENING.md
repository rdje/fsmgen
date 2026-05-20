# R12-FSM-ROOT-BODY-CORPUS-WIDENING: FSM-Root Body Corpus Widening

## Metadata

- Tree ID: `R12-FSM-ROOT-BODY-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused malformed structured `?fsm` root-body failures into
the maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not add new top-level root, source-kind, or body-item syntax.
- Do not alter supported structured `?fsm:name` bodies.
- Do not claim all root/body behavior is exhausted; this tree covers one
  bounded subset of already-focused structured-root body rejection behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected structured `?fsm` root-body
  rejection families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-FSM-ROOT-BODY-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for malformed structured ?fsm root-body failures`
  Children: `R12-FSM-ROOT-BODY-CORPUS-WIDENING.1`, `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2`

- ID: `R12-FSM-ROOT-BODY-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the FSM-root body corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-FSM-ROOT-BODY-CORPUS-WIDENING.1: select FSM-root body widening`

- ID: `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for empty and scalar structured ?fsm root bodies`
  Acceptance: `named fixtures/catalog entries cover empty structured ?fsm roots and scalar top-level body items with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused FSM-root body tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2: widen FSM-root body corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2` shipped the selected FSM-root body corpus widening. |

## Decisions

- `2026-05-20`: Selected empty structured `?fsm` roots and scalar top-level
  body items as the next R12 corpus subset because both are user-visible
  source-shape diagnostics with focused coverage but no maintained
  expected-failure corpus entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-FSM-ROOT-BODY-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused FSM-root body tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-FSM-ROOT-BODY-CORPUS-WIDENING.1` | `R12-FSM-ROOT-BODY-CORPUS-WIDENING.1: select FSM-root body widening` | Selection leaf; no compiler behavior changed. |
| `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2` | `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2: widen FSM-root body corpus` | Adds two maintained structured `?fsm` root-body expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected FSM-root body corpus widening and closed
  the task tree.
