---
id: vial-portable-systemverilog-backend-v1
title: VIAL portable SystemVerilog uses deterministic inactive-edge scheduling and an exact known-value Verilator profile
answers:
  - "what is the first executable VIAL backend?"
  - "how does VIAL lower to plain SystemVerilog?"
  - "what exact Verilator version is selected for VIAL?"
  - "how does the VIAL SystemVerilog backend avoid clock races?"
  - "does the portable Verilator backend preserve X and Z?"
  - "does Verilator success prove full SystemVerilog or UVM support?"
  - "how are VIAL verification probes accessed in SystemVerilog?"
  - "what artifacts does the VIAL SystemVerilog backend produce?"
  - "what is the VIAL SystemVerilog runtime trace?"
  - "is the VIAL SystemVerilog backend implementation active?"
  - "how is VIAL backend implementation decomposed?"
  - "what owns VIAL backend implementation next?"
date: 2026-07-31
status: current
tags: [vial, systemverilog, verilator, backend, scheduler, known-value, four-state, source-map, result, jsonl]
evidence: docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; perl/FSM/VIAL/Backend/SVPortableVerilator.pm; perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/PlanBuilder.pm; t/1557-vial-portable-sv-backend-emission.t; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt; docs/book/src/16d-hial-vial-verification-architecture.md; ROADMAP_V2.md
reverify: perl -Iperl -c perl/FSM/VIAL/Backend/SVPortableVerilator.pm && perl -Iperl -c perl/FSM/VIAL/Backend/TraceValidator.pm && prove -Iperl t/1557-vial-portable-sv-backend-emission.t && rg -n 'sv_portable_verilator|known-value|inactive edge|--binary|--timing|--assert|generated_hierarchical_read_alias_v1|fsmgen.vial_sv_runtime_trace.v1|completed `.10.3`|active `.10.4`|201590d84' docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md ROADMAP_V2.md
---

Decision `0043` selects `sv_portable_verilator` as VIAL's first executable
backend contract. It statically partially evaluates one immutable execution
plan into a small non-UVM SystemVerilog runtime package, one fixture module,
the HIAL-generated DUT, complete generated-source maps, and normalized result
artifacts. Clean selection commit `ab3e73b72` activates parent `.10`; clean
activation commit `5fd766600` decomposes it into public source tooling,
planning/artifact, backend/trace, and exact runtime/result children. Completed
`.10.1` ships the public capabilities/check/normal-terse source surfaces.
Clean implementation commit `50a0d7d39` activates `.10.2`; completed `.10.2`
ships planning and target-neutral artifacts. Clean `.10.2` commit `045629c97`
activates `.10.3` alone for this backend and trace implementation. Completed
`.10.3` now ships a private deterministic emitter and pure trace validator.
Clean implementation commit `201590d84` activates `.10.4` for public
publication, exact tool execution, runtime capture, and normalized result
production without changing behavior during activation.

One scheduler samples at the clock's inactive edge, performs react/check work
in exact plan order, then applies the next logical cycle's drives before the
active DUT edge. VIAL authors see only drive/sample/react/check intent; target
regions, clocking blocks, event controls, and delays remain compiler details.

The reference profile is exactly Verilator 5.046 dated 2026-02-28 with
`--binary --timing --assert`, one build/runtime thread, deterministic X
concretization, explicit `1ns/1ps` default timescale, explicit top, and a
repository-local object directory. Compile, executable creation, run, trace,
result-schema, and semantic-outcome gates are independent.

This is a known-value/two-state runtime tier. Authored X/Z-sensitive meaning
fails negotiation, and the manifest states that full four-state observation is
not supported. A later qualified backend may disagree with a Verilator trace;
parity reports the mismatch. Verilator success never proves full SystemVerilog
or UVM support.

Only bridge-declared probes receive generated source-mapped hierarchy
adapters. The private emitter returns one sorted eight-artifact virtual graph:
the generated HIAL DUT, runtime package, fixture module, backend/source-map/
tool-profile records, and selected-but-unexecuted compile/run commands. One
inactive-edge scheduler also latches `parallel` child satisfaction, so target
process ordering is never semantic authority. Backend caps stay outside
target-neutral ExecutionIR limits and therefore do not change its plan ID.

The runtime representation is a closed prefixed JSONL trace. The shipped pure
validator accepts caller-supplied bytes and projects
`fsmgen.vial_sv_trace_projection.v1` without rerunning VIAL scheduling, models,
scoreboards, coverage, faults, or decisions. It produces no normalized result
manifest and executes no simulator in `.10.3`. `.10.4` owns those gates;
`.11` alone owns parity with the handwritten AHB oracle.
