---
id: ial1-vhdl-verification-output-selection
title: VHDL verification output has one bounded inert package target
answers:
  - "does FSMGen generate VHDL verification output?"
  - "what did IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5 decide?"
  - "what VHDL verification artifact ships?"
  - "what owns VHDL verification validation selection?"
  - "is GHDL available for VHDL verification output?"
  - "can --language vhdl emit verification assertions or PSL?"
  - "does verification_observations generate VHDL verification code?"
date: 2026-06-26
status: current
tags: [ial1, vhdl, verification, validation, task-tree]
evidence: >-
  docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md; docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md; docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/VHDL_SCOPE.md; docs/knowledge/direct-vhdl-scaffold.md; docs/knowledge/vhdl-deferred-until-sv-ial-complete.md; docs/knowledge/ial1-vhdl-verification-validation-substrate-selection.md; docs/knowledge/ial1-vhdl-observation-package-selection.md; perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm; perl/FSM/Support/HDLExternalValidationContract.pm; perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm; perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm; t/1420-vhdl-direct-backend-scaffold.t; t/1465-isf-verification-output-vhdl-observation-package.t; README.md; ROADMAP_V2.md;
  docs/book/src/14-feature-backlog.md
reverify: >-
  rg -n 'IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION|IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION|IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.5|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.9|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.10|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.11|ObservationPackageSkeleton|vhdl-observation-package|vhdl_observation_package_skeleton|shape-only|GHDL validation|vhdl_validation_deferred_until_ghdl_validation_lane|verification_observations\\[\\]' docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/VHDL_SCOPE.md
  perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm perl/FSM/Support/HDLExternalValidationContract.pm t/1465-isf-verification-output-vhdl-observation-package.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

FSMGen now ships one bounded VHDL-oriented verification-output artifact.

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5` audited VHDL assertion,
testbench, and PSL feasibility against the shipped VHDL scaffold and validation
environment. The selector did not choose a VHDL assertion, PSL sidecar, VHDL
testbench shell, or monitor-like behavior. It recorded that VHDL verification
generation first needed `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`, which
selected shape-only inert-artifact validation with explicit no-compile/no-PSL
manifest claims. `.10` then selected the first VHDL artifact: an inert
observation metadata package, target `vhdl-observation-package`, and `.11`
implemented it.

The reason is concrete: the `--language vhdl` path remains a synthesizable
scaffold, not a VHDL verification path, and the external HDL validation
contract remains SystemVerilog-only. GHDL validation is explicitly deferred,
and `ghdl` was not available in the local selector environment.
`verification_observations[]` remains passive report metadata and is consumed
today by the explicit `uvm-passive-monitor` and
`vhdl-observation-package` verification-output modes. The `.9` substrate does
not claim VHDL syntax, compile, PSL, simulation, formal, or analyzer support.

The VHDL target emits only an inert metadata package plus
`verification-output-manifest.json` for `.isf` sources with passive
`verification_observations[]`; it does not imply VHDL compile/syntax
validation, PSL, testbench, coverage, scoreboard, reusable VIP, simulator,
analyzer, formal, or direct IAL2 support.
