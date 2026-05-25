# ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC: Rule-Trigger Output History Truth Sync

## Metadata

- Tree ID: `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 roadmap maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize stale current and historical documentation that still says
rule-trigger output bindings are wholly unsupported after generated-child
rule-trigger output bindings shipped.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public contract code, or runtime behavior.
- Do not claim direct/local rule-trigger output bindings are shipped.
- Do not alter the historical sequence of earlier slices beyond noting the
  later shipped state.

## Acceptance Criteria

- The mdBook activation-parameter backlog text distinguishes shipped
  generated-child rule-trigger output bindings from deferred direct/local
  rule-trigger output bindings.
- Historical live/recovery notes that say rule-trigger output bindings remain
  unsupported are synchronized with the later shipped generated-child surface.
- The task tree, roadmap status, live docs, and change history record this as
  documentation-only truth synchronization.
- Focused public-doc/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize stale rule-trigger output-binding history.`
  Children: `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.1`

- ID: `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Sync rule-trigger output-binding docs with the later generated-child shipment.`
  Acceptance: `Current mdBook wording and historical recovery notes no longer imply all rule-trigger output bindings are unsupported.`
  Verification: `stale wording grep; focused live-doc/book audits; mdBook build; git diff --check`
  Commit: `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-SYNC.1: sync trigger output history`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Keep this docs-only. Generated-child rule-trigger output
  bindings are shipped; direct/local rule-trigger output bindings remain
  deferred behind the completion-identity boundary.

## Open Questions

- None for this truth-sync slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.1` | stale broad-output wording grep confirmed remaining matches are direct/local deferrals; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.1` | `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-SYNC.1: sync trigger output history` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree for rule-trigger output-binding
  historical truth synchronization.
- `2026-05-25`: Completed truth synchronization; current mdBook and
  historical recovery notes now distinguish shipped generated-child
  rule-trigger output bindings from deferred direct/local targets.
