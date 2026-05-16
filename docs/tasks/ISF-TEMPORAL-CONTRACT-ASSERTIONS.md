# ISF-TEMPORAL-CONTRACT-ASSERTIONS: Temporal Contract Assertion Projection

## Metadata

- Tree ID: `ISF-TEMPORAL-CONTRACT-ASSERTIONS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Project the shipped bounded eventual contract monitor's sticky fail bit into a
verification-only SystemVerilog assertion while preserving the scheduled
monitor as the source of truth.

## Non-Goals

- Do not add new temporal contract source forms.
- Do not change the monitor equations, overlap policy, reset behavior, or
  generated scheduled `.fsm` artifact.
- Do not emit SystemVerilog assertions for Verilog or other non-SystemVerilog
  targets.
- Do not expose raw monitor equations or backend assertion text in schedule
  JSON.

## Acceptance Criteria

- SystemVerilog generation for an accepted ISF bounded eventual contract emits
  an `` `ifndef SYNTHESIS`` assertion that fails when the generated sticky fail
  bit is set.
- Verilog-family output remains free of SystemVerilog assertion syntax.
- Schedule JSON advertises the bounded assertion projection status through the
  public temporal-contract value family.
- Focused regression tests cover generated HDL, schedule-report metadata, and
  non-SystemVerilog behavior.
- ISF spec, downstream handoff, public contract doc, mdBook, roadmap, task
  tree, and live docs are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TEMPORAL-CONTRACT-ASSERTIONS`
  Status: `done`
  Goal: `Ship SystemVerilog assertion projection for bounded temporal contracts.`
  Children: `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1`

- ID: `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1`
  Status: `done`
  Goal: `Emit verification-only sticky-fail assertions for bounded eventual contracts.`
  Acceptance: `SystemVerilog HDL, schedule reports, docs, and contract metadata describe the projection while Verilog stays assertion-free.`
  Verification: `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1141-isf-public-identity-flags-metadata-audit.t t/1224-isf-contract-lowering.t t/1225-isf-stage-contract-schedule-report.t t/1255-isf-schedule-report-golden-matrix.t`; `./bin/ci-regression isf`; `git diff --check`
  Commit: `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1: project contract fail assertions`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1` | `done` | Closed the bounded assertion-projection slice. |

## Decisions

- `2026-05-16`: The projected assertion checks the generated sticky fail bit,
  not the raw temporal expression. The scheduled monitor remains the source of
  truth, and the assertion is a verification-only observer under
  `` `ifndef SYNTHESIS``.
- `2026-05-16`: The first projection is SystemVerilog-only. Verilog output
  stays assertion-free, matching the existing selector-assertion policy.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1` | `perl -Iperl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Backend/GeneratedModuleEmitter.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm` | `pass` |
| `2026-05-16` | `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1` | `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1141-isf-public-identity-flags-metadata-audit.t t/1224-isf-contract-lowering.t t/1225-isf-stage-contract-schedule-report.t t/1255-isf-schedule-report-golden-matrix.t` | `pass: Files=7, Tests=18` |
| `2026-05-16` | `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1` | `./bin/ci-regression isf` | `pass: Files=162, Tests=559; mdBook built` |
| `2026-05-16` | `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1` | `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1` | `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1: project contract fail assertions` | `SystemVerilog sticky-fail assertion projection and public report metadata.` |

## Changelog

- `2026-05-16`: Created the task tree for bounded temporal contract assertion
  projection.
- `2026-05-16`: Shipped SystemVerilog sticky-fail assertion projection and
  synchronized public report metadata and docs.
