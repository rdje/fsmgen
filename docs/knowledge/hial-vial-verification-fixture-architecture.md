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
  - "what is the VIAL version 2 source and migration contract?"
  - "is the VIAL v2 common envelope implemented?"
  - "where is the VIAL semantic family registry and profile negotiation?"
  - "where is the common VIAL backend adapter preflight?"
  - "which VIAL backend profiles have compile runtime result parity maturity?"
  - "what is the next HIAL VIAL task?"
  - "is a mixed-language HIAL VIAL simulator available?"
  - "why is mixed-language qualification not active?"
  - "where should I start reading about HIAL and VIAL?"
  - "how is the HIAL VIAL mdBook being organized?"
  - "how do I run the checked AHB HIAL VIAL tutorial?"
  - "how do I migrate observe metadata and legacy verification skeletons to VIAL?"
  - "where is the exact VIAL capability support parity and troubleshooting matrix?"
date: 2026-09-04
status: current
tags: [hial, vial, ial0, ial1, ial2, verification, semantic-ir, execution-ir, bridge, simulator-profile, architecture, task-tree]
evidence: >-
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md;
  docs/VIAL_SOURCE_AND_SEMANTIC_IR_V2_CONTRACT.md;
  docs/vial-spec/semantic-family-envelope-and-registry.md;
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
  t/1555-vial-public-source-tooling.t;
  t/1801-vial-v2-source-projections.t; t/1802-vial-v2-semantic-family-envelope.t;
  t/1803-vial-v2-family-registry.t; t/1804-vial-v2-backend-adapter-seams.t;
  t/1556-vial-public-planning-artifacts.t;
  t/1557-vial-portable-sv-backend-emission.t;
  t/1558-vial-verilator-run-integration.t;
  t/1559-vial-ahb-runtime-parity.t;
  t/1796-hial-vial-book-entry-path.t;
  t/1798-hial-vial-ahb-end-to-end-tutorial.t;
  t/1799-hial-vial-legacy-migration.t;
  t/1800-hial-vial-capability-support-reference.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/TASK_TREE.md; README.md; ROADMAP_V2.md;
  docs/book/src/14e-hial-vial-verification.md;
  docs/book/src/16d-hial-vial-verification-architecture.md;
  docs/book/src/16dh-vial-ahb-end-to-end-tutorial.md;
  docs/book/src/16di-vial-legacy-migration.md;
  docs/book/src/16dj-vial-capability-support-reference.md
reverify: >-
  scripts/check_task_tree_integrity.pl &&
  rg -n 'sv_portable_verilator|vhdl_portable_ghdl|vhdl_osvvm_qualified|mixed_language_qualified|drive|sample|react|check'
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  prove -Iperl t/1555-vial-public-source-tooling.t
  t/1801-vial-v2-source-projections.t t/1802-vial-v2-semantic-family-envelope.t
  t/1803-vial-v2-family-registry.t t/1804-vial-v2-backend-adapter-seams.t
  t/1556-vial-public-planning-artifacts.t
  t/1557-vial-portable-sv-backend-emission.t
  t/1558-vial-verilator-run-integration.t
  t/1559-vial-ahb-runtime-parity.t
  t/1796-hial-vial-book-entry-path.t
  t/1798-hial-vial-ahb-end-to-end-tutorial.t
  t/1799-hial-vial-legacy-migration.t
  t/1800-hial-vial-capability-support-reference.t
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

The first runnable profile, `sv_portable_verilator`, uses plain-SystemVerilog
lowering, inactive-edge scheduling, declared probes, a closed trace, and exact
Verilator 5.046 gates. It is known-value/two-state, not complete four-state,
SystemVerilog, or UVM authority. UVM, VHDL, methodology, and mixed-language
profiles keep separate exact capability states; legacy observation outputs are
inert compatibility surfaces.

Shipped behavior covers typed frontend, review-routed bridge, ExecutionIR,
public source/plan/run tools, atomic portable-SV results, and bounded AHB
parity. VHDL/GHDL and OSVVM are qualified private profiles; native UVM is
review/experiment evidence. Separate successes cannot satisfy the proposed
mixed-language route.

Foundation `.19.1.1-.19.1.5` implements private v2 parsing/projections/imports,
the common family envelope, empty-family plans, and content-addressed family
and backend-adapter registries with exact v1 preservation. Its twelve selected
namespaces have no functional or backend maturity. All four emitters admit only
exact typed ExecutionIR and reject complete unsupported sets before rendering;
OSVVM also rejects before portable delegation or provider access. The adapter
registry keeps the public portable-SV, review-only native-UVM, private portable-
VHDL, and private OSVVM maturity states distinct. Public v2 tooling and family
implementations/results/parity/support remain later.

The architecture is selected. `HIAL-VIAL-VERIFICATION-FIXTURE-
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
