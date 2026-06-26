---
id: ial1-vhdl-verification-validation-substrate-selection
title: VHDL verification validation starts with a shape-only inert-artifact substrate
answers:
  - "what VHDL verification validation substrate is selected?"
  - "does VHDL verification output use GHDL validation?"
  - "does the VHDL verification substrate claim compile support?"
  - "what owns the first VHDL verification artifact after substrate selection?"
  - "does the VHDL verification substrate support PSL?"
  - "can a future VHDL verification skeleton be shape-only?"
date: 2026-06-26
status: current
tags: [ial1, vhdl, verification, validation, task-tree]
evidence: docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md; docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md; docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/VHDL_SCOPE.md; perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm; perl/FSM/Support/HDLExternalValidationContract.pm; perl/FSM/Support/VerificationOutputsContract.pm; t/1464-isf-verification-output-uvm-passive-monitor.t; t/1465-isf-verification-output-vhdl-observation-package.t; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION|IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.9|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.10|IAL1-VERIFICATION-CODE-GENERATION-FRONTIER\\.11|ObservationPackageSkeleton|artifact-shape|inert-behavior|claimed_vhdl_compile_support|vhdl_syntax_validator|claimed_psl_support|vhdl-observation-package|GHDL validation' docs/IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md docs/IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md docs/VHDL_SCOPE.md perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm t/1465-isf-verification-output-vhdl-observation-package.t README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
---

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9` selected the first VHDL
verification validation substrate as artifact-shape and inert-behavior checks
with explicit manifest non-claims.

The substrate does not use GHDL, NVC, ModelSim/Questa `vcom`, PSL analysis,
simulation, elaboration, or syntax compilation. It may only be used for a
future inert, reviewable VHDL-oriented verification skeleton that records no
VHDL compile support, no VHDL syntax validator, no PSL support, and no PSL
validator while still proving artifact location, naming, manifest shape,
source identity, observation projection, and absence of runtime behavior.

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10` selected the first artifact
under this substrate: an inert VHDL observation metadata package target named
`vhdl-observation-package`. `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11`
implements that target under the same shape-only, inert validation substrate.
Any artifact that claims VHDL syntax, compile,
simulation, formal, PSL, coverage, scoreboard, reusable VIP, or direct IAL2
behavior needs a later validation owner before implementation.
