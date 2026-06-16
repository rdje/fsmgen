# CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR: PPIF Verify-HDL CI Tool Dependency Repair

## Metadata

- Tree ID: `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR`
- Status: `done`
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
  Status: `done`
  Goal: `Repair the hosted CI failure caused by unguarded PPIF --verify-hdl subtests.`
  Children: `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1`

- ID: `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1`
  Status: `done`
  Goal: `Guard PPIF CLI --verify-hdl tests with the existing external-tool availability policy.`
  Acceptance: `PPIF --verify-hdl subtests skip when Verilator/Yosys are unavailable, still run when they are available, and the GitHub CI failure mode is covered by focused validation.`
  Verification: `pass`
  Commit: `pending commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | `done` | PPIF `--verify-hdl` tests now follow the existing external-validation tool availability policy. |

## Findings

- `2026-06-16`: GitHub run `27621526955` failed workflow `Perl FSM Regression`
  on commit `8c39827f698e0944281e996b96c99e90c93a04c6`.
- `2026-06-16`: Failed file was `t/1436-ial2-ppif-parser-cli.t` with failed
  tests `65-85, 87-88, 121`; each failing `--verify-hdl` CLI subtest reported
  `Missing external HDL validation tool(s): verilator, yosys`.
- `2026-06-16`: `t/308-systemverilog-external-validation.t` already skips the
  external SystemVerilog validation lane when required tools are unavailable,
  so the repair should align PPIF CLI tests with that established policy.
- `2026-06-16`: `t/1436-ial2-ppif-parser-cli.t` now imports
  `missing_systemverilog_validation_tools()` and skips only the exact
  tool-dependent PPIF `--verify-hdl` subtests/tail assertions when Verilator or
  Yosys are absent. Non-HDL PPIF parser, report, check-JSON, semantic-JSON,
  review-artifact, and default-HDL coverage still runs in no-tool environments.
- `2026-06-16`: With the normal tool-equipped PATH, the same `t/1436` file
  still runs and passes the PPIF `--verify-hdl` coverage.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | GitHub run `27621526955`; inspection of `t/308-systemverilog-external-validation.t`, `t/1436-ial2-ppif-parser-cli.t`, and `perl/FSM/Support/HDLExternalValidation.pm` | Failure classified; implementation pending. |
| `2026-06-16` | `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`; `env -u PERL5LIB PATH=/usr/bin:/bin prove -Iperl t/1436-ial2-ppif-parser-cli.t`; `env -u PERL5LIB prove -Iperl t/1436-ial2-ppif-parser-cli.t` | `PASS`; simulated no-Verilator/no-Yosys run passed `Files=1, Tests=121, 1456 wallclock secs`; normal tool-equipped run passed `Files=1, Tests=121, 1505 wallclock secs`. |
| `2026-06-16` | `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `env -u PERL5LIB prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `PASS`; Knowledge Map has `230` facts / `1379` question keys; memory, docs path, and whitespace gates pass. |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` | `CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1: guard PPIF verify-hdl tests` | `pending commit` |

## Changelog

- `2026-06-16`: Created task tree and selected the hosted CI PPIF
  `--verify-hdl` tool-dependency repair leaf.
- `2026-06-16`: Closed `.1` after guarding PPIF CLI `--verify-hdl` tests with
  the existing external-tool availability policy and proving both no-tool and
  tool-equipped focused runs pass.
