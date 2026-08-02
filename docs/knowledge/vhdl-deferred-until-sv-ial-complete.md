---
id: vhdl-deferred-until-sv-ial-complete
title: Direct HIAL VHDL remains separately sequenced while VIAL VHDL now has an exact provider-free and OSVVM architecture
answers:
  - "should VHDL backend work happen before SV backend feature completeness?"
  - "when should direct VHDL rerouting resume?"
  - "is R11-DIRECT-STRUCTURAL-VHDL-REROUTING PNT-ready?"
  - "is VHDL deferred until IAL0 IAL1 IAL2 are feature complete?"
  - "what is the selected VIAL VHDL verification backend?"
  - "does VIAL VHDL require OSVVM?"
  - "did FSMGen select OSVVM or UVVM?"
  - "what exact OSVVM version is selected for VIAL?"
  - "what exact GHDL version is selected for VIAL?"
  - "is GHDL installed and qualified for VIAL?"
  - "how does VIAL logical time map to VHDL?"
  - "how do VIAL four-state values map to std_logic?"
  - "does the VIAL VHDL backend require PSL?"
  - "how are VIAL scoreboards and coverage implemented in VHDL?"
  - "may OSVVM rerandomize portable VIAL decisions?"
  - "what artifacts will the VIAL VHDL backend generate?"
  - "what happens to the legacy VHDL observation package?"
  - "does selecting GHDL imply VHDL compile support now?"
  - "can VHDL generation progress before GHDL is available?"
date: 2026-08-01
status: current
tags: [vhdl, hial, vial, vhdl-2008, ghdl, osvvm, uvvm, backend, verification, roadmap, four-state, psl]
evidence: >-
  docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md;
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md;
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md;
  perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm;
  perl/FSM/Support/VerificationOutputsContract.pm;
  t/1465-isf-verification-output-vhdl-observation-package.t;
  t/297-capability-manifest.t;
  docs/TASK_TREE.md;
  ROADMAP_V2.md;
  docs/book/src/16d-hial-vial-verification-architecture.md;
  https://ghdl.github.io/ghdl/using/ImplementationOfVHDL.html;
  https://github.com/ghdl/ghdl/releases/tag/v6.0.0;
  https://github.com/OSVVM/OsvvmLibraries/releases/tag/2026.05;
  https://github.com/UVVM/UVVM/releases/tag/2026.03.20
reverify: >-
  rg -n 'vhdl_portable_ghdl|vhdl_osvvm_qualified|6\.0\.0|2026\.05|provider-free|unchanged_not_consumed|PSL' docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md
---

The historical direct-HIAL decision remains narrow: do not promote the direct
`StructuralRTLIR` VHDL reroute ahead of its separately owned HIAL sequencing
and parity prerequisites. That does not defer the independent VIAL
verification backend, whose target-neutral execution plan and portable result
contracts are now mature enough for exact architecture selection.

Decision `0051` selects provider-free IEEE VHDL-2008 as the VIAL portable
semantic core and OSVVM 2026.05 as its advanced methodology provider. GHDL
6.0.0 is the first exact analysis/elaboration/runtime tool, but it is not
installed locally; both profiles are selected and unexecuted rather than
supported runtime capabilities. UVVM 2026.03.20 was audited but is not the
version-1 provider.

`vhdl_portable_ghdl` statically lowers one bound execution plan into standard
VHDL packages, a deterministic single-clock scheduler/testbench, explicit
probe adapters, a closed trace, and normalized results. The inactive-edge
barrier and exact plan ranks remain semantic authority; delta cycles and
process wake-up order do not.

VIAL `0/1/X/Z` drives strong `std_logic` values. Sampling maps `L/H` to known
`0/1`, `Z` to `Z`, and `U/X/W/-` to VIAL `X`, retaining the original VHDL
symbol as representation evidence. Version 1 does not claim distinct
nine-state authored semantics.

`vhdl_osvvm_qualified` adds negotiated OSVVM mappings for advanced
randomization, coverage, scoreboards, reporting, synchronization, and
verification components. Portable random choices remain pre-resolved and may
not be rerandomized. OSVVM reports are supplementary evidence; the normalized
FSMGen result remains the parity oracle.

Portable properties use procedural checks rather than PSL. GHDL documents
partial VHDL-2008 and PSL support, so any future PSL profile must name the
exercised subset and flags independently.

The legacy `vhdl-observation-package` remains an unchanged inert compatibility
surface with no analyzer/runtime claim. Native VIAL uses a separate profile,
artifact graph, metadata package, manifest, and source map. Reviewable emission
may proceed before GHDL is available, while analysis, elaboration, run, result,
parity, and OSVVM capability claims wait for `.15` exact gates.
