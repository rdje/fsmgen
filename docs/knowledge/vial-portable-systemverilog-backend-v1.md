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
evidence: docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt; docs/book/src/16d-hial-vial-verification-architecture.md; ROADMAP_V2.md
reverify: verilator --version && rg -n 'sv_portable_verilator|known-value|inactive edge|--binary|--timing|--assert|generated_hierarchical_read_alias_v1|fsmgen.vial_sv_runtime_trace.v1|completed `.10.1`|5fd766600' docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md ROADMAP_V2.md
---

Decision `0043` selects `sv_portable_verilator` as VIAL's first executable
backend contract. It statically partially evaluates one immutable execution
plan into a small non-UVM SystemVerilog runtime package, one fixture module,
the HIAL-generated DUT, complete generated-source maps, and normalized result
artifacts. Clean selection commit `ab3e73b72` activates parent `.10`; clean
activation commit `5fd766600` decomposes it into public source tooling,
planning/artifact, backend/trace, and exact runtime/result children. Completed
`.10.1` ships the public capabilities/check/normal-terse source surfaces.
Clean implementation commit `50a0d7d39` activates `.10.2` for planning and
artifacts, while `.10.3` still owns this backend and trace implementation.

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

Only bridge-declared probes may receive generated source-mapped hierarchy
adapters. The runtime emits a closed prefixed JSONL trace; the host validates
and projects it into the selected result manifest without rerunning VIAL
scheduling, models, scoreboards, coverage, faults, or decisions. `.11` alone
owns parity with the handwritten AHB oracle.
