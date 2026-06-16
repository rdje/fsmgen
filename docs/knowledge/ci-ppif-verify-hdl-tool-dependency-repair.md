---
id: ci-ppif-verify-hdl-tool-dependency-repair
title: PPIF verify-hdl tests follow optional external-tool policy
answers:
  - "why did GitHub run 27621526955 fail?"
  - "what owns the PPIF verify-hdl missing tools CI repair?"
  - "do PPIF --verify-hdl tests skip when Verilator or Yosys are missing?"
  - "how is t/1436 guarded for missing external HDL validation tools?"
  - "what is CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1?"
date: 2026-06-16
status: current
tags: [ci, regression, ppif, verify-hdl, verilator, yosys, task-tree]
evidence: docs/tasks/CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.md; t/1436-ial2-ppif-parser-cli.t; t/308-systemverilog-external-validation.t; perl/FSM/Support/HDLExternalValidation.pm; README.md
reverify: rg -n '27621526955|external_systemverilog_validation_skip_reason|missing_systemverilog_validation_tools|External SystemVerilog validation tools are not installed|--verify-hdl' docs/tasks/CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.md t/1436-ial2-ppif-parser-cli.t t/308-systemverilog-external-validation.t perl/FSM/Support/HDLExternalValidation.pm README.md
---

GitHub `Perl FSM Regression` run `27621526955` failed on commit `8c39827f`
because `t/1436-ial2-ppif-parser-cli.t` contained PPIF CLI `--verify-hdl`
subtests that expected Verilator and Yosys to be installed on the hosted
runner. The CLI correctly reported `Missing external HDL validation tool(s):
verilator, yosys`; the test policy was stale.

`CI-PPIF-VERIFY-HDL-TOOL-DEPENDENCY-REPAIR.1` aligns those PPIF tests with the
existing optional external-validation policy already used by
`t/308-systemverilog-external-validation.t`: PPIF `--verify-hdl` checks are
skipped when required external tools are unavailable, while non-HDL PPIF
coverage continues to run.

The same `t/1436` file passes in a simulated no-tool environment
(`PATH=/usr/bin:/bin`) and in the normal tool-equipped local environment, so
the guard does not suppress Verilator/Yosys coverage when the tools exist.
