---
id: isf-record-input-direct-runtime
title: Direct packed-input public-pin behavior is qualified separately from generated domains
answers:
  - "which direct record-input runtime behavior is qualified?"
  - "does record-input runtime establish four-state behavior or native EPERM causality?"
  - "where is the recoverable direct packed-input runtime observation?"
date: 2026-10-01
status: current
tags: [isf, record-ports, verification, runtime]
evidence: docs/audits/record-input-signoff-20261001/manifest.json; docs/audits/record-input-direct-observation-20261001/manifest.json; t/2024-isf-record-input-runtime.t; t/data/isf_record_input_runtime_tb.sv; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 docs/audits/record-input-direct-observation-20261001/verify.py
---

SEM .60.4.3.2.5.3 consumes the committed corrected fixed observer and fresh
exclusive record_input_direct_oct01 admission for genuine T2024 execution.
Both emitted Verilog families pass the independently literal public-pin bench:
entry sampling, later live scalar reads, whole-input copy edge, held reset/prior
values, nested packed layout, signed comparison, idle hold, repeated requests
and asynchronous reset/abort. The actually authored unsigned same-width source
compiles and reaches the expected PACKED_SIGNED_MISMATCH rejection. Complete
TAP has no runtime skip. Original stage arguments/results/bounds and supervisor
cleanup remain, with exact admitted plus extra producer identities before/after.

Both emitter options used `.sv` DUTs and Verilator default SystemVerilog parsing.
This is not IEEE 1364 Verilog-2005 qualification; the compatibility emitter
retains packed typedefs. SEM `.60.4.3.2.5.5.3.2.2` qualifies the precise current ISF Verilog/v
refusal; `.3.2.3` closes selected input delivery. Original positive/negative receipts stay immutable.

The sealed archive retains full receipts, test/source/bench, producer Git blobs,
TAP/stdout/stderr and independent workspace/command census. Normal temporary
cleanup removes generated HDL/binaries. Successful native calls intentionally
produce no context records, so individual successful-child PID absence is not
independently measured. Native events and diagnostic gaps are empty. Historical
EPERM remains P1-open. HIAL .11.6 subsequently completes generated/domain
observation without native rejection; .11.7 schedules the next genuinely required
feature HDL qualification. No recurrence-only retry follows this pass.

Actual stage receipts, literal bench expectations and exact Git sources provide
re-derivation. The compiled unsigned source and hostile saved bounds, marker,
cleanup, assertion, identity, gap, target and result mutations provide distinct
falsification. Tracked immutable evidence, source/test/bench, tasks, book and Git
provide durability. Binary Verilator values do not establish X/Z behavior;
signed/state declarations have separate structural witnesses. Generated/domain
execution .5.4 is subsequently qualified and reconciled; backend/input
completion .5.5 is qualified; record outputs and aggregate consumer delivery remain open. Reverify consumes saved records only.
