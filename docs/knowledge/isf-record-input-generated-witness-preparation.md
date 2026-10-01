---
id: isf-record-input-generated-witness-preparation
title: Generated input witnesses prepare live readers and whole-copy ownership before runtime
answers:
  - "where is generated record-input runtime preparation owned?"
  - "how do generated input witnesses distinguish live reads and whole copies?"
  - "are spawned output bindings guarded by child completion?"
date: 2026-10-01
status: current
tags: [isf, record-ports, verification, runtime, domains, composition]
evidence: t/2025-isf-record-input-generated-runtime.t; t/data/isf_record_input_generated_domains_runtime.isf; t/data/isf_record_input_generated_blocking_runtime.isf; t/data/isf_record_input_generated_runtime_tb.sv; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; docs/book/src/13f-composition.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib t/2025-isf-record-input-generated-runtime.t
---

SEM .60.4.3.2.5.4.1 prepares T2025's fixed named-domain spawned copier and
ordinary parameterized blocking copier sources. Both reuse separately activated
reader instances with explicit scalar output bindings. Parent-owned phase pins
separate independently authored entry, whole-copy and later live packed words.
The public-pin bench expects every copied packed leaf, live reader data and
signed comparisons, sampled/prior-held values, idle hold, repeated requests and
owning asynchronous reset/abort. An unused clock-only sibling remains in its
named domain; changing its input/clock is part of the prepared isolation oracle,
with no guarantee about initial state in reset-free hardware.

Spawned output bindings forward child outputs without a completion guard;
parameterized blocking `do` output bindings use the child's done guard. This
scope comes from the documented blocking-call contract and actual emitted
role-specific assignments, not a generalization to all generated calls.
The first unqualified draft wrongly expected a guard on spawned reader outputs
and renamed replay artifact files so normal child-source lookup failed. Correct
literal call-role assignments and a complete same-directory artifact cohort
repair those preparation oracles without changing production behavior.
A subsequent real blocking run exposed the bench's late-retention assumption.
Correction .5.4.3.3.2 observes the bound result during public phase 1 and checks
its documented role at later completion/idle, retaining all packed state
predicates. Exact old-bench RED, independent temporal/packed controls and sealed
byte reconstruction qualify this test correction before fresh complete runtime.

Actual parser/caller JSON, lowered artifacts, typed private packet/data/enable
roles, exact whole public/private wiring, owning/reset-free declarations, strict
native replay and both emitted Verilog-family products re-derive preparation.
Independent literal declarations and disabled actual write-enable/unsigned
authored property counterexamples falsify weaker structural claims. Fixed
test/source/bench, tasks, this card, book and Git provide durability. An actual
unsigned behavioral counterexample is emitted for later execution. Genuine
HDL compilation/execution remains gated by separately qualified fixed observer
.5.4.2 and fresh observation .5.4.3; preparation does not establish runtime,
X/Z behavior, historical EPERM repair or complete record-input delivery.
