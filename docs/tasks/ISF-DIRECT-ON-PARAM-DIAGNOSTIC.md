# ISF-DIRECT-ON-PARAM-DIAGNOSTIC: Direct Entry Parameter Diagnostic

## Metadata

- Tree ID: `ISF-DIRECT-ON-PARAM-DIAGNOSTIC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Make unsupported direct `(on ... (params ...))` syntax fail closed with a
diagnostic that names the direct-entry specialization boundary, not only the
generic `(on ...)` body-shape rule.

## Non-Goals

- Do not accept activation-site `(params ...)` on direct `(on ...)` entry
  guards.
- Do not change legal `(on ... (sample ...))` behavior.
- Do not change generated `.fsm`, HDL, schedule-report schema, public API, or
  runtime behavior for accepted sources.
- Do not reopen general activation parameter override semantics.

## Acceptance Criteria

- Direct `(on start (params ...))` still fails before scheduled `.fsm`
  emission.
- The diagnostic explains that direct `(on ...)` is an entry guard, not a
  generated activation-site parameter override.
- Legal `(on start (sample ...))` behavior remains covered and green.
- Specs, mdBook, public contract notes, task tree, roadmap status, and live
  docs record the diagnostic-only boundary.
- Focused parser/lowering/public-doc/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DIRECT-ON-PARAM-DIAGNOSTIC`
  Status: `done`
  Goal: `Clarify direct entry parameter override rejection diagnostics.`
  Children: `ISF-DIRECT-ON-PARAM-DIAGNOSTIC.1`

- ID: `ISF-DIRECT-ON-PARAM-DIAGNOSTIC.1`
  Status: `done`
  Goal: `Harden the direct (on ... params) diagnostic.`
  Acceptance: `Direct on-entry params still reject, but the diagnostic names the direct-entry generated-specialization boundary; existing sample coverage remains green.`
  Verification: `syntax checks; focused sample/public-doc/book tests; mdBook build; git diff --check`
  Commit: `ISF-DIRECT-ON-PARAM-DIAGNOSTIC.1: clarify direct on params diagnostic`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Keep this diagnostic-only. Static transaction parameter
  specialization remains limited to generated activation sites such as spawn,
  parameterized blocking `do`, and parameterized rule `trigger`.

## Open Questions

- None for this diagnostic slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-DIRECT-ON-PARAM-DIAGNOSTIC.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1195-isf-sample-clause-boundary.t`; `prove -Iperl t/1195-isf-sample-clause-boundary.t t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DIRECT-ON-PARAM-DIAGNOSTIC.1` | `ISF-DIRECT-ON-PARAM-DIAGNOSTIC.1: clarify direct on params diagnostic` | `completion commit` |

## Changelog

- `2026-05-25`: Created active task tree for direct `(on ... (params ...))`
  diagnostic hardening.
- `2026-05-25`: Completed diagnostic hardening; direct `(on ... (params ...))`
  still fails closed, now with the entry-guard/generated-activation boundary
  in the diagnostic.
