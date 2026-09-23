---
id: vhdl-deferred-until-sv-ial-complete
title: Direct HIAL VHDL sequencing and qualified VIAL profiles are separate contracts
answers:
  - "does --verify-hdl use the qualified VIAL GHDL profiles?"
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
date: 2026-09-23
status: current
tags: [vhdl, hial, vial, vhdl-2008, ghdl, osvvm, uvvm, backend, verification, roadmap, four-state, psl]
evidence: >-
  perl/FSM/Support/HDLExternalValidationContract.pm; docs/book/src/11-extensions-and-embedding.md;
  docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md;
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md;
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md;
  perl/FSM/VIAL/Backend/VHDLPortableGHDLQualification.pm;
  perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMGHDLQualification.pm;
  scripts/run_vial_vhdl_portable_ghdl_qualification.pl;
  scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl;
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json;
  vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json;
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
  scripts/run_with_ram_guard.sh -- prove -Iperl t/313-hdl-external-validation-contract.t t/297-capability-manifest.t &&
  scripts/run_with_ram_guard.sh -- perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check &&
  scripts/run_with_ram_guard.sh -- perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
---

Direct HIAL `StructuralRTLIR` VHDL rerouting retains its HIAL sequencing and
parity prerequisites. VIAL has independent target-neutral execution-plan and
portable-result contracts. Ordinary `--verify-hdl` remains SystemVerilog-only;
its contract has no GHDL stage. VIAL qualification does not widen that contract.

Decision `0051` selects provider-free IEEE VHDL-2008 as the VIAL portable
semantic core and OSVVM 2026.05 as its advanced methodology provider. GHDL
6.0.0 is the first exact analysis/elaboration/runtime tool. Completed `.15.5`
materialized the verified official macOS ARM64 LLVM release under a
repository-derived dependency root and qualified the canonical provider-free
fixture. Completed `.15.6` materialized the exact recursive OSVVM 2026.05
graph, and completed `.15.7` qualified that provider with exact GHDL 6.0.0.
UVVM 2026.03.20 was audited but is not the version-1 provider.

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
surface with no analyzer/runtime claim. Native VIAL has its own profile,
artifact graph, metadata package, manifest and source map. `.15.1-.15.5` own
provider-free emission/review/GHDL qualification; `.15.6-.15.7` own recursive
OSVVM materialization and combined qualification. That proof compiles 61
OSVVM/Common sources, analyzes the emitted graph and exercises randomization,
coverage, scoreboard, reporting, memory and barrier services, preserving the
portable normalized-result oracle.
