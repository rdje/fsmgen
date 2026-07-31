---
id: hial-vial-verification-fixture-architecture
title: VIAL uses one public source, two private IRs, and a versioned HIAL bridge
answers:
  - "what do HIAL and VIAL mean in FSMGen?"
  - "does FSMGen plan a Verification IAL?"
  - "where is powerful verification fixture generation tracked?"
  - "should HIAL lower to SystemVerilog and VHDL?"
  - "should VIAL lower to SV UVM and VHDL verification code?"
  - "will VIAL have VIAL0 VIAL1 and VIAL2 layers?"
  - "what is VIALSemanticIR?"
  - "what is VIALExecutionIR?"
  - "what is HIALVIALBridgeManifest?"
  - "how do HIAL designs connect to VIAL fixtures?"
  - "how can VIAL use native SV UVM or VHDL power?"
  - "how is portable VIAL backend parity judged?"
  - "what are VIAL drive sample react check phases?"
  - "what is the first runnable VIAL backend?"
  - "is Verilator enough to validate full SystemVerilog and UVM VIAL output?"
  - "what simulator capability profiles does VIAL require?"
  - "is Verilator a traditional event-driven simulator?"
  - "does Verilator support events with timing enabled?"
  - "is the HIAL VIAL architecture selected now?"
  - "what is the next HIAL VIAL task?"
date: 2026-07-31
status: current
tags: [hial, vial, ial0, ial1, ial2, verification, semantic-ir, execution-ir, bridge, sv-uvm, vhdl, verilator, simulator-profile, architecture, task-tree]
evidence: docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md; docs/decisions/0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/decisions/0004-simulate-to-catch-codegen-bugs.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16d-hial-vial-verification-architecture.md; https://www.accellera.org/downloads/standards/uvm; https://verilator.org/guide/latest/languages.html; https://verilator.org/guide/latest/connecting.html; https://ghdl.github.io/ghdl/using/ImplementationOfVHDL.html; https://osvvm.org/about-os-vvm; https://uvvm.github.io/
reverify: scripts/check_task_tree_integrity.pl && rg -n 'one public.*\.vial|VIALSemanticIR|VIALExecutionIR|HIALVIALBridgeManifest|core_directed_single_clock_v1|drive.*sample.*react.*check|sv_portable_verilator|sv_uvm_qualified|vhdl_portable_ghdl|vhdl_methodology_qualified|mixed_language_qualified|normalized.*result|Proposed `\.3`' docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md docs/decisions/0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md ROADMAP_V2.md docs/book/src/16d-hial-vial-verification-architecture.md
---

Hardware IAL (HIAL) is the collective architecture name for FSMGen's current
synthesizable IAL0/IAL1/IAL2 stack. Its public names and review route remain
unchanged. Verification IAL (VIAL) is its future pure-verification peer.

Decision `0032` selects one public, reviewable `.vial` source language rather
than VIAL0/VIAL1/VIAL2. Private immutable `VIALSemanticIR` owns unbound typed
verification meaning. A bounded versioned `HIALVIALBridgeManifest` supplies
sanitized HIAL units, configuration, types, endpoints, clocks/resets,
transactions/events, protocol facts, observations/probes, backend bindings,
capabilities, source identity, and source maps. Private immutable
`VIALExecutionIR` owns the bound, capability-checked deterministic plan.

Portable VIAL covers typed stimulus, transactions, scenarios, deterministic
fibers, expected outcomes, temporal checks, reference models, scoreboards,
coverage, bounded fault injection, and reproducible randomness. Execution uses
logical `drive`, `sample`, `react`, and `check` phases. Native target power is
provided by typed external repository-relative extensions, never anonymous raw
SV/UVM or VHDL embedded in portable source.

Portable backend parity compares normalized logical result manifests, not
generated source or waveforms. Public ports are the portable access baseline;
declared HIAL verification probes require capability-qualified equivalent
adapters; raw hierarchy is native-only. IAL2 facts must remain reviewable
through generated IAL1 before the bridge consumes them, so there is still no
direct `.ppif` verification-output path.

The first runnable profile is `sv_portable_verilator`, using plain generated
SystemVerilog and exact `--binary --timing` compile/elaborate/run evidence.
Verilator is event-capable compiled simulation for its supported features, not
complete SystemVerilog or UVM authority. `sv_uvm_qualified`,
`vhdl_portable_ghdl`, `vhdl_methodology_qualified`, and
`mixed_language_qualified` remain separate claims with exact tools, versions,
providers, and exercised capabilities. Existing UVM 1.2 and VHDL observation
outputs remain inert compatibility surfaces until later migration leaves.

The architecture audit is complete and maps the handwritten AHB arbitration
fixture, migration, public artifacts, parity, and scale boundaries. Clean audit
commit `2e2f7d25e` activated only
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2`; completed `.2` now selects the
exact spanned `.vial` version-1 language and private typed `VIALSemanticIR`
under decision `0033`. Proposed `.3` alone owns implementation after separate
clean activation; no parser, source, report, or product behavior ships in the
contract slice.
