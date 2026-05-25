# ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC: Local Rule-Trigger Output Binding Diagnostic

## Metadata

- Tree ID: `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Make the direct/local rule-trigger output-binding rejection explain the real
completion-identity boundary now that generated-child rule-trigger output
bindings are shipped.

## Non-Goals

- Do not accept direct/local rule-trigger output bindings.
- Do not change generated-child rule-trigger output-binding behavior.
- Do not change scheduler lowering, generated `.fsm`, HDL, schedule-report
  schema, public API, or runtime behavior.

## Acceptance Criteria

- Direct/local rule-trigger output bindings still fail closed.
- The diagnostic says rule-trigger output bindings require generated-child
  completion identity and that direct/local targets do not provide it.
- Existing generated-child rule-trigger output-binding coverage remains green.
- Specs, mdBook, task tree, roadmap status, and live docs reflect the
  diagnostic-only boundary when the leaf lands.
- Focused parser/lowering/report/book validation passes; broader validation
  runs if warranted.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC`
  Status: `done`
  Goal: `Clarify direct/local rule-trigger output-binding rejection diagnostics.`
  Children: `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.1`

- ID: `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.1`
  Status: `done`
  Goal: `Harden the direct/local rule-trigger output-binding diagnostic.`
  Acceptance: `Direct/local rule-trigger output bindings still reject, but the diagnostic names the missing generated-child completion identity; generated-child output-binding coverage remains green.`
  Verification: `syntax checks; focused transaction-port/report/book tests; mdBook build; git diff --check`
  Commit: `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.1: clarify local trigger output diagnostic`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Keep this diagnostic-only. Accepting direct/local rule-trigger
  output bindings still needs a separate completion-identity contract.

## Open Questions

- None for this diagnostic slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `perl -Iperl -c t/1248-isf-rule-trigger-parameter-binding.t`; `prove -Iperl t/1241-isf-transaction-port-bindings.t t/1248-isf-rule-trigger-parameter-binding.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `prove -Iperl t/1242-isf-port-binding-conflict-semantics.t t/1255-isf-schedule-report-golden-matrix.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.1` | `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.1: clarify local trigger output diagnostic` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree for direct/local rule-trigger
  output-binding diagnostic hardening.
- `2026-05-25`: Completed diagnostic hardening; direct/local rule-trigger
  output bindings still fail closed, now with the generated-child completion
  identity reason.
