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
  - "is a mixed-language HIAL VIAL simulator available?"
  - "why is mixed-language qualification not active?"
  - "where should I start reading about HIAL and VIAL?"
  - "how is the HIAL VIAL mdBook being organized?"
  - "how do I run the checked AHB HIAL VIAL tutorial?"
  - "how do I migrate observe metadata and legacy verification skeletons to VIAL?"
date: 2026-09-04
status: current
tags: [hial, vial, ial0, ial1, ial2, verification, semantic-ir, execution-ir, bridge, simulator-profile, architecture, task-tree]
evidence: >-
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md;
  docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md;
  docs/VIAL_EXECUTION_IR_V1_CONTRACT.md;
  docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md;
  docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md;
  docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md;
  docs/decisions/0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md;
  docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md;
  docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md;
  docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md;
  docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md;
  docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md;
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm;
  perl/FSM/VIAL/Backend/TraceValidator.pm;
  perl/FSM/VIAL/Parity/AHBBaseOutput.pm;
  t/1555-vial-public-source-tooling.t;
  t/1556-vial-public-planning-artifacts.t;
  t/1557-vial-portable-sv-backend-emission.t;
  t/1558-vial-verilator-run-integration.t;
  t/1559-vial-ahb-runtime-parity.t;
  t/1796-hial-vial-book-entry-path.t;
  t/1798-hial-vial-ahb-end-to-end-tutorial.t;
  t/1799-hial-vial-legacy-migration.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/TASK_TREE.md; README.md; ROADMAP_V2.md;
  docs/book/src/14e-hial-vial-verification.md;
  docs/book/src/16d-hial-vial-verification-architecture.md;
  docs/book/src/16dh-vial-ahb-end-to-end-tutorial.md;
  docs/book/src/16di-vial-legacy-migration.md
reverify: >-
  scripts/check_task_tree_integrity.pl &&
  rg -n 'sv_portable_verilator|vhdl_portable_ghdl|vhdl_osvvm_qualified|mixed_language_qualified|drive|sample|react|check'
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  prove -Iperl t/1555-vial-public-source-tooling.t
  t/1556-vial-public-planning-artifacts.t
  t/1557-vial-portable-sv-backend-emission.t
  t/1558-vial-verilator-run-integration.t
  t/1559-vial-ahb-runtime-parity.t
  t/1796-hial-vial-book-entry-path.t
  t/1798-hial-vial-ahb-end-to-end-tutorial.t
  t/1799-hial-vial-legacy-migration.t
---

Hardware IAL (HIAL) names FSMGen's synthesizable IAL0/IAL1/IAL2 stack;
Verification IAL (VIAL) is its pure-verification peer. Decision `0032` selects
one public `.vial` language, not VIAL0/VIAL1/VIAL2. Private immutable
`VIALSemanticIR` owns unbound typed meaning, a versioned
`HIALVIALBridgeManifest` supplies sanitized reviewable HIAL facts, and private
immutable `VIALExecutionIR` owns the bound deterministic plan.

Portable VIAL covers typed stimulus, scenarios, fibers, checks, models,
scoreboards, coverage, faults, and reproducible randomness through logical
`drive`, `sample`, `react`, and `check` phases. Typed native extensions retain
target power without anonymous raw target code. Parity compares normalized
logical results, not generated source or waveforms. IAL2 facts remain
reviewable through generated IAL1; there is no direct `.ppif` verification-
output path.

The first runnable profile is `sv_portable_verilator`, using static plain-
SystemVerilog lowering, inactive-edge scheduling, declared-probe adapters, a
closed result trace, and exact Verilator 5.046 `--binary --timing --assert`
gates. It is explicitly a known-value/two-state runtime profile, not complete
four-state, SystemVerilog, or UVM authority. `sv_uvm_qualified`,
`vhdl_portable_ghdl`, methodology, and mixed-language profiles remain separate
claims whose public/private/review/unavailable state must be reported exactly.
Existing UVM 1.2 and VHDL observation outputs remain inert compatibility
surfaces.

The shipped stack now covers the typed `.vial` frontend, review-routed bridge,
bound deterministic ExecutionIR, public source/planning/run tools, atomic
artifacts, portable-SystemVerilog execution, normalized results, and the
selected 19-path AHB parity oracle. General cross-backend parity remains
unclaimed.

Provider-free VHDL/GHDL and the additive OSVVM tier are exact qualified private
profiles. Native UVM has deterministic review emission and separate
experimental evidence, not a qualified product runtime. Separate
Verilator/GHDL qualifications cannot satisfy `mixed_language_qualified`;
`.16` remains proposed until one exact compatible mixed-language route exists.

Documentation closeout `.18` routes README/SUMMARY through the overview and
selected lifecycle, tutorial, and migration guides; backlog is future-only.
Together they cover HIAL review, planning, public portable-SystemVerilog runs,
normalized outcomes, 19-path parity, VHDL/OSVVM qualification, and stable
legacy outputs beside VIAL successors. T1796/T1798/T1799 watch these routes; a
later child owns the capability reference.

The architecture is selected, not proposed. `HIAL-VIAL-VERIFICATION-FIXTURE-
ARCHITECTURE` is the owning tree and the only authority for the current
frontier; read its live frontier row rather than any copied value. Each backend
family, runtime and native framework direction, and the scale programme keeps
its own card:

- native UVM emission and the PGEN/NEXSIM qualified tier:
  [[vial-native-uvm-emission-contract]]
- the exact tool-limited Verilator UVM probe:
  [[vial-native-uvm-experimental-probe]]
- provider-free VHDL and its exact GHDL qualification:
  [[vial-vhdl-portable-profile]]
- the advanced OSVVM provider tier: [[vial-vhdl-osvvm-qualified-tier]]
- the proposed HDL-independent runtime: [[iasim-executable-reference-semantics]]
- the surrounding no-HDL ecosystem: [[xial-native-development-framework]]
- architecture-scale proof: [[vial-architecture-scale-proof]]
