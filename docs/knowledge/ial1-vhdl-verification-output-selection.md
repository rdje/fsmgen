---
id: ial1-vhdl-verification-output-selection
title: VHDL verification output remains deferred behind validation-substrate selection
answers:
  - "does FSMGen generate VHDL verification output?"
  - "what did IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5 decide?"
  - "why is there no VHDL verification artifact yet?"
  - "what owns VHDL verification validation selection?"
  - "is GHDL available for VHDL verification output?"
  - "can --language vhdl emit verification assertions or PSL?"
  - "does verification_observations generate VHDL verification code?"
date: 2026-06-26
status: current
tags: [ial1, vhdl, verification, validation, task-tree]
evidence: docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/VHDL_SCOPE.md; docs/knowledge/direct-vhdl-scaffold.md; docs/knowledge/vhdl-deferred-until-sv-ial-complete.md; perl/FSM/Support/HDLExternalValidationContract.pm; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm; t/1420-vhdl-direct-backend-scaffold.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.5|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.9|VHDL verification validation|GHDL validation|vhdl_validation_deferred_until_ghdl_validation_lane|verification_observations\\[\\]' docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/VHDL_SCOPE.md perl/FSM/Support/HDLExternalValidationContract.pm README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen does not currently ship a VHDL-oriented verification-output artifact.

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5` audited VHDL assertion,
testbench, and PSL feasibility against the shipped VHDL scaffold and validation
environment. The selector did not choose a VHDL assertion, PSL sidecar, VHDL
testbench shell, package, or monitor-like artifact. It recorded that VHDL
verification generation remains deferred behind the smaller prerequisite
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`, which must select the first
VHDL verification validation substrate.

The reason is concrete: the current VHDL path is a synthesizable scaffold, not
a verification-output path, and the external HDL validation contract remains
SystemVerilog-only. GHDL validation is explicitly deferred, and `ghdl` was not
available in the local selector environment. `verification_observations[]`
remains passive report metadata and is consumed today only by the explicit
`uvm-passive-monitor` verification-output mode.

The shipped verification-output target remains the inert SystemVerilog/UVM
passive-monitor skeleton package plus `verification-output-manifest.json` for
`.isf` sources with passive `verification_observations[]`; it does not imply
VHDL verification, PSL, testbench, coverage, scoreboard, or reusable VIP
support.
