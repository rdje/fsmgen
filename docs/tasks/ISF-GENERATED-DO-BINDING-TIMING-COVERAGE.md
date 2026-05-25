# ISF-GENERATED-DO-BINDING-TIMING-COVERAGE: Generated Do Binding Timing Coverage

## Metadata

- Tree ID: `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Add focused regression coverage for the already-shipped generated blocking
`do` input-binding timing surface.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report schema, public contract code, or runtime behavior.
- Do not add behavior-changing snapshot/live timing conversion.
- Do not widen binding timing syntax beyond current-timing assertions.

## Acceptance Criteria

- A parameterized/generated blocking `do` input binding with `(timing live)`
  is accepted and reports `binding_timing => generated_live_handoff` plus
  `authored_timing_mode => live`.
- A parameterized/generated blocking `do` input binding with
  `(timing snapshot)` fails closed against the generated-live current timing
  class.
- Existing local `do`, `spawn`, and rule-trigger timing coverage remains green.
- Task tree, roadmap status, live docs, and change history record this as
  coverage-only behavior preservation.
- Focused syntax/test validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE`
  Status: `done`
  Goal: `Lock generated blocking do timing assertion coverage.`
  Children: `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1`

- ID: `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1`
  Status: `done`
  Goal: `Cover generated do live timing acceptance and snapshot rejection.`
  Acceptance: `Generated blocking do timing assertions are explicitly covered without changing production behavior.`
  Verification: `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `prove -Iperl t/1241-isf-transaction-port-bindings.t`; focused port-binding/report/spec/book audits; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1: cover generated do timing`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1` | `done` | Generated blocking `do` timing assertions are now explicit regression coverage. |

## Decisions

- `2026-05-25`: Keep this coverage-only. Generated blocking `do` input
  bindings already use generated-top live handoff wiring; this slice only
  makes that timing assertion explicit in regression coverage.

## Open Questions

- None for this coverage slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1` | `perl -Iperl -c t/1241-isf-transaction-port-bindings.t`; `prove -Iperl t/1241-isf-transaction-port-bindings.t`; focused port-binding/report/spec/book audits; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1` | `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1: cover generated do timing` | Coverage-only; production lowering/report/runtime behavior unchanged. |

## Changelog

- `2026-05-25`: Created active task tree for generated blocking `do` binding
  timing coverage.
- `2026-05-25`: Covered generated blocking `do` `(timing live)` acceptance,
  report metadata, and generated-live snapshot mismatch rejection without
  changing production behavior; closed the task tree.
