# ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC: Transaction Priority Book Truth Sync

## Metadata

- Tree ID: `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Synchronize the mdBook intent-scheduling chapter with the shipped
transaction-over-rule same-target data priority behavior.

## Non-Goals

- Do not change parser, scheduler, report, generated artifact, HDL, CLI,
  public API, source, test, or generated behavior.
- Do not widen transaction-over-rule priority beyond the already shipped
  covered same-target data case.

## Acceptance Criteria

- The mdBook no longer claims transaction-over-rule priority is deferred.
- The mdBook describes the shipped `(state_active STATE)` scheduled `.fsm`
  guard boundary and the remaining fail-closed conflict surfaces.
- Focused documentation validation passes.
- Live docs and task-tree status are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize stale transaction-over-rule priority book prose`
  Children: `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1`

- ID: `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Correct the stale mdBook current-limitation text`
  Acceptance: `The book states that covered transaction-over-rule same-target data priority is shipped and names the remaining fail-closed boundaries`
  Verification: `passed`
  Commit: `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1: sync transaction priority book truth`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1` | `done` | Closed stale intent-scheduling chapter prose after the feature shipped. |

## Decisions

- `2026-05-24`: Scope this as a documentation truth-sync leaf because the
  codebase, spec, public contract, downstream handoff, feature matrix, and
  focused rule chapter already describe the shipped behavior.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1` | `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1` | `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1: sync transaction priority book truth` | `documentation truth-sync slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the one-leaf documentation
  truth-sync frontier.
- `2026-05-24`: Corrected the stale mdBook transaction-over-rule priority
  limitation text and closed the tree.
