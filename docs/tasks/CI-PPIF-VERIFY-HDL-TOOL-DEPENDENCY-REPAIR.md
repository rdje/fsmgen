# CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR: PPIF Verify-HDL CI Tool Dependency Repair

## Metadata

- Tree ID: `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR`
- Status: `active`
- Roadmap lane: `CI / regression integrity`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Repair the failed GitHub `Perl FSM Regression` run `27621526955`, where
PPIF CLI `--verify-hdl` subtests in `t/1436-ial2-ppif-parser-cli.t` failed on
the hosted runner because required external HDL validation tools were not
installed.

## Non-Goals

- Do not weaken `--verify-hdl` behavior when Verilator and Yosys are installed.
- Do not remove PPIF HDL validation coverage from tool-equipped environments.
- Do not install heavyweight hosted-CI packages unless the existing optional
  external-validation policy proves insufficient.
- Do not edit frozen legacy prose logs.
- Do not change generated HDL, PPIF parsing, or IAL2 lowering behavior.

## Acceptance Criteria

- GitHub run `27621526955` is classified with exact failing test evidence.
- The PPIF CLI regression aligns with the existing external SystemVerilog
  validation policy: skip tool-dependent `--verify-hdl` checks when required
  tools are unavailable, but keep the checks active when the tools are present.
- Focused validation proves `t/1436-ial2-ppif-parser-cli.t` no longer fails in
  a simulated no-Verilator/no-Yosys environment.
- Focused validation keeps existing external-validation coverage passing in a
  normal tool-equipped environment, where available.
- Memory, task-tree state, Knowledge Map, and user-facing docs are updated if
  durable policy or behavior documentation changes.
- The completed leaf is committed through `COMMIT.md` with this work-unit id.

## Task Tree

- ID: `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR`
  Status: `active`
  Goal: `Repair the hosted CI failure caused by unguarded PPIF --verify-hdl subtests.`
  Children: `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1`

- ID: `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1`
  Status: `pending`
  Goal: `Guard PPIF CLI --verify-hdl tests with the existing external-tool availability policy.`
  Acceptance: `PPIF --verify-hdl subtests skip when Verilator/Yosys are unavailable, still run when they are available, and the GitHub CI failure mode is covered by focused validation.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | `pending` | GitHub run `27621526955` failed because PPIF `--verify-hdl` tests were not guarded like the existing external-validation regression. |

## Findings

- `2026-06-16`: GitHub run `27621526955` failed workflow `Perl FSM Regression`
  on commit `8c39827f698e0944281e996b96c99e90c93a04c6`.
- `2026-06-16`: Failed file was `t/1436-ial2-ppif-parser-cli.t` with failed
  tests `65-85, 87-88, 121`; each failing `--verify-hdl` CLI subtest reported
  `Missing external HDL validation tool(s): verilator, yosys`.
- `2026-06-16`: `t/308-systemverilog-external-validation.t` already skips the
  external SystemVerilog validation lane when required tools are unavailable,
  so the repair should align PPIF CLI tests with that established policy.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | GitHub run `27621526955`; inspection of `t/308-systemverilog-external-validation.t`, `t/1436-ial2-ppif-parser-cli.t`, and `perl/FSM/Support/HDLExternalValidation.pm` | Failure classified; implementation pending. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | `pending` | `pending` |

## Changelog

- `2026-06-16`: Created task tree and selected the hosted CI PPIF
  `--verify-hdl` tool-dependency repair leaf.
