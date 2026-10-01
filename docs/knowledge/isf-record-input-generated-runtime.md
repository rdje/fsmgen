---
id: isf-record-input-generated-runtime
title: Generated record-input behavior passes under SystemVerilog parsing
answers:
  - "is generated record-input native behavior qualified?"
  - "which generated record-input storage and binding behaviors pass?"
  - "does generated record-input runtime prove X/Z or reset-free initialization?"
date: 2026-10-01
status: current
tags: [isf, record-ports, composition, domains, runtime, verification]
evidence: docs/audits/record-input-generated-observation-complete-20261001/manifest.json; docs/audits/generated-binding-oracle-correction-20261001/manifest.json; docs/audits/typed-composition-carrier-repair-20261001/manifest.json; t/2025-isf-record-input-generated-runtime.t; t/data/isf_record_input_generated_domains_runtime.isf; t/data/isf_record_input_generated_blocking_runtime.isf; t/data/isf_record_input_generated_runtime_tb.sv; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 docs/audits/record-input-generated-observation-complete-20261001/verify.py
---

SEM .60.4.3.2.5.4.3.3.3 qualifies fresh generated_input_window_oct01 against
committed f606ce2fd01461039d279d13fa863478fe91d375 and the unchanged separately
qualified fixed observer. Named-domain spawned and ordinary parameterized
blocking sources compile and pass all selected public-pin predicates in both
Verilog-family targets. The actual same-width unsigned source compiles, passes
its bound-result observation and reaches the expected signed mismatch.

Both emitter options used `.sv` DUTs and Verilator default SystemVerilog parsing.
This is not IEEE 1364 Verilog-2005 qualification; the compatibility emitter
retains packed typedefs. SEM `.60.4.3.2.5.5.3.2.2` owns the precise profile
boundary before input signoff. Original positive/negative receipts stay immutable.

Positive predicates cover each copied packed leaf, prior held/entry sampled
values, reused live readers, signed comparisons, repeated requests, owning
asynchronous reset/abort, idle hold and unused clock-only sibling isolation.
The bound result is observed during public phase 1 before phase 2. Later checks
distinguish spawned forwarding from the blocking done-guarded combinational
default. These independent literals use the book's entry/copy/live/prior words.

Complete original stage arguments, results, bounds, summary, admission and
cleanup remain sealed. Every admitted/extra producer matches its exact Git
identity before and after; the overall target passes without skips. Native
events and capture/retention gaps are empty. Independent selected workspace
and command residue is absent. Successful-child native PID identities were
intentionally not captured, so individual PID absence is not independently
measured. Binary execution proves no X/Z behavior, reset-free initialization
or historical native EPERM cause. HIAL .11.7 owns the next genuine opportunity.

The original typed-wire compile rejection and partial blocking late-hold test
failure remain immutable. Their declaration and oracle corrections precede
this new capture; never replay any spent generated capture. Generated execution
reconciliation .5.4.4 is complete, joining current complete native/API/newline,
contextual refusal, package and prior scalar/storage checks to retained runtime.
Exact source/crosswalk/receipt evidence is in
docs/audits/generated-input-execution-reconciliation-20261001/. Supported
backend/input completion .5.5 remains open;
record outputs and complete SPECFORGE aggregate delivery are separate.

Full original genuine receipts and fixed source/bench products re-derive these
results. The actually executed unsigned counterexample and hostile saved
scope/result/bound/identity/native-gap/cleanup and signed-vector substitutions
provide distinct falsification. Sealed recipes/receipts, Git source objects,
qualified observer, task/book/response and this card provide durability. Saved
reverification compiles or executes no HDL and launches no native fixture.
