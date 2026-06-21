---
id: hdl-validation-slang-candidate
title: Slang validation is a future optional backend-validation candidate
answers:
  - "should FSMGen add slang to --verify-hdl?"
  - "does --verify-hdl currently run slang?"
  - "why not add slang during IAL2-FEATURE-COMPLETENESS-FRONTIER.194?"
  - "what is the planned stance on slang HDL validation?"
date: 2026-06-21
status: current
tags: [backend-validation, systemverilog, slang, verilator, yosys, verify-hdl]
evidence: perl/FSM/Support/HDLExternalValidation.pm; README.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'slang|verilator|yosys|verify-hdl|HDLExternalValidation' perl/FSM/Support/HDLExternalValidation.pm README.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
---

`--verify-hdl` currently requires Verilator and Yosys for the default external
SystemVerilog validation lane. The default path is Verilator lint plus
ABC-free Yosys structural synthesis; ABC mapping is separate optional
in-process validation and is not required by the CLI default.

Adding `slang` is an agreed future direction because it would provide an
independent SystemVerilog frontend and catch portability issues that Verilator
or Yosys may accept or diagnose differently. It is not part of
`IAL2-FEATURE-COMPLETENESS-FRONTIER.194` because it changes external
validation policy and tool prerequisites.

The conservative implementation plan is a future backend-validation slice:
discover `slang`, run it when available, skip cleanly when absent, document the
optional lane, and only later decide whether it should become required. No code
change for `slang` may happen before that future task-tree owner exists.
