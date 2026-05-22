# ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS: Temporal Contract Actor-Constant Windows

## Metadata

- Tree ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS`
- Status: `completed`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow bounded eventual temporal-contract windows to use positive actor
constants anywhere the shipped literal `within` cycle count is accepted.

## Non-Goals

- Do not accept actor parameters, transaction parameters, runtime signals, or
  arbitrary expressions as temporal-contract windows.
- Do not add dynamic contract bounds, min/max windows, same-cycle checks,
  nested contracts, or multiple outstanding obligations.
- Do not change generated monitor timing, SystemVerilog assertion projection,
  or the public `temporal_contracts[]` schedule-report schema.

## Acceptance Criteria

- `(contract name (eventually signal (within CONST)))` lowers when `CONST` is
  a declared actor constant whose resolved value is positive.
- `(contract name (eventually signal within CONST))` lowers through the same
  path as the nested spelling.
- Schedule reports continue to expose `within_cycles` as the resolved positive
  integer, without adding an unstable source-token field.
- Unknown, zero-valued, parameter-backed, and dynamic window tokens remain
  fail-closed with targeted diagnostics.
- The ISF spec, mdBook, public contract guidance where relevant, roadmap
  status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS`
  Status: `completed`
  Goal: `ship positive actor constants as bounded eventual contract windows`
  Children: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1`,
  `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2`

- ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1`
  Status: `done`
  Goal: `select the temporal-contract actor-constant window task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `8890ca29 ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1: select contract actor-constant windows`

- ID: `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2`
  Status: `done`
  Goal: `implement and document actor-constant temporal-contract windows`
  Acceptance: `positive actor constants lower as literal windows; unsupported window tokens fail closed; docs and focused tests are synchronized`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1224-isf-contract-lowering.t`; focused contract/boundary tests; public/doc audits; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2` | `done` | Completed; no remaining frontier in this tree. |

## Decisions

- `2026-05-22`: Treat actor constants as static compile-time evidence for
  contract windows, matching the existing static-wait convention. Parameters
  remain out of scope because they are overrideable specialization values.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1` | `mdbook build docs/book`; `git diff --check` | Pass |
| 2026-05-22 | `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1224-isf-contract-lowering.t`; `prove -Iperl t/1175-isf-contract-fail-closed.t t/1180-isf-unsupported-transaction-clause-boundary.t t/1224-isf-contract-lowering.t t/1225-isf-stage-contract-schedule-report.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | Pass; broad ISF gate `Files=238, Tests=1584` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1` | `8890ca29 ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1: select contract actor-constant windows` | Selection commit. |
| `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2` | `pending this commit: ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2: ship contract actor-constant windows` | Implementation and documentation commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for positive actor constants in
  bounded eventual temporal-contract windows.
- `2026-05-22`: Shipped positive actor constants for nested and flat bounded
  eventual temporal-contract windows, with parameters and dynamic windows still
  fail-closed.
