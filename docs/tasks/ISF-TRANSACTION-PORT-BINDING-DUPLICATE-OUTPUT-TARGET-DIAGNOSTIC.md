# ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC: Duplicate Output Binding Target Diagnostic

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Reject multiple transaction output bindings in one activation bind block when
they target the same actor signal, with a direct binding-level diagnostic.

## Non-Goals

- Do not change accepted single-output binding behavior.
- Do not change input binding fan-out behavior.
- Do not change generated `.fsm`, HDL, schedule-report schema, public API, or
  runtime behavior for accepted sources.
- Do not replace broader assignment conflict detection.

## Acceptance Criteria

- A bind block that maps two output ports to the same actor target fails
  closed before scheduled `.fsm` emission.
- The diagnostic names the duplicated actor target and the activation context.
- Existing generated-child rule-trigger output binding behavior remains green.
- Specs, mdBook, task tree, roadmap status, and live docs record the
  diagnostic-only boundary.
- Focused parser/lowering/report/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC`
  Status: `done`
  Goal: `Add a targeted duplicate output binding actor-target diagnostic.`
  Children: `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1`

- ID: `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1`
  Status: `done`
  Goal: `Reject duplicate output actor targets inside one bind block.`
  Acceptance: `Duplicate output actor targets in one bind block reject with a targeted diagnostic while existing output-binding paths stay green.`
  Verification: `syntax checks; focused transaction-port/conflict/spec/book tests; final live-doc/book audits; mdBook build; git diff --check`
  Commit: `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1: reject duplicate output targets`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Keep the check activation-local. Broader cross-activation
  assignment conflicts remain owned by the existing conflict machinery.

## Open Questions

- None for this diagnostic slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `prove -Iperl t/1241-isf-transaction-port-bindings.t t/1242-isf-port-binding-conflict-semantics.t t/1248-isf-rule-trigger-parameter-binding.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1` | `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1: reject duplicate output targets` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree for duplicate output actor-target
  binding diagnostics.
- `2026-05-25`: Completed diagnostic hardening; duplicate output actor targets
  inside one bind block now fail closed before scheduled `.fsm` emission.
