# ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC: Rule Trigger Duplicate Output Target Diagnostic

## Metadata

- Tree ID: `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Reject a rule that has multiple generated-child trigger output bindings
targeting the same actor signal across the rule's trigger actions.

## Non-Goals

- Do not change generated-child rule-trigger output binding behavior when each
  actor output target is unique within the rule.
- Do not add direct/local rule-trigger output bindings.
- Do not replace broader assignment conflict detection.
- Do not change generated `.fsm`, HDL, schedule-report schema, public API, or
  runtime behavior for accepted sources.

## Acceptance Criteria

- A rule with two generated-child trigger output bindings to the same actor
  signal fails closed before scheduled `.fsm` emission.
- The diagnostic names the rule and duplicated actor target.
- Existing generated-child rule-trigger output binding behavior remains green.
- Specs, mdBook, task tree, roadmap status, and live docs record the
  diagnostic-only boundary.
- Focused lowering/report/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC`
  Status: `done`
  Goal: `Add a rule-local duplicate generated-trigger output target diagnostic.`
  Children: `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1`

- ID: `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1`
  Status: `done`
  Goal: `Reject duplicate generated rule-trigger output actor targets within one rule.`
  Acceptance: `Duplicate generated rule-trigger output actor targets in one rule reject with a targeted diagnostic while existing generated output-binding paths stay green.`
  Verification: `syntax checks; focused rule-trigger/port-binding/report/spec/book tests; final live-doc/book audits; mdBook build; git diff --check`
  Commit: `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1: reject duplicate trigger output targets`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Keep the check rule-local. Two generated trigger output
  copies in the same rule that target one actor signal have no source-level
  selection policy, and their completion cycles cannot be statically ordered
  by the binding surface.

## Open Questions

- None for this diagnostic slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1248-isf-rule-trigger-parameter-binding.t`; `prove -Iperl t/1248-isf-rule-trigger-parameter-binding.t t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1243-isf-port-binding-schedule-report.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1` | `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1: reject duplicate trigger output targets` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree for rule-local duplicate generated
  rule-trigger output actor-target diagnostics.
- `2026-05-25`: Completed diagnostic hardening; generated rule-trigger output
  bindings inside one rule now fail closed when they target the same actor
  signal.
